import Combine
import Foundation
import IdentifiedCollections
import os.log
import ThoughtsTypes

enum ThoughtsViewAction {
  case addThought
  case refresh
}

@MainActor
class ThoughtsViewModel: ObservableObject {
  public let store: Store
  
  private var thoughtsCancellable: AnyCancellable?
  private var accountStateCancellable: AnyCancellable?
  
  @Published var navigationPath: [OneThoughtView.Kind] = []
  @Published var thoughts: IdentifiedArrayOf<Thought> = []
  @Published var accountState: CloudKitAccountState = .provisionalAvailable
  @Published var showSettingsSheet = false
  
  private let logger = Logger(subsystem: "Thoughts", category: "ThoughtsViewModel")
  
  init(store: Store) {
    self.store = store
    Task {
      // Receive any changes to the source of truth
      // and re-publish them for the UI.
      self.thoughtsCancellable = await store.$thoughts
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] thoughts in
          // Sort by modification time, newest, first.
          self?.thoughts = IdentifiedArray(
            uniqueElements: thoughts.sorted(
              by: { lhs, rhs in
                lhs.modifiedAt ?? Date.distantPast > rhs.modifiedAt ?? Date.distantPast
              }
            )
          )
          self?.updateNavigationPathFromThoughts()
        })
      
      // Observe the account state.
      self.accountStateCancellable = await store.$cloudKitAccountState
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] newState in
          self?.accountState = newState
        })
    }
  }
    
  deinit {
    logger.debug("deinit")
  }
  
  /// Make any updates to navigation path if the source of truth changed.
  ///
  /// For example, if a thought was deleted and we are currently looking at it
  /// or editing it, drop it from the path.
  private func updateNavigationPathFromThoughts() {
    if let lastPath = navigationPath.last,
       case let OneThoughtView.Kind.existing(visibleThought) = lastPath,
       !thoughts.contains(visibleThought)
    {
      // We are looking at a thought which is no longer present in the store.
      // It was likely deleted on this or another device.
      // So we unconditionally drop it from the navigation path.
      navigationPath.removeLast()
    }
  }
  
  func send(_ action: ThoughtsViewAction) async {
    switch action {
    case .addThought:
      navigationPath.append(.new)
    case .refresh:
      await store.send(.refresh)
    }
  }
  
  func delete(at index: Int) {
    let thought = thoughts[index]
    Task {
      await store.send(.delete(thought))
    }
  }
}
