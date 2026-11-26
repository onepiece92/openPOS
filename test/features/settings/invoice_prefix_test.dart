import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/settings/presentation/widgets/tax_section.dart';

import '../../_support/temp_hive.dart';

/// "IMP" marks CSV-imported orders (never restocked), so the shop's own
/// invoice prefix can't be it.
void main() {
  test('IMP is rejected in any case, after trimming; others are fine', () {
    for (final p in ['IMP', 'imp', ' Imp ']) {
      expect(invoicePrefixError(p), 'IMP is reserved for imported orders.');
    }
    for (final p in ['', 'IMPX', 'SHOP', '2082/83']) {
      expect(invoicePrefixError(p), isNull);
    }
  });

  testWidgets('the dialog shows the reason and will not save IMP',
      (tester) async {
    final settings = await tester.runAsync(openTempSettingsBox);
    final container = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(settings!)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: InvoiceSection())),
    ));
    await tester.tap(find.text('Invoice Prefix'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' imp ');
    await tester.pump();
    expect(find.text('IMP is reserved for imported orders.'), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'SHOP');
    await tester.pump();
    expect(find.text('IMP is reserved for imported orders.'), findsNothing);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(container.read(invoicePrefixProvider), 'SHOP');
  });

  test('setInvoicePrefix itself rejects IMP and writes nothing', () async {
    final box = await openTempSettingsBox();
    final container =
        ProviderContainer(overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(container.dispose);
    final n = container.read(settingsProvider.notifier);
    for (final p in ['IMP', 'imp', ' Imp ']) {
      await expectLater(n.setInvoicePrefix(p), throwsArgumentError);
    }
    expect(container.read(invoicePrefixProvider), isNot('IMP'));
    await n.setInvoicePrefix(' SHOP ');
    expect(container.read(invoicePrefixProvider), 'SHOP');
  });

  testWidgets('a shop already on IMP sees the hint and can Cancel',
      (tester) async {
    final settings = await tester.runAsync(openTempSettingsBox);
    await tester.runAsync(() => settings!.put(kInvoicePrefix, 'IMP'));
    final container = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(settings!)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: InvoiceSection())),
    ));
    await tester.tap(find.text('Invoice Prefix'));
    await tester.pumpAndSettle();
    expect(find.text(kReservedPrefixHint), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(container.read(invoicePrefixProvider), 'IMP');
  });
}
