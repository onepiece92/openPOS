import 'package:url_launcher/url_launcher.dart';

/// Support's WhatsApp number, as shown to people.
const kSupportWhatsAppDisplay = '+977 9802850777';
const _kSupportWhatsAppDigits = '9779802850777';

/// Opens a WhatsApp chat with support: the WhatsApp app if installed,
/// otherwise wa.me in the browser. A user-initiated hand-off to another
/// app; this app itself makes no network call.
Future<void> openSupportWhatsApp() async {
  final native = Uri.parse('whatsapp://send?phone=$_kSupportWhatsAppDigits');
  final web = Uri.parse('https://wa.me/$_kSupportWhatsAppDigits');
  if (await canLaunchUrl(native)) {
    await launchUrl(native, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}
