import Canopy
@testable import Thoughts
import ThoughtsTypes
import XCTest

final class StoreTestsWithMockCKService: XCTestCase {
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
      ),
      preferencesService: TestPreferencesService(cloudKitSetupDone: true, cloudKitUserRecordName: "mockUserRecordID"),
      tokenStore: TestTokenStore()
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!, Thought(id: id2, title: "changed title 2", body: "test body new"))
  }
}
