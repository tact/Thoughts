//
//  OneThoughtView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

struct OneThoughtView: View {
  
  @ObservedObject var viewModel: OneThoughtViewModel

  private let fieldInnerPadding: CGFloat = 4.0
  
  var body: some View {
    VStack {
      Text("Add thought. Received navigation: \(viewModel.kind == .new ? "new" : "existing")")
      TextField("Title (optional)", text: $viewModel.title)
        .padding(fieldInnerPadding)
        .border(.tertiary)
      TextEditor(text: $viewModel.body)
        .padding(fieldInnerPadding)
        .border(.tertiary)
      Button(action: {
        viewModel.send(.save)
      }, label: {
        Text("Save")
      })
      .disabled(viewModel.title.isEmpty && viewModel.body.isEmpty)
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
