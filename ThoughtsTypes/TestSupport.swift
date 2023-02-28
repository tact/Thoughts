#if DEBUG
import CanopyTestTools

public enum TestSupport {
  public static var StoreEnvironmentKey = "store"
  
  public struct MockLocalCacheServiceContent: Codable {
    public let thoughts: [Thought]
    public init(thoughts: [Thought]) {
      self.thoughts = thoughts
    }
  }
  
  public struct MockCloudKitServiceContent: Codable {
    public let containerOperationResults: [MockCKContainer.OperationResult]
    public let privateDatabaseOperationResults: [MockDatabase.OperationResult]
    
    public init(
      containerOperationResults: [MockCKContainer.OperationResult],
      privateDatabaseOperationResults: [MockDatabase.OperationResult]
    ) {
      self.containerOperationResults = containerOperationResults
      self.privateDatabaseOperationResults = privateDatabaseOperationResults
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
