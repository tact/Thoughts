import CloudKit
import ThoughtsTypes

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
      case let .mock(state):
        guard !mockEmitted else { return nil }
        mockEmitted = true
        return state
      case let .live(stream):
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
