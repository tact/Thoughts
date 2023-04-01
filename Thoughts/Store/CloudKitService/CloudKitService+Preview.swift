#if DEBUG
import Canopy
import CloudKit
import CanopyTestTools
import Foundation

extension CloudKitService {
  static var accountAvailable: CloudKitService {
    CloudKitService(
      canopy: MockCanopy(
        mockPrivateDatabase: ReplayingMockCKDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: ReplayingMockCKContainer(
          operationResults: [
            .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
            .accountStatus(.init(status: .available, error: nil)),
            .accountStatus(.init(status: .available, error: nil)),
            .accountStatus(.init(status: .available, error: nil))
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
        mockPrivateDatabase: ReplayingMockCKDatabase(
          operationResults: [
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
                  .init(
                    recordID: .init(recordName: "recordID"),
                    result: .success(mockThoughtRecord))
                ],
                recordWithIDWasDeletedInZoneResults: [],
                oneZoneFetchResults: [.successForZoneID(.init(zoneName: "Thoughts"))],
                fetchZoneChangesResult: .init(
                  result: .success(())
                )
              )
            )
          ],
          scope: .private
        ),
        mockContainer: ReplayingMockCKContainer(
          operationResults: [
            .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
            .accountStatus(.init(status: .available, error: nil)),
            .accountStatus(.init(status: .available, error: nil)),
            .accountStatus(.init(status: .available, error: nil))
          ]
        )
      ),
      preferencesService: TestPreferencesService(cloudKitSetupDone: true, cloudKitUserRecordName: "testUserRecordName")
    )
  }
  
  static var noAccountState: CloudKitService {
    CloudKitService(
      canopy: MockCanopy(
        mockPrivateDatabase: ReplayingMockCKDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: ReplayingMockCKContainer(
          operationResults: [
            .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
            .accountStatus(.init(status: .noAccount, error: nil)),
            .accountStatus(.init(status: .noAccount, error: nil)),
            .accountStatus(.init(status: .noAccount, error: nil))
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
        mockPrivateDatabase: ReplayingMockCKDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: ReplayingMockCKContainer(
          operationResults: [
            .userRecordID(.init(userRecordID: .init(recordName: "testUserRecordName"))),
            .accountStatus(.init(status: .couldNotDetermine, error: nil)),
            .accountStatus(.init(status: .couldNotDetermine, error: nil)),
            .accountStatus(.init(status: .couldNotDetermine, error: nil))
          ]
        )
      ),
      preferencesService: TestPreferencesService(
        cloudKitSetupDone: true,
        cloudKitUserRecordName: "testUserRecordName"
      )
    )
  }
  
  private static var mockThoughtRecord: CKRecord {
    let record = MockCKRecord(recordType: "Thought", recordID: .init(recordName: UUID().uuidString))
    record.encryptedValues["title"] = "Thought from cloud"
    record.encryptedValues["body"] = "Thought body from cloud"
    record[MockCKRecord.testingCreatedAtKey] = ISO8601DateFormatter().date(from: "2023-03-08T10:25:00Z00:00")
    record[MockCKRecord.testingModifiedAtKey] = ISO8601DateFormatter().date(from: "2023-03-08T10:26:00Z00:00")
    return record
  }
}
#endif
