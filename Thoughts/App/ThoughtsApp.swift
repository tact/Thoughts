//
//  ThoughtsApp.swift
//  Thoughts
//
//  Created by Jaanus Kase on 04.02.2023.
//

import SwiftUI

@main
struct ThoughtsApp: App {
  #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif
  
  #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #endif
  
  var body: some Scene {
    WindowGroup {
      ThoughtsView(store: appDelegate.sharedAppDelegate.store)
    }
    #if os(macOS)
      Settings {
        SettingsView(store: appDelegate.sharedAppDelegate.store)
      }
    #endif
  }
}
