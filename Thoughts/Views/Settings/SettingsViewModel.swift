import Foundation
import os.log

@MainActor
class SettingsViewModel: ObservableObject {
  private let store: Store
  
  private let logger = Logger(subsystem: "Thoughts", category: "SettingsViewModel")
  
  @Published var simulateSendFailureEnabled: Bool = false {
    didSet {
      Task {
        await store.send(.simulateSendFailure(simulateSendFailureEnabled))
      }
    }
  }
  
  @Published var simulateFetchFailureEnabled: Bool = false {
    didSet {
      Task {
        await store.send(.simulateFetchFailure(simulateFetchFailureEnabled))
      }
    }
  }

  enum State {
    case regular
    
    /// Currently clearing local cache and re-downloading content
    case clearing
  }
  
  @Published private(set) var state: State
  
  init(store: Store, state: State = .regular) {
    self.store = store
    self.state = state
    
    Task {
      let sendFailureEnabled = await store.simulateSendFailureEnabled
      await MainActor.run {
        self.simulateSendFailureEnabled = sendFailureEnabled
      }
      let fetchFailureEnabled = await store.simulateFetchFailureEnabled
      await MainActor.run {
        self.simulateFetchFailureEnabled = fetchFailureEnabled
      }
    }
  }
  
  func resetLocalCache() async {
    logger.debug("User requested to reset local cache.")
    await MainActor.run {
      state = .clearing
    }
    await store.send(.clearLocalState)
    await MainActor.run {
      state = .regular
    }
  }
}
