import Canopy
import Combine
import Foundation

protocol CloudTransactionStatusProvider {
  var transactionPublisher: AnyPublisher<Store.CloudTransactionStatus, Never> { get async }
}

extension Store: CloudTransactionStatusProvider {
  var transactionPublisher: AnyPublisher<CloudTransactionStatus, Never> {
    $cloudTransactionStatus.eraseToAnyPublisher()
  }
}

@MainActor
class StatusViewModel: ObservableObject {
  @Published private(set) var status: Store.CloudTransactionStatus = .idle
  
  private var statusCancellable: AnyCancellable?
  private(set) var error: CloudKitServiceError?
  @Published var showErrorAlert = false
  
  init(statusProvider: CloudTransactionStatusProvider) {
    Task {
      statusCancellable = await statusProvider.transactionPublisher
        .receive(on: DispatchQueue.main)
        .sink(
          receiveValue: { [weak self] newStatus in
            self?.status = newStatus
          }
        )
    }
  }
  
  func showError(_ error: CloudKitServiceError) {
    self.error = error
    self.showErrorAlert = true
  }
}
