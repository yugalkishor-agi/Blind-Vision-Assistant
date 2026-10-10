
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


enum TokenStatus { notStored, expired, valid }
