import Foundation
import os.log

enum StoreAction {
  case saveNewThought(title: String, body: String)
}

actor Store {
  
  /// Current in-memory source of truth for the state of the model,
  /// known to the current running instance of the app.
  ///
  /// UI sends actions to manipulate this source of truth, which then gets stored
  /// to local cache and persisted to CloudKit.
  ///
  /// This is bootstrapped from local cache when the app starts.
  ///
  /// Manipulations can also arrive through CloudKit, modeled as async stream.
  /// Those manipulations are applied to this state and again persisted to local storage.
  @Published var thoughts: [Thought] = []
  
  private let logger = Logger(subsystem: "Thoughts", category: "Store")
  
  static let live = Store(
    localCacheService: LocalCacheService(),
    cloudKitService: CloudKitService.live
  )
  
  private let localCacheService: LocalCacheServiceType
  private let cloudKitService: CloudKitServiceType
  
  private init(
    localCacheService: LocalCacheServiceType,
    cloudKitService: CloudKitServiceType
  ) {
    self.localCacheService = localCacheService
    self.cloudKitService = cloudKitService
    Task {
      // Get the initial state of thoughts from storage
      await loadInitialThoughts()
      
      // Stream the changes from cloud
      for await change in cloudKitService.changes {
        await ingestChangeFromCloud(change)
      }
    }
  }
  
  func loadInitialThoughts() async {
    self.thoughts = localCacheService.thoughts
  }
  
  func send(_ action: StoreAction) async {
    switch action {
    case .saveNewThought(title: let title, body: let body):
      let thought = Thought(
        id: UUID(),
        title: title,
        body: body
      )
      thoughts.append(thought)
      localCacheService.storeThoughts(thoughts)
      let storedThought = await cloudKitService.storeThought(thought)
      switch storedThought {
      case .success(let thought):
        logger.debug("Saved new thought to CloudKit: \(thought)")
        ingestChangesFromCloud([.modified(thought)])
        // update local thought from it
      case .failure(let error): logger.error("Could not save thought to CloudKit: \(error)")
      }
    }
  }
  
  /// Ingest a collection of changes from the cloud.
  ///
  /// In case of fetching changes at startup or after foregrounding the app,
  /// this may be a collection. In case of ingesting changes after saving a record
  /// or receiving a notification, there may be just one element in the collection.
  private func ingestChangesFromCloud(_ changes: [CloudChange]) {
    for change in changes {
      switch change {
      case .modified(let thought):
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
          thoughts[index] = thought
        } else {
          thoughts.append(thought)
        }
      case .deleted(let id):
        if let index = thoughts.firstIndex(where: { $0.id == id }) {
          thoughts.remove(at: index)
        }
      }
    }
    localCacheService.storeThoughts(thoughts)
  }
}

#if DEBUG
extension Store {
  
  /// Empty static store.
  static var previewEmpty: Store {
    Store(
      localCacheService: MockLocalCacheService(thoughts: []),
      cloudKitService: MockCloudKitService()
    )
  }
  
  /// A store populated with some thoughts.
  static var previewPopulated: Store {
    Store(
      localCacheService: MockLocalCacheService(
        thoughts: [
          .init(
            id: UUID(),
            title: "Thought 1",
            body: "Body 1",
            createdAt: nil,
            modifiedAt: nil
          )
        ]
      ),
      cloudKitService: MockCloudKitService()
    )
  }
  
  static func testInitialCloudChanges(changes: [CloudChange]) -> Store {
    Store(
      localCacheService: MockLocalCacheService(thoughts: []),
      cloudKitService: MockCloudKitService(initialChanges: changes)
    )
  }
}
#endif
