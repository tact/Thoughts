import Canopy
import Foundation

struct UserDefaultsPreferencesService: PreferencesServiceType {
  private let cloudKitSetupDoneKey = "cloudKitSetupDone"
  private let cloudKitUserRecordNameKey = "cloudKitUserRecordName"
  private let simulateModifyFailureKey = "simulateModifyFailure"
  private let simulateFetchFailureKey = "simulateFetchFailure"
  
  var cloudKitSetupDone: Bool { UserDefaults.standard.bool(forKey: cloudKitSetupDoneKey) }
  
  func setCloudKitSetupDone(_ done: Bool) {
    UserDefaults.standard.set(done, forKey: cloudKitSetupDoneKey)
  }
  
  var cloudKitUserRecordName: String? {
    UserDefaults.standard.object(forKey: cloudKitUserRecordNameKey) as? String ?? nil
  }
  
  func setCloudKitUserRecordName(_ recordName: String?) {
    UserDefaults.standard.set(recordName, forKey: cloudKitUserRecordNameKey)
  }
  
  var simulateModifyFailure: Bool { UserDefaults.standard.bool(forKey: simulateModifyFailureKey) }
  
  func setSimulateModifyFailure(_ simulateModifyFailure: Bool) async {
    UserDefaults.standard.set(simulateModifyFailure, forKey: simulateModifyFailureKey)
  }

  var simulateFetchFailure: Bool { UserDefaults.standard.bool(forKey: simulateFetchFailureKey) }
  
  func setSimulateFetchFailure(_ simulateFetchFailure: Bool) async {
    UserDefaults.standard.set(simulateFetchFailure, forKey: simulateFetchFailureKey)
  }
  
  var canopySettings: CanopySettings {
    .init(
      modifyRecordsBehavior: simulateModifyFailure ? .simulatedFail(1) : .regular(nil),
      fetchDatabaseChangesBehavior: simulateFetchFailure ? .simulatedFail(1) : .regular(nil),
      fetchZoneChangesBehavior: simulateFetchFailure ? .simulatedFail(1) : .regular(nil)
    )
  }

  func clear() {
    UserDefaults.standard.removeObject(forKey: cloudKitSetupDoneKey)
    UserDefaults.standard.removeObject(forKey: cloudKitUserRecordNameKey)
    UserDefaults.standard.removeObject(forKey: simulateModifyFailureKey)
    UserDefaults.standard.removeObject(forKey: simulateFetchFailureKey)
  }
}
