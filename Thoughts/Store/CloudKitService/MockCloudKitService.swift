import ThoughtsTypes

#if DEBUG
struct MockCloudKitService: CloudKitServiceType {
  let changes: AsyncStream<[CloudChange]>
  let accountState: CloudKitAccountState
  
  static let mockUserRecordName = "mockUserRecordName"
  
  init(
    initialChanges: [CloudChange] = [],
    initialAccountState: CloudKitAccountState = .unknown
  ) {
    changes = AsyncStream { continuation in
      continuation.yield(initialChanges)
    }
    accountState = initialAccountState
  }
  
  func saveThought(_ thought: Thought) async -> Result<Thought, CloudKitServiceError> {
    .success(thought)
  }

  func deleteThought(_ thought: Thought) async -> Result<Thought.ID, CloudKitServiceError> {
    .success(thought.id)
  }
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable : Any]) async -> FetchCloudChangesResult {
    .noData
  }
  
  func accountStateStream() -> CloudKitAccountStateSequence {
    CloudKitAccountStateSequence(kind: .mock(accountState))
  }
  
  func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    .noData
  }
  
  func cloudKitUserRecordName() async -> Result<String, CloudKitServiceError> {
    .success(Self.mockUserRecordName)
  }
  
}
#endif
