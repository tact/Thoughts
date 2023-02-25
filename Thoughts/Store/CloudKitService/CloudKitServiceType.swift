import CloudKit
import Foundation
import ThoughtsTypes

#if os(iOS)
import UIKit
#endif



enum FetchCloudChangesResult {
  case newData
  case noData
  case failed
  
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

/// One change made in CloudKit.
enum CloudChange {
  
  /// Thought was modified or added.
  case modified(Thought)
  
  /// Thought was deleted.
  case deleted(Thought.ID)
}

struct CloudKitAccountStateSequence: AsyncSequence {

  enum Kind {
    case mock(CloudKitAccountState)
    case live(AsyncStream<CKAccountStatus>)
  }
  
  let kind: Kind
  
  init(kind: Kind) {
    self.kind = kind
  }

  func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(kind: kind)
  }
  
  typealias Element = CloudKitAccountState
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    let kind: Kind
    
    /// Make sure that the mock emitter emits only one value.
    var mockEmitted = false
    
    init(kind: Kind) {
      self.kind = kind
    }
    
    public mutating func next() async -> Element? {
      switch kind {
      case .mock(let state):
        guard !mockEmitted else { return nil }
        mockEmitted = true
        return state
      case .live(let stream):
        let nextStatus = await stream.first(where: { _ in true })
        switch nextStatus {
        case .available: return .available
        case .couldNotDetermine: return .unknown
        default: return .noAccount
        }
      }
    }
  }
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
  
  func accountStateStream() async -> CloudKitAccountStateSequence
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult
}
