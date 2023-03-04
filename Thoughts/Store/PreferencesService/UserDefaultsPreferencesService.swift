import Foundation

struct UserDefaultsPreferencesService: PreferencesServiceType {
  
  private let cloudKitSetupDoneKey = "cloudKitSetupDone"
  private let cloudKitUserRecordNameKey = "cloudKitUserRecordName"
  
  var cloudKitSetupDone: Bool {
    get {
      UserDefaults.standard.bool(forKey: cloudKitSetupDoneKey)
    }
    set {
      UserDefaults.standard.set(newValue, forKey: cloudKitSetupDoneKey)
    }
  }
  
  var cloudKitUserRecordName: String? {
    get {
      UserDefaults.standard.object(forKey: cloudKitUserRecordNameKey) as? String ?? nil
    }
    set {
      UserDefaults.standard.set(newValue, forKey: cloudKitUserRecordNameKey)
    }
  }
  
  func clear() {
    UserDefaults.standard.removeObject(forKey: cloudKitSetupDoneKey)
    UserDefaults.standard.removeObject(forKey: cloudKitUserRecordNameKey)
  }
}
