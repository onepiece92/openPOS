import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/tips/tips_section.dart';
import 'package:pos_app/features/tips/tips_settings.dart';

void main() {
  late Directory tmp;
  late Box<dynamic> box;
  late ProviderContainer c;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pos_tipset_');
    Hive.init(tmp.path);
    box = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    c = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
  });

  tearDown(() async {
    c.dispose();
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  Future<void> pump(WidgetTester tester) =>
      tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: Scaffold(body: TipsSection()))));

  testWidgets('percentages and the tip base are editable', (tester) async {
    await pump(tester);
    expect(c.read(tipsSettingsProvider).presets, [15, 18, 20]);
    expect(find.text('15%, 18%, 20%'), findsOneWidget);
    expect(find.text('Accept tips'), findsNothing);

    await tester.tap(find.text('Tip on total after tax'));
    await tester.pump();
    expect(c.read(tipsSettingsProvider).postTax, isTrue);
  });

  test('Tips follows the Features switch: off by default, and the old '
      'tips_enabled key is ignored', () async {
    expect(c.read(tipsEnabledProvider), isFalse);
    await box.put('tips_enabled', true);
    final c2 = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(c2.dispose);
    expect(c2.read(tipsEnabledProvider), isFalse);
    await box.put(kFeaturesKey, {'tips': true});
    final c3 = ProviderContainer(
        overrides: [settingsBoxProvider.overrideWithValue(box)]);
    addTearDown(c3.dispose);
    expect(c3.read(tipsEnabledProvider), isTrue);
  });

  testWidgets('presets are validated, then saved', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Tip percentages'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '10, 120');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('at most 100'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1 2 3 4 5');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('At most 4'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '10, 12.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(c.read(tipsSettingsProvider).presets, [10, 12.5]);
    expect(box.get(kTipPresets), [10.0, 12.5]);
    expect(find.text('10%, 12.5%'), findsOneWidget);
  });
}
