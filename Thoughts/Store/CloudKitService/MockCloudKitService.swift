#if DEBUG
struct MockCloudKitService: CloudKitServiceType {

  let changes: AsyncStream<CloudChange>
  
  init(initialChanges: [CloudChange] = []) {
    changes = AsyncStream { continuation in
      for change in initialChanges {
        continuation.yield(change)
      }
    }
  }
  
  func storeThought(_ thought: Thought) async -> Result<Thought, Error> {
    .success(thought)
  }
}
#endif
