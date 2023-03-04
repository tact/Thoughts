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
  
  public struct MockPreferencesServiceContent: Codable {
    public let cloudKitSetupDone: Bool
    public let cloudKitUserRecordName: String?
    
    public init(cloudKitSetupDone: Bool, cloudKitUserRecordName: String?) {
      self.cloudKitSetupDone = cloudKitSetupDone
      self.cloudKitUserRecordName = cloudKitUserRecordName
    }
  }
  
  public struct MockStore: Codable {
    public let mockLocalCacheServiceContent: MockLocalCacheServiceContent
    public let mockCloudKitServiceContent: MockCloudKitServiceContent
    public let mockPreferencesServiceContent: MockPreferencesServiceContent
    public init(
      mockLocalCacheServiceContent: MockLocalCacheServiceContent,
      mockCloudKitServiceContent: MockCloudKitServiceContent,
      mockPreferencesServiceContent: MockPreferencesServiceContent
    ) {
      self.mockLocalCacheServiceContent = mockLocalCacheServiceContent
      self.mockCloudKitServiceContent = mockCloudKitServiceContent
      self.mockPreferencesServiceContent = mockPreferencesServiceContent
    }
  }
}
#endif
