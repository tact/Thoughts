//
//  ContentView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

struct ThoughtsView: View {
  
  @State private var path: [OneThoughtViewKind] = []
  
  var body: some View {
    NavigationStack(path: $path) {
      Text("What")
        .navigationTitle("Thoughts")
        .toolbar {
          ToolbarItem {
            Button(
              action: {
                path.append(.new)
              }, label: {
                Label("Add", systemImage: "plus")
              })
          }
        }
        .navigationDestination(for: OneThoughtViewKind.self) { kind in
          OneThoughtView(viewModel: OneThoughtViewModel(kind: kind))
        }
    }
  }
}

#if DEBUG
struct ThoughtsView_Previews: PreviewProvider {
  static var previews: some View {
    ThoughtsView()
  }
}
#endif
