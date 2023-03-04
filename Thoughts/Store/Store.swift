import Canopy
import Foundation
import IdentifiedCollections
import os.log
import ThoughtsTypes

enum StoreAction {
  /// User indicated to create a new thought with the indicated content.
  case saveNewThought(title: String, body: String)
  
  /// User indicated to delete this thought.
  case delete(Thought)
  
  /// Clear local state and re-download everything.
  ///
  /// This may happen in two cases: user can manually request this in Settings,
  /// or a CloudKit record name mismatch is detected (meaning that another iCloud
  /// user logged in, who shouldn’t see previous user’s content.)
  case clearLocalState
}

actor Store {

  enum Behavior {
    /// The store should not run any logic.
    case blank
    
    /// Regular behavior.
    case regular
  }
  
  /// Current in-memory source of truth for the state of the model,
  /// known to the current running instance of the app.
  ///
  /// UI sends actions to manipulate this source of truth, which then gets stored
  /// to local cache and persisted to CloudKit.
  ///
  /// This is bootstrapped from local cache when the app starts.
  ///
  /// Manipulations can also arrive through CloudKit, modeled as async stream.
  /// Those manipulations are applied to this state and again persisted to local storage.
  @Published private(set) var thoughts: IdentifiedArrayOf<Thought> = []
  
  @Published private(set) var cloudKitAccountState: CloudKitAccountState = .provisionalAvailable
  
  private let logger = Logger(subsystem: "Thoughts", category: "Store")
  
  #if DEBUG
  /// Return a blank store that doesn’t talk to anything.
  ///
  /// This is mainly to be used in unit tests where the tests start the app but the app itself shouldn’t talk to any real services.
  static var blank: Store {
    Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: MockCloudKitService(),
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore(),
      behavior: .blank
    )
  }
  #endif
  
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
  
  private let localCacheService: LocalCacheServiceType
  private let cloudKitService: CloudKitServiceType
  private let preferencesService: PreferencesServiceType
  private let tokenStore: TokenStore
  private let behavior: Behavior
  
  init(
    localCacheService: LocalCacheServiceType,
    cloudKitService: CloudKitServiceType,
    preferencesService: PreferencesServiceType,
    tokenStore: TokenStore,
    behavior: Behavior = .regular
  ) {
    self.localCacheService = localCacheService
    self.cloudKitService = cloudKitService
    self.preferencesService = preferencesService
    self.tokenStore = tokenStore
    self.behavior = behavior
    
    guard behavior == .regular else { return }
    
    Task {
      // Task to observe CloudKit account state.
      for await newState in await cloudKitService.accountStateStream() {
        await ingestAccountState(newState)
      }
    }
    
    Task {
      // Task to load initial state and then apply changes from cloud.
      
      // Get the initial state of thoughts from storage
      await loadThoughtsFromLocalCache()

      await verifyCloudKitUser()
      
      // Stream the changes from cloud.
      // The stream is never closed and remains running
      // for the lifetime of the store.
      for await change in cloudKitService.changes {
        await ingestChangesFromCloud(change)
      }
    }
  }
  
  
  func loadThoughtsFromLocalCache() async {
    self.thoughts = IdentifiedArray(uniqueElements: localCacheService.thoughts)
  }
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult {
    await cloudKitService.ingestRemoteNotification(withUserInfo: userInfo)
  }
  
  func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    await cloudKitService.fetchChangesFromCloud()
  }
    
  func send(_ action: StoreAction) async {
    switch action {
    case .saveNewThought(title: let title, body: let body):
      let thought = Thought(
        id: UUID(),
        title: title,
        body: body
      )
      thoughts.append(thought)
      localCacheService.storeThoughts(thoughts.elements)
      let storedThought = await cloudKitService.saveThought(thought)
      switch storedThought {
      case .success(let thought):
        logger.debug("Saved new thought to CloudKit: \(thought)")
        ingestChangesFromCloud([.modified(thought)])
      case .failure(let error):
        logger.error("Could not save thought to CloudKit: \(error)")
      }
            
    case .delete(let thought):
      thoughts.remove(id: thought.id)
      localCacheService.storeThoughts(thoughts.elements)
      
      let deleteResult = await cloudKitService.deleteThought(thought)
      switch deleteResult {
      case .success(let deletedThoughtID):
        logger.debug("Deleted thought ID from CloudKit: \(deletedThoughtID)")
        // Since local store was already modified above, nothing further to do here.
      case .failure(let error):
        logger.error("Could not delete thought from CloudKit: \(error)")
      }
      
    case .clearLocalState:
      thoughts = []
      localCacheService.clear()
      await tokenStore.clear()
      _ = await cloudKitService.fetchChangesFromCloud()
    }
  }
  
  /// Ingest a collection of changes from the cloud.
  ///
  /// - Parameter changes: a sequence of mutations to apply.
  ///
  /// In case of fetching changes at startup or after foregrounding the app,
  /// this may be a collection. In case of ingesting changes after saving a record
  /// or receiving a notification, there may be just one element in the collection.
  private func ingestChangesFromCloud(_ changes: [CloudChange]) {
    for change in changes {
      switch change {
      case .modified(let thought):
        thoughts[id: thought.id] = thought
      case .deleted(let thoughtId):
        thoughts.remove(id: thoughtId)
      }
    }
    localCacheService.storeThoughts(thoughts.elements)
  }
  
  private func ingestAccountState(_ state: CloudKitAccountState) {
    print("Ingesting account state: \(state)")
    cloudKitAccountState = state
  }
  
  /// Verify that we are running with the correct CloudKit user.
  ///
  /// If the ID has changed, clear the state and start over, so that one user
  /// would not see content from another user.
  ///
  /// This may happen if the iCloud user changes on this device.
  private func verifyCloudKitUser() async {
    let recordName = try? await cloudKitService.cloudKitUserRecordName().get()
    guard let recordName else { return }
    let previousRecordName = await preferencesService.cloudKitUserRecordName
    if previousRecordName == nil {
      await preferencesService.setCloudKitUserRecordName(recordName)
      logger.debug("verifyCloudKitUser: no previous record name found, storing new one.")
    } else if previousRecordName == recordName {
      logger.debug("verifyCloudKitUser: record name matches known name.")
    } else {
      logger.error("verifyCloudKitUser: record name does not match known name. Clearing local state and starting over.")
      await preferencesService.setCloudKitUserRecordName(recordName)
      await send(.clearLocalState)
    }
  }
}


