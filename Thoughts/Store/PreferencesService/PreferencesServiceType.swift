protocol PreferencesServiceType {
  /// User has ran the app previously on this device.
  ///
  /// CloudKit zone and subscription have been set up, no need to set them up again.
  var initialCloudKitSetupDone: Bool { get set }
}
