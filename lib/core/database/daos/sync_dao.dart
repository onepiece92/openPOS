import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/outbox_queue_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [OutboxQueue])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Stream<int> watchPendingCount() {
    final query = customSelect(
      "SELECT COUNT(*) as cnt FROM outbox_queue WHERE status = 'pending'",
      readsFrom: {outboxQueue},
    );
    return query.watchSingle().map((row) => row.read<int>('cnt'));
  }

  Future<List<OutboxQueueData>> getPending() =>
      (select(outboxQueue)
            ..where((q) => q.status.equals('pending'))
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .get();

  Future<int> enqueue(OutboxQueueCompanion entry) =>
      into(outboxQueue).insert(entry);

  Future<void> markSent(int id) async {
    await (update(outboxQueue)..where((q) => q.id.equals(id)))
        .write(const OutboxQueueCompanion(status: Value('sent')));
  }

  Future<void> markFailed(int id) async {
    await (update(outboxQueue)..where((q) => q.id.equals(id))).write(
      OutboxQueueCompanion(
        status: const Value('failed'),
        lastAttemptAt: Value(DateTime.now()),
        retryCount: Value(
          (await (select(outboxQueue)..where((q) => q.id.equals(id)))
                  .getSingle())
              .retryCount +
              1,
        ),
      ),
    );
  }

  Future<void> clearSent() async {
    await (delete(outboxQueue)
          ..where((q) => q.status.equals('sent')))
        .go();
  }
}
