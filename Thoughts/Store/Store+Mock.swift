import Canopy
import ThoughtsTypes

#if DEBUG
extension Store {
  
  /// Create a store with given static mock data.
  ///
  /// The main use for this is UI tests. The test side encodes a state of the store and passes it over in app environment.
  /// The environment is decoded by SharedAppDelegate. If a mock store is found to be passed in, the delegate
  /// creates the mock store.
  static func fromMockStore(_ mockStore: TestSupport.MockStore) -> Store {    
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: mockStore.mockPreferencesServiceContent.cloudKitSetupDone,
      cloudKitUserRecordName: mockStore.mockPreferencesServiceContent.cloudKitUserRecordName
    )
    
    return Store(
      localCacheService: MockLocalCacheService(thoughts: mockStore.mockLocalCacheServiceContent.thoughts),
      cloudKitService: CloudKitService.test(
        containerOperationResults: mockStore.mockCloudKitServiceContent.containerOperationResults,
        privateDatabaseOperationResults: mockStore.mockCloudKitServiceContent.privateDatabaseOperationResults,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
  }
}
#endif
