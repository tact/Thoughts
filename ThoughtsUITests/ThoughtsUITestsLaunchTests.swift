//
//  ThoughtsUITestsLaunchTests.swift
//  ThoughtsUITests
//
//  Created by Jaanus Kase on 04.02.2023.
//

import XCTest
import ThoughtsTypes

final class ThoughtsUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
      true
    }

    override func setUpWithError() throws {
      continueAfterFailure = false
    }
  
  private func launchAppWithMockStore(_ mockStore: TestSupport.MockStore) -> XCUIApplication {
    let encoded = try! JSONEncoder().encode(mockStore)
    let encodedString = String(data: encoded, encoding: .utf8)!
    
    let app = XCUIApplication()
    app.launchEnvironment = [TestSupport.StoreEnvironmentKey: encodedString]
    app.launch()
    return app
  }

  func testLaunch() throws {
    let app = launchAppWithMockStore(ThoughtsUITests.withSomeLocalThoughtsMockStore)
    app.launch()

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
