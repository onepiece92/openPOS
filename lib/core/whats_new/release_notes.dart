/// The "What's new" notes, bundled in the app as constants (nothing is
/// fetched), and the pure rule for which of them to show.
library;

/// One release's notes.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.major,
    required this.title,
    required this.bullets,
  });

  /// `major.minor.patch`, e.g. `1.2.0`.
  final String version;

  /// NOT semver major. Set by hand per release: true marks a release with
  /// major changes, worth announcing on the first open after the update.
  /// A release with `major: false` is updated past silently.
  final bool major;

  /// One short line under the headline.
  final String title;

  /// 3 to 6 short lines.
  final List<String> bullets;
}

/// Shown under the bullets of every release.
const kWhatsNewOfflineLine =
    'Everything still stays on this device. No account, no internet needed.';

/// The releases, in any order ([planWhatsNew] sorts). Add an entry per
/// release; flag it `major: true` only when it brings major changes, since
/// that is what makes the pop-up appear after an update.
const kReleaseNotes = <ReleaseNote>[
  ReleaseNote(
    version: '1.2.0',
    major: true,
    title: 'Tips, end-of-day close and feature switches',
    bullets: [
      'Tips: add a tip at payment. Tips show on receipts and in reports. '
          'Off until you switch it on in Features.',
      'End-of-day close: count the cash drawer and print a summary. '
          'Off until you switch it on in Features.',
      'Features: turn off the parts of the app your shop does not use.',
      'Refunds and voids can put sold items back in stock, using the sale\'s '
          'own stock records.',
      'Faster start-up: the first screen appears at once.',
      'Safer reset: a backup is taken before a factory reset, and a reset '
          'that was interrupted can be finished.',
    ],
  ),
];

/// Splits `1.10.0` (a `+build` or `-tag` suffix is ignored) into numbers, or
/// null when it is not numeric dot-separated.
List<int>? parseVersion(String? v) {
  if (v == null) return null;
  final core = v.trim().split(RegExp(r'[+-]')).first;
  if (core.isEmpty) return null;
  final out = <int>[];
  for (final part in core.split('.')) {
    final n = int.tryParse(part);
    if (n == null || n < 0) return null;
    out.add(n);
  }
  return out;
}

/// Numeric comparison: negative when [a] < [b], 0 when equal, positive when
/// [a] > [b]. `1.10.0` is newer than `1.9.0`; a missing part counts as 0, so
/// `1.2` equals `1.2.0`. An unparsable version compares as `0`.
int compareVersions(String a, String b) {
  final x = parseVersion(a) ?? const [0];
  final y = parseVersion(b) ?? const [0];
  final n = x.length > y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    final p = i < x.length ? x[i] : 0;
    final q = i < y.length ? y[i] : 0;
    if (p != q) return p < q ? -1 : 1;
  }
  return 0;
}

/// What to do on this launch.
class WhatsNewPlan {
  const WhatsNewPlan({this.show = const [], this.writeSeen});

  /// Major releases to announce, newest first. Empty: show nothing.
  final List<ReleaseNote> show;

  /// The version to store as last seen now, or null to store nothing.
  final String? writeSeen;

  @override
  String toString() =>
      'WhatsNewPlan(show: ${[for (final r in show) r.version]}, '
      'writeSeen: $writeSeen)';
}

/// Decides, from three small facts, whether to show notes and what to store.
///
/// - [lastSeen]: the stored version, or null when none is stored.
/// - [onboarded]: setup was finished. With no stored version this tells a
///   fresh install (not onboarded: store the version, show nothing) from an
///   upgrade out of a build that never stored one (onboarded: show).
/// - [switchOn]: the "Show what's new after updates" switch. Off still
///   stores the version, silently.
///
/// Equal or older [current] than [lastSeen] (a downgrade) stores nothing.
WhatsNewPlan planWhatsNew({
  required String current,
  required String? lastSeen,
  required bool onboarded,
  required bool switchOn,
  List<ReleaseNote> releases = kReleaseNotes,
}) {
  final seen = parseVersion(lastSeen) == null ? null : lastSeen;
  if (seen == null && !onboarded) return WhatsNewPlan(writeSeen: current);
  if (seen != null && compareVersions(current, seen) <= 0) {
    return const WhatsNewPlan();
  }
  final unseen = <ReleaseNote>[
    if (switchOn)
      for (final r in releases)
        if (r.major &&
            (seen == null || compareVersions(r.version, seen) > 0) &&
            compareVersions(r.version, current) <= 0)
          r,
  ]..sort((a, b) => compareVersions(b.version, a.version));
  return WhatsNewPlan(show: unseen, writeSeen: current);
}

/// The notes for "What's new" in Settings: the newest release not newer than
/// [current] (major or not), else the newest there is.
ReleaseNote? currentReleaseNote(String current,
    {List<ReleaseNote> releases = kReleaseNotes}) {
  if (releases.isEmpty) return null;
  final sorted = [...releases]
    ..sort((a, b) => compareVersions(b.version, a.version));
  for (final r in sorted) {
    if (compareVersions(r.version, current) <= 0) return r;
  }
  return sorted.first;
}
