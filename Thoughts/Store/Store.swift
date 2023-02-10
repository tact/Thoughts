import Foundation
import IdentifiedCollections
import os.log

enum StoreAction {
  /// User indicated to create a new thought with the indicated content.
  case saveNewThought(title: String, body: String)
  
  /// User indicated to delete this thought.
  case delete(Thought)
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
  @Published private(set) var thoughts: IdentifiedArrayOf<Thought> = []
  
  private let logger = Logger(subsystem: "Thoughts", category: "Store")
  
  static var live = Store(
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
      await loadThoughtsFromLocalCache()
      
      // Stream the changes from cloud.
      // The stream is never closed and remains running
      // for the lifetime of the store.
      for await change in cloudKitService.changes {
        await ingestChangesFromCloud(change)
      }
    }
  }
  
  func loadThoughtsFromLocalCache() async {
    self.thoughts = IdentifiedArray(uniqueElements: localCacheService.thoughts)
  }
  
  

  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult {
    await cloudKitService.ingestRemoteNotification(withUserInfo: userInfo)
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
      localCacheService.storeThoughts(thoughts.elements)
      let storedThought = await cloudKitService.saveThought(thought)
      switch storedThought {
      case .success(let thought):
        logger.debug("Saved new thought to CloudKit: \(thought)")
        ingestChangesFromCloud([.modified(thought)])
      case .failure(let error):
        logger.error("Could not save thought to CloudKit: \(error)")
      }
            
    case .delete(let thought):
      thoughts.remove(id: thought.id)
      localCacheService.storeThoughts(thoughts.elements)
      
      let deleteResult = await cloudKitService.deleteThought(thought)
      switch deleteResult {
      case .success(let deletedThoughtID):
        logger.debug("Deleted thought ID from CloudKit: \(deletedThoughtID)")
        // Since local store was already modified above, nothing further to do here.
      case .failure(let error):
        logger.error("Could not delete thought from CloudKit: \(error)")
      }
    }
  }
  
  /// Ingest a collection of changes from the cloud.
  ///
  /// - Parameter changes: a sequence of mutations to apply.
  ///
  /// In case of fetching changes at startup or after foregrounding the app,
  /// this may be a collection. In case of ingesting changes after saving a record
  /// or receiving a notification, there may be just one element in the collection.
  private func ingestChangesFromCloud(_ changes: [CloudChange]) {
    for change in changes {
      switch change {
      case .modified(let thought):
        thoughts[id: thought.id] = thought
      case .deleted(let thoughtId):
        thoughts.remove(id: thoughtId)
      }
    }
    localCacheService.storeThoughts(thoughts.elements)
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
