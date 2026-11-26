import 'package:drift/drift.dart' show CouldNotRollBackException;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqliteException;

/// SQLITE_CONSTRAINT_FOREIGNKEY: a row points at one that does not exist.
const kSqliteForeignKeyFailure = 787;

/// Whether [error] is a failed foreign-key check, also when it was thrown
/// in the database's background isolate and arrives wrapped.
bool isForeignKeyFailure(Object error) {
  Object? e = error;
  for (var depth = 0; e != null && depth < 4; depth++) {
    if (e is SqliteException) {
      return e.extendedResultCode == kSqliteForeignKeyFailure ||
          e.message.contains('FOREIGN KEY constraint failed');
    }
    e = switch (e) {
      DriftRemoteException(:final remoteCause) => remoteCause,
      CouldNotRollBackException(:final cause) => cause,
      _ => null,
    };
  }
  return error.toString().contains('FOREIGN KEY constraint failed');
}

/// Payment: the sale points at a product, customer or table that is gone.
const kSaleForeignKeyMessage = 'Some items or the customer on this sale no '
    'longer exist. Remove them and try again.';

/// Payment: any other failure to save the sale (never the raw error).
const kSaleFailedMessage = "The sale couldn't be saved. Please try again.";

/// What payment shows when saving the sale threw [error]. `placeOrder`'s
/// own refusals (an [ArgumentError] such as a tip far past the cap) are
/// already written for people and are shown as they are.
String saleFailureMessage(Object error) {
  if (isForeignKeyFailure(error)) return kSaleForeignKeyMessage;
  if (error is ArgumentError && error.message is String) {
    return error.message as String;
  }
  return kSaleFailedMessage;
}

/// The support log line for a failed sale. Debug: the full error and the
/// stack. Release: only the exception type and, for a SQLite error, its
/// short message ("FOREIGN KEY constraint failed"): the full text of a
/// database error carries the SQL and its bound values (customer, amounts).
String saleFailureLog(Object error, StackTrace stack,
    {required bool release}) {
  if (!release) return 'Sale failed: $error\n$stack';
  final short = error is SqliteException ? ': ${error.message}' : '';
  return 'Sale failed: ${error.runtimeType}$short';
}
