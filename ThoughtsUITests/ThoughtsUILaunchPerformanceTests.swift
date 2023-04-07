import CloudKit
import ThoughtsTypes
import XCTest

final class ThoughtsUILaunchPerformanceTests: XCTestCase {
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }
  
  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  private func launchAppWithMockStore(_ mockStore: TestSupport.MockStore) -> XCUIApplication {
    let encoded = try! JSONEncoder().encode(mockStore)
    let encodedString = String(data: encoded, encoding: .utf8)!
    
    let app = XCUIApplication()
    app.launchEnvironment = [TestSupport.StoreEnvironmentKey: encodedString]
    app.launch()
    return app
  }
  
  func testLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
      // This measures how long it takes to launch your application.
      measure(metrics: [XCTApplicationLaunchMetric()]) {
        let _ = launchAppWithMockStore(ThoughtsUITests.withSomeLocalThoughtsMockStore)
      }
    }
  }
}
