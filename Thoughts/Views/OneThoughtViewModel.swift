import Foundation



enum OneThoughtViewAction {
  case save
}

@MainActor
class OneThoughtViewModel: ObservableObject {
  @Published var title = ""
  @Published var body = ""

  let kind: OneThoughtView.Kind
  private let store: Store?
  
  // Initializer for live use.
  init(store: Store?, kind: OneThoughtView.Kind) {
    self.store = store
    self.kind = kind
  }
  
  deinit {
    print("OneThoughtViewModel deinit")
  }
  
  // Initializer for previews. Add view state
  init(kind: OneThoughtView.Kind) {
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
