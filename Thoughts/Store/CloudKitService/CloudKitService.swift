import Canopy
import CloudKit
import os.log
import ThoughtsTypes

#if DEBUG
import CanopyTestTools
#endif

struct ThoughtsSyncSettings: SyncSettings {
  var developerCausePostingToFail: Bool { false }
  var developerAddFailureResponseDelay: Double { 0.0 }
}

actor CloudKitService {

  let syncService: SyncService
  let preferencesService: PreferencesServiceType
  
  private let logger = Logger(subsystem: "Thoughts", category: "CloudKitService")
  private let cloudChanges: AsyncStream<[CloudChange]>
  private static let thoughtsCloudKitZoneName = "Thoughts"
  
  private var cloudChangeContinuation: AsyncStream<[CloudChange]>.Continuation? = nil
  
  static func live(
    withPreferencesService preferencesService: PreferencesServiceType,
    tokenStore: TokenStore
  ) -> CloudKitService {
    CloudKitService(
      syncService: CloudKitSyncService(
        ThoughtsSyncSettings(),
        cloudKitContainerIdentifier: "iCloud.com.justtact.Thoughts",
        tokenStore: tokenStore
      ),
      preferencesService: preferencesService
    )
  }
  
  #if DEBUG
  static func test(
    containerOperationResults: [MockCKContainer.OperationResult],
    privateDatabaseOperationResults: [MockDatabase.OperationResult],
    preferencesService: PreferencesServiceType
  ) -> CloudKitService {
    CloudKitService(
      syncService: MockSyncService(
        mockPrivateDatabase: MockDatabase(
          operationResults: privateDatabaseOperationResults,
          scope: .private
        ),
        mockContainer: MockCKContainer(
          operationResults: containerOperationResults
        )
      ),
      preferencesService: preferencesService
    )
  }
  #endif
  
  init(
    syncService: SyncService,
    preferencesService: PreferencesServiceType
  ) {
    self.syncService = syncService
    self.preferencesService = preferencesService

    // Idea to capture and store the continuation from here:
    // https://www.donnywals.com/understanding-swift-concurrencys-asyncstream/
    var capturedContinuation: AsyncStream<[CloudChange]>.Continuation? = nil
    self.cloudChanges = AsyncStream { continuation in
      capturedContinuation = continuation
    }
    self.cloudChangeContinuation = capturedContinuation
    Task {
      await createZoneAndSubscriptionIfNeeded()

      // Not sure why code from here on is run with Xcode 14.3.0 previews??? But above is not?
      // Thread.callStackSymbols.forEach{print($0)}
      
      // Fetch initial set of changes from cloud when starting up.
      _ = await fetchChangesFromCloud()
    }
  }
  
  private func createZoneAndSubscriptionIfNeeded() async {
    guard await !preferencesService.cloudKitSetupDone else {
      logger.debug("Previously already created zone and subscription. Not doing again.")
      return
    }
    
    // Create CloudKit zone.
    
    let zoneCreatedSuccessfully: Bool
    let api = syncService.api(usingDatabaseScope: .private)
    let result = await api.modifyZones(saving: [Self.thoughtsZone], deleting: nil, qualityOfService: .default)
    switch result {
    case .success:
      logger.debug("Stored CKRecordZone for thoughts.")
      zoneCreatedSuccessfully = true
    case .failure(let error):
      logger.error("Error storing CKRecordZone for thoughts: \(error)")
      zoneCreatedSuccessfully = false
    }
    
    // Create CloudKit subscription.
    
    let subscriptionCreatedSuccessfully: Bool
    let subscription = CKDatabaseSubscription(subscriptionID: "PrivateThoughtsZone")
    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.shouldSendContentAvailable = true
    subscription.notificationInfo = notificationInfo
    
    let subscriptionResult = await api.modifySubscriptions(
      saving: [subscription],
      deleting: nil,
      qualityOfService: .utility
    )
    switch subscriptionResult {
    case .success(let subs):
      subscriptionCreatedSuccessfully = true
      print("Got subscriptions: \(subs)")
    case .failure(let error):
      subscriptionCreatedSuccessfully = false
      print("Error saving subscriptions: \(error)")
    }

    // We are done with initial setup and successfully created zone and subscription,
    // no need to run it in the future until the state is cleared for some reason.
    if zoneCreatedSuccessfully && subscriptionCreatedSuccessfully {
      await preferencesService.setCloudKitSetupDone(true)
    }
  }

  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable : Any]) async -> FetchCloudChangesResult {
    guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
          let databaseNotification = notification as? CKDatabaseNotification,
          databaseNotification.databaseScope == .private else {
      return .noData
    }
    return await fetchChangesFromCloud()
  }
  
  private static var thoughtsZone: CKRecordZone {
    CKRecordZone(zoneID: .init(zoneName: thoughtsCloudKitZoneName, ownerName: CKCurrentUserDefaultName))
  }
  
  public static func ckRecord(for thought: Thought) -> CKRecord {
    let record = CKRecord(recordType: "Thought", recordID: .init(recordName: thought.id.uuidString, zoneID: thoughtsZone.zoneID))
    record.encryptedValues["title"] = thought.title
    record.encryptedValues["body"] = thought.body
    return record
  }
}

