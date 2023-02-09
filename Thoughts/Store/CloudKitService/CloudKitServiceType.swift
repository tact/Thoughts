import Foundation

/// One change made in CloudKit.
enum CloudChange {
  
  /// Thought was modified or added.
  case modified(Thought)
  
  /// Thought was deleted.
  case deleted(Thought.ID)
}

protocol CloudKitServiceType {
  
  /// Save a new or existing thought to CloudKit.
  ///
  /// Returns the thought that has been possibly augmented by CloudKit. E.g CloudKit
  /// adds `createdAt` and updates `modifiedAt` timestamps.
  func saveThought(_ thought: Thought) async -> Result<Thought, Error>
  
  /// Delete a thought from CloudKit.
  ///
  /// If successful, returns the ID of the deleted thought.
  func deleteThought(_ thought: Thought) async -> Result<Thought.ID, Error>
  
  /// Emit a collection of changes received from the cloud.
  var changes: AsyncStream<[CloudChange]> { get }
}
