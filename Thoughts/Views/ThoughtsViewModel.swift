import Combine
import Foundation
import IdentifiedCollections

enum ThoughtsViewAction {
  case addThought
}

@MainActor
class ThoughtsViewModel: ObservableObject {
  public let store: Store
  
  private var thoughtsCancellable: AnyCancellable?
  
  @Published var navigationPath: [OneThoughtView.Kind] = []
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  
  init(store: Store) {
    self.store = store
    Task {
      // Receive any changes to the source of truth
      // and re-publish them for the UI.
      thoughtsCancellable = await store.$thoughts
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { thoughts in
          // can re-sort it here
          self.thoughts = thoughts
        })
    }
  }
    
  deinit {
    print("ThoughtsViewModel deinit")
  }
  
  func send(_ action: ThoughtsViewAction) {
    switch action {
    case .addThought:
      navigationPath.append(.new)
    }
  }
  
  func delete(at index: Int) {
    let thought = thoughts[index]
    Task {
      await store.send(.delete(thought))
    }
  }
}
