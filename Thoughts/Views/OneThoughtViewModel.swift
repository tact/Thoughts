import Foundation

enum OneThoughtViewKind: Equatable, Hashable {
  case new
  case existing(Thought)
}

enum OneThoughtViewAction {
  case save
}

class OneThoughtViewModel: ObservableObject {
  @Published var title = ""
  @Published var body = ""
  let kind: OneThoughtViewKind
  
  private let store: Store?
  
  // Initializer for live use.
  init(store: Store?, kind: OneThoughtViewKind) {
    self.store = store
    self.kind = kind
  }
  
  deinit {
    print("OneThoughtViewModel deinit")
  }
  
  // Initializer for previews. Add view state
  init(kind: OneThoughtViewKind) {
    self.kind = kind
    self.store = nil
  }
  
  func send(_ action: OneThoughtViewAction) {
    switch action {
    case .save:
      guard let store else { return }
      Task {
        await store.send(.saveNewThought(title: title, body: body))
      }
    }
  }
}
