import Canopy
@testable import Thoughts
import XCTest

final class SettingsViewModelTests: XCTestCase {
  func test_init() async {
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await SettingsViewModel(store: store)
    let simulateSendFailureEnabled = await vm.simulateSendFailureEnabled
    let simulateFetchFailureEnabled = await vm.simulateFetchFailureEnabled
    XCTAssertFalse(simulateSendFailureEnabled)
    XCTAssertFalse(simulateFetchFailureEnabled)
  }
  
  func test_local_cache() async {
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [
          .init(id: .init(), title: "Title", body: "Body")
        ]
      ),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore()
    )
    let vm = await SettingsViewModel(store: store)
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    
    await vm.resetLocalCache()
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 0)
  }
}
