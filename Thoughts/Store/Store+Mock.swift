import ThoughtsTypes

#if DEBUG
extension Store {
  static func fromMockStore(_ mockStore: TestSupport.MockStore) -> Store {
    Store(
      localCacheService: MockLocalCacheService(thoughts: mockStore.mockLocalCacheServiceContent.thoughts),
      cloudKitService: CloudKitService.test(
        containerOperationResults: mockStore.mockCloudKitServiceContent.containerOperationResults,
        privateDatabaseOperationResults: mockStore.mockCloudKitServiceContent.privateDatabaseOperationResults
      )
    )
  }
}
#endif
