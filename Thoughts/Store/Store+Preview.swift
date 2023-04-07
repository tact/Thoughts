#if DEBUG
  import Canopy
  import Foundation

  extension Store {
    /// Empty static store.
    static var previewEmpty: Store {
      Store(
        localCacheService: MockLocalCacheService(),
        cloudKitService: CloudKitService.accountAvailable,
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
        cloudKitService: CloudKitService.populatedWithOneThought,
        preferencesService: TestPreferencesService(cloudKitSetupDone: true),
        tokenStore: TestTokenStore()
      )
    }
     
    static var noAccountState: Store {
      Store(
        localCacheService: MockLocalCacheService(),
        cloudKitService: CloudKitService.noAccountState,
        preferencesService: TestPreferencesService(cloudKitSetupDone: false),
        tokenStore: TestTokenStore()
      )
    }
  
    static var unknownAccountState: Store {
      Store(
        localCacheService: MockLocalCacheService(),
        cloudKitService: CloudKitService.unknownAccountState,
        preferencesService: TestPreferencesService(cloudKitSetupDone: false),
        tokenStore: TestTokenStore()
      )
    }
  }
#endif
