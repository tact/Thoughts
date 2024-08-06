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
      public let containerOperationResults: [ReplayingMockContainer.OperationResult]
      public let privateDatabaseOperationResults: [ReplayingMockDatabase.OperationResult]
    
      public init(
        containerOperationResults: [ReplayingMockContainer.OperationResult],
        privateDatabaseOperationResults: [ReplayingMockDatabase.OperationResult]
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
  
    public struct MockUUIDServiceContent: Codable {
      public let uuids: [UUID]
      public init(uuids: [UUID]) {
        self.uuids = uuids
      }
    }
  
    public struct MockStore: Codable {
      public let mockLocalCacheServiceContent: MockLocalCacheServiceContent
      public let mockCloudKitServiceContent: MockCloudKitServiceContent
      public let mockPreferencesServiceContent: MockPreferencesServiceContent
      public let mockUUIDServiceContent: MockUUIDServiceContent
      public init(
        mockLocalCacheServiceContent: MockLocalCacheServiceContent,
        mockCloudKitServiceContent: MockCloudKitServiceContent,
        mockPreferencesServiceContent: MockPreferencesServiceContent,
        mockUUIDServiceContent: MockUUIDServiceContent
      ) {
        self.mockLocalCacheServiceContent = mockLocalCacheServiceContent
        self.mockCloudKitServiceContent = mockCloudKitServiceContent
        self.mockPreferencesServiceContent = mockPreferencesServiceContent
        self.mockUUIDServiceContent = mockUUIDServiceContent
      }
    }
  }
#endif
