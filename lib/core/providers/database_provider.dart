import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';

/// App-wide database instance. Owned by the ProviderContainer: created on
/// first read, closed when the container is disposed (see `AppRoot`, which
/// swaps containers to hot-restart after a backup restore).
///
/// Tests override it:
/// `ProviderScope(overrides: [databaseProvider.overrideWithValue(testDb)])`
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
