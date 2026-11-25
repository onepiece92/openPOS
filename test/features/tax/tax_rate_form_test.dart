import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/tax/presentation/tax_settings_screen.dart';

import '../../_support/test_db.dart';

/// Opening a tax rate and saving it untouched must not change it. The form
/// used to pre-fill the rate rounded to two decimals, so 8.875 % came back
/// as 8.88 %.
void main() {
  late AppDatabase db;
  setUp(() => db = openInMemoryDatabase());
  tearDown(() => db.close());

  Future<TaxRate> create(double percent) async {
    final id = await db.taxDao.upsertRate(TaxRatesCompanion.insert(
        name: 'Sales Tax',
        rate: percent / 100,
        inclusionType: const Value('inclusive')));
    return (await db.taxDao.getById(id))!;
  }

  Future<void> pumpForm(WidgetTester tester, TaxRate existing) =>
      tester.pumpWidget(ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: TaxRateForm(existing: existing)),
          ),
        ),
      ));

  String rateField(WidgetTester tester) => tester
      .widget<TextFormField>(find.widgetWithText(TextFormField, 'Rate (%)'))
      .controller!
      .text;

  for (final (percent, shown) in [
    (8.875, '8.875'),
    (13.0, '13'),
    (12.5, '12.5'),
    (8.25, '8.25'),
  ]) {
    testWidgets('$percent % is pre-filled as "$shown" and survives a save',
        (tester) async {
      final existing = await tester.runAsync(() => create(percent));
      await pumpForm(tester, existing!);
      expect(rateField(tester), shown);

      await tester.runAsync(() async {
        await tester.tap(find.byType(FilledButton));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final after = await tester.runAsync(() => db.taxDao.getById(existing.id));
      expect(after!.rate, closeTo(percent / 100, 1e-12));
      expect(after.inclusionType, 'inclusive');
    });
  }
}
