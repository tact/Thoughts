import SwiftUI

struct SettingsView: View {
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
      Button(action: {}, label: {
        Text("Reset local cache")
      })
      Text("Reset the cache to clear local app state and re-download everything from iCloud.")
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView()
  }
}
