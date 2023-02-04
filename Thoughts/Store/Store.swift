import Foundation
import IdentifiedCollections

enum StoreAction {
  case saveNewThought(title: String, body: String)
}

actor Store {
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  
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
