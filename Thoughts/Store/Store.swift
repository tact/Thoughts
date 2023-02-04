import Foundation

enum StoreAction {
  case saveNewThought(title: String, body: String)
}

class Store: ObservableObject {
  @Published var thoughts: [Thought] = []
  
  func send(_ action: StoreAction) {
    switch action {
    case .saveNewThought(title: let title, body: let body):
      print("Save new thought. Title: \(title), body: \(body)")
    }
  }
}
