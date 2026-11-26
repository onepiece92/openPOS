import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support's WhatsApp number, as shown to people.
const kSupportWhatsAppDisplay = '+977 9802850777';
const _kSupportWhatsAppDigits = '9779802850777';

/// Shown when nothing could open the WhatsApp chat.
const kSupportWhatsAppUnavailable =
    "WhatsApp didn't open. Message us on WhatsApp at $kSupportWhatsAppDisplay.";

/// How long the "didn't open" messages stay up.
const kLinkFailureMessageDuration = Duration(seconds: 8);

typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> _canLaunch(Uri u) => canLaunchUrl(u);
Future<bool> _launch(Uri u) =>
    launchUrl(u, mode: LaunchMode.externalApplication);

/// Opens a WhatsApp chat with support: the WhatsApp app if installed,
/// otherwise wa.me in the browser. A user-initiated hand-off to another
/// app; this app itself makes no network call.
///
/// Returns whether anything opened. Never throws: `launchUrl` returning
/// false and a `PlatformException` (no handler at all) both give false.
Future<bool> openSupportWhatsApp({
  UrlOpener canLaunch = _canLaunch,
  UrlOpener launch = _launch,
}) async {
  final native = Uri.parse('whatsapp://send?phone=$_kSupportWhatsAppDigits');
  final web = Uri.parse('https://wa.me/$_kSupportWhatsAppDigits');
  try {
    if (await canLaunch(native) && await launch(native)) return true;
  } catch (_) {/* fall back to wa.me */}
  try {
    return await launch(web);
  } catch (_) {
    return false;
  }
}

/// [openSupportWhatsApp], and when nothing opens, a short message with the
/// number so the shopkeeper can still reach us.
Future<void> openSupportWhatsAppOrExplain(
  BuildContext context, {
  UrlOpener canLaunch = _canLaunch,
  UrlOpener launch = _launch,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (await openSupportWhatsApp(canLaunch: canLaunch, launch: launch)) return;
  messenger?.showSnackBar(const SnackBar(
    content: Text(kSupportWhatsAppUnavailable),
    duration: kLinkFailureMessageDuration,
  ));
}

/// Support's email address.
const kSupportEmail = 'support@rebuzzpos.com';

/// Shown when no mail app opened.
const kSupportMailUnavailable =
    'No mail app opened. Email us at $kSupportEmail.';

/// Opens a new email to support in the mail app. Never throws: false from
/// `launchUrl` and a `PlatformException` both give false.
Future<bool> openSupportMail({String? subject, UrlOpener? launch}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: kSupportEmail,
    query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
  );
  try {
    return await (launch ?? launchUrl)(uri);
  } catch (_) {
    return false;
  }
}

/// [openSupportMail], and when nothing opens, a short message with the
/// address so the shopkeeper can still reach us.
Future<void> openSupportMailOrExplain(
  BuildContext context, {
  String? subject,
  UrlOpener? launch,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (await openSupportMail(subject: subject, launch: launch)) return;
  messenger?.showSnackBar(const SnackBar(
    content: Text(kSupportMailUnavailable),
    duration: kLinkFailureMessageDuration,
  ));
}

/// Shown when the browser did not open the RebuzzPOS site.
const kSiteUnavailable = "Couldn't open the browser. Visit rebuzzpos.com.";

/// Opens rebuzzpos.com in the browser, and when nothing opens says so.
/// A user-initiated hand-off; never throws.
Future<void> openRebuzzSiteOrExplain(
  BuildContext context, {
  UrlOpener? launch,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final open =
      launch ?? (Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
  var ok = false;
  try {
    ok = await open(Uri.parse('https://rebuzzpos.com'));
  } catch (_) {}
  if (ok) return;
  messenger?.showSnackBar(const SnackBar(
    content: Text(kSiteUnavailable),
    duration: kLinkFailureMessageDuration,
  ));
}
