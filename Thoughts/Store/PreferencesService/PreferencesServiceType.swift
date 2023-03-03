/// Store user preferences and settings on this device.
///
/// This stores local state of the user, except CloudKit tokens which are managed by
/// Canopy TokenStore.
protocol PreferencesServiceType {
  /// User has ran the app previously on this device.
  ///
  /// CloudKit zone and subscription have been set up, no need to set them up again.
  var initialCloudKitSetupDone: Bool { get set }
  
  /// User record name on CloudKit.
  ///
  /// We can think of it as user ID. It is unique per app and user.
  /// We can request this from CloudKit to understand which CloudKit user we are running as,
  /// and more importantly, to detect any changes and react to that. If the user signs out
  /// with one user on their device, and signs in with another, we should remove all local state,
  /// so one user wouldn’t see the data of another.
  var cloudKitUserRecordName: String { get set }
}
