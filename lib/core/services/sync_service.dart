import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/tables/outbox_queue_table.dart';
import '../providers/connectivity_provider.dart';
import '../providers/database_provider.dart';

/// Processes the outbox queue when the device comes back online.
/// Called by workmanager and also reactively when connectivity is restored.
class SyncService {
  const SyncService(this._db);

  final AppDatabase _db;

  /// Attempt to send all pending outbox entries.
  /// On success each entry is marked 'sent'.
  /// On failure retry_count is incremented and entry remains 'pending'.
  Future<void> processOutbox() async {
    final pending = await _db.syncDao.getPending();
    for (final item in pending) {
      try {
        await _sendEntry(item);
        await _db.syncDao.markSent(item.id);
      } catch (_) {
        await _db.syncDao.markFailed(item.id);
      }
    }
    await _db.syncDao.clearSent();
  }

  Future<void> enqueue({
    required String endpoint,
    required Map<String, Object?> payload,
  }) async {
    await _db.syncDao.enqueue(
      OutboxQueueCompanion.insert(
        endpoint: endpoint,
        payload: jsonEncode(payload),
      ),
    );
  }

  Future<void> _sendEntry(OutboxQueueData item) async {
    // TODO: implement actual HTTP call (Supabase / REST endpoint)
    // Example: await supabase.rpc(item.endpoint, params: jsonDecode(item.payload));
    throw UnimplementedError('HTTP sync not yet implemented');
  }
}

// ── Riverpod provider ─────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final svc = SyncService(db);

  // Auto-sync when connectivity is restored
  ref.listen<bool>(isOnlineProvider, (prev, next) {
    if (next && prev == false) svc.processOutbox();
  });

  return svc;
});
