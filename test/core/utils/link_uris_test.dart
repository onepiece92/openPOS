import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pos_app/core/utils/link_uris.dart';

/// A receipt sent by SMS or email has to arrive as it was written. Building
/// the link with `Uri(queryParameters:)` turned every space into "+", which
/// mail and message apps show as-is: "Total+due+12.50".
void main() {
  const receipt = 'Chiya Pasal & Sons\n'
      'Bill #12 · 5 Mar 2:30 PM\n'
      '\n'
      'Tea + Biscuit x2 @ 12.50 = 25.00\n'
      'चिया x1 @ 30.00 = 30.00\n'
      'Discount: 10% off\r\n'
      'Total due 49.50\n'
      'Thank you 🙏';

  /// What a mail or message app does with a field: percent-decode it, and
  /// nothing else ("+" stays "+").
  String field(String link, String name) {
    final match = RegExp('[?&]$name=([^&]*)').firstMatch(link);
    expect(match, isNotNull, reason: '$name missing from $link');
    return Uri.decodeComponent(match!.group(1)!);
  }

  void expectSafe(String link) {
    expect(link, isNot(contains(' ')));
    expect(link, isNot(contains('\n')));
    expect(link, isNot(contains('+')),
        reason: 'a "+" in the link is shown as "+", or read as a space');
    expect(link, isNot(contains('#')), reason: '"#" would start a fragment');
    expect(RegExp(r'%(?![0-9A-F]{2})').hasMatch(link), isFalse,
        reason: 'stray "%"');
    expect(link.codeUnits.every((c) => c < 0x80), isTrue,
        reason: 'non-ASCII text must be percent-encoded UTF-8');
    // url_launcher is handed Uri.parse(link); it must not rewrite anything.
    expect(Uri.parse(link).toString(), link);
  }

  group('mailtoLink', () {
    final link = mailtoLink(
      'ram@example.com',
      subject: 'Chiya Pasal & Sons — Receipt #12',
      body: receipt,
    );

    test('the old Uri(queryParameters:) form really did produce "+"', () {
      final old = Uri(
        scheme: 'mailto',
        path: 'ram@example.com',
        queryParameters: {'body': 'Total due 12.50'},
      ).toString();
      expect(old, contains('Total+due+12.50'));
    });

    test('spaces are %20, never "+"', () {
      expectSafe(link);
      expect(link, contains('Total%20due%2049.50'));
    });

    test('line breaks are CRLF', () {
      expect(link, contains('Sons%0D%0ABill'));
      // An existing CRLF is not doubled.
      expect(link, contains('off%0D%0ATotal'));
      expect(link, isNot(contains('%0D%0D')));
      expect(link, isNot(contains('%0A%0A')));
    });

    test('"+", "&", "#" and "%" survive as text', () {
      expect(link, contains('Tea%20%2B%20Biscuit'));
      expect(link, contains('Pasal%20%26%20Sons'));
      expect(link, contains('Bill%20%2312'));
      expect(link, contains('10%25%20off'));
    });

    test('decodes back to the receipt, Devanagari and emoji included', () {
      expect(field(link, 'body'),
          receipt.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n'));
      expect(field(link, 'subject'), 'Chiya Pasal & Sons — Receipt #12');
      expect(link, contains('%E0%A4%9A')); // च
      expect(link, contains('%F0%9F%99%8F')); // 🙏
    });

    test('address keeps its "@"; a "+" tag is encoded', () {
      expect(link, startsWith('mailto:ram@example.com?subject='));
      expect(mailtoLink('ram+shop@example.com'),
          'mailto:ram%2Bshop@example.com');
    });

    test('no subject or body means no query', () {
      expect(mailtoLink('a@b.co'), 'mailto:a@b.co');
      expect(mailtoLink('a@b.co', subject: 'Hi there'),
          'mailto:a@b.co?subject=Hi%20there');
    });
  });

  group('smsLink', () {
    final android = smsLink('+977 980-1234567',
        body: receipt, platform: TargetPlatform.android);
    final ios = smsLink('+977 980-1234567',
        body: receipt, platform: TargetPlatform.iOS);

    test('Android puts the body after "?"', () {
      expect(android, startsWith('sms:+977980-1234567?body='));
    });

    test('iOS and macOS put the body after "&"', () {
      expect(ios, startsWith('sms:+977980-1234567&body='));
      expect(ios, isNot(contains('?')));
      expect(
          smsLink('123', body: 'a b', platform: TargetPlatform.macOS),
          'sms:123&body=a%20b');
    });

    test('follows the running platform when none is given', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(smsLink('123', body: 'a b'), 'sms:123&body=a%20b');
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(smsLink('123', body: 'a b'), 'sms:123?body=a%20b');
      debugDefaultTargetPlatformOverride = null;
    });

    for (final (name, link) in [('android', android), ('ios', ios)]) {
      test('$name: body is percent-encoded with LF line breaks', () {
        // Only the number's leading "+" may appear.
        expectSafe(link.replaceFirst('sms:+', 'sms:'));
        expect(link, contains('Total%20due%2049.50'));
        expect(link, contains('Sons%0ABill'));
        expect(link, isNot(contains('%0D')));
        expect(link, contains('Tea%20%2B%20Biscuit'));
        expect(link, contains('Pasal%20%26%20Sons'));
        expect(link, contains('Bill%20%2312'));
        expect(link, contains('10%25%20off'));
        expect(field(link, 'body'), receipt.replaceAll('\r\n', '\n'));
      });
    }

    test('no body means just the number', () {
      expect(smsLink('9801234567', platform: TargetPlatform.iOS),
          'sms:9801234567');
    });
  });

  group('whatsAppLink', () {
    test('digits only, text percent-encoded with LF line breaks', () {
      expect(whatsAppLink('+977 980-2850777'), 'https://wa.me/9779802850777');
      final link = whatsAppLink('9779802850777', text: 'A & B\n50% #1 +x');
      expect(link,
          'https://wa.me/9779802850777?text=A%20%26%20B%0A50%25%20%231%20%2Bx');
      expect(Uri.parse(link).queryParameters['text'], 'A & B\n50% #1 +x');
    });
  });
}
