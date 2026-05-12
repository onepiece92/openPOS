import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/providers/hive_provider.dart';

/// Controls the app-wide ThemeMode.
/// Reads initial value from Hive; persists changes back to Hive.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(savedThemeModeProvider);

  Future<void> setMode(ThemeMode mode) async {
    final box = ref.read(settingsBoxProvider);
    await saveThemeMode(box, mode);
    state = mode;
  }

  void toggle() {
    setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
