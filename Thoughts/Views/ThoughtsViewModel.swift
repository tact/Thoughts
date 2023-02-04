import Combine
import Foundation
import IdentifiedCollections

enum ThoughtsViewAction {
  case addThought
}

@MainActor
class ThoughtsViewModel: ObservableObject {
  private let store: Store?
  
  private var thoughtsCancellable: AnyCancellable?
  
  @Published var navigationPath: [OneThoughtView.Kind] = []
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  
  init(store: Store? = nil) {
    self.store = store
    if let store {
      Task {
        thoughtsCancellable = await store.$thoughts
          .receive(on: DispatchQueue.main)
          .sink(receiveValue: { thoughts in
            // can re-sort it here
            self.thoughts = thoughts
          })
      }
    }
  }
    
  deinit {
    print("Thoughts deinit")
  }
  
  func send(_ action: ThoughtsViewAction) {
    switch action {
    case .addThought:
      navigationPath.append(.new)
    }
  }
}
