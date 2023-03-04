import Foundation
import os.log

@MainActor
class SettingsViewModel: ObservableObject {
  private let store: Store
  
  private let logger = Logger(subsystem: "Thoughts", category: "SettingsViewModel")
  
  enum State {
    case regular
    
    /// Currently clearing local cache and re-downloading content
    case clearing
  }
  
  @Published private(set) var state: State
  
  init(store: Store, state: State = .regular) {
    self.store = store
    self.state = state
  }
  
  func resetLocalCache() {
    logger.debug("User requested to reset local cache.")
    state = .clearing
    Task {
      await store.send(.clearLocalState)
      await MainActor.run {
        state = .regular
      }
    }
  }
}
