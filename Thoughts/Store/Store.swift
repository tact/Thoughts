import Foundation
import IdentifiedCollections

enum StoreAction {
  case saveNewThought(title: String, body: String)
}

actor Store {  
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
    self.thoughts = await localCacheService.thoughts
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
      await localCacheService.storeThoughts(thoughts)
    }
  }
}

#if DEBUG
extension Store {
  
  static var previewEmpty: Store {
    Store(localCacheService: MockLocalCacheService(thoughts: []))
  }
  
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
