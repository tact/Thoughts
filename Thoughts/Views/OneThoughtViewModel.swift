import Foundation

enum OneThoughtViewKind {
  case new
  case existing
}

enum OneThoughtViewAction {
  case save
}

class OneThoughtViewModel: ObservableObject {
  @Published var text = ""
  let kind: OneThoughtViewKind
  
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
