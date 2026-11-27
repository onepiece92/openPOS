import 'dart:io';

import 'package:sqlite3/sqlite3.dart' show SqliteException;

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

/// SQLite's primary result codes for a damaged file: SQLITE_CORRUPT (11)
/// and SQLITE_NOTADB (26). Extended codes carry the primary one in their
/// low byte (e.g. SQLITE_CORRUPT_VTAB 267 & 0xFF == 11).
const kSqliteCorrupt = 11;
const kSqliteNotADb = 26;

/// The primary SQLite result code behind [error], or null when it is not
/// a SQLite error. An error that crossed drift's background isolate arrives
/// wrapped (its text is the original's), so `SqliteException(N)` in the
/// text counts too.
int? sqlitePrimaryResultCode(Object error) {
  if (error is SqliteException) return error.resultCode;
  final m = RegExp(r'SqliteException\((\d+)\)').firstMatch('$error');
  return m == null ? null : int.parse(m.group(1)!) & 0xFF;
}

/// Whether [error] means the database FILE is gone or damaged — missing or
/// 0 bytes ([DatabaseMissingError]), not a database (26) or corrupt (11) —
/// so that restoring a backup or starting fresh is a sensible offer. Any
/// other failure (locked, busy, I/O, a full disk, a migration bug…) may
/// well be on a healthy file: those get Try again and support only, never
/// an exit that sets the file aside.
bool isDatabaseFileDamaged(Object error) {
  if (error is DatabaseMissingError) return true;
  final code = sqlitePrimaryResultCode(error);
  return code == kSqliteCorrupt || code == kSqliteNotADb;
}
