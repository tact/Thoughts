import Foundation
import os.log
import ThoughtsTypes

/// Live implementation of the cache.
///
/// Persists the thoughts to local disk.
///
/// Disk operations can take time. There is no queues defined here, but the code here will work
/// on a background queue and won’t block UI. This is because it’s driven by
/// Store mutating functions, which run off the main queue.
struct LocalCacheService: LocalCacheServiceType {
  private let logger = Logger(subsystem: "Thoughts", category: "LocalCacheService")

  var thoughts: [Thought] {
    do {
      let data = try Data(contentsOf: cacheURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      return try decoder.decode([Thought].self, from: data)
    } catch {
      logger.error("Error restoring state from local cache: \(error)")
      return []
    }
  }
    
  func storeThoughts(_ thoughts: [Thought]) {
    do {
      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .iso8601
      let json = try encoder.encode(thoughts)
      try json.write(to: cacheURL, options: .atomic)
    } catch {
      logger.error("Error storing local cache values: \(error)")
    }
  }
  
  func clear() {
    do {
      try FileManager.default.removeItem(at: cacheURL)
      logger.info("Cleared local cache.")
    } catch {
      logger.error("Error clearing local cache: \(error)")
    }
  }
  
  private var cacheURL: URL {
    URL.cachesDirectory.appending(component: "thoughts.json")
  }
}
