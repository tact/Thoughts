import ThoughtsTypes

#if DEBUG
extension Store {
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
      preferencesService: preferencesService
    )
  }
}
#endif
