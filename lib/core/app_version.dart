/// The app's version, as shown on the Support screen.
///
/// Must equal `version:` in pubspec.yaml (name+build), which is what the
/// stores see; test/core/app_version_test.dart fails when the two drift.
/// Kept as constants because reading the installed version at run time
/// would need a platform plugin.
const kAppVersion = '1.1.0';
const kAppBuildNumber = '10';
