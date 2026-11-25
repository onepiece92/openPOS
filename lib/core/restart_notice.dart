import 'package:flutter/foundation.dart';

/// True while `AppRoot` shows a restart notice (after a restore or a
/// recovery) over the app. That notice sits where SnackBars appear, so the
/// usage disclosure waits until it is gone.
///
/// Top-level (not a provider) because the notice lives above the provider
/// container that a restore replaces.
final restartNoticeShowing = ValueNotifier<bool>(false);
