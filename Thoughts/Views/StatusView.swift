//
//  StatusView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 14.03.2023.
//

import SwiftUI

/// A view to indicate the status of CloudKit operations, as an overlay
/// on the main view.
///
/// If there is no ongoing operation and all is well, there’s no view.
struct StatusView: View {
  @StateObject var viewModel: StatusViewModel
  
  init(status: StatusViewModel.Status) {
    self._viewModel = StateObject(wrappedValue: .init(status: status))
  }
  
  var body: some View {
    switch viewModel.status {
    case .ok: EmptyView()
    case .fetching:
      HStack {
        ProgressView()
        Text("Some state … ")
      }
      .background(Color.yellow)
    case .error:
      Text("Error state")
    }
  }
}

#if DEBUG
struct StatusView_Previews: PreviewProvider {
  static var previews: some View {
    StatusView(status: .ok)
      .previewDisplayName("ok")
    
    StatusView(status: .fetching)
      .previewDisplayName("fetching")
  }
}
#endif
