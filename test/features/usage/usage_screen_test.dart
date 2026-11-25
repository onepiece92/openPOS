import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart' show XFile;

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/link_uris.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/data/usage_inputs.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/domain/usage_summary.dart';
import 'package:pos_app/features/usage/presentation/usage_screen.dart';
import 'package:pos_app/features/usage/usage_constants.dart';
import 'package:pos_app/features/usage/usage_providers.dart';

import '../../_support/test_db.dart';
import '_grammar.dart';

class _Shared {
  _Shared(this.files, this.subject);
  final List<XFile> files;
  final String? subject;
}

void main() {
  late AppDatabase db;
  late Box<dynamic> settings;
  late Box<dynamic> usageBox;
  late UsageCounter counter;
  late List<Uri> launched;
  late List<_Shared> shared;
  late Directory tmp;
  late bool Function() launchBehaviour;

  setUp(() async {
    Hive.init('.');
    // Memory-backed: file writes inside the fake clock never finish.
    settings = await Hive.openBox<dynamic>('settings', bytes: Uint8List(0));
    usageBox = await Hive.openBox<dynamic>(kUsageBoxName, bytes: Uint8List(0));
    await settings.put(kCurrencyCode, 'USD');
    db = openInMemoryDatabase();
    counter = UsageCounter(openBox: () async => usageBox);
    await counter.ensureLoaded();
    counter
      ..record(UsageEvent.saleCompleted)
      ..record(UsageEvent.saleCompleted)
      ..record(UsageEvent.reportViewed);
    launched = [];
    shared = [];
    tmp = Directory.systemTemp.createTempSync('pos_usage_share_');
    launchBehaviour = () => true;
  });
  tearDown(() async {
    await db.close();
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsBoxProvider.overrideWithValue(settings),
        usageCounterProvider.overrideWithValue(counter),
        linkLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return launchBehaviour();
        }),
        usageTempDirProvider.overrideWithValue(() async => tmp),
        shareFilesProvider.overrideWithValue((files,
            {String? subject,
            String? text,
            required Rect sharePositionOrigin}) async {
          shared.add(_Shared(files, subject));
        }),
      ],
      child: const MaterialApp(home: UsageScreen()),
    ));
    await tester.pumpAndSettle();
  }

  /// What buildUsageSummary gives for [s] and [message] with this test's
  /// inputs (empty database → every shop count is 0).
  String expected(UsageSelection s, String message) => buildUsageSummary(
        selection: s,
        message: message,
        counts: counter.counts,
        env: currentUsageEnvironment(currencyCode: 'USD'),
        shop:
            const ShopSizeCounts(products: 0, ordersLast7Days: 0, customers: 0),
      );

  String preview(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('usage-preview'))).data!;

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String key) =>
      tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).enabled;

  testWidgets('shows the instruction, the offline-first line and the question',
      (tester) async {
    await pump(tester);
    expect(find.text(kUsageScreenTitle), findsOneWidget);
    expect(find.text(kFeedbackInstruction), findsOneWidget);
    expect(find.text(kOfflineFirstLine), findsOneWidget);
    expect(find.text(kFeedbackAreaQuestion), findsOneWidget);
    // UI only: never in what is sent.
    expect(preview(tester), isNot(contains('offline')));
  });

  testWidgets('nothing ticked by default; Send needs a message or data',
      (tester) async {
    await pump(tester);
    expect(preview(tester), kUsageSummaryHeader);
    expect(enabled(tester, 'send-whatsapp'), isFalse);
    expect(enabled(tester, 'send-email'), isFalse);
    await tester.enterText(
        find.byKey(const ValueKey('feedback-message')), 'Add tips');
    await tester.pumpAndSettle();
    expect(enabled(tester, 'send-whatsapp'), isTrue);
    expect(enabled(tester, 'send-email'), isTrue);
  });

  testWidgets('live preview is exactly buildUsageSummary for the selection',
      (tester) async {
    await pump(tester);
    await tap(tester, 'pick-reports');
    var s = const UsageSelection().togglePicked(FeatureArea.reports);
    expect(find.text(expected(s, '')), findsOneWidget);
    expect(preview(tester), contains('- reportViewed: 1'));
    expect(preview(tester), isNot(contains('saleCompleted')));

    await tap(tester, 'tick-app-info');
    await tap(tester, 'tick-shop-size');
    await tap(tester, 'tick-selling');
    s = s.withAppInfo(true).withShopSize(true).toggleArea(FeatureArea.selling);
    await tester.enterText(
        find.byKey(const ValueKey('feedback-message')), 'Need split bills');
    await tester.pumpAndSettle();
    final text = expected(s, 'Need split bills');
    expect(find.text(text), findsOneWidget);
    expect(preview(tester), text);
    expectGrammar(text);

    // Un-ticking a group removes it from the preview at once.
    await tap(tester, 'tick-reports');
    expect(preview(tester), isNot(contains('reportViewed')));
  });

  testWidgets('WhatsApp gets exactly the previewed text', (tester) async {
    await pump(tester);
    await tap(tester, 'pick-selling');
    await tester.enterText(find.byKey(const ValueKey('feedback-message')),
        'Line one\nA & B #1 50%');
    await tester.pumpAndSettle();
    final text = preview(tester);
    await tap(tester, 'send-whatsapp');
    expect(shared, isEmpty);
    expect(launched, hasLength(1));
    expect(launched.single.toString(),
        whatsAppLink(kUsageWhatsAppNumber, text: text));
    expect(launched.single.host, 'wa.me');
    expect(launched.single.path, '/$kUsageWhatsAppNumber');
    expect(launched.single.queryParameters['text'], text);
  });

  testWidgets('pure feedback (message, no data) can be sent', (tester) async {
    await pump(tester);
    await tester.enterText(
        find.byKey(const ValueKey('feedback-message')), 'Love it');
    await tester.pumpAndSettle();
    await tap(tester, 'send-whatsapp');
    expect(launched.single.queryParameters['text'],
        '$kUsageSummaryHeader\nMessage:\nLove it');
  });

  testWidgets('data and no message can be sent', (tester) async {
    await pump(tester);
    await tap(tester, 'tick-shop-size');
    await tap(tester, 'send-email');
    final uri = launched.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, kUsageEmailAddress);
    expect(uri.queryParameters['subject'], kUsageEmailSubject);
    // mailto sends line breaks as CRLF (RFC 6068); the text is otherwise
    // byte-identical to the preview.
    expect(
        uri.queryParameters['body']!.replaceAll('\r\n', '\n'), preview(tester));
    expect(
        preview(tester),
        contains(
            'Shop size: products 0, orders in last 7 days 0, customers 0'));
  });

  testWidgets(
      'a wa.me link over 2000 characters goes to the share sheet as .txt',
      (tester) async {
    await pump(tester);
    for (final a in FeatureArea.values) {
      await tap(tester, 'pick-${a.name}');
    }
    await tap(tester, 'tick-app-info');
    await tester.enterText(find.byKey(const ValueKey('feedback-message')),
        'word ' * 200); // over the cap on purpose
    await tester.pumpAndSettle();
    final text = preview(tester);
    expect(whatsAppLink(kUsageWhatsAppNumber, text: text).length,
        greaterThan(kWhatsAppMaxUrlLength));
    await tap(tester, 'send-whatsapp');
    expect(launched, isEmpty);
    expect(shared, hasLength(1));
    final f = shared.single.files.single;
    expect(f.name, kUsageSummaryFileName);
    expect(f.mimeType, 'text/plain');
    expect(File(f.path).readAsStringSync(), text);
  });

  testWidgets('the message box is capped at 500 characters with a counter',
      (tester) async {
    await pump(tester);
    await tester.enterText(
        find.byKey(const ValueKey('feedback-message')), 'y' * 650);
    await tester.pumpAndSettle();
    expect(find.text('500/500'), findsOneWidget);
    expect(splitSummary(preview(tester)).message, 'y' * 500);
  });

  testWidgets('"Stop counting" is honoured at once; Reset asks first',
      (tester) async {
    await pump(tester);
    await tap(tester, 'stop-counting');
    expect(counter.countingEnabled, isFalse);
    expect(usageBox.get(kUsageCountingOnKey), isFalse);
    counter.record(UsageEvent.saleCompleted);
    expect(counter.counts[UsageEvent.saleCompleted]!.count, 2);

    await tap(tester, 'reset-usage');
    expect(find.text('Reset usage counts?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(counter.counts, isNotEmpty);
    await tap(tester, 'reset-usage');
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(counter.counts, isEmpty);
    expect(readUsageCounts(usageBox), isEmpty);
  });

  for (final (label, behaviour) in <(String, bool Function())>[
    ('returns false', () => false),
    ('throws PlatformException',
        () => throw PlatformException(code: 'ACTIVITY_NOT_FOUND')),
  ]) {
    testWidgets('when WhatsApp $label: copied, and the number is shown',
        (tester) async {
      final clip = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clip.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      launchBehaviour = behaviour;
      await pump(tester);
      await tester.enterText(
          find.byKey(const ValueKey('feedback-message')), 'Hello');
      await tester.pumpAndSettle();
      await tap(tester, 'send-whatsapp');
      expect(find.text(kUsageWhatsAppUnavailable), findsOneWidget);
      expect(kUsageWhatsAppUnavailable, contains('+977 9802850777'));
      expect(clip, [preview(tester)]);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      await tap(tester, 'send-email');
      expect(find.text(kUsageEmailUnavailable), findsOneWidget);
      expect(kUsageEmailUnavailable, contains(kUsageEmailAddress));
    });
  }
}
