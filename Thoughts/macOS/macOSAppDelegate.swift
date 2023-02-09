#if os(macOS)
import AppKit

class AppDelegate: NSObject {
  let store = Store.live
}

extension AppDelegate: NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    NSApplication.shared.registerForRemoteNotifications()
  }
  
  func application(_: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
    print("Did receive notification: \(userInfo)")
  }
}
#endif
