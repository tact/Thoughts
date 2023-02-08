#if DEBUG
struct MockCloudKitService: CloudKitServiceType {

  let changes: AsyncStream<[CloudChange]>
  
  init(initialChanges: [CloudChange] = []) {
    changes = AsyncStream { continuation in
      continuation.yield(initialChanges)
    }
  }
  
  func storeThought(_ thought: Thought) async -> Result<Thought, Error> {
    .success(thought)
  }
}
#endif
