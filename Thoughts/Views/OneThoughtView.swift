import SwiftUI
import ThoughtsTypes

struct OneThoughtView: View {

  @StateObject private var viewModel: OneThoughtViewModel

  /// View kind.
  ///
  /// This does not change through the view lifetime. View is represented in navigation path by this.
  enum Kind: Equatable, Hashable, CustomStringConvertible {
    /// Adding a new thought.
    case new

    /// Viewing or editing an existing thought.
    case existing(Thought)
    
    var description: String {
      switch self {
      case .new: return "new"
      case .existing(let thought): return "existing(\(thought))"
      }
    }
  }
  
  /// View state.
  ///
  /// This may change through the view lifetime. it is managed by the view model.
  enum State {
    /// Viewing an existing thought.
    case viewing
    
    /// Editing either a new or existing thought.
    case editing
  }
  
  private let fieldInnerPadding: CGFloat = 4.0
  @Environment(\.dismiss) private var dismiss

  init(store: Store, kind: Kind, state: State) {
    self._viewModel = StateObject(
      wrappedValue: OneThoughtViewModel(
        store: store,
        kind: kind,
        state: state
      )
    )
  }
  
  
  var body: some View {
    VStack {
      switch viewModel.state {
      case .viewing:
        if let thought = viewModel.thought {
          Text("Existing thought. id: \(thought.id), title: \(thought.title)")
          Text(LocalizedStringKey(thought.body))
            .frame(maxWidth: .infinity, alignment: .leading)
          Button("Edit") {
            viewModel.send(.editExisting(thought))
          }
        }
        
      case .editing:
        TextField("Title (optional)", text: $viewModel.title)
          .padding(fieldInnerPadding)
          .border(.tertiary)
        TextEditor(text: $viewModel.body)
          .padding(fieldInnerPadding)
          .border(.tertiary)
        HStack {

          if viewModel.shouldShowCancelEditButton {
            Button("Cancel") {
              viewModel.send(.cancelEditExisting)
            }
          }
          
          Button(action: {
            viewModel.send(.save)
            // Dismiss in case of when a new thought was added
            if viewModel.kind == .new {
              dismiss()
            }
          }, label: {
            Text("Save")
          })
          .disabled(viewModel.title.isEmpty && viewModel.body.isEmpty)
        }
      }
    }
    .padding()
  }
}

#if DEBUG
struct OneThoughtView_Previews: PreviewProvider {
  static var previews: some View {
    
    let thought = Thought(
      id: UUID(),
      title: "A thought",
      body: "The thought body.\n\nAnother paragraph.\n\nHow about a **bold text** and link: https://apple.com/",
      createdAt: nil,
      modifiedAt: nil
    )
    
    OneThoughtView(
      store: .previewEmpty,
      kind: .new,
      state: .editing
    )
    .previewDisplayName("Enter new")
    
    OneThoughtView(
      store: .previewPopulated,
      kind: .existing(thought),
      state: .viewing
    )
    .previewDisplayName("View existing thought")

    OneThoughtView(
      store: .previewPopulated,
      kind: .existing(thought),
      state: .editing
    )
    .previewDisplayName("Edit existing thought")

  }
}
#endif
