#if DEBUG

  import Canopy
  import CanopyTestTools
  import Foundation

  extension CloudKitService {
    /// A blank service that returns barebones responses.
    ///
    /// Meant to be used in the blank store of the app that’s run by unit tests,
    /// where the app shouldn’t actually talk to any real services.
    static var blank: CloudKitService {
      CloudKitService(
        canopy: MockCanopy(
          mockPrivateDatabase: ReplayingMockCKDatabase(
            operationResults: [
              .fetchDatabaseChanges(.blank)
            ]
          ),
          mockContainer: ReplayingMockCKContainer(
            operationResults: [
            ]
          )
        ),
        preferencesService: TestPreferencesService(
          cloudKitSetupDone: true,
          cloudKitUserRecordName: "testUserRecordName"
        )
      )
    }
  }

#endif
