import Foundation

@MainActor
class StatusViewModel: ObservableObject {
  enum Status {
    case ok
    case fetching
    case error(LocalizedError)
  }
  
  init(status: Status) {
    self.status = status
  }
  
  @Published var status = Status.ok
}
