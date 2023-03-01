import SwiftUI

struct SettingsView: View {
  
  @StateObject var viewModel: SettingsViewModel
  
  init(store: Store, state: SettingsViewModel.State = .regular) {
    self._viewModel = StateObject(wrappedValue: SettingsViewModel(store: store, state: state))
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      #if os(iOS)
      Text("Settings")
        .font(.largeTitle)
        .bold()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top)
      #endif
      Spacer()
      switch viewModel.state {
      case .regular:
        Button(action: {}, label: {
          Text("Reset local cache")
        })
      case .clearing:
        ProgressView(label: {
          Text("Resetting local cache…")
        })
      }
      Text("Reset the cache to clear local app state and re-download everything from iCloud.")
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
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
