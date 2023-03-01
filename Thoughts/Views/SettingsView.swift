//
//  SettingsView.swift
//  Thoughts
//
//  Created by Jaanus Kase on 01.03.2023.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
      VStack {
        Spacer()
        Text("Hello, settings")
          .frame(maxWidth: .infinity)
      }
      .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
