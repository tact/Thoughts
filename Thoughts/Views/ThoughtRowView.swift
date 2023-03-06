import SwiftUI
import ThoughtsTypes

struct ThoughtRowView: View {
  let thought: Thought
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if !thought.title.isEmpty {
        Text(thought.title)
          .font(.title2)
          .bold()
      }
      if let modifiedAt = thought.modifiedAt {
        Text("Modified \(modifiedAt.formatted(date: .abbreviated, time: .shortened))")
          .font(.caption)
      }
      if !thought.body.isEmpty {
        Text(thought.body)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)

  }
}

struct ThoughtRowView_Previews: PreviewProvider {
  static var previews: some View {
    ThoughtRowView(
      thought: .init(
        id: .init(),
        title: "Thought title",
        body: "Thought body. This is a very long body that should span multipe lines.",
        createdAt: Date(),
        modifiedAt: Date()
      )
    )
    .previewDisplayName("With dates")

    ThoughtRowView(
      thought: .init(
        id: .init(),
        title: "Thought title",
        body: "Thought body"
      )
    )
    .previewDisplayName("Without dates")

  }
}
