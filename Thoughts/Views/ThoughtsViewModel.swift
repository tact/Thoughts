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
  private var accountStateCancellable: AnyCancellable?
  
  @Published var navigationPath: [OneThoughtView.Kind] = []
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  @Published var accountState: CloudKitAccountState = .provisionalAvailable
  
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
          self.updateNavigationPathFromThoughts()
        })
      
      // Observe the account state.
      accountStateCancellable = await store.$cloudKitAccountState
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { newState in
          self.accountState = newState
        })
    }
  }
    
  deinit {
    print("ThoughtsViewModel deinit")
  }
  
  /// Make any updates to navigation path if the source of truth changed.
  ///
  /// For example, if a thought was deleted and we are currently looking at it
  /// or editing it, drop it from the path.
  private func updateNavigationPathFromThoughts() {
    if let lastPath = navigationPath.last,
       case OneThoughtView.Kind.existing(let visibleThought) = lastPath,
       !thoughts.contains(visibleThought) {
      // We are looking at a thought which is no longer present in the store.
      // It was likely deleted on this or another device.
      // So we unconditionally drop it from the navigation path.
      navigationPath.removeLast()
    }
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
