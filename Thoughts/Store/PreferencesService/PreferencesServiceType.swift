/// Store user preferences and settings on this device.
///
/// This stores local state of the user, except CloudKit tokens which are managed by
/// Canopy TokenStore.
protocol PreferencesServiceType {
  /// User has ran the app previously on this device.
  ///
  /// CloudKit zone and subscription have been set up, no need to set them up again.
  var cloudKitSetupDone: Bool { get async }
  
  func setCloudKitSetupDone(_ done: Bool) async
  
  /// User record name on CloudKit.
  ///
  /// We can think of it as user ID. It is unique per app and user.
  /// We can request this from CloudKit to understand which CloudKit user we are running as,
  /// and more importantly, to detect any changes and react to that. If the user signs out
  /// with one user on their device, and signs in with another, we should remove all local state,
  /// so one user wouldn’t see the data of another.
  var cloudKitUserRecordName: String? { get async }
  
  func setCloudKitUserRecordName(_ recordName: String?) async
  
  /// Clear the preferences and start from fresh state.
  func clear() async
}

actor TestPreferencesService: PreferencesServiceType {
  var cloudKitSetupDone: Bool
  var cloudKitUserRecordName: String?
  
  init(cloudKitSetupDone: Bool = false, cloudKitUserRecordName: String? = nil) {
    self.cloudKitSetupDone = cloudKitSetupDone
    self.cloudKitUserRecordName = cloudKitUserRecordName
  }
  
  func setCloudKitSetupDone(_ done: Bool) async {
    self.cloudKitSetupDone = done
  }
  
  func setCloudKitUserRecordName(_ recordName: String?) async {
    self.cloudKitUserRecordName = recordName
  }
  
  func clear() {}
}
