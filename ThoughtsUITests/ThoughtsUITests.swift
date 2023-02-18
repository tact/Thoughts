//
//  ThoughtsUITests.swift
//  ThoughtsUITests
//
//  Created by Jaanus Kase on 04.02.2023.
//

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
  
  private func launchAppWithMockStore(fixtureName: String) -> XCUIApplication {
    let app = XCUIApplication()
    let testBundle = Bundle(for: type(of: self))
    let jsonURL = testBundle.url(forResource: fixtureName, withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    let jsonString = String(data: jsonData, encoding: .utf8)!
    
    app.launchEnvironment = ["store": jsonString]
    app.launch()
    return app
  }
  
  func test_blank_app() throws {
    let app = launchAppWithMockStore(fixtureName: "blank")
    XCTAssertTrue(app.staticTexts["No thoughts. Tap + to add one."].exists)
  }
  
  func test_with_some_thoughts() throws {
    let app = launchAppWithMockStore(fixtureName: "mock1")
    
    app.collectionViews.buttons["one thought. id: BF69292D-27CE-49C0-84C6-80F93D28A74D, title: Title from UI Test, body: Body from UI Test"].tap()
    app.navigationBars["_TtGC7SwiftUI32NavigationStackHosting"].buttons["Thoughts"].tap()
    
    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }
  
//  func testLaunchPerformance() throws {
//    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//      // This measures how long it takes to launch your application.
//      measure(metrics: [XCTApplicationLaunchMetric()]) {
//        XCUIApplication().launch()
//      }
//    }
//  }
}
