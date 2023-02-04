import Combine
import Foundation
import IdentifiedCollections

enum ThoughtsViewAction {
  case addThought
}

class ThoughtsViewModel: ObservableObject {
  private let store: Store?
  
  private var thoughtsCancellable: AnyCancellable?
  
  @Published var path: [OneThoughtViewKind] = []
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
  
  func oneThoughtViewModel(for kind: OneThoughtViewKind) -> OneThoughtViewModel {
    OneThoughtViewModel(store: self.store, kind: kind)
  }
    
  func send(_ action: ThoughtsViewAction) {
    switch action {
    case .addThought:
      path.append(.new)
    }
  }
}
