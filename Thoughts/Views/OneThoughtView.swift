//
//  OneThoughtView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

struct OneThoughtView: View {
  
  @ObservedObject var viewModel: OneThoughtViewModel
  
  var body: some View {
    VStack {
      Text("Add thought. Received navigation: \(viewModel.kind == .new ? "new" : "existing")")
      TextEditor(text: $viewModel.text)
        .border(.secondary)
      Button(action: {
        viewModel.send(.save)
      }, label: {
        Text("Save")
      })
    }
    .padding()
  }
}

#if DEBUG
struct OneThoughtView_Previews: PreviewProvider {
  static var previews: some View {
    OneThoughtView(viewModel: OneThoughtViewModel(kind: .new))
  }
}
#endif
