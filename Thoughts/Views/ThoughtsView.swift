//
//  ContentView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

struct ThoughtsView: View {
  
  @StateObject var viewModel: ThoughtsViewModel
  
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
      .navigationDestination(for: OneThoughtViewKind.self) { kind in
        OneThoughtView(viewModel: viewModel.oneThoughtViewModel(for: kind))
      }
    }
  }
  
  @ViewBuilder
  var content: some View {
    if viewModel.thoughts.isEmpty {
      Text("No thoughts. Tap + to add one.")
    } else {
      List(viewModel.thoughts) { thought in
        NavigationLink(value: OneThoughtViewKind.existing(thought), label: {
          Text("one thought. id: \(thought.id), title: \(thought.title), body: \(thought.body)")
        })
      }
    }
  }
}

#if DEBUG
struct ThoughtsView_Previews: PreviewProvider {
  static var previews: some View {
    ThoughtsView(viewModel: ThoughtsViewModel())
  }
}
#endif
