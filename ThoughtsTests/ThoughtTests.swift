import CloudKit
import ThoughtsTypes
import XCTest

final class ThoughtTests: XCTestCase {
  func test_init() {
    let thought = Thought(id: UUID(), title: "Title", body: "Body")
    XCTAssertEqual(thought.title, "Title")
    XCTAssertEqual(thought.body, "Body")
  }
  
  func test_init_with_dates() {
    let date = Date.now
    let thought = Thought(id: UUID(), title: "Title", body: "Body", createdAt: date, modifiedAt: date)
    XCTAssertEqual(thought.createdAt, date)
  }
  
  func test_init_with_ckrecord() {
    let record = CKRecord(recordType: "Thought")
    record.encryptedValues["title"] = "Title"
    record.encryptedValues["body"] = "Body"
    let thought = Thought(from: .init(ckRecord: record))
    XCTAssertEqual(thought.title, "Title")
  }

  func test_init_with_ckrecord_without_values() {
    let record = CKRecord(recordType: "Thought")
    let thought = Thought(from: .init(ckRecord: record))
    XCTAssertEqual(thought.title, "")
    XCTAssertEqual(thought.body, "")
  }
}
