import Foundation

struct UserDefaultsPreferencesService: PreferencesServiceType {
  
  private let cloudKitSetupDoneKey = "cloudKitSetupDone"
  private let cloudKitUserRecordNameKey = "cloudKitUserRecordName"
  
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
  
  func clear() {
    UserDefaults.standard.removeObject(forKey: cloudKitSetupDoneKey)
    UserDefaults.standard.removeObject(forKey: cloudKitUserRecordNameKey)
  }
}
