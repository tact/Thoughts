#if os(iOS)
import UIKit

class AppDelegate: NSObject {
  let store = Store.live
  

}

extension AppDelegate: UIApplicationDelegate {
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      application.registerForRemoteNotifications()
      return true
  }
  
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: (UIBackgroundFetchResult)->()
  ) {
    completionHandler(.newData)
  }
}

#endif
