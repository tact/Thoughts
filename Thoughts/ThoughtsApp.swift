//
//  ThoughtsApp.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

@main
struct ThoughtsApp: App {
  
  let store = Store.live
  
  var body: some Scene {
    WindowGroup {
      ThoughtsView(store: store)
    }
  }
}
