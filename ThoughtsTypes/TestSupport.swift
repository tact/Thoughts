#if DEBUG
public enum TestSupport {
  public static var StoreEnvironmentKey = "store"
  
  public struct MockLocalCacheServiceContent: Codable {
    public let thoughts: [Thought]
    public init(thoughts: [Thought]) {
      self.thoughts = thoughts
    }
  }
  
  public struct MockCloudKitServiceContent: Codable {
    public let accountState: CloudKitAccountState
    
    public init(accountState: CloudKitAccountState) {
      self.accountState = accountState
    }
  }
  
  public struct MockStore: Codable {
    public let mockLocalCacheServiceContent: MockLocalCacheServiceContent
    public let mockCloudKitServiceContent: MockCloudKitServiceContent
    public init(
      mockLocalCacheServiceContent: MockLocalCacheServiceContent,
      mockCloudKitServiceContent: MockCloudKitServiceContent
    ) {
      self.mockLocalCacheServiceContent = mockLocalCacheServiceContent
      self.mockCloudKitServiceContent = mockCloudKitServiceContent
    }
  }
}
#endif
