import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/settings/presentation/widgets/backup_section.dart';

void main() {
  testWidgets('the Backup & Restore row says what it does', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BackupSection())));
    expect(find.text('Backup & Restore'), findsOneWidget);
    expect(
        find.text(
            'Back up everything, restore, or export and import CSV files'),
        findsOneWidget);
    expect(find.textContaining('via CSV'), findsNothing);
  });
}
