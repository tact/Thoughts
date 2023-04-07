import Combine
@testable import Thoughts
import XCTest

final class StatusViewModelTests: XCTestCase {
  struct StatusProvider: CloudTransactionStatusProvider {
    let subject = CurrentValueSubject<Thoughts.Store.CloudTransactionStatus, Never>(.idle)
    var transactionPublisher: AnyPublisher<Thoughts.Store.CloudTransactionStatus, Never> {
      subject.eraseToAnyPublisher()
    }

    func publishStatus(_ status: Thoughts.Store.CloudTransactionStatus) {
      subject.send(status)
    }
  }
  
  func test_status_change() async {
    let provider = StatusProvider()
    let vm = await StatusViewModel(statusProvider: provider)
    provider.publishStatus(.fetching)
    try? await Task.sleep(for: .seconds(0.01))
    let status = await vm.status
    XCTAssertEqual(status, .fetching)
  }
  
  func test_show_error() async {
    let vm = await StatusViewModel(statusProvider: StatusProvider())
    
    let errorAlert = await vm.showErrorAlert
    XCTAssertFalse(errorAlert)
    
    let error = await vm.error
    XCTAssertNil(error)
    
    await vm.showError(.couldNotGetModifiedThought)
    let newErrorAlert = await vm.showErrorAlert
    XCTAssertTrue(newErrorAlert)
    let newError = await vm.error
    XCTAssertEqual(newError, .couldNotGetModifiedThought)
  }
}
