import CloudKit
import ThoughtsTypes
import XCTest

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
    XCTAssertTrue(app.staticTexts["No thoughts."].exists)
    XCTAssertTrue(app.staticTexts["Tap + to add a thought."].exists)
  }
  
  #if os(iOS)
  // Some UI tests only work on iOS, probably because the element trees are somewhat different
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
  
  func test_add_thought() throws {
    let app = launchAppWithMockStore(ThoughtsUITests.addThoughtToBlankAppMockStore)

    app.navigationBars["Thoughts"]/*@START_MENU_TOKEN@*/.buttons["Add"]/*[[".otherElements[\"Add\"].buttons[\"Add\"]",".buttons[\"Add\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()
    app.typeText("New body")
    app.textFields["Title (optional)"].tap()
    app.typeText("New title")
    app.navigationBars["Add thought"].buttons["Done"].tap()
            
    let buttonPredicate = NSPredicate(format: "label BEGINSWITH 'New title'")
    XCTAssertTrue(app.collectionViews.buttons.element(matching: buttonPredicate).exists)
  }
  #endif
}
