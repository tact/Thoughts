import Foundation
import os.log

/// Live implementation of the cache.
///
/// Persists the thoughts to local disk.
struct LocalCacheService: LocalCacheServiceType {
  private let logger = Logger(subsystem: "Thoughts", category: "LocalCacheService")

  var thoughts: [Thought] {
    do {
      let data = try Data(contentsOf: cacheURL)
      return try JSONDecoder().decode([Thought].self, from: data)
    } catch {
      logger.error("Error restoring state from local cache: \(error)")
      return []
    }
  }
    
  func storeThoughts(_ thoughts: [Thought]) async {
    do {
      let json = try JSONEncoder().encode(thoughts)
      try json.write(to: cacheURL, options: .atomic)
    } catch {
      logger.error("Error storing local cache values: \(error)")
    }
  }
  
  func clear() async {
  
  }
  
  private var cacheURL: URL {
    URL.cachesDirectory.appending(component: "thoughts.json")
  }
}
