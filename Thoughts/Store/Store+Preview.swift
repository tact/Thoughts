#if DEBUG
import Canopy
import Foundation

extension Store {
  
  /// Empty static store.
  static var previewEmpty: Store {
    Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(initialAccountState: .available),
      preferencesService: TestPreferencesService(cloudKitSetupDone: true),
      tokenStore: TestTokenStore()
    )
  }
  
  /// A store populated with some thoughts.
  static var previewPopulated: Store {
    Store(
      localCacheService: MockLocalCacheService(
        thoughts: [
          .init(
            id: UUID(),
            title: "Thought 1",
            body: "Body 1",
            createdAt: nil,
            modifiedAt: nil
          )
        ]
      ),
      cloudKitService: MockCloudKitService(
        initialChanges: [
          .modified(
            .init(
              id: UUID(),
              title: "Thought from cloud",
              body: "Thought body from cloud"
            )
          )
        ],
        initialAccountState: .available
      ),
      preferencesService: TestPreferencesService(cloudKitSetupDone: true),
      tokenStore: TestTokenStore()
    )
  }
  
  static var noAccountState: Store {
    Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(initialAccountState: .noAccount),
      preferencesService: TestPreferencesService(cloudKitSetupDone: false),
      tokenStore: TestTokenStore()
    )
  }
  
  static var unknownAccountState: Store {
    Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(initialAccountState: .unknown),
      preferencesService: TestPreferencesService(cloudKitSetupDone: false),
      tokenStore: TestTokenStore()
    )
  }
}
#endif
