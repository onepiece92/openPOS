import 'dart:io';

/// Deletes [dir] recursively, retrying briefly if a background write (Hive,
/// Drift isolate, async file IO) is still finishing and the delete races it
/// with "Directory not empty". The last failure is ignored: a leftover temp
/// dir must never fail the test that already passed.
///
/// Call this only after the test has closed whatever it opened in [dir].
Future<void> deleteTempDir(Directory dir, {int attempts = 5}) async {
  for (var i = 1; i <= attempts; i++) {
    try {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
      return;
    } on FileSystemException {
      if (i == attempts) return;
      await Future<void>.delayed(Duration(milliseconds: 50 * i));
    }
  }
}
