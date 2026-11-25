import 'dart:io' show Platform;

import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pos_app/features/review/domain/review_prompter.dart';

/// Store listing used when the plugin can't open the store itself (no Play
/// Store on a sideloaded device, or the F-Droid `foss` build, whose stub
/// `in_app_review` throws). F-Droid builds pass
/// `--dart-define=ANDROID_LISTING_URL=https://f-droid.org/packages/com.brandbuilder.openpos/`.
const _kAndroidListingUrl = String.fromEnvironment(
  'ANDROID_LISTING_URL',
  defaultValue:
      'https://play.google.com/store/apps/details?id=$kAndroidPackage',
);

/// iOS / Android implementation. The ONLY file that imports `in_app_review`.
///
/// F-Droid `foss` build: this file compiles unchanged against the pure-Dart
/// stub in `packages/in_app_review_stub/` (swapped in by a
/// `pubspec_overrides.yaml`; see that package's library doc). The stub's
/// `isAvailable()` is false, so only the "Rate Open POS" row remains and no
/// Google library is linked.
///
/// What the plugin does natively (v2.0.12):
/// * Android `isAvailable`: builds a ReviewManager and calls
///   `requestReviewFlow()` (IPC to the Play Store app); any failure, a missing
///   activity or an exception returns false. `requestReview`: same flow, then
///   `launchReviewFlow`; failures come back as a PlatformException.
/// * iOS `isAvailable`: true on iOS ≥ 10.3. `requestReview`:
///   `AppStore.requestReview(in:)` — the OS decides whether to show anything.
class StoreReviewPrompter implements ReviewPrompter {
  StoreReviewPrompter([InAppReview? review])
      : _review = review ?? InAppReview.instance;
  final InAppReview _review;

  @override
  Future<bool> maybeRequestReview() async {
    if (!await _review.isAvailable()) return false;
    await _review.requestReview();
    return true;
  }

  @override
  Future<void> openStoreListing({required String appStoreId}) async {
    try {
      await _review.openStoreListing(appStoreId: appStoreId);
    } catch (_) {
      final url = Platform.isIOS
          ? 'https://apps.apple.com/app/id$appStoreId'
          : _kAndroidListingUrl;
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        // Nothing can open it (no store, no browser) — nothing to do.
      }
    }
  }
}
