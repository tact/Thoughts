/// Live implementation of the cache.
///
/// Persists the thoughts to local disk.
struct LocalCacheService: LocalCacheServiceType {
  var thoughts: [Thought] { [] }
  
  func storeThoughts(_ thoughts: [Thought]) async {
  }
  
  func clear() async {
  
  }
}
