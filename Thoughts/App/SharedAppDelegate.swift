import Foundation
import ThoughtsTypes

enum AppBehavior {
  /// App is being run in the context of unit testing. Don’t load any live data or services.
  case unitTesting
  
  /// App is being run in a configuration with a static mock store.
  ///
  /// The mock store is passed in through the OS environment. One use for this is UI testing
  /// where the UI test side sets up the mock store data, and passes it to the app.
  /// This way, the app is run with preconfigured data, without any real interaction
  /// to external services.
  case mockStore(TestSupport.MockStore)
  
  /// App is being run in its regular configuration.
  case regular
}

/// Functionality shared between iOS and macOS app delegates.
struct SharedAppDelegate {
  let store: Store
  
  init() {
    #if DEBUG
    switch SharedAppDelegate.appBehavior {
    case .regular: store = Store.live
    case .unitTesting: store = Store.blank
    case .mockStore(let mockStore): store = Store.fromMockStore(mockStore)
    }
    #else
    // When running the app in non-debug configuration, just use the live store.
    store = Store.live
    #endif
  }
  
  static var appBehavior: AppBehavior {
    #if DEBUG
    if let behavior = ProcessInfo.processInfo.environment["APP_BEHAVIOR"], behavior == "unitTesting" {
      return .unitTesting
    }
    
    if let mockJson = ProcessInfo.processInfo.environment[TestSupport.StoreEnvironmentKey],
       let jsonData = mockJson.data(using: .utf8) {
      // We have a mock store passed in. Attempt to decode it.
      do {
        let decodedMockStore = try JSONDecoder().decode(TestSupport.MockStore.self, from: jsonData)
        return .mockStore(decodedMockStore)
      } catch {
        // If it looks like it was a mock, but we couldn’t decode it properly, it’s best to crash
        // and not put the app in some weird state. Probably there was invalid data passed in
        // that couldn’t be decoded.
        fatalError("Error decoding store from mock: \(error)")
      }
    }
    
    // There was no unit test and no mock store. We are running a regular app.
    return .regular
    #else
    .regular
    #endif
  }
}
