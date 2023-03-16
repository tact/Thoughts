//
//  StatusView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 14.03.2023.
//

import SwiftUI
import ThoughtsTypes

/// A view to indicate the status of CloudKit operations, as an overlay
/// on the main view.
///
/// If there is no ongoing operation and all is well, there’s no view.
struct StatusView: View {
  @StateObject var viewModel: StatusViewModel
  
  init(statusProvider: CloudTransactionStatusProvider) {
    self._viewModel = StateObject(wrappedValue: StatusViewModel(statusProvider: statusProvider))
  }
  
  var body: some View {
    switch viewModel.status {
    case .idle: EmptyView()
    case .fetching:
      HStack(spacing: 10) {
        ProgressView()
        Text("Fetching…")
      }
      .padding()
    case.saving:
      HStack(spacing: 10) {
        ProgressView()
        Text("Saving…")
      }
      .padding()
    case .error(let error):
      Button(
        action: {
          viewModel.showError(error)
        },
        label: {
          HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
              .symbolRenderingMode(.multicolor)
            Text("Error state")
              .foregroundColor(.red)
          }
          .padding(8)
          .background(Capsule().fill(Color(.systemBackground)))
          .padding()
        }
      )
      .buttonStyle(PlainButtonStyle())
      .alert(
        isPresented: $viewModel.showErrorAlert,
        error: viewModel.error,
        actions: { _ in }, message: { error in
          Text("\(error.failureReason ?? "?")\n\n\(error.recoverySuggestion ?? "?")")
        }
      )
    }
  }
}

#if DEBUG
import Combine
import Canopy
import CloudKit

struct StatusView_Previews: PreviewProvider {
  struct PreviewStatusProvider: CloudTransactionStatusProvider {
    let status: Store.CloudTransactionStatus
    var transactionPublisher: AnyPublisher<Store.CloudTransactionStatus, Never> {
      Just(status)
        .eraseToAnyPublisher()
    }
  }

  static var previews: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay(alignment: .bottomLeading) {
        StatusView(
          statusProvider: PreviewStatusProvider(
            status: .idle
          )
        )
      }
      .previewDisplayName("Idle")

    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay(alignment: .bottomLeading) {
        StatusView(
          statusProvider: PreviewStatusProvider(
            status: .fetching
          )
        )
      }
      .previewDisplayName("Fetching")

    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay(alignment: .bottomLeading) {
        StatusView(
          statusProvider: PreviewStatusProvider(
            status: .saving(
              Thought(
                id: .init(),
                title: "Saving title",
                body: "Saving body"
              )
            )
          )
        )
      }
      .previewDisplayName("Saving")
    
    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay(alignment: .bottomLeading) {
        StatusView(
          statusProvider: PreviewStatusProvider(
            status: .error(
              .canopy(.ckRecordError(
                .init(
                  from: CKError(CKError.Code.badContainer)
                ))
              )
            )
          )
        )
      }
      .previewDisplayName("Error")
  }
}
#endif
