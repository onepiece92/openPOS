import 'package:drift/drift.dart';

/// Outbox pattern: failed API calls queued here for background retry.
/// workmanager processes this table and clears rows on success.
///
/// status: 'pending' | 'failed' | 'sent'
class OutboxQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get endpoint => text()(); // e.g. '/payments/sync'
  TextColumn get payload => text()(); // JSON body
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}
