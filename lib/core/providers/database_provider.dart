import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';

/// Singleton database instance. Overridden in main() so the same
/// AppDatabase is shared across the entire app.
/// Also overridable in tests: ProviderScope(overrides: [databaseProvider.overrideWithValue(testDb)])
final databaseProvider = Provider<AppDatabase>((ref) {
  throw StateError(
    'databaseProvider must be overridden in ProviderScope before use.',
  );
});
