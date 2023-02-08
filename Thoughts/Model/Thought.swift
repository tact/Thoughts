import Foundation
import CloudKit

struct Thought: Identifiable, Equatable, Hashable, Codable {
  
  typealias ID = UUID
  
  let id: ID
  let title: String
  let body: String
  let createdAt: Date?
  let modifiedAt: Date?
  
  init(id: ID, title: String, body: String, createdAt: Date? = nil, modifiedAt: Date? = nil) {
    self.id = id
    self.title = title
    self.body = body
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
  }
  
  init(from record: CKRecord) {
    self.id = UUID(uuidString: record.recordID.recordName)!
    if let title = record.encryptedValues["title"] as? String {
      self.title = title
    } else {
      self.title = ""
    }
    if let body = record.encryptedValues["body"] as? String {
      self.body = body
    } else {
      self.body = ""
    }
    self.createdAt = record.creationDate
    self.modifiedAt = record.modificationDate
  }
}

extension Thought: CustomStringConvertible {
  var description: String {
    "Thought(id: \(id), title: “\(title)”, body: “\(body)”, createdAt: \(String(describing: createdAt)), modifiedAt: \(String(describing: modifiedAt)))"
  }
}
