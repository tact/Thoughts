@testable import Thoughts
import XCTest

final class StoreTests: XCTestCase {
  func test_store_streams_cloud_changes() async {
    
    let id1 = UUID()
    let id2 = UUID()
    
    let store = Store(
      localCacheService: MockLocalCacheService(thoughts: []),
      cloudKitService: MockCloudKitService(
        initialChanges: [
          .modified(
            .init(
              id: id1,
              title: "test title",
              body: "test body"
            )
          ),
          .modified(
            .init(
              id: id2,
              title: "changed title",
              body: "test body 2"
            )
          ),
          .deleted(id1),
          .modified(
            .init(
              id: id2,
              title: "changed title 2",
              body: "test body new"
            )
          )
        ]
      )
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!, Thought(id: id2, title: "changed title 2", body: "test body new"))
  }
}
