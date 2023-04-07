import CloudKit
import Foundation

public struct Thought: Identifiable, Equatable, Hashable, Codable {
  public typealias ID = UUID
  
  public let id: ID
  public let title: String
  public let body: String
  public let createdAt: Date?
  public let modifiedAt: Date?
  
  public init(id: ID, title: String, body: String, createdAt: Date? = nil, modifiedAt: Date? = nil) {
    self.id = id
    self.title = title
    self.body = body
    self.createdAt = createdAt
    self.modifiedAt = modifiedAt
  }
  
  public init(from record: CKRecord) {
    self.id = UUID(uuidString: record.recordID.recordName)!
    self.title = record.encryptedValues["title"] as? String ?? ""
    self.body = record.encryptedValues["body"] as? String ?? ""
    self.createdAt = record.creationDate
    self.modifiedAt = record.modificationDate
  }
}

extension Thought: CustomStringConvertible {
  public var description: String {
    "Thought(id: \(id), title: “\(title)”, body: “\(body)”, createdAt: \(String(describing: createdAt)), modifiedAt: \(String(describing: modifiedAt)))"
  }
}
