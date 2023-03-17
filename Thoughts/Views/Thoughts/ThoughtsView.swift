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
        .navigationTitle("Thoughts")
    }
    .overlay(alignment: .bottomLeading) {
      StatusView(statusProvider: viewModel.store)
    }
  }
  
  @ViewBuilder
  var content: some View {
    switch viewModel.accountState {
    case .unknown: ProgressView()
    case .noAccount: noICloudAccount
    case .available, .provisionalAvailable:
      accountAvailableContent
        .toolbar {
          ToolbarItem {
            Button(
              action: {
                Task {
                  await viewModel.send(.addThought)
                }
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
      noThoughtsContent
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
      .refreshable {
        await viewModel.send(.refresh)
      }
      .animation(.default, value: viewModel.thoughts)
    }
  }
  
  @ViewBuilder
  var noThoughtsContent: some View {
    VStack(spacing: 32) {
      Spacer()
      Image(systemName: "lightbulb")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 128)
        .opacity(0.2)
      Text("No thoughts.")
      Text("Tap + to add a thought.")
        .foregroundColor(.secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
  
  @ViewBuilder
  var noICloudAccount: some View {
    VStack(spacing: 32) {
      Spacer()
      Image(systemName: "exclamationmark.icloud")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 128)
        .opacity(0.2)
      Text("No iCloud account.")
      Text("Sign in to iCloud in your device settings.")
        .foregroundColor(.secondary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
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
