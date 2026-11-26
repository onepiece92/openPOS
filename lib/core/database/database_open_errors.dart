import 'dart:io';

/// Thrown by the migration when the file on disk was written by a newer
/// app (its schema version is above ours). A [StateError] so existing
/// handlers still see it as one.
class DatabaseTooNewError extends StateError {
  DatabaseTooNewError(this.fileVersion, this.appVersion)
      : super('Database schema v$fileVersion is newer than this app '
            '(v$appVersion). Update the app.');

  final int fileVersion;
  final int appVersion;
}

/// Shown when the data was saved by a newer app. No retry: nothing this
/// version can do will open it, and nothing destructive is offered.
const kDataTooNewTitle = 'Update Open POS';
const kDataTooNewMessage =
    'This data was saved by a newer version of Open POS. '
    'Update the app to open it.';

/// Shown for any other failure to open the database.
const kDataOpenFailedTitle = 'Something went wrong';
const kDataOpenFailedMessage = "Open POS couldn't open its data.";

/// Whether [error] (as thrown by the first database query) means the file
/// is from a newer app. The text check covers an error that crossed an
/// isolate and lost its type.
bool isDatabaseTooNew(Object error) =>
    error is DatabaseTooNewError ||
    error.toString().contains('is newer than this app');

/// The database file is missing or empty although onboarding was finished:
/// the shop's data is gone from where it should be (deleted, a failed
/// copy, storage trouble). Opening would silently create an empty database
/// under the old settings, so the app goes to the error screen instead
/// ("Open POS couldn't open its data.", Try again and WhatsApp).
class DatabaseMissingError extends StateError {
  DatabaseMissingError(String path)
      : super('The database file is missing or empty: $path');
}

/// Throws [DatabaseMissingError] when [onboardingComplete] and [file] is
/// missing or 0 bytes. Run before the open: one exists check and, when it
/// exists, one length — no SQLite involved. A genuinely fresh install
/// (onboarding not complete) passes and Drift creates the database.
Future<void> assertDatabaseFilePresent({
  required bool onboardingComplete,
  required File file,
}) async {
  if (!onboardingComplete) return;
  if (!await file.exists() || await file.length() == 0) {
    throw DatabaseMissingError(file.path);
  }
}
