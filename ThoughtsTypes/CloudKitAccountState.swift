public enum CloudKitAccountState: Codable {
  /// CloudKit account is operational and available.
  case available
  
  /// We optimistically assume the account is available, after we have previously
  /// initialized the app state.
  ///
  /// This is to avoid UI flickering in the case of “happy path”, where the account indeed
  /// is available but there can be a slight delay at the start of the app while it is checked.
  case provisionalAvailable
  
  /// No or restricted account.
  ///
  /// In a real app, you would distinguish more between the various CloudKit statuses.
  case noAccount
  
  /// Undetermined account state. This is the initial state when the app is first started
  /// on this device.
  case unknown
}
