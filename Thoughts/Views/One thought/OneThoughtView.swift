import SwiftUI
import ThoughtsTypes

struct OneThoughtView: View {

  @StateObject private var viewModel: OneThoughtViewModel

  @FocusState private var focusedField: OneThoughtViewModel.Field?
  
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
          viewingView(thought: thought)
        }
        
      case .editing:
        editingView
        #if os(macOS)
          .padding(.bottom)
        #endif
      }
    }
    .onChange(of: focusedField) {
      viewModel.focusedField = $0
    }
    .onChange(of: viewModel.focusedField) {
      focusedField = $0
    }
    .onAppear {
      if viewModel.kind == .new {
        focusedField = .body
      }
    }
    .animation(.default, value: viewModel.state)
    .padding(.horizontal)
    .navigationTitle(viewModel.navigationTitle)
    #if os(iOS)
    .navigationBarTitleDisplayMode(viewModel.navigationBarTitleDisplayMode)
    #endif
  }
  
  @ViewBuilder
  func viewingView(thought: Thought) -> some View {
    ScrollView(.vertical) {
      VStack(spacing: 4) {
        #if os(macOS)
        Text(thought.title)
          .font(.title)
          .bold()
          .padding(.vertical)
          .frame(maxWidth: .infinity, alignment: .leading)
        #endif
        VStack {
          if let createdAt = thought.createdAt {
            Text("Created \(createdAt.formatted(date: .abbreviated, time: .shortened))")
              .font(.caption)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          if let modifiedAt = thought.modifiedAt {
            Text("Modified \(modifiedAt.formatted(date: .abbreviated, time: .shortened))")
              .font(.caption)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(.bottom, 4)
        Divider()
          .padding(.bottom, 16)
        
        Text(LocalizedStringKey(thought.body))
          .frame(maxWidth: .infinity, alignment: .leading)
          .onTapGesture {
            Task {
              await viewModel.send(.editExisting(thought))
            }
          }
      }
      .toolbar {
        ToolbarItem {
          Button(
            action: {
              Task {
                await viewModel.send(.editExisting(thought))
              }
            }, label: {
              Text("Edit")
                .help("Edit")
            }
          )
        }
      }
    }
  }
  
  @ViewBuilder
  var editingView: some View {
    VStack {
      TextField("Title (optional)", text: $viewModel.title)
        .font(.title)
        .bold()
        .focused($focusedField, equals: .title)
        .padding(.top)
      
      #if os(iOS)
      Divider()
      #endif
      
      TextEditor(text: $viewModel.body)
        .font(.body)
        .focused($focusedField, equals: .body)
        .toolbar {
          ToolbarItem {
            Button(
              action: {
                Task {
                  await viewModel.send(.done)
                }
                if viewModel.shouldDismissOnDone {
                  dismiss()
                }
              },
              label: {
                Text("Done")
                  .bold()
                  .help("Done")
              }
            )
          }
        }
    }
  }
  
}

#if DEBUG
struct PreviewWrapper: ViewModifier {
  func body(content: Content) -> some View {
    #if os(macOS)
    content
    #else
    NavigationView {
      content
    }
    #endif
  }
}

struct OneThoughtView_Previews: PreviewProvider {
  static var previews: some View {
    let thought = Thought(
      id: UUID(),
      title: "A thought",
      body: "The thought body.\n\nAnother paragraph.\n\nHow about a **bold text** and link: https://apple.com/",
      createdAt: Date(),
      modifiedAt: Date()
    )
    
    OneThoughtView(
      store: .previewEmpty,
      kind: .new,
      state: .editing
    )
    .modifier(PreviewWrapper())
    .previewDisplayName("Enter new")
    
    OneThoughtView(
      store: .previewPopulated,
      kind: .existing(thought),
      state: .viewing
    )
    .modifier(PreviewWrapper())
    .previewDisplayName("View existing thought")

    OneThoughtView(
      store: .previewPopulated,
      kind: .existing(thought),
      state: .editing
    )
    .modifier(PreviewWrapper())
    .previewDisplayName("Edit existing thought")
  }
}
#endif
