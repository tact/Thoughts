import Canopy

extension Store {
  static var live: Store {
    let preferencesService = UserDefaultsPreferencesService()
    let tokenStore = UserDefaultsTokenStore()
    return Store(
      localCacheService: LocalCacheService(),
      cloudKitService: CloudKitService.live(
        withPreferencesService: preferencesService,
        tokenStore: tokenStore
      ),
      preferencesService: preferencesService,
      tokenStore: tokenStore
    )
  }
}
