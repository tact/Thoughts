import Foundation
import IdentifiedCollections

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
  
  static let live = Store(
    localCacheService: LocalCacheService()
  )
  
  private let localCacheService: LocalCacheServiceType
  // private let cloudKitService: CloudKitServiceType
  
  private init(
    localCacheService: LocalCacheServiceType
  ) {
    self.localCacheService = localCacheService
    // Get the initial state of thoughts from storage
    Task {
      await loadInitialThoughts()
    }
  }
  
  func loadInitialThoughts() async {
    self.thoughts = localCacheService.thoughts
  }
  
  func send(_ action: StoreAction) async {
    switch action {
    case .saveNewThought(title: let title, body: let body):
      print("Save new thought. Title: \(title), body: \(body)")
      thoughts.append(
        .init(
          id: UUID(),
          title: title,
          body: body,
          createdAt: nil,
          modifiedAt: nil
        )
      )
      localCacheService.storeThoughts(thoughts)
    }
  }
}

#if DEBUG
extension Store {
  
  /// Empty static store.
  static var previewEmpty: Store {
    Store(localCacheService: MockLocalCacheService(thoughts: []))
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
      )
    )
  }  
}
#endif
