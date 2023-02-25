#if os(macOS)
import AppKit

class AppDelegate: NSObject {
  let sharedAppDelegate = SharedAppDelegate()
}

extension AppDelegate: NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    NSApplication.shared.registerForRemoteNotifications()
  }
  
  func application(_: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
    Task {
      let _ = await sharedAppDelegate.store.ingestRemoteNotification(withUserInfo: userInfo)
    }
  }
}
#endif
