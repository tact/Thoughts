//
//  ContentView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

struct ThoughtsView: View {
  
  @StateObject var viewModel: ThoughtsViewModel

  init(store: Store) {
    // Apparently, this is the state of the art of initalizing a StateObject
    // with parameters in Feb 2023.
    // https://hachyderm.io/@Alexbbrown/109807454267493715
    self._viewModel = StateObject(wrappedValue: ThoughtsViewModel(store: store))
  }
  
  var body: some View {
    NavigationStack(path: $viewModel.navigationPath) {
      content
      .navigationTitle("Thoughts")
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
      }
      .navigationDestination(for: OneThoughtView.Kind.self) { kind in
        OneThoughtView(store: viewModel.store, kind: kind)
      }
    }
  }
  
  @ViewBuilder
  var content: some View {
    if viewModel.thoughts.isEmpty {
      Text("No thoughts. Tap + to add one.")
    } else {
      List(viewModel.thoughts) { thought in
        NavigationLink(
          value: OneThoughtView.Kind.existing(thought),
          label: {
            Text("one thought. id: \(thought.id), title: \(thought.title), body: \(thought.body)")
          }
        )
      }
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
    
  }
}
#endif
