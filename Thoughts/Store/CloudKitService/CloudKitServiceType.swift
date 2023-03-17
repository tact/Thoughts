import Canopy
import CloudKit
import Foundation
import ThoughtsTypes

#if os(iOS)
import UIKit
#endif

enum FetchCloudChangesResult {
  case newData
  case noData
  case failed(CanopyError)
  
  #if os(iOS)
  var backgroundFetchResult: UIBackgroundFetchResult {
    switch self {
    case .newData: return .newData
    case .noData: return .noData
    case .failed: return .failed
    }
  }
  #endif
}

enum CloudKitServiceError: Error, LocalizedError, Equatable {
  case couldNotGetModifiedThought
  case couldNotGetDeletedThoughtID
  case couldNotGetUserRecordID
  case canopy(CanopyError)
  
  var errorDescription: String? {
    switch self {
    case .couldNotGetModifiedThought: return "Could not get modified thought."
    case .couldNotGetDeletedThoughtID: return "Could not get deleted thought ID."
    case .couldNotGetUserRecordID: return "Could not get user record ID."
    case .canopy(let canopyError): return canopyError.localizedDescription
    }
  }
  
  var recoverySuggestion: String? {
    switch self {
    case .canopy(let canopyError): return canopyError.recoverySuggestion
    default: return "Check your network connection and iCloud account."
    }
  }
}

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
  func saveThought(_ thought: Thought) async -> Result<Thought, CloudKitServiceError>
  
  /// Delete a thought from CloudKit.
  ///
  /// If successful, returns the ID of the deleted thought.
  func deleteThought(_ thought: Thought) async -> Result<Thought.ID, CloudKitServiceError>
  
  /// Emit a collection of changes received from the cloud.
  var changes: AsyncStream<[CloudChange]> { get }
  
  func accountStateStream() async -> CloudKitAccountStateSequence
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult
  
  func fetchChangesFromCloud() async -> FetchCloudChangesResult
  
  func cloudKitUserRecordName() async -> Result<String, CloudKitServiceError>
}
