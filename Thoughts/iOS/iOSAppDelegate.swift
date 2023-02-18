#if os(iOS)
import UIKit

class AppDelegate: NSObject {
  let sharedAppDelegate = SharedAppDelegate()
}

extension AppDelegate: UIApplicationDelegate {
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.registerForRemoteNotifications()
    return true
  }
  
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)->()
  ) {
    Task {
      completionHandler(await sharedAppDelegate.store.ingestRemoteNotification(withUserInfo: userInfo).backgroundFetchResult)
    }
  }
}

#endif
