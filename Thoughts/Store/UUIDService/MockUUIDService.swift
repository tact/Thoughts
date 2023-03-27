import Foundation

actor MockUUIDService: UUIDServiceType {
  var uuids: [UUID]
  
  init(uuids: [UUID]) {
    self.uuids = uuids
  }
  
  var uuid: UUID {
    get async {
      guard let uuid = uuids.first else {
        fatalError("Asked to dequeue UUID, but no more UUID-s available")
      }
      uuids.removeFirst()
      return uuid
    }
  }
}
