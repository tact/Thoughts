import Foundation

enum OneThoughtViewKind {
  case new
  case existing
}

enum OneThoughtViewAction {
  case save
}

class OneThoughtViewModel: ObservableObject {
  @Published var title = ""
  @Published var body = ""
  let kind: OneThoughtViewKind
  
  private let store: Store? = nil
  
  // Initializer for live use.
  
  // Initializer for previews
  init(kind: OneThoughtViewKind) {
    self.kind = kind
  }
  
  func send(_ action: OneThoughtViewAction) {
    switch action {
    case .save:
      print("Save")
    }
  }
}
