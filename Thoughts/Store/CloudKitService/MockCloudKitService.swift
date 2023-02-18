#if DEBUG
struct MockCloudKitService: CloudKitServiceType {
  let changes: AsyncStream<[CloudChange]>
  
  init(initialChanges: [CloudChange] = []) {
    changes = AsyncStream { continuation in
      continuation.yield(initialChanges)
    }
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
}
#endif
