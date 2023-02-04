//
//  OneThoughtView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI


struct OneThoughtView: View {

  @StateObject var viewModel: OneThoughtViewModel

  enum Kind: Equatable, Hashable {

    /// Adding a new thought.
    case new

    /// Seeing and editing an existing thought.
    case existing(Thought)
  }
  
  let store: Store?
  private let fieldInnerPadding: CGFloat = 4.0
  @Environment(\.dismiss) private var dismiss

  init(store: Store? = nil, kind: Kind) {
    self.store = store
    self._viewModel = StateObject(wrappedValue: OneThoughtViewModel(store: store, kind: kind))
  }
  
  
  var body: some View {
    VStack {
      
      switch viewModel.kind {
      case .existing(let thought):
        Text("Existing thought. id: \(thought.id), title: \(thought.title), body: \(thought.body)")
        
      case .new:
        Text("Add thought. Received navigation: \(viewModel.kind == .new ? "new" : "existing")")
        TextField("Title (optional)", text: $viewModel.title)
          .padding(fieldInnerPadding)
          .border(.tertiary)
        TextEditor(text: $viewModel.body)
          .padding(fieldInnerPadding)
          .border(.tertiary)
        Button(action: {
          viewModel.send(.save)
          // Dismiss in case of when a new thought was added
          dismiss()
        }, label: {
          Text("Save")
        })
        .disabled(viewModel.title.isEmpty && viewModel.body.isEmpty)
      }
    }
    .padding()
  }
}

#if DEBUG
struct OneThoughtView_Previews: PreviewProvider {
  static var previews: some View {
    OneThoughtView(
      kind: .new
    )
    .previewDisplayName("Enter new")
    
    OneThoughtView(
      kind: .existing(
        Thought(
          id: UUID(),
          title: "A thought",
          body: "The thought body.\n\nAnother paragraph.",
          createdAt: nil,
          modifiedAt: nil)
      )
    )
    .previewDisplayName("Existing thought")
  }
}
#endif