enum CloudKitServiceError: Error {
  case couldNotGetModifiedThought
  case couldNotGetDeletedThoughtID
  case couldNotGetUserRecordID
}



extension CloudKitService: CloudKitServiceType {
  
  nonisolated var changes: AsyncStream<[CloudChange]> { cloudChanges }
  
  func saveThought(_ thought: Thought) async -> Result<Thought, Error> {
    let api = syncService.api(usingDatabaseScope: .private)
    let result = await api.modifyRecords(
      saving: [Self.ckRecord(for: thought)],
      deleting: nil,
      perRecordProgressBlock: nil,
      qualityOfService: .userInitiated
    )
    switch result {
    case .success(let modifyRecordsResult):
      if let modifiedThought = modifyRecordsResult.savedRecords.first {
        return .success(Thought(from: modifiedThought))
      } else {
        return .failure(CloudKitServiceError.couldNotGetModifiedThought)
      }
    case .failure(let error):
      return .failure(error)
    }
  }
  
  func deleteThought(_ thought: Thought) async -> Result<Thought.ID, Error> {
    let api = syncService.api(usingDatabaseScope: .private)
    let result = await api.modifyRecords(
      saving: nil,
      deleting: [Self.ckRecord(for: thought).recordID],
      perRecordProgressBlock: nil,
      qualityOfService: .userInitiated
    )
    switch result {
    case .success(let modifyRecordsResult):
      if let deletedThoughtIDResult = modifyRecordsResult.deletedRecordIDs.first,
         let deletedThoughtID = Thought.ID(uuidString: deletedThoughtIDResult.recordName)
      {
        return .success(deletedThoughtID)
      } else {
        return .failure(CloudKitServiceError.couldNotGetDeletedThoughtID)
      }
    case .failure(let error):
      return .failure(error)
    }
  }
  
  func accountStateStream() async -> CloudKitAccountStateSequence {
    let containerAPI = syncService.containerAPI()
    // Don’t handle the unlikely case where getting the account stream is an error - crash in that case
    let stream = try! await containerAPI.accountStatusStream.get()
    
    return CloudKitAccountStateSequence(kind: .live(stream))
  }
  
  /// Fetch set of changes
  func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    let api = syncService.api(usingDatabaseScope: .private)
    let databaseChanges = await api.fetchDatabaseChanges(qualityOfService: .default)
    guard let changedRecordZoneIDs = try? databaseChanges.get().changedRecordZoneIDs else {
      return .failed
    }
    
    guard changedRecordZoneIDs.contains(Self.thoughtsZone.zoneID) else {
      return .noData
    }
    
    let zoneChanges = await api.fetchZoneChanges(
      recordZoneIDs: [Self.thoughtsZone.zoneID],
      fetchMethod: .changeTokenAndAllData,
      qualityOfService: .default
    )
    switch zoneChanges {
    case .success(let result):
      logger.debug("Fetched Thoughts zone changes: \(result.changedRecords.count) changed, \(result.deletedRecords.count) deleted records.")
      var changes: [CloudChange] = []
      for changed in result.changedRecords {
        changes.append(.modified(.init(from: changed)))
      }
      for deleted in result.deletedRecords {
        if let uuid = UUID(uuidString: deleted.recordID.recordName) {
          changes.append(.deleted(uuid))
        } else {
          logger.log("Error creating UUID from deleted record ID: \(deleted.recordID)")
        }
      }
      cloudChangeContinuation?.yield(changes)
      return changes.isEmpty ? .noData : .newData
    case .failure(let error):
      logger.log("Error fetching Thoughts zone changes: \(error)")
      return .failed
    }
  }
  
  /// Fetch current user’s CloudKit record name.
  func cloudKitUserRecordName() async -> Result<String, Error> {
    let result = await syncService.containerAPI().userRecordID
    switch result {
    case .failure(let error): return .failure(error)
    case .success(let recordID):
      if let recordID {
        return .success(recordID.recordName)
      } else {
        return .failure(CloudKitServiceError.couldNotGetUserRecordID)
      }
    }
  }
}
