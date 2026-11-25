/// The app's `version:` from pubspec.yaml (name+build). Kept as a constant so
/// reading it needs no extra plugin; `test/features/review/app_version_test.dart`
/// fails if it drifts from pubspec.yaml, so bump both together.
///
/// The build number is included on purpose: every store upload bumps it, so
/// each release counts as a "new version" for the review rule.
const kAppVersion = '1.0.0+9';
