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
}
