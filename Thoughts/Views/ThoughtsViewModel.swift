import Foundation

class ThoughtsViewModel: ObservableObject {
  private let store: Store?
  
  init(store: Store? = nil) {
    self.store = nil
  }
}
