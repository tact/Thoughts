import Canopy
import Foundation
import IdentifiedCollections
import os.log
import Semaphore
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
    
    /// Simulate send failure.
    ///
    /// This instructs the system to treat all saving to CloudKit as failed.
    case simulateSendFailure(Bool)
    
    /// Simulate fetch failure
    ///
    /// This instructs the system to treat all change fetching as failed.
    case simulateFetchFailure(Bool)
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
  
  /// The semaphore makes sure that only one state-modifying operation is in progress at a time.
  /// This involves the initial bootstrap function, as well as action handling.
  private let semaphore = AsyncSemaphore(value: 1)
  
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
  private let tokenStore: TokenStoreType
  private let uuidService: UUIDServiceType
  private let behavior: Behavior
  
  init(
    localCacheService: LocalCacheServiceType,
    cloudKitService: CloudKitServiceType,
    preferencesService: PreferencesServiceType,
    tokenStore: TokenStoreType,
    behavior: Behavior = .regular,
    cloudTransactionStatus: CloudTransactionStatus = .idle,
    uuidService: UUIDServiceType = UUIDService()
  ) {
    self.localCacheService = localCacheService
    self.cloudKitService = cloudKitService
    self.preferencesService = preferencesService
    self.tokenStore = tokenStore
    self.behavior = behavior
    self.uuidService = uuidService
    
    guard behavior == .regular else { return }

    Task {
      await bootstrap()
    }
    
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
      
      // Stream the changes from cloud.
      // The stream is never closed and remains running
      // for the lifetime of the store.
      for await change in cloudKitService.changes {
        await ingestChangesFromCloud(change)
      }
    }
  }
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable: Any]) async -> FetchCloudChangesResult {
    await cloudKitService.ingestRemoteNotification(withUserInfo: userInfo)
  }
  
  var simulateSendFailureEnabled: Bool {
    get async {
      await preferencesService.simulateModifyFailure
    }
  }
  
  var simulateFetchFailureEnabled: Bool {
    get async {
      await preferencesService.simulateFetchFailure
    }
  }
    
  /// Receive an action, and process it.
  ///
  /// Actions are processed serially, guarded by the semaphore.
  func send(_ action: Store.Action) async {
    await semaphore.wait()
    defer { semaphore.signal() }
    
    switch action {
    case let .saveNewThought(title: title, body: body):
      let uuid = await uuidService.uuid
      let thought = Thought(
        id: uuid,
        title: title,
        body: body
      )
      thoughts.append(thought)
      await saveThought(thought)
      
    case let .modifyExistingThought(thought: thought, title: title, body: body):
      let updatedThought = Thought(
        id: thought.id,
        title: title,
        body: body,
        createdAt: thought.createdAt,
        modifiedAt: thought.modifiedAt
      )
      thoughts[id: thought.id] = updatedThought
      await saveThought(updatedThought)
      
    case let .delete(thought):
      thoughts.remove(id: thought.id)
      localCacheService.storeThoughts(thoughts.elements)
      
      let deleteResult = await cloudKitService.deleteThought(thought)
      switch deleteResult {
      case let .success(deletedThoughtID):
        logger.debug("Deleted thought ID from CloudKit: \(deletedThoughtID)")
      // Since local store was already modified above, nothing further to do here.
      case let .failure(error):
        logger.error("Could not delete thought from CloudKit: \(error)")
      }
      
    case .clearLocalState:
      thoughts = []
      localCacheService.clear()
      await tokenStore.clear()
      _ = await cloudKitService.fetchChangesFromCloud()
      
    case .refresh:
      _ = await fetchChangesFromCloud()
      
    case let .simulateSendFailure(simulate):
      await preferencesService.setSimulateModifyFailure(simulate)
      
    case let .simulateFetchFailure(simulate):
      await preferencesService.setSimulateFetchFailure(simulate)
    }
  }
}

// Private functions, called only from sender and other public code above.
extension Store {
  /// Bootstrap the store state upon initialization.
  ///
  /// Load data from storage and verify the iCloud user.
  private func bootstrap() async {
    await semaphore.wait()
    defer { semaphore.signal() }

    await loadThoughtsFromLocalCache()
    await verifyCloudKitUser()
  }
  
  /// A thought object has been created and updated locally and is ready to be saved.
  ///
  /// This could be either a new or updated thought, doesn’t really matter, they behave the same.
  /// It’s not meant to be called directly from outside: it should be called by the action handler.
  private func saveThought(_ thought: Thought) async {
    cloudTransactionStatus = .saving(thought)
    localCacheService.storeThoughts(thoughts.elements)
    let storedThought = await cloudKitService.saveThought(thought)
    switch storedThought {
    case let .success(thought):
      logger.debug("Saved modified thought to CloudKit: \(thought)")
      ingestChangesFromCloud([.modified(thought)])
      cloudTransactionStatus = .idle
    case let .failure(error):
      logger.error("Could not save modified thought to CloudKit: \(error)")
      cloudTransactionStatus = .error(error)
    }
  }
  
  private func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    // Slightly ghetto to do the waiting with a timer, but it will do for now.
    // We wait for the initial CloudKit setup to be done, and check every 0.2 seconds.
    // When it’s done, we do the initial pull from the cloud.
    // This makes sure the initial pull is done on a new device, as well as
    // when re-starting the app on a device where the setup is already done.
    while await preferencesService.cloudKitSetupDone == false {
      try? await Task.sleep(nanoseconds: UInt64(0.2 * Double(NSEC_PER_SEC)))
    }
    
    logger.debug("Starting to fetch changes from cloud.")
    cloudTransactionStatus = .fetching
    let result = await cloudKitService.fetchChangesFromCloud()
    switch result {
    case .noData, .newData:
      logger.debug("Fetched changes from cloud. No error.")
      cloudTransactionStatus = .idle
    case let .failed(error):
      logger.debug("Error fetching changes from cloud: \(error)")
      cloudTransactionStatus = .error(.canopy(error))
    }
    return result
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
      case let .modified(thought):
        thoughts[id: thought.id] = thought
      case let .deleted(thoughtId):
        thoughts.remove(id: thoughtId)
      }
    }
    localCacheService.storeThoughts(thoughts.elements)
  }
  
  private func ingestAccountState(_ state: CloudKitAccountState) {
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
  
  private func loadThoughtsFromLocalCache() async {
    let cachedThoughts = localCacheService.thoughts
    logger.debug("Restoring \(cachedThoughts.count) thoughts from local cache.")
    thoughts = IdentifiedArray(uniqueElements: cachedThoughts)
  }
  
  private func setInitialCloudTransactionStatus(_ status: CloudTransactionStatus) async {
    cloudTransactionStatus = status
  }
}
