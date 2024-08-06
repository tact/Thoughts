import Canopy
import CanopyTestTools
import CloudKit
@testable import Thoughts
import ThoughtsTypes
import XCTest

final class StoreTests: XCTestCase {
  func test_initial_blank_state() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: false,
      cloudKitUserRecordName: nil
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationResults,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 0)
  }
  
  func test_blank_state_when_cloudkit_setup_is_done() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: nil
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 0)
  }
  
  func test_ingests_new_thought_from_cloud() async {
    let zoneID = CKRecordZone.ID(zoneName: "Thoughts")
    let thought = Thought(id: .init(), title: "thought title", body: "body")
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: nil
    )
    
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone +
          [
            .fetchDatabaseChanges(
              .init(result: .success(.init(changedRecordZoneIDs: [zoneID], deletedRecordZoneIDs: [], purgedRecordZoneIDs: [])))
            ),
            .fetchZoneChanges(
              .init(result: .success(.init(records: [.init(ckRecord: thoughtRecord)], deletedRecords: [])))
            )
          ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )

    // let the initial operations complete
    try! await Task.sleep(for: .seconds(0.01))
    
    await store.send(.refresh)

    // Let the fetched changes flow through the async stream into the store.
    // This happens asynchronously.
    try! await Task.sleep(for: .seconds(0.01))

    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!.title, "thought title")
  }
  
  func test_ingests_notification() async {
    let zoneID = CKRecordZone.ID(zoneName: "Thoughts")
    let thought = Thought(id: .init(), title: "thought title", body: "body")
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .fetchDatabaseChanges(
            .init(
              changedRecordZoneIDs: [zoneID],
              deletedRecordZoneIDs: [],
              purgedRecordZoneIDs: [],
              fetchDatabaseChangesResult: .success
            )
          ),
          .fetchZoneChanges(
            .init(
              recordWasChangedInZoneResults: [
                .init(recordID: thoughtRecord.recordID, result: .success(thoughtRecord))
              ],
              recordWithIDWasDeletedInZoneResults: [],
              oneZoneFetchResults: [],
              fetchZoneChangesResult: .init(result: .success(()))
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    let result = await store.ingestRemoteNotification(withUserInfo: StoreTests.databaseNotificationUserInfoMock)
    XCTAssertEqual(result, .newData)
    
    // Let the fetched changes flow through the async stream into the store.
    // This happens asynchronously.
    try! await Task.sleep(for: .seconds(0.01))
    
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!.title, "thought title")
  }
  
  func test_preference_getters() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: StoreTests.testUserRecordName
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    let simulateSendFailureEnabled = await store.simulateSendFailureEnabled
    let simulateFetchFailureEnabled = await store.simulateFetchFailureEnabled
    XCTAssertFalse(simulateSendFailureEnabled)
    XCTAssertFalse(simulateFetchFailureEnabled)
  }
  
  func test_preference_setters() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    let oldFetchFailureState = await preferencesService.simulateFetchFailure
    let oldModifyFailureState = await preferencesService.simulateModifyFailure
    XCTAssertFalse(oldFetchFailureState)
    XCTAssertFalse(oldModifyFailureState)

    await store.send(.simulateSendFailure(true))
    await store.send(.simulateFetchFailure(true))
    let newFetchFailureState = await preferencesService.simulateFetchFailure
    let newModifyFailureState = await preferencesService.simulateModifyFailure
    XCTAssertTrue(newFetchFailureState)
    XCTAssertTrue(newModifyFailureState)
  }
  
  func test_saves_new_thought() async {
    let uuid = UUID()
    
    let thoughtRecordID = CKRecord.ID(recordName: uuid.uuidString)
    let thoughtRecord = CKRecord(recordType: "Thought", recordID: thoughtRecordID)
    thoughtRecord.encryptedValues["title"] = "New saved title"
    thoughtRecord.encryptedValues["body"] = "New saved body"
    
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName
    )
        
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .modify(
            .init(
              savedRecordResults: [
                .init(
                  recordID: thoughtRecordID,
                  result: .success(thoughtRecord)
                )
              ],
              deletedRecordIDResults: [],
              modifyResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore(),
      uuidService: MockUUIDService(uuids: [uuid])
    )
    await store.send(
      .saveNewThought(
        title: "New saved title",
        body: "New saved body"
      )
    )
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!.title, "New saved title")
  }
  
  func test_saves_new_thought_error() async {
    let uuid = UUID()
    
    let thoughtRecordID = CKRecord.ID(recordName: uuid.uuidString)
    let thoughtRecord = CKRecord(recordType: "Thought", recordID: thoughtRecordID)
    thoughtRecord.encryptedValues["title"] = "New saved title"
    thoughtRecord.encryptedValues["body"] = "New saved body"
    
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
        
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .modify(
            .init(
              savedRecordResults: [
                .init(
                  recordID: thoughtRecordID,
                  result: .failure(CKError(CKError.Code.networkUnavailable, userInfo: [CKErrorRetryAfterKey: 0.1]))
                )
              ],
              deletedRecordIDResults: [],
              modifyResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore(),
      uuidService: MockUUIDService(uuids: [uuid])
    )
    // Give the Store bootstrap a moment to run, so it manages to load the empty local store first.
    // Otherwise there is a data race - first the save runs, and then the bootstrap overwrites local store
    // with empty content.
    try? await Task.sleep(for: .seconds(0.01))
    await store.send(
      .saveNewThought(
        title: "New saved title",
        body: "New saved body"
      )
    )
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    let transactionStatus = await store.cloudTransactionStatus
    switch transactionStatus {
    case .error:
      break
    default:
      XCTFail("Unexpected transaction status: \(transactionStatus)")
    }
  }
  
  func test_modifies_thought() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let thought = Thought(
      id: .init(),
      title: "Previous title",
      body: "Previous body"
    )
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    thoughtRecord.encryptedValues["title"] = "Modified title"
    thoughtRecord.encryptedValues["body"] = "Modifed body"
    
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [thought]
      ),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .modify(
            .init(
              savedRecordResults: [
                .init(
                  recordID: thoughtRecord.recordID,
                  result: .success(thoughtRecord)
                )
              ],
              deletedRecordIDResults: [],
              modifyResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    let existingThought = thoughts.first!
    await store.send(
      .modifyExistingThought(
        thought: existingThought,
        title: "Modified title",
        body: "Modified body"
      )
    )
    
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 1)
    XCTAssertEqual(newThoughts.first!.title, "Modified title")
  }
  
  func test_deletes_thought_locally() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let thought = Thought(
      id: .init(),
      title: "Previous title",
      body: "Previous body"
    )
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [thought]
      ),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .modify(
            .init(
              savedRecordResults: [],
              deletedRecordIDResults: [
                .init(
                  recordID: thoughtRecord.recordID,
                  result: .success(())
                )
              ],
              modifyResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    let existingThought = thoughts.first!
    await store.send(.delete(existingThought))
    
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 0)
  }
  
  func test_deletes_thought_cloud_error() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let thought = Thought(
      id: .init(),
      title: "Previous title",
      body: "Previous body"
    )
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [thought]
      ),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .modify(
            .init(
              savedRecordResults: [],
              deletedRecordIDResults: [
                .init(
                  recordID: thoughtRecord.recordID,
                  result: .failure(CKError(CKError.Code.zoneBusy))
                )
              ],
              modifyResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    let existingThought = thoughts.first!
    await store.send(.delete(existingThought))
    
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 0)
  }
  
  func test_clears_local_state() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let thought = Thought(
      id: .init(),
      title: "Previous title",
      body: "Previous body"
    )
    
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [thought]
      ),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .fetchDatabaseChanges(
            .init(
              changedRecordZoneIDs: [],
              deletedRecordZoneIDs: [],
              purgedRecordZoneIDs: [],
              fetchDatabaseChangesResult: .success
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    await store.send(.clearLocalState)
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 0)
  }
  
  func test_cloud_refresh_error() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .fetchDatabaseChanges(
            .init(
              changedRecordZoneIDs: [],
              deletedRecordZoneIDs: [],
              purgedRecordZoneIDs: [],
              fetchDatabaseChangesResult: .init(
                result: .failure(
                  CKError(CKError.Code.networkUnavailable)
                )
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    await store.send(.refresh)
    let cloudTransactionStatus = await store.cloudTransactionStatus
    XCTAssertEqual(cloudTransactionStatus, .error(
      .canopy(
        .ckRequestError(
          .init(
            from: CKError(CKError.Code.networkUnavailable)
          )
        )
      )
    ))
  }
  
  func test_ingests_delete_from_cloud() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let thought = Thought(
      id: .init(),
      title: "Previous title",
      body: "Previous body"
    )
    let thoughtRecord = CloudKitService.ckRecord(for: thought)
    
    let thoughtsZoneID = CKRecordZone.ID(zoneName: "Thoughts")
    
    let store = Store(
      localCacheService: MockLocalCacheService(
        thoughts: [thought]
      ),
      cloudKitService: CloudKitService.test(
        containerOperationResults: StoreTests.initialContainerOperationResults,
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone + [
          .fetchDatabaseChanges(
            .init(
              changedRecordZoneIDs: [thoughtsZoneID],
              deletedRecordZoneIDs: [],
              purgedRecordZoneIDs: [],
              fetchDatabaseChangesResult: .success
            )
          ),
          .fetchZoneChanges(
            .init(
              recordWasChangedInZoneResults: [],
              recordWithIDWasDeletedInZoneResults: [
                .init(recordID: thoughtRecord.recordID, recordType: "Thought")
              ],
              oneZoneFetchResults: [],
              fetchZoneChangesResult: .init(
                result: .success(())
              )
            )
          )
        ],
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    
    try? await Task.sleep(for: .seconds(0.1))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    
    await store.send(.refresh)
    try? await Task.sleep(for: .seconds(0.1))
    let newThoughts = await store.thoughts
    XCTAssertEqual(newThoughts.count, 0)
  }
  
  func test_verify_user_does_not_get_record_name_from_cloud() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: Self.testUserRecordName,
      autoRetryForRetriableErrors: false
    )
    let _ = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: [
          .accountStatus(.init(status: .available, error: nil)),
          .userRecordID(.init(userRecordID: nil, error: CKError(CKError.Code.networkUnavailable)))
        ],
        privateDatabaseOperationResults: StoreTests.initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService,
      tokenStore: TestTokenStore()
    )
    try? await Task.sleep(for: .seconds(0.1))
  }
}
