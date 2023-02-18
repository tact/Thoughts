#if DEBUG
enum TestSupport {
  static var StoreEnvironmentKey = "store"
  struct MockLocalStoreContent: Codable {
    let thoughts: [Thought]
  }
  struct MockStore: Codable {
    let mockLocalStoreContent: MockLocalStoreContent
  }
}
#endif
