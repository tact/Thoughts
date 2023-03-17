import Canopy
import Foundation
import IdentifiedCollections
import os.log
import ThoughtsTypes

actor Store {

  enum Behavior {
    /// The store should not run any logic.
    case blank
    
    /// Regular behavior.
    case regular
  }
  
  enum Action {
    /// User indicated to create a new thought with the indicated content.
    case saveNewThought(title: String, body: String)
    
    /// User indicated to update an existing thought with the indicated content.
    case modifyExistingThought(thought: Thought, title: String, body: String)
    
    /// User indicated to delete this thought.
    case delete(Thought)
    
    /// Clear local state and re-download everything.
    ///
    /// This may happen in two cases: user can manually request this in Settings,
    /// or a CloudKit record name mismatch is detected (meaning that another iCloud
    /// user logged in, who shouldn’t see previous user’s content.)
    case clearLocalState
    
    /// Refresh data from the cloud.
    ///
    /// This could be from a user interaction, e.g pull down in the list.
    case refresh
  }
  
  /// Indicate cloud transaction status in a form that’s suitable for presenting to the user.
  ///
  /// This is not a comprehensive log. Latest changes will overwrite previous ones.
  /// The main use for this is to present the latest status to user in UI, and allow them
  /// to find out more.
  enum CloudTransactionStatus: Equatable {
    /// No operations in progress.
    case idle
    
    /// Saving one thought.
    case saving(Thought)
    
    /// Fetching new changes from the cloud.
    case fetching
    
    /// There was an error fetching or syncing.
    case error(CloudKitServiceError)
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
  
  @Published private(set) var cloudTransactionStatus: CloudTransactionStatus = .idle
  
  private let logger = Logger(subsystem: "Thoughts", category: "Store")
  
  #if DEBUG
  /// Return a blank store that doesn’t talk to anything.
  ///
  /// This is mainly to be used in unit tests where the tests start the app but the app itself shouldn’t talk to any real services.
  static var blank: Store {
    Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.blank,
      preferencesService: TestPreferencesService(),
      tokenStore: TestTokenStore(),
      behavior: .blank
    )
  }
  #endif
  
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
    behavior: Behavior = .regular,
    cloudTransactionStatus: CloudTransactionStatus = .idle
  ) {
    self.localCacheService = localCacheService
    self.cloudKitService = cloudKitService
    self.preferencesService = preferencesService
    self.tokenStore = tokenStore
    self.behavior = behavior
    
    guard behavior == .regular else { return }

    Task {
      await setInitialCloudTransactionStatus(cloudTransactionStatus)
    }
    
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
  
  func setInitialCloudTransactionStatus(_ status: CloudTransactionStatus) async {
    print("Store \(Unmanaged.passUnretained(self).toOpaque()): Setting initial cloud transaction status: \(status)")
    self.cloudTransactionStatus = status
  }
  
  private func loadThoughtsFromLocalCache() async {
    self.thoughts = IdentifiedArray(uniqueElements: localCacheService.thoughts)
  }
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult {
    await cloudKitService.ingestRemoteNotification(withUserInfo: userInfo)
  }
  
  private func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    cloudTransactionStatus = .fetching
    let result = await cloudKitService.fetchChangesFromCloud()
    switch result {
    case .noData, .newData:
      cloudTransactionStatus = .idle
    case .failed(let error):
      cloudTransactionStatus = .error(.canopy(error))
    }
    return result
  }
    
  func send(_ action: Store.Action) async {
    switch action {
    case .saveNewThought(title: let title, body: let body):
      let thought = Thought(
        id: UUID(),
        title: title,
        body: body
      )
      cloudTransactionStatus = .saving(thought)
      
      #warning("fixme remove debugging")
//      try? await Task.sleep(for: .seconds(3600))
      
      thoughts.append(thought)
      localCacheService.storeThoughts(thoughts.elements)
      let storedThought = await cloudKitService.saveThought(thought)
      switch storedThought {
      case .success(let thought):
        logger.debug("Saved new thought to CloudKit: \(thought)")
        ingestChangesFromCloud([.modified(thought)])
        cloudTransactionStatus = .idle
      case .failure(let error):
        logger.error("Could not save thought to CloudKit: \(error)")
        cloudTransactionStatus = .error(error)
      }
    case .modifyExistingThought(thought: let thought, title: let title, body: let body):
      let updatedThought = Thought(
        id: thought.id,
        title: title,
        body: body,
        createdAt: thought.createdAt,
        modifiedAt: thought.modifiedAt
      )
      cloudTransactionStatus = .saving(updatedThought)
      thoughts[id: thought.id] = updatedThought
      localCacheService.storeThoughts(thoughts.elements)
      let storedThought = await cloudKitService.saveThought(updatedThought)
      switch storedThought {
      case .success(let thought):
        logger.debug("Saved modified thought to CloudKit: \(thought)")
        ingestChangesFromCloud([.modified(thought)])
        cloudTransactionStatus = .idle
      case .failure(let error):
        logger.error("Could not save modified thought to CloudKit: \(error)")
        cloudTransactionStatus = .error(error)
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
      
    case .refresh:
      logger.debug("Starting refresh")
      cloudTransactionStatus = .fetching
      let result = await cloudKitService.fetchChangesFromCloud()
      switch result {
      case .newData, .noData:
        logger.debug("Ended refresh, no error.")
        cloudTransactionStatus = .idle
      case .failed(let error):
        logger.debug("Ended refresh with error: \(error)")
        cloudTransactionStatus = .error(.canopy(error))
      }
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


