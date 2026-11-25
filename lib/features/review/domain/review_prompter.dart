/// Talks to the platform's store-review UI. The app only ever depends on this
/// interface; the `in_app_review` package is imported in exactly one file,
/// `lib/features/review/data/store_review_prompter.dart`.
///
/// Implementations:
/// * `StoreReviewPrompter` — iOS and Android (App Store / Google Play).
/// * `NoopReviewPrompter` — macOS, Windows, Linux and tests.
///
/// Neither call makes a network request from our process: the OS / store app
/// draws the review sheet, and opening the listing hands a URL to the store
/// app (like `url_launcher`).
abstract interface class ReviewPrompter {
  /// Asks the OS to show its native review sheet if it can. Returns true when
  /// the OS was asked (it may still decide not to show anything — both stores
  /// rate-limit and never report the outcome), false when review is
  /// unavailable (sideloaded APK, no Play Store / Play services, old OS).
  ///
  /// May throw or never complete — callers must wrap it in a timeout and a
  /// catch-all (see `ReviewController`).
  Future<bool> maybeRequestReview();

  /// Opens the app's store page (user-initiated "Rate Open POS").
  /// [appStoreId] is used on iOS; Android uses the app's package name.
  Future<void> openStoreListing({required String appStoreId});
}

/// App Store id of Open POS (confirmed via Apple's lookup API).
const kAppStoreId = '6761003751';

/// Android application id.
const kAndroidPackage = 'com.brandbuilder.openpos';
