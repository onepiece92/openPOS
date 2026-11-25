/// FOSS stand-in for `package:in_app_review` (F-Droid `foss` build).
///
/// Pure Dart, no Flutter plugin section, so swapping it in removes the
/// plugin's Android code and with it every proprietary Google Play library
/// (review, review-ktx, core-common, play-services-base/-basement/-tasks)
/// from the APK. Same public API as in_app_review 2.0.12, so
/// `lib/features/review/data/store_review_prompter.dart` compiles unchanged:
/// `isAvailable()` is false (no automatic prompt) and `openStoreListing`
/// throws, which makes the app fall back to `url_launcher` with
/// `--dart-define=ANDROID_LISTING_URL=...` (the "Rate Open POS" row stays).
///
/// To build FOSS, create `pubspec_overrides.yaml` next to pubspec.yaml
/// (gitignore it; pub reads it automatically):
///
/// ```yaml
/// dependency_overrides:
///   in_app_review:
///     path: packages/in_app_review_stub
/// ```
///
/// then `flutter pub get` and
/// `flutter build apk --dart-define=OPENPOS_FOSS=true --dart-define=ANDROID_LISTING_URL=https://f-droid.org/packages/com.brandbuilder.openpos/`.
/// (`OPENPOS_FOSS` tells the feedback ask there is no store review to wait
/// for; without it the ask still shows once the review has been
/// unavailable for 14 days.)
library;

class InAppReview {
  InAppReview._();

  static final InAppReview instance = InAppReview._();

  Future<bool> isAvailable() async => false;

  Future<void> requestReview() async {}

  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) =>
      Future<void>.error(
          UnsupportedError('No store review in the FOSS build'));
}
