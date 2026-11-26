import 'package:flutter/foundation.dart';

/// True while `AppDatabase`'s `onUpgrade` is migrating an older file to
/// the current schema. Set at the start of the upgrade and cleared when it
/// ends (even on failure), so the launch surface can say "Updating your
/// data…" instead of "Opening Open POS…" — a flag flip, no extra query.
final ValueNotifier<bool> databaseUpgradeRunning = ValueNotifier<bool>(false);
