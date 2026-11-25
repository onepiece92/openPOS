import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/features/help/support_contact.dart';

void main() {
  final opened = <String>[];
  setUp(opened.clear);

  Future<bool> yes(Uri u) async => true;
  Future<bool> no(Uri u) async => false;
  Future<bool> record(Uri u) async {
    opened.add('$u');
    return true;
  }

  Future<bool> throws(Uri u) async =>
      throw PlatformException(code: 'ACTIVITY_NOT_FOUND');

  group('openSupportWhatsApp', () {
    test('the WhatsApp app when it can open', () async {
      expect(await openSupportWhatsApp(canLaunch: yes, launch: record), isTrue);
      expect(opened, ['whatsapp://send?phone=9779802850777']);
    });

    test('wa.me when the app is missing', () async {
      expect(await openSupportWhatsApp(canLaunch: no, launch: record), isTrue);
      expect(opened, ['https://wa.me/9779802850777']);
    });

    test('false, never an exception, when nothing opens', () async {
      expect(await openSupportWhatsApp(canLaunch: no, launch: no), isFalse);
      expect(await openSupportWhatsApp(canLaunch: throws, launch: throws),
          isFalse);
      expect(
          await openSupportWhatsApp(canLaunch: yes, launch: throws), isFalse);
    });
  });

  testWidgets('when nothing opens, a message gives the number', (tester) async {
    expect(kSupportWhatsAppUnavailable,
        "WhatsApp didn't open. Message us on WhatsApp at +977 9802850777.");
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openSupportWhatsAppOrExplain(context,
                canLaunch: throws, launch: no),
            child: const Text('WhatsApp'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text(kSupportWhatsAppUnavailable), findsOneWidget);
  });

  testWidgets('no message when WhatsApp opened', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openSupportWhatsAppOrExplain(context,
                canLaunch: no, launch: yes),
            child: const Text('WhatsApp'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
