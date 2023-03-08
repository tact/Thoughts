#if DEBUG
import Canopy
import CloudKit
import CanopyTestTools
import Foundation

extension CloudKitService {
  static var accountAvailable: CloudKitService {
    CloudKitService(
      syncService: MockSyncService(
        mockPrivateDatabase: MockDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: MockCKContainer(
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
      syncService: MockSyncService(
        mockPrivateDatabase: MockDatabase(
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
        mockContainer: MockCKContainer(
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
      syncService: MockSyncService(
        mockPrivateDatabase: MockDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: MockCKContainer(
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
      syncService: MockSyncService(
        mockPrivateDatabase: MockDatabase(
          operationResults: [
            .fetchDatabaseChanges(.blank)
          ],
          scope: .private
        ),
        mockContainer: MockCKContainer(
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
    let record = CKRecord(recordType: "Thought", recordID: .init(recordName: UUID().uuidString))
    record.encryptedValues["title"] = "Thought from cloud"
    record.encryptedValues["body"] = "Thought body from cloud"
    return record
  }
}
#endif
