/// The app's version, as shown on the Support screen. The single source of
/// truth for the version inside the app.
///
/// Must equal `version:` in pubspec.yaml (name+build), which is what the
/// stores see; test/core/app_version_test.dart fails when the two drift.
/// Kept as constants because reading the installed version at run time
/// would need a platform plugin.
const kAppVersion = '1.1.0';
const kAppBuildNumber = '10';

/// The full pubspec `version:` string, e.g. `1.1.0+10`. The review reminder
/// asks at most once per value of this; the build number is included on
/// purpose, because every store upload bumps it.
const kAppVersionFull = '$kAppVersion+$kAppBuildNumber';
