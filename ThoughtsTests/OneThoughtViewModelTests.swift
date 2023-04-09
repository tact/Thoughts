import Canopy
@testable import Thoughts
import ThoughtsTypes
import XCTest

final class OneThoughtViewModelTests: XCTestCase {
  func test_new_thought() async {
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await OneThoughtViewModel(
      store: store,
      kind: .new,
      state: .editing
    )
    
    let state = await vm.state
    XCTAssertEqual(state, .editing)
    
    let shouldEnableSave = await vm.shouldEnableSave
    XCTAssertFalse(shouldEnableSave)
    
    let navigationTitle = await vm.navigationTitle
    XCTAssertEqual(navigationTitle, "Add thought")
    
    let shouldDismissOnDone = await vm.shouldDismissOnDone
    XCTAssertTrue(shouldDismissOnDone)
    
    #if os(iOS)
      let navigationBarTitleDisplayMode = await vm.navigationBarTitleDisplayMode
      XCTAssertEqual(navigationBarTitleDisplayMode, .inline)
    #endif

    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 0)
    
    await MainActor.run {
      vm.body = "New body"
    }
    
    let newShouldEnableSave = await vm.shouldEnableSave
    XCTAssertTrue(newShouldEnableSave)
    
    await vm.send(.done)
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 1)
  }
  
  func test_view_existing_thought() async {
    let id = Thought.ID()
    let thought = Thought(
      id: id,
      title: "Previous title",
      body: "Previous body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await OneThoughtViewModel(
      store: store,
      kind: .existing(thought),
      state: .viewing
    )
    
    let navigationTitle = await vm.navigationTitle
    XCTAssertEqual(navigationTitle, "Previous title")
    
    let shouldEnableSave = await vm.shouldEnableSave
    XCTAssertFalse(shouldEnableSave)
    
    #if os(iOS)
      let navigationBarTitleDisplayMode = await vm.navigationBarTitleDisplayMode
      XCTAssertEqual(navigationBarTitleDisplayMode, .automatic)
    #endif
    
    await store.send(.modifyExistingThought(thought: thought, title: "New title", body: "New body"))
    let updatedThought = await vm.thought!
    XCTAssertEqual(updatedThought.title, "New title")
  }
  
  func test_edit_existing_thought() async {
    let id = Thought.ID()
    let thought = Thought(
      id: id,
      title: "Previous title",
      body: "Previous body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await OneThoughtViewModel(
      store: store,
      kind: .existing(thought),
      state: .editing
    )
        
    let title = await vm.title
    XCTAssertEqual(title, "Previous title")
  }
  
  func test_view_edit_cancel_without_changes() async {
    let id = Thought.ID()
    let thought = Thought(
      id: id,
      title: "Previous title",
      body: "Previous body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await OneThoughtViewModel(
      store: store,
      kind: .existing(thought),
      state: .viewing
    )
    
    let focusedField = await vm.focusedField
    XCTAssertNil(focusedField)
    
    await vm.send(.editExisting(thought))
    let state = await vm.state
    XCTAssertEqual(state, .editing)
    let newFocusedField = await vm.focusedField
    XCTAssertEqual(newFocusedField, .body)
    let navigationTitle = await vm.navigationTitle
    XCTAssertEqual(navigationTitle, "")
    
    await vm.send(.done)
    let newState = await vm.state
    XCTAssertEqual(newState, .viewing)
  }
  
  func test_view_edit_save() async {
    let id = Thought.ID()
    let thought = Thought(
      id: id,
      title: "Previous title",
      body: "Previous body"
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await OneThoughtViewModel(
      store: store,
      kind: .existing(thought),
      state: .viewing
    )
    
    let focusedField = await vm.focusedField
    XCTAssertNil(focusedField)
    
    await vm.send(.editExisting(thought))
    let state = await vm.state
    XCTAssertEqual(state, .editing)
    let newFocusedField = await vm.focusedField
    XCTAssertEqual(newFocusedField, .body)
    let navigationTitle = await vm.navigationTitle
    XCTAssertEqual(navigationTitle, "")
    
    await MainActor.run {
      vm.title = "Updated title"
    }
    
    await vm.send(.done)
    let newState = await vm.state
    XCTAssertEqual(newState, .viewing)

    let updatedThought = await vm.thought!
    XCTAssertEqual(updatedThought.title, "Updated title")
  }
}
