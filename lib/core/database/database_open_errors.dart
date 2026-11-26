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
