import ThoughtsTypes

#if DEBUG
extension Store {
  static func fromMockStore(_ mockStore: TestSupport.MockStore) -> Store {
    Store(
      localCacheService: MockLocalCacheService(thoughts: mockStore.mockLocalCacheServiceContent.thoughts),
      cloudKitService: MockCloudKitService(initialAccountState: mockStore.mockCloudKitServiceContent.accountState)
    )
  }
}
#endif
