import CanopyTestTools
import CloudKit

extension StoreTests {
  /// Mock UserInfo, out of which we can construct a CKDatabaseNotification.
  static var databaseNotificationUserInfoMock: [AnyHashable: Any] = [
    "ck": [
      "met": [
        "zid": "Thoughts",
        "sid": "PrivateThoughtsZone",
        "zoid": "_deadbeef8badf00dd637d6f1feedface",
        "dbs": Int64(1)
      ],
      "ckuserid": "_deadbeef8badf00dd637d6f1feedface",
      "ce": Int64(2),
      "aux": [:],
      "nid": "deadbeef-f00d-beef-f00d-b8778badf00d",
      "cid": "iCloud.com.justtact.Thoughts"
    ],
    "aps": [
      "content-available": Int64(1)
    ]
  ]
  
  static var testUserRecordName = "testUserRecordID"
  
  /// Initial mock operations to run at store startup.
  static var initialContainerOperationResults: [ReplayingMockContainer.OperationResult] = {
    [
      .accountStatus(.init(status: .available, error: nil)),
      .userRecordID(.init(userRecordID: .init(recordName: testUserRecordName)))
    ]
  }()
  
  /// The operations performed from a blank state of the app.
  static var initialPrivateDatabaseOperationResults: [ReplayingMockDatabase.OperationResult] = {
    let zoneID = CKRecordZone.ID(zoneName: "Thoughts")
    let zone = CKRecordZone(zoneID: zoneID)
    let subscription = CKDatabaseSubscription(subscriptionID: "privateDatabase")

    return [
      .modifyZones(
        .init(result: .success(.init(savedZones: [zone], deletedZoneIDs: [])))
      ),
      .modifySubscriptions(
        .init(result: .success(.init(savedSubscriptions: [subscription], deletedSubscriptionIDs: [])))
      )
    ]
  }()
  
  /// Initial operations performed by the store when the CloudKit setup is done and we have a subscription.
  static var initialPrivateDatabaseOperationsWhenCloudKitSetupIsDone: [ReplayingMockDatabase.OperationResult] = {
    [
    ]
  }()
}
