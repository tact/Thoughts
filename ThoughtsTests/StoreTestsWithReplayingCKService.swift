@testable import Thoughts
import ThoughtsTypes
import Canopy
import CanopyTestTools
import CloudKit
import XCTest

final class StoreTestsWithReplayingCKService: XCTestCase {

  /// Initial mock operations to run at store startup.
  private var initialContainerOperationResults: [MockCKContainer.OperationResult] {
    [
      .accountStatus(.init(status: .available, error: nil)),
      .accountStatus(.init(status: .available, error: nil))
    ]
  }
  
  /// The operations performed from a blank state of the app.
  private var initialPrivateDatabaseOperationResults: [MockDatabase.OperationResult] {
    let zoneID = CKRecordZone.ID(zoneName: "Thoughts")
    let zone = CKRecordZone(zoneID: zoneID)
    let subscription = CKDatabaseSubscription(subscriptionID: "privateDatabase")

    return [
      .modifyZones(
        .init(
          savedZoneResults: [
            .init(zoneID: zoneID, result: .success(zone))
          ],
          deletedZoneIDResults: [],
          modifyZonesResult: .init(result: .success(()))
        )
      ),
      .modifySubscriptions(
        .init(
          savedSubscriptionResults: [
            .init(subscriptionID: "Subscription", result: .success(subscription))
          ],
          deletedSubscriptionIDResults: [],
          modifySubscriptionsResult: .init(result: .success(()))
        )
      ),
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .success
        )
      )
    ]
  }
  
  /// Initial operations performed by the store when the CloudKit setup is done and we have a subscription.
  private var initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone: [MockDatabase.OperationResult] {
    [
      .fetchDatabaseChanges(
        .init(
          changedRecordZoneIDs: [],
          deletedRecordZoneIDs: [],
          purgedRecordZoneIDs: [],
          fetchDatabaseChangesResult: .success
        )
      )
    ]
  }

  func test_store_initial_blank_state_from_cloud() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: false,
      cloudKitUserRecordName: nil
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: initialContainerOperationResults,
        privateDatabaseOperationResults: initialPrivateDatabaseOperationResults,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService
    )
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 0)
  }
  
  func test_store_blank_state_when_cloudkit_setup_is_done() async {
    let preferencesService = TestPreferencesService(
      cloudKitSetupDone: true,
      cloudKitUserRecordName: nil
    )
    let store = Store(
      localCacheService: MockLocalCacheService(),
      cloudKitService: CloudKitService.test(
        containerOperationResults: initialContainerOperationResults,
        privateDatabaseOperationResults: initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone,
        preferencesService: preferencesService
      ),
      preferencesService: preferencesService
    )
    try! await Task.sleep(for: .seconds(0.01))
    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 0)
  }
  
  func test_store_receives_new_thought_from_cloud_after_notification() async {
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
        containerOperationResults: initialContainerOperationResults,
        privateDatabaseOperationResults: initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone +
          [
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
      preferencesService: preferencesService
    )

    // let the initial operations complete
    try! await Task.sleep(for: .seconds(0.01))
    
    let fetchChangesResult = await store.fetchChangesFromCloud()
    XCTAssertEqual(fetchChangesResult, .newData)

    // Let the fetched changes flow through the async stream into the store.
    // This happens asynchronously.
    try! await Task.sleep(for: .seconds(0.01))

    let thoughts = await store.thoughts
    XCTAssertEqual(thoughts.count, 1)
    XCTAssertEqual(thoughts.first!.title, "thought title")
  }
}
