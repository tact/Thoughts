import Foundation
import IdentifiedCollections

enum StoreAction {
  case saveNewThought(title: String, body: String)
}

actor Store {
  enum Behavior {
    case live
    case preview
  }
  
  let behavior: Behavior
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  
  init(behavior: Behavior) {
    self.behavior = behavior
  }
  
  func send(_ action: StoreAction) {
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
    }
  }
}

#if DEBUG
extension Store {
  
  static var previewEmpty: Store {
    Store(behavior: .preview)
  }
  
  static var previewPopulated: Store {
    let store = Store(behavior: .preview)
    Task {
      await store.loadThoughtsForPreview()
    }
    return store
  }
  
  private func loadThoughtsForPreview() async {
    self.thoughts = [
      .init(
        id: UUID(),
        title: "Thought 1",
        body: "Body 1",
        createdAt: nil,
        modifiedAt: nil
      )
    ]
  }
}
#endif
