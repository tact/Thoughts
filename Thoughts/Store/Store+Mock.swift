#if DEBUG
extension Store {
  static func fromMockStore(_ mockStore: TestSupport.MockStore) -> Store {
    Store(
      localCacheService: MockLocalCacheService(thoughts: mockStore.mockLocalStoreContent.thoughts ?? []),
      cloudKitService: MockCloudKitService()
    )
  }
}
#endif
