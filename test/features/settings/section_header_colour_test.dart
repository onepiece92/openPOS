import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/settings/presentation/widgets/settings_section_header.dart';

void main() {
  for (final (mode, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('settings section header is muted grey, not orange ($mode)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(body: SettingsSectionHeader('Currency')),
      ));
      final style = tester.widget<Text>(find.text('CURRENCY')).style!;
      expect(style.color, theme.colorScheme.onSurfaceVariant);
      expect(style.color, isNot(theme.colorScheme.primary));
    });
  }
}
