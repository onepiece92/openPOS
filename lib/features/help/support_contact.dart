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
