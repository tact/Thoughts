import CloudKit
import XCTest
import ThoughtsTypes

final class ThoughtsUITests: XCTestCase {
  
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
  
  func test_blank_app() throws {
    let app = launchAppWithMockStore(ThoughtsUITests.blankAppMockStore)
    XCTAssertTrue(app.staticTexts["No thoughts. Tap + to add one."].exists)
  }
  
  func test_with_some_local_thoughts() throws {
    let app = launchAppWithMockStore(ThoughtsUITests.withSomeLocalThoughtsMockStore)
    let buttonPredicate = NSPredicate(format: "label BEGINSWITH 'Title from UI test'")
    app.collectionViews.buttons.element(matching: buttonPredicate).tap()
    app.navigationBars["Title from UI test"].buttons["Thoughts"].tap()
  }
  
  func test_with_some_local_and_cloud_thoughts() throws {
    let app = launchAppWithMockStore(ThoughtsUITests.withSomeLocalAndCloudThoughtsMockStore)
    let buttonPredicate = NSPredicate(format: "label BEGINSWITH 'Title from cloud'")
    app.collectionViews.buttons.element(matching: buttonPredicate).tap()
    app.navigationBars["Title from cloud"].buttons["Thoughts"].tap()
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
