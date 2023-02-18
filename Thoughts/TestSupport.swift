#if DEBUG
public enum TestSupport {
  public static var StoreEnvironmentKey = "store"
  public struct MockLocalStoreContent: Codable {
    let thoughts: [Thought]?
    public init(thoughts: [Thought]?) {
      self.thoughts = thoughts
    }
  }
  public struct MockStore: Codable {
    let mockLocalStoreContent: MockLocalStoreContent
    public init(mockLocalStoreContent: MockLocalStoreContent) {
      self.mockLocalStoreContent = mockLocalStoreContent
    }
  }
}
#endif
