import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/support_contact.dart';

void main() {
  Future<bool> no(Uri u) async => false;
  Future<bool> throws(Uri u) async =>
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND');

  group('openSupportMail', () {
    test('builds the mailto, with and without a subject', () async {
      final seen = <String>[];
      Future<bool> record(Uri u) async {
        seen.add('$u');
        return true;
      }

      expect(await openSupportMail(launch: record), isTrue);
      expect(await openSupportMail(subject: 'Open POS Bug', launch: record),
          isTrue);
      expect(seen, [
        'mailto:support@rebuzzpos.com',
        'mailto:support@rebuzzpos.com?subject=Open%20POS%20Bug',
      ]);
    });

    test('false, never an exception, when nothing opens', () async {
      expect(await openSupportMail(launch: no), isFalse);
      expect(await openSupportMail(launch: throws), isFalse);
    });
  });

  testWidgets('no mail app: a message gives the address', (tester) async {
    expect(kSupportMailUnavailable,
        'No mail app opened. Email us at support@rebuzzpos.com.');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openSupportMailOrExplain(context, launch: throws),
            child: const Text('Mail'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Mail'));
    await tester.pumpAndSettle();
    expect(find.text(kSupportMailUnavailable), findsOneWidget);
  });

  Future<void> pumpSite(
      WidgetTester tester, Future<bool> Function(Uri) launch) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openRebuzzSiteOrExplain(context, launch: launch),
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  testWidgets('site opens: right url, no message', (tester) async {
    final seen = <String>[];
    await pumpSite(tester, (u) async {
      seen.add('$u');
      return true;
    });
    expect(seen, ['https://rebuzzpos.com']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('site fails (false): SnackBar', (tester) async {
    await pumpSite(tester, no);
    expect(find.text(kSiteUnavailable), findsOneWidget);
    expect(kSiteUnavailable, "Couldn't open the browser. Visit rebuzzpos.com.");
  });

  testWidgets('site fails (PlatformException): SnackBar', (tester) async {
    await pumpSite(tester, throws);
    expect(find.text(kSiteUnavailable), findsOneWidget);
  });
}
