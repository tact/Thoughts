import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
  private let store: Store
  
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
}
