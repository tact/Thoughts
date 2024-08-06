import CanopyTestTools
import CanopyTypes
import CloudKit
import ThoughtsTypes

extension ThoughtsUITests {
  static var mockUUIDs: [UUID] = [UUID()]
  
  static var blankAppMockStore: TestSupport.MockStore {
    .init(
      mockLocalCacheServiceContent: .init(thoughts: []),
      mockCloudKitServiceContent: .init(
        containerOperationResults: [
          .accountStatus(.init(status: .available, error: nil)),
          .userRecordID(.init(userRecordID: .init(recordName: "blankTestUserRecordName"))),
          .accountStatusStream(.init(statuses: [.available], error: nil))
        ],
        privateDatabaseOperationResults: [
          .modifyZones(
            .init(result: .success(.init(savedZones: [.init(zoneID: .init(zoneName: "Thoughts", ownerName: CKCurrentUserDefaultName))], deletedZoneIDs: [])))
          ),
          .modifySubscriptions(
            .init(result: .success(.init(savedSubscriptions: [CKDatabaseSubscription(subscriptionID: "Thoughts")], deletedSubscriptionIDs: [])))
          ),
          .fetchDatabaseChanges(
            .init(result: .success(.empty))
          )
        ]
      ),
      mockPreferencesServiceContent: .init(cloudKitSetupDone: false, cloudKitUserRecordName: nil),
      mockUUIDServiceContent: .init(uuids: [])
    )
  }
  
  static var withSomeLocalThoughtsMockStore: TestSupport.MockStore {
    .init(
      mockLocalCacheServiceContent: .init(
        thoughts: [
          .init(
            id: .init(uuidString: "BF69292D-27CE-49C0-84C6-80F93D28A74D")!,
            title: "Title from UI test",
            body: "Body from UI test",
            createdAt: ISO8601DateFormatter().date(from: "2023-02-24T05:43:00Z02:00"),
            modifiedAt: ISO8601DateFormatter().date(from: "2023-02-24T05:43:00Z02:00")
          )
        ]
      ),
      mockCloudKitServiceContent: .init(
        containerOperationResults: [
          .userRecordID(.init(userRecordID: .init(recordName: "TestUserRecordName"))),
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatusStream(.init(statuses: [.available], error: nil))
        ],
        privateDatabaseOperationResults: [
          .fetchDatabaseChanges(.blank)
        ]
      ),
      mockPreferencesServiceContent: .init(
        cloudKitSetupDone: true,
        cloudKitUserRecordName: "TestUserRecordName"
      ),
      mockUUIDServiceContent: .init(uuids: [])
    )
  }
  
  static var withSomeLocalAndCloudThoughtsMockStore: TestSupport.MockStore {
    let thoughtID = UUID()
    
    let thoughtRecord = MockCanopyResultRecord(
      recordID: .init(recordName: thoughtID.uuidString),
      recordType: "Thought",
      creationDate: ISO8601DateFormatter().date(from: "2023-03-01T10:00:00Z00:00"),
      modificationDate: ISO8601DateFormatter().date(from: "2023-03-02T10:00:00Z00:00"),
      encryptedValues: [
        "title":  "Title from cloud",
        "body": "Body from cloud"
      ]
    )

    return .init(
      mockLocalCacheServiceContent: .init(
        thoughts: [
          .init(
            id: .init(uuidString: "BF69292D-27CE-49C0-84C6-80F93D28A74D")!,
            title: "Title from UI test",
            body: "Body from UI test",
            createdAt: ISO8601DateFormatter().date(from: "2023-02-24T05:43:00Z02:00"),
            modifiedAt: ISO8601DateFormatter().date(from: "2023-02-24T05:43:00Z02:00")
          )
        ]
      ),
      mockCloudKitServiceContent: .init(
        containerOperationResults: [
          .userRecordID(.init(userRecordID: .init(recordName: "TestUserRecordName"))),
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatusStream(.init(statuses: [.available], error: nil))
        ],
        privateDatabaseOperationResults: [
          .fetchDatabaseChanges(
            .init(
              result: .success(
                .init(
                  changedRecordZoneIDs: [.init(zoneName: "Thoughts")],
                  deletedRecordZoneIDs: [],
                  purgedRecordZoneIDs: []
                )
              )
            )
          ),
          .fetchZoneChanges(
            .init(result: .success(.init(records: [.mock(thoughtRecord)], deletedRecords: [])))
          )
        ]
      ),
      mockPreferencesServiceContent: .init(
        cloudKitSetupDone: true,
        cloudKitUserRecordName: "TestUserRecordName"
      ),
      mockUUIDServiceContent: .init(uuids: [])
    )
  }
  
  static var addThoughtToBlankAppMockStore: TestSupport.MockStore {
    let savedRecordID = CKRecord.ID(recordName: mockUUIDs[0].uuidString)
    let savedRecord = CanopyResultRecord(
      mock: .init(
        recordID: savedRecordID,
        recordType: "Thought",
        creationDate: ISO8601DateFormatter().date(from: "2023-03-01T10:00:00Z00:00"),
        modificationDate: ISO8601DateFormatter().date(from: "2023-03-02T10:00:00Z00:00"),
        encryptedValues: [
          "title": "New title",
          "body": "New body"
        ]
      )
    )
        
    return .init(
      mockLocalCacheServiceContent: .init(thoughts: []),
      mockCloudKitServiceContent: .init(
        containerOperationResults: [
          .accountStatus(.init(status: .available, error: nil)),
          .userRecordID(.init(userRecordID: .init(recordName: "blankTestUserRecordName"))),
          .accountStatusStream(.init(statuses: [.available], error: nil))
        ],
        privateDatabaseOperationResults: [
          .modifyZones(
            .init(
              result: .success(
                .init(
                  savedZones: [.init(zoneID: .init(zoneName: "Thoughts", ownerName: CKCurrentUserDefaultName))],
                  deletedZoneIDs: []
                )
              )
            )
          ),
          .modifySubscriptions(
            .init(result: .success(.init(savedSubscriptions: [CKDatabaseSubscription(subscriptionID: "Thoughts")], deletedSubscriptionIDs: [])))
          ),
          .fetchDatabaseChanges(
            .init(result: .success(.empty))
          ),
          .modifyRecords(.init(result: .success(.init(savedRecords: [savedRecord], deletedRecordIDs: []))))          
        ]
      ),
      mockPreferencesServiceContent: .init(cloudKitSetupDone: false, cloudKitUserRecordName: nil),
      mockUUIDServiceContent: .init(uuids: mockUUIDs)
    )
  }
}
