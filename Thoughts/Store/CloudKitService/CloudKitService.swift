import Canopy
import CloudKit
import os.log

struct ThoughtsSyncSettings: SyncSettings {
  var developerCausePostingToFail: Bool { false }
  var developerAddFailureResponseDelay: Double { 0.0 }
}

actor CloudKitService {

  let syncService: SyncService
  private let logger = Logger(subsystem: "Thoughts", category: "CloudKitService")
  private let cloudChanges: AsyncStream<[CloudChange]>
  
  private var cloudChangeContinuation: AsyncStream<[CloudChange]>.Continuation? = nil
  
  static var live: CloudKitService {
    CloudKitService(
      syncService: CloudKitSyncService(
        ThoughtsSyncSettings(),
        cloudKitContainerIdentifier: "iCloud.com.justtact.Thoughts",
        tokenStore: UserDefaultsTokenStore()
      )
    )
  }
  
  private init(
    syncService: SyncService
  ) {
    self.syncService = syncService

    // Idea to capture and store the continuation from here:
    // https://www.donnywals.com/understanding-swift-concurrencys-asyncstream/
    var capturedContinuation: AsyncStream<[CloudChange]>.Continuation? = nil
    self.cloudChanges = AsyncStream { continuation in
      capturedContinuation = continuation
    }
    self.cloudChangeContinuation = capturedContinuation

    Task {
      await initZone()
      _ = await fetchChangesFromCloud()
      await createSubscriptionIfNeeded()
    }
  }
  
  private func initZone() async {
    let api = syncService.api(usingDatabaseScope: .private)
    let result = await api.modifyZones(saving: [thoughtsZone], deleting: nil, qualityOfService: .default)
    switch result {
    case .success: logger.debug("Stored CKRecordZone for thoughts.")
    case .failure(let error): logger.error("Error storing CKRecordZone for thoughts: \(error)")
    }
  }

  /// Fetch set of changes
  private func fetchChangesFromCloud() async -> FetchCloudChangesResult {
    let api = syncService.api(usingDatabaseScope: .private)
    let databaseChanges = await api.fetchDatabaseChanges(qualityOfService: .default)
    guard let changedRecordZoneIDs = try? databaseChanges.get().changedRecordZoneIDs else {
      return .failed
    }
    
    guard changedRecordZoneIDs.contains(thoughtsZone.zoneID) else {
      return .noData
    }
    
    let zoneChanges = await api.fetchZoneChanges(
      recordZoneIDs: [thoughtsZone.zoneID],
      fetchMethod: .changeTokenAndAllData,
      qualityOfService: .default
    )
    switch zoneChanges {
    case .success(let result):
      logger.debug("Fetched Thoughts zone changes: \(String(describing: result))")
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
  
  func ingestRemoteNotification(withUserInfo userInfo: [AnyHashable : Any]) async -> FetchCloudChangesResult {
    guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
          let databaseNotification = notification as? CKDatabaseNotification,
          databaseNotification.databaseScope == .private else {
      return .noData
    }
    return await fetchChangesFromCloud()
  }
  
  private func createSubscriptionIfNeeded() async {
    
    #warning("Check that we already have one, before making new one")
    
    let api = syncService.api(usingDatabaseScope: .private)
    
    let subscription = CKDatabaseSubscription(subscriptionID: "PrivateThoughtsZone")
    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.shouldSendContentAvailable = true
    subscription.notificationInfo = notificationInfo
    
    let result = await api.modifySubscriptions(
      saving: [subscription],
      deleting: nil,
      qualityOfService: .utility
    )
    switch result {
    case .success(let subs):
      print("Got subscriptions: \(subs)")
    case .failure(let error):
      print("Error saving subscriptions: \(error)")
    }
  }
  
  private var thoughtsZone: CKRecordZone {
    CKRecordZone(zoneID: .init(zoneName: "Thoughts", ownerName: CKCurrentUserDefaultName))
  }
  
  private func ckRecord(for thought: Thought) -> CKRecord {
    let record = CKRecord(recordType: "Thought", recordID: .init(recordName: thought.id.uuidString, zoneID: thoughtsZone.zoneID))
    record.encryptedValues["title"] = thought.title
    record.encryptedValues["body"] = thought.body
    return record
  }
}

enum CloudKitServiceError: Error {
  case couldNotGetModifiedThought
  case couldNotGetDeletedThoughtID
}

extension CloudKitService: CloudKitServiceType {
  
  nonisolated var changes: AsyncStream<[CloudChange]> { cloudChanges }
  
  func saveThought(_ thought: Thought) async -> Result<Thought, Error> {
    let api = syncService.api(usingDatabaseScope: .private)
    let result = await api.modifyRecords(
      saving: [ckRecord(for: thought)],
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
      deleting: [ckRecord(for: thought).recordID],
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
}
