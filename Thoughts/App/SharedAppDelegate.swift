import Foundation
import ThoughtsTypes

enum AppBehavior {
  /// App is being run in the context of unit testing. Don’t load any live data or services.
  case unitTesting
  
  /// App is being run in its regular configuration.
  case regular
}

/// Functionality shared between iOS and macOS app delegates.
struct SharedAppDelegate {
  let store: Store
  
  init() {
    #if DEBUG
    do {
      guard let mockJson = ProcessInfo.processInfo.environment[TestSupport.StoreEnvironmentKey],
            let jsonData = mockJson.data(using: .utf8) else {
        // There was no mock data passed in.
        // We may be running either unit tests, or in real configuration.
        // In case of unit tests, we learn this from the environment variable that the unit tests set.
        switch SharedAppDelegate.appBehavior {
        case .regular: store = Store.live
        case .unitTesting: store = Store.blank
        }
        return
      }
      // We got a correctly decoded mock state for the store. Set the store up from the received state.
      let decodedMockStore = try JSONDecoder().decode(TestSupport.MockStore.self, from: jsonData)
      store = Store.fromMockStore(decodedMockStore)
    } catch {
      // If it looks like it was a mock, but we couldn’t decode it properly, it’s best to crash
      // and not put the app in some weird state. Probably there was invalid data passed in
      // that couldn’t be decoded.
      fatalError("Error decoding store from mock: \(error)")
    }
    
    #else
    // When running the app in non-debug configuration, just use the live store.
    store = Store.live
    #endif
  }
  
  static var appBehavior: AppBehavior {
    if let behavior = ProcessInfo.processInfo.environment["APP_BEHAVIOR"], behavior == "unitTesting" {
      return .unitTesting
    }
    return .regular
  }
}
