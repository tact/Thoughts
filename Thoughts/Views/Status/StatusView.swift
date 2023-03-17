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
  
  #warning("re-test this once there is simulation of errors")
  
  init(statusProvider: CloudTransactionStatusProvider) {
    self._viewModel = StateObject(
      wrappedValue: StatusViewModel(
        statusProvider: statusProvider
      )
    )
  }
  
  var body: some View {
    content
      .animation(.default, value: viewModel.status)
  }
  
  @ViewBuilder
  var content: some View {
    switch viewModel.status {
    case .idle: EmptyView()
    case .fetching:
      HStack(spacing: hStackSpacing) {
        ProgressView()
        #if os(macOS)
          .scaleEffect(x: 0.5, y: 0.5)
        #endif
        Text("Fetching…")
          .font(.caption)
          .foregroundColor(Color.secondary)
      }
      .padding()
    case.saving:
      HStack(spacing: hStackSpacing) {
        ProgressView()
        Text("Saving…")
          .font(.caption)
          .foregroundColor(Color.secondary)
      }
      .padding()
    case .error(let error):
      Button(
        action: {
          viewModel.showError(error)
        },
        label: {
          HStack(spacing: hStackSpacing) {
            Image(systemName: "exclamationmark.circle")
              .symbolRenderingMode(.multicolor)
            Text("Error talking to iCloud.")
              .font(.caption)
              .foregroundColor(Color.secondary)
          }
          .padding(8)
          #if os(iOS)
          .background(Capsule().fill(Color(.systemBackground)))
          #else
          .background(Capsule().fill(Color(.white)))
          #endif
          .padding()
        }
      )
      .buttonStyle(PlainButtonStyle())
      .alert(
        isPresented: $viewModel.showErrorAlert,
        error: viewModel.error,
        actions: { _ in }, message: { error in
          Text("\(error.recoverySuggestion ?? "?")")
        }
      )
    }
  }
  
  var hStackSpacing: CGFloat {
    #if os(iOS)
    10
    #else
    0
    #endif
  }
}

#if DEBUG
import Combine
import Canopy
import CloudKit

struct StatusView_Previews: PreviewProvider {
  class PreviewStatusProvider: CloudTransactionStatusProvider {
    @Published var status = Store.CloudTransactionStatus.idle
    
    var transactionPublisher: AnyPublisher<Store.CloudTransactionStatus, Never> {
      $status.eraseToAnyPublisher()
    }
    
    static var error = CloudKitServiceError.canopy(
      .ckRecordError(
        .init(from: CKError(CKError.Code.badContainer))
      )
    )
    
    static var thought = Thought(
      id: .init(),
      title: "Saving title",
      body: "Saving body"
    )
    
    private var timerCancellable: AnyCancellable?
    
    init(initialStatus: Store.CloudTransactionStatus = .idle, rotate: Bool = false) {
      status = initialStatus
      if rotate {
        // Rotates through the values, so you can see the transition animation in SwiftUI preview.
        timerCancellable = Timer.publish(every: 2, on: .main, in: .common)
          .autoconnect()
          .sink(
            receiveValue: { [weak self] _ in
              switch self?.status {
              case .idle: self?.status = .fetching
              case .fetching: self?.status = .saving(Self.thought)
              case .saving: self?.status = .error(Self.error)
              case .error: self?.status = .idle
              case .none: break
              }
            }
          )
      }
    }
  }
  
  static func containedOverlay(overlay: () -> StatusView) -> some View {
    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay(alignment: .bottomLeading) {
        overlay()
      }
  }

  static var previews: some View {
    containedOverlay {
      StatusView(
        statusProvider: PreviewStatusProvider(
          initialStatus: .idle
        )
      )
    }
   .previewDisplayName("Idle")

    containedOverlay {
      StatusView(
        statusProvider: PreviewStatusProvider(
          initialStatus: .fetching
        )
      )
    }
    .previewDisplayName("Fetching")

    containedOverlay {
      StatusView(
        statusProvider: PreviewStatusProvider(
          initialStatus: .saving(PreviewStatusProvider.thought)
        )
      )
    }
    .previewDisplayName("Saving")
    
    containedOverlay {
      StatusView(
        statusProvider: PreviewStatusProvider(
          initialStatus: .error(PreviewStatusProvider.error)
        )
      )
    }
    .previewDisplayName("Error")

    containedOverlay {
      StatusView(
        statusProvider: PreviewStatusProvider(
          rotate: true
        )
      )
    }
    .previewDisplayName("Rotating status")
  }
}
#endif
