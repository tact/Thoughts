import CanopyTestTools
import CloudKit
import ThoughtsTypes

extension ThoughtsUITests {
  static var blankAppMockStore: TestSupport.MockStore {
    .init(
      mockLocalCacheServiceContent: .init(thoughts: []),
      mockCloudKitServiceContent: .init(
        containerOperationResults: [
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatus(.init(status: .available, error: nil)),
          .accountStatus(.init(status: .available, error: nil)),
          .userRecordID(.init(userRecordID: .init(recordName: "blankTestUserRecordName")))
        ],
        privateDatabaseOperationResults: [
          .modifyZones(
            .init(
              savedZoneResults: [
                .init(zoneID: .init(zoneName: "Thoughts", ownerName: CKCurrentUserDefaultName), result: .success(.init(zoneID: .init(zoneName: "Thoughts", ownerName: CKCurrentUserDefaultName))))
              ],
              deletedZoneIDResults: [],
              modifyZonesResult: .init(
                result: .success(())
              )
            )
          ),
          .modifySubscriptions(
            .init(
              savedSubscriptionResults: [
                .init(
                  subscriptionID: "Thoughts",
                  result: .success(CKDatabaseSubscription(subscriptionID: "Thoughts"))
                )
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
      ),
      mockPreferencesServiceContent: .init(cloudKitSetupDone: false, cloudKitUserRecordName: nil)
    )
  }
  
  static var withSomeLocalThoughtsMockStore: TestSupport.MockStore {
    .init(
      mockLocalCacheServiceContent: .init(
        thoughts: [
          .init(
            id:  .init(uuidString: "BF69292D-27CE-49C0-84C6-80F93D28A74D")!,
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
          .accountStatus(.init(status: .available, error: nil))
        ],
        privateDatabaseOperationResults: [
          .fetchDatabaseChanges(.blank)
        ]
      ),
      mockPreferencesServiceContent: .init(
        cloudKitSetupDone: true,
        cloudKitUserRecordName: "TestUserRecordName"
      )
    )
  }
  
  static var withSomeLocalAndCloudThoughtsMockStore: TestSupport.MockStore {
    let thoughtID = UUID()
    
    let thoughtRecord = MockCKRecord(recordType: "Thought", recordID: .init(recordName: thoughtID.uuidString))
    thoughtRecord.encryptedValues["title"] = "Title from cloud"
    thoughtRecord.encryptedValues["body"] = "Body from cloud"
    thoughtRecord[MockCKRecord.testingCreatedAtKey] = ISO8601DateFormatter().date(from: "2023-03-01T10:00:00Z00:00")
    thoughtRecord[MockCKRecord.testingModifiedAtKey] = ISO8601DateFormatter().date(from: "2023-03-02T10:00:00Z00:00")

    return .init(
      mockLocalCacheServiceContent: .init(
        thoughts: [
          .init(
            id:  .init(uuidString: "BF69292D-27CE-49C0-84C6-80F93D28A74D")!,
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
          .accountStatus(.init(status: .available, error: nil))
        ],
        privateDatabaseOperationResults: [
          .fetchDatabaseChanges(
            .init(
              changedRecordZoneIDs: [.init(zoneName: "Thoughts")],
              deletedRecordZoneIDs: [],
              purgedRecordZoneIDs: [],
              fetchDatabaseChangesResult: .success
            )
          ),
          .fetchZoneChanges(
            .init(
              recordWasChangedInZoneResults: [
                .init(recordID: .init(recordName: thoughtID.uuidString), result: .success(thoughtRecord))
              ],
              recordWithIDWasDeletedInZoneResults: [],
              oneZoneFetchResults: [.successForZoneID(.init(zoneName: "Thoughts"))],
              fetchZoneChangesResult: .init(
                result: .success(())
              )
            )
          )
        ]
      ),
      mockPreferencesServiceContent: .init(
        cloudKitSetupDone: true,
        cloudKitUserRecordName: "TestUserRecordName"
      )
    )
  }
}
