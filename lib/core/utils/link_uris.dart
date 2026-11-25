import 'package:flutter/foundation.dart';

/// Builders for the `mailto:` and `sms:` links handed to other apps.
///
/// Do not build these with `Uri(queryParameters: ...)`: that form-encodes a
/// space as "+", and mail and message apps do not turn "+" back into a space
/// for these schemes, so a receipt arrives as "Total+due+12.50". Here every
/// value is percent-encoded instead: a space is %20, a literal "+" is %2B,
/// and "&", "#" and "%" cannot cut the text short.

final _lineBreak = RegExp(r'\r\n|\r|\n');

String _encode(String value, {required String lineBreak}) =>
    Uri.encodeComponent(value.replaceAll(_lineBreak, lineBreak));

/// A `mailto:` link (RFC 6068). Line breaks in [subject] and [body] are sent
/// as CRLF (%0D%0A), which is what the scheme specifies.
String mailtoLink(String address, {String? subject, String? body}) {
  // "@" separates the mailbox from the domain and must stay readable; a "+"
  // in the address (name+tag@example.com) stays encoded as %2B.
  final to = Uri.encodeComponent(address.trim()).replaceAll('%40', '@');
  final query = [
    if (subject != null && subject.isNotEmpty)
      'subject=${_encode(subject, lineBreak: '\r\n')}',
    if (body != null && body.isNotEmpty)
      'body=${_encode(body, lineBreak: '\r\n')}',
  ].join('&');
  return query.isEmpty ? 'mailto:$to' : 'mailto:$to?$query';
}

/// An `sms:` link with the message text filled in.
///
/// Android follows RFC 5724: `sms:<number>?body=<text>`. Apple's Messages
/// has never documented a body field and is known to drop the text (or
/// treat it as part of the number) when it follows "?", while
/// `sms:<number>&body=<text>` has worked since iOS 8, so Apple platforms get
/// the "&" form. Line breaks are sent as a bare LF (%0A).
String smsLink(String phone, {String? body, TargetPlatform? platform}) {
  final target = platform ?? defaultTargetPlatform;
  final apple =
      target == TargetPlatform.iOS || target == TargetPlatform.macOS;
  // The leading "+" of an international number is literal in the path of
  // an sms: link; spaces typed for readability are dropped.
  final to = Uri.encodeComponent(phone.replaceAll(RegExp(r'\s'), ''))
      .replaceAll('%2B', '+');
  if (body == null || body.isEmpty) return 'sms:$to';
  return 'sms:$to${apple ? '&' : '?'}body=${_encode(body, lineBreak: '\n')}';
}
