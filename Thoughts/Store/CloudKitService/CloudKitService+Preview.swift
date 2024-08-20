#if DEBUG
  import Canopy
  import CanopyTestTools
  import CloudKit
  import Foundation

  extension CloudKitService {
    static var accountAvailable: CloudKitService {
      CloudKitService(
        canopy: MockCanopy(
          container: ReplayingMockContainer(
            operationResults: [
              .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
              .accountStatus(.init(status: .available, error: nil)),
              .accountStatus(.init(status: .available, error: nil)),
              .accountStatus(.init(status: .available, error: nil))
            ]
          ), privateDatabase: ReplayingMockDatabase(
            operationResults: [
              .fetchDatabaseChanges(.blank)
            ]
          )
        ),
        preferencesService: TestPreferencesService(
          cloudKitSetupDone: true,
          cloudKitUserRecordName: "testUserRecordName"
        )
      )
    }
  
    static var populatedWithOneThought: CloudKitService {
      CloudKitService(
        canopy: MockCanopy(
          container: ReplayingMockContainer(
            operationResults: [
              .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
              .accountStatus(.init(status: .available, error: nil)),
              .accountStatus(.init(status: .available, error: nil)),
              .accountStatus(.init(status: .available, error: nil))
            ]
          ), privateDatabase: ReplayingMockDatabase(
            operationResults: [
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
                .init(
                  result: .success(
                    .init(
                      records: [.mock(mockThoughtRecord)],
                      deletedRecords: []
                    )
                  )
                )
              )
            ]
          )
        ),
        preferencesService: TestPreferencesService(cloudKitSetupDone: true, cloudKitUserRecordName: "testUserRecordName")
      )
    }
  
    static var noAccountState: CloudKitService {
      CloudKitService(
        canopy: MockCanopy(
          container: ReplayingMockContainer(
            operationResults: [
              .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
              .accountStatus(.init(status: .noAccount, error: nil)),
              .accountStatus(.init(status: .noAccount, error: nil)),
              .accountStatus(.init(status: .noAccount, error: nil))
            ]
          ), privateDatabase: ReplayingMockDatabase(
            operationResults: [
              .fetchDatabaseChanges(.blank)
            ]
          )
        ),
        preferencesService: TestPreferencesService(
          cloudKitSetupDone: true,
          cloudKitUserRecordName: "testUserRecordName"
        )
      )
    }
  
    static var unknownAccountState: CloudKitService {
      CloudKitService(
        canopy: MockCanopy(
          container: ReplayingMockContainer(
            operationResults: [
              .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
              .accountStatus(.init(status: .couldNotDetermine, error: nil)),
              .accountStatus(.init(status: .couldNotDetermine, error: nil)),
              .accountStatus(.init(status: .couldNotDetermine, error: nil))
            ]
          ), privateDatabase: ReplayingMockDatabase(
            operationResults: [
              .fetchDatabaseChanges(.blank)
            ]
          )
        ),
        preferencesService: TestPreferencesService(
          cloudKitSetupDone: true,
          cloudKitUserRecordName: "testUserRecordName"
        )
      )
    }
  
    private static var mockThoughtRecord: MockCanopyResultRecord {
      MockCanopyResultRecord(
        recordID: .init(recordName: UUID().uuidString),
        recordType: "Thought",
        creationDate: ISO8601DateFormatter().date(from: "2023-03-08T10:25:00Z00:00"),
        modificationDate: ISO8601DateFormatter().date(from: "2023-03-08T10:26:00Z00:00"),
        encryptedValues: [
          "title": "Thought from cloud",
          "body": "Thought body from cloud"
        ]
      )
    }
  }
#endif
