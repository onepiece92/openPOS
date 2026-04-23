import 'package:drift/native.dart';

import 'package:pos_app/core/database/app_database.dart';

/// Fresh in-memory Drift database for tests.
/// Migrations run automatically via the `schemaVersion` + `onCreate` hooks.
AppDatabase openInMemoryDatabase() =>
    AppDatabase(NativeDatabase.memory(logStatements: false));
