import SwiftUI
import ThoughtsTypes

struct ThoughtsView: View {
  
  @StateObject private var viewModel: ThoughtsViewModel
  
  init(store: Store) {
    // Apparently, this is the state of the art of initalizing a StateObject
    // with parameters in Feb 2023.
    // https://hachyderm.io/@Alexbbrown/109807454267493715
    // https://mastodon.social/@lucabernardi/109948882720031817
    //
    self._viewModel = StateObject(wrappedValue: ThoughtsViewModel(store: store))
  }
  
  var body: some View {
    NavigationStack(path: $viewModel.navigationPath) {
      content
        .overlay(alignment: .bottomLeading) {
          StatusView(status: .ok)
        }
        .navigationTitle("Thoughts")
    }
  }
  
  @ViewBuilder
  var content: some View {
    switch viewModel.accountState {
    case .unknown: Text("Unknown account state")
    case .noAccount: Text("No account available")
    case .available, .provisionalAvailable:
      accountAvailableContent
        .toolbar {
          ToolbarItem {
            Button(
              action: {
                viewModel.send(.addThought)
              }, label: {
                Label("Add", systemImage: "plus")
                  .help("Add a thought")
              })
          }
          #if os(iOS)
          ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
              viewModel.showSettingsSheet = true
            }, label: {
              Label("Settings", systemImage: "gear")
                .help("Settings")
            })
          }
          #endif
        }
        .navigationDestination(for: OneThoughtView.Kind.self) { kind in
          OneThoughtView(store: viewModel.store, kind: kind, state: .viewing)
        }
        .sheet(isPresented: $viewModel.showSettingsSheet) {
          SettingsView(store: viewModel.store)
        }
    }
  }
  
  @ViewBuilder
  var accountAvailableContent: some View {
    if viewModel.thoughts.isEmpty {
      Text("No thoughts. Tap + to add one.")
      #warning("big add button here")
    } else {
      List {
        ForEach(viewModel.thoughts) { thought in
          NavigationLink(
            value: OneThoughtView.Kind.existing(thought),
            label: {
              ThoughtRowView(thought: thought)
              #if os(macOS)
                .padding(.bottom, 16)
              #endif
            }
          )
        }
        .onDelete { indexSet in
          if let firstIndex = indexSet.first {
            viewModel.delete(at: firstIndex)
          }
        }
      }
      .animation(.default, value: viewModel.thoughts)
    }
  }
}

#if DEBUG
struct ThoughtsView_Previews: PreviewProvider {
  static var previews: some View {
    ThoughtsView(store: .previewEmpty)
      .previewDisplayName("Empty")

    ThoughtsView(store: .previewPopulated)
      .previewDisplayName("Some thoughts")

    ThoughtsView(store: .noAccountState)
      .previewDisplayName("No CloudKit account")

    ThoughtsView(store: .unknownAccountState)
      .previewDisplayName("Unknown account state")
  }
}
#endif
