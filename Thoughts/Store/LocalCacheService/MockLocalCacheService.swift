#if DEBUG
struct MockLocalCacheService: LocalCacheServiceType {
  
  private(set) var thoughts: [Thought]
  
  init(thoughts: [Thought]) {
    self.thoughts = thoughts
  }
  
  func storeThoughts(_ thoughts: [Thought]) {
    // no-op. Mock only works with the state that was passed in init.
  }
  
  func clear() {
    // no-op.
  }
}
#endif
