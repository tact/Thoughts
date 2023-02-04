import Foundation

struct Thought: Identifiable {
  let id: UUID
  let title: String
  let body: String
  let createdAt: Date
  let modifiedAt: Date
}
