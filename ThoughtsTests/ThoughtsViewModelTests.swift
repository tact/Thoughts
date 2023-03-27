import Canopy
@testable import Thoughts
import ThoughtsTypes
import XCTest

final class ThoughtsViewModelTests: XCTestCase {
  func test_navigates_to_add_new_thought() async {
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let sut = await ThoughtsViewModel(store: store)
    await sut.send(.addThought)
    let navigationPath = await sut.navigationPath
    XCTAssertEqual(navigationPath, [.new])
  }
  
  func test_sorts_thoughts_correctly_for_displaying() async {
    let thought1 = Thought(
      id: .init(),
      title: "Previous thought",
      body: "Newer thought body",
      createdAt: ISO8601DateFormatter().date(from: "2023-03-01T10:00:00Z00:00"),
      modifiedAt: ISO8601DateFormatter().date(from: "2023-03-01T10:00:00Z00:00")
    )
    let thought2 = Thought(
      id: .init(),
      title: "Newer thought",
      body: "Newer thought body",
      createdAt: ISO8601DateFormatter().date(from: "2023-03-02T10:00:00Z00:00"),
      modifiedAt: ISO8601DateFormatter().date(from: "2023-03-02T10:00:00Z00:00")
    )
    let thought3 = Thought(
      id: .init(),
      title: "Thought 3 title",
      body: "Thought 3 body"
    )
    let thought4 = Thought(
      id: .init(),
      title: "Thought 4 title",
      body: "Thought 4 body"
    )

    let store = Store(
      localCacheService: MockLocalCacheService(thoughts: [thought1, thought2, thought3, thought4]),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let sut = await ThoughtsViewModel(store: store)
    try? await Task.sleep(for: .seconds(0.01))
    
    let displayedThoughts = await sut.thoughts
    // Newer thought is sorted first in the list
    XCTAssertEqual(displayedThoughts, [thought2, thought1, thought3, thought4])
  }
  
  func test_dismisses_thought_view_when_thought_is_deleted_in_cloud() async {
    let thought = Thought(
      id: .init(),
      title: "title",
      body: "body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(thoughts: [thought]),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let sut = await ThoughtsViewModel(store: store)
    await MainActor.run {
      sut.navigationPath = [.existing(thought)]
    }
    await store.send(.delete(thought))
    let navigationPath = await sut.navigationPath
    XCTAssertEqual(navigationPath, [])
  }
  
  func test_deletes_thought() async {
    let thought = Thought(
      id: .init(),
      title: "title",
      body: "body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(thoughts: [thought]),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let sut = await ThoughtsViewModel(store: store)
    try? await Task.sleep(for: .seconds(0.01))
    let thoughts = await sut.thoughts
    XCTAssertEqual(thoughts, [thought])
    await sut.delete(at: 0)
    try? await Task.sleep(for: .seconds(0.01))
    let modifiedThoughts = await sut.thoughts
    XCTAssertEqual(modifiedThoughts, [])

  }
}
