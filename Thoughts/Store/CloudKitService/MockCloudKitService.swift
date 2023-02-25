import ThoughtsTypes

#if DEBUG
struct MockCloudKitService: CloudKitServiceType {
  let changes: AsyncStream<[CloudChange]>
  let accountState: CloudKitAccountState
  
  init(initialChanges: [CloudChange] = [], initialAccountState: CloudKitAccountState = .unknown) {
    changes = AsyncStream { continuation in
      continuation.yield(initialChanges)
    }
    accountState = initialAccountState
  }
  
  func saveThought(_ thought: Thought) async -> Result<Thought, Error> {
    .success(thought)
  }

  func deleteThought(_ thought: Thought) async -> Result<Thought.ID, Error> {
    .success(thought.id)
  }
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable : Any]) async -> FetchCloudChangesResult {
    .noData
  }
  
  func accountStateStream() -> CloudKitAccountStateSequence {
    CloudKitAccountStateSequence(kind: .mock(accountState))
  }
}
#endif
