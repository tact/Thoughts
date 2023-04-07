import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel: SettingsViewModel
  
  init(store: Store, state: SettingsViewModel.State = .regular) {
    self._viewModel = StateObject(wrappedValue: SettingsViewModel(store: store, state: state))
  }
  
  private let intraBlockSpacing = 8.0
  private let interBlockSpacing = 24.0
  
  var body: some View {
    VStack(alignment: .leading, spacing: interBlockSpacing) {
      #if os(iOS)
        Text("Settings")
          .font(.largeTitle)
          .bold()
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top)
      #endif
      Spacer()
      simulateFetchFailureView
      simulateSendFailureView
      resetLocalCacheView
    }
    .padding()
  }
  
  var simulateFetchFailureView: some View {
    VStack(alignment: .leading, spacing: intraBlockSpacing) {
      Toggle("Simulate fetch failures", isOn: $viewModel.simulateFetchFailureEnabled)
      Text("Simulate a failure for getting all changes on CloudKit. This lets you see how fetch errors are handled in the UI.")
        .font(.caption)
    }
  }
  
  var simulateSendFailureView: some View {
    VStack(alignment: .leading, spacing: intraBlockSpacing) {
      Toggle("Simulate save failures", isOn: $viewModel.simulateSendFailureEnabled)
      Text("Simulate a failure for storing all changes to CloudKit. This lets you see how saving errors are handled in the UI.")
        .font(.caption)
    }
  }
  
  var resetLocalCacheView: some View {
    VStack(alignment: .leading, spacing: intraBlockSpacing) {
      switch viewModel.state {
      case .regular:
        Button(action: {
          Task {
            await viewModel.resetLocalCache()
          }
        }, label: {
          Text("Reset local cache")
        })
      case .clearing:
        ProgressView(label: {
          Text("Resetting local cache…")
        })
      }
      Text("Reset the cache to clear local app state and re-download everything from iCloud.")
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView(store: .previewPopulated)
      .previewDisplayName("Regular")

    SettingsView(store: .previewPopulated, state: .clearing)
      .previewDisplayName("Clearing")
  }
}
