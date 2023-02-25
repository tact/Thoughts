public enum CloudKitAccountState: Codable {
  /// CloudKit account is operational and available.
  case available
  
  /// We haven’t yet checked the state, but optimistically assume it is available.
  ///
  /// This is to avoid UI flickering in the case of “happy path”, where the account indeed
  /// is available but there can be a slight delay at the start of the app while it is checked.
  case provisionalAvailable
  
  /// No or restricted account.
  ///
  /// In a real app, you would distinguish more between the various CloudKit statuses.
  case noAccount
  
  /// Undetermined account state.
  case unknown
}
