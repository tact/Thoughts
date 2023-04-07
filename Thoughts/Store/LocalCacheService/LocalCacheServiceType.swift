import ThoughtsTypes

/// Storage to device.
///
/// It’s called a “Cache” because it’s not source of truth: CloudKit holds the source of truth.
protocol LocalCacheServiceType {
  /// Get the current state of local cache.
  var thoughts: [Thought] { get }
  
  /// Store  a full new state of local cache.
  func storeThoughts(_ thoughts: [Thought])
  
  /// Clear local cache.
  ///
  /// One reason for this could be that you reset the state
  /// and re-sync from CloudKit source of truth.
  func clear()
}
