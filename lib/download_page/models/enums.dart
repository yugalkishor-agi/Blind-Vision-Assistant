// download_page/models/enums.dart

// All possible download states for UI state management
enum DownloadStatus {
  notStarted,
  checkingAccess,
  authenticating,
  awaitingLicenseAcceptance,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

// OAuth token validation states
enum TokenStatus { notStored, expired, valid }
