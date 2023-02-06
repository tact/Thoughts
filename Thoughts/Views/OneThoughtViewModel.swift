import Foundation

enum OneThoughtViewAction {
  case save
}

@MainActor
class OneThoughtViewModel: ObservableObject {
  @Published var title = ""
  @Published var body = ""

  let kind: OneThoughtView.Kind
  private let store: Store
  
  // Initializer for live use.
  // Maybe add another initializer for previews with view state, when we get view state
  init(store: Store, kind: OneThoughtView.Kind) {
    self.store = store
    self.kind = kind
  }
  
  deinit {
    print("OneThoughtViewModel deinit")
  }
  
  func send(_ action: OneThoughtViewAction) {
    switch action {
    case .save:
      Task {
        await store.send(.saveNewThought(title: title, body: body))
      }
    }
  }
}
