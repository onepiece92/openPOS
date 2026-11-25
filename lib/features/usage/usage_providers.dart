import 'dart:io' show Directory, File;
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'package:url_launcher/url_launcher.dart';

import 'package:pos_app/core/app_version.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/utils/link_uris.dart';
import 'package:pos_app/features/backup/data/share_files.dart';
import 'package:pos_app/features/review/data/review_state_store.dart';
import 'package:pos_app/features/review/review_providers.dart';
import 'package:pos_app/features/usage/application/usage_ask_controller.dart';
import 'package:pos_app/features/usage/data/usage_counter.dart';
import 'package:pos_app/features/usage/domain/usage_ask_policy.dart';
import 'package:pos_app/features/usage/domain/usage_event.dart';
import 'package:pos_app/features/usage/usage_constants.dart';

/// The on-device usage counter of this container. Count with
/// `ref.read(usageCounterProvider).record(UsageEvent.x)` — synchronous,
/// never awaited.
final usageCounterProvider = Provider<UsageCounter>((ref) {
  final c = UsageCounter();
  ref.onDispose(c.dispose);
  return c;
});

extension UsageRecording on Ref {
  void recordUsage(UsageEvent e) => read(usageCounterProvider).record(e);
}

extension UsageRecordingWidget on WidgetRef {
  void recordUsage(UsageEvent e) => read(usageCounterProvider).record(e);
}

final usageAskControllerProvider = Provider<UsageAskController>((ref) {
  final c = UsageAskController(
    reviewStore: ReviewStateStore(ref.watch(settingsBoxProvider)),
    counter: ref.watch(usageCounterProvider),
    completedSales: () => ref
        .read(databaseProvider)
        .ordersDao
        .completedOrderCount(upTo: kUsageAskMinCompletedSales),
    appVersion: kAppVersionFull,
    reviewSupported: storeReviewSupported,
  );
  ref.onDispose(c.dispose);
  return c;
});

/// Opens a link in another app (WhatsApp, the mail app). Overridden in
/// tests to capture the exact link.
typedef LinkLauncher = Future<bool> Function(Uri uri);

final linkLauncherProvider = Provider<LinkLauncher>(
    (ref) => (uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

/// Folder for the .txt handed to the share sheet. Overridden in tests.
final usageTempDirProvider =
    Provider<Future<Directory> Function()>((ref) => getTemporaryDirectory);

/// How a summary left the app.
enum UsageSendResult { launched, sharedAsFile, noApp }

/// Hands [text] — exactly the string the screen shows — to WhatsApp. When
/// the wa.me link would be longer than [kWhatsAppMaxUrlLength] it goes to
/// the share sheet as a .txt file instead.
Future<UsageSendResult> sendUsageViaWhatsApp(
  String text, {
  required LinkLauncher launch,
  required ShareFiles share,
  required Rect shareOrigin,
  required Future<Directory> Function() tempDir,
}) async {
  final link = whatsAppLink(kUsageWhatsAppNumber, text: text);
  if (link.length > kWhatsAppMaxUrlLength) {
    await share(
      [writeUsageSummaryFile(text, await tempDir())],
      subject: kUsageEmailSubject,
      sharePositionOrigin: shareOrigin,
    );
    return UsageSendResult.sharedAsFile;
  }
  return _tryLaunch(launch, link);
}

/// Hands [text] to the mail app, addressed to [kUsageEmailAddress].
Future<UsageSendResult> sendUsageViaEmail(
  String text, {
  required LinkLauncher launch,
}) async {
  final link =
      mailtoLink(kUsageEmailAddress, subject: kUsageEmailSubject, body: text);
  return _tryLaunch(launch, link);
}

/// `launchUrl` returning false and a `PlatformException` (no app handles
/// the link) both mean nothing opened.
Future<UsageSendResult> _tryLaunch(LinkLauncher launch, String link) async {
  try {
    return await launch(Uri.parse(link))
        ? UsageSendResult.launched
        : UsageSendResult.noApp;
  } catch (_) {
    return UsageSendResult.noApp;
  }
}

/// The summary as a UTF-8 .txt (named [kUsageSummaryFileName]) in [dir],
/// for the share sheet. Written synchronously: it is a few KB.
XFile writeUsageSummaryFile(String text, Directory dir) {
  final f = File(p.join(dir.path, kUsageSummaryFileName))
    ..writeAsStringSync(text, flush: true);
  return XFile(f.path, mimeType: 'text/plain');
}
