import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/core/whats_new/release_notes.dart';

const _r120 = ReleaseNote(
    version: '1.2.0', major: true, title: 't', bullets: ['a', 'b', 'c']);
const _r121 = ReleaseNote(
    version: '1.2.1', major: false, title: 't', bullets: ['a', 'b', 'c']);
const _r130 = ReleaseNote(
    version: '1.3.0', major: true, title: 't', bullets: ['a', 'b', 'c']);
const _r200 = ReleaseNote(
    version: '2.0.0', major: true, title: 't', bullets: ['a', 'b', 'c']);
const _all = [_r120, _r121, _r130, _r200];

WhatsNewPlan plan(String current, String? seen,
        {bool onboarded = true, bool on = true}) =>
    planWhatsNew(
        current: current,
        lastSeen: seen,
        onboarded: onboarded,
        switchOn: on,
        releases: _all);

List<String> versions(WhatsNewPlan p) => [for (final r in p.show) r.version];

void main() {
  group('compareVersions', () {
    test('1.10.0 is newer than 1.9.0', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });
    test('equal, short forms and build suffixes', () {
      expect(compareVersions('1.2.0', '1.2.0'), 0);
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.0+13', '1.2.0+12'), 0);
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });
    test('garbage compares as 0', () {
      expect(compareVersions('x', '0.0.0'), 0);
      expect(parseVersion('1.a.0'), isNull);
    });
  });

  group('planWhatsNew', () {
    test('(c) fresh install: nothing shown, current stored', () {
      final p = plan('1.2.0', null, onboarded: false);
      expect(p.show, isEmpty);
      expect(p.writeSeen, '1.2.0');
    });

    test('(a) upgrade from no key with shop data shows once, then never', () {
      final first = plan('1.2.0', null);
      expect(versions(first), ['1.2.0']);
      expect(first.writeSeen, '1.2.0');
      // Second launch: the stored value is now the current version.
      final second = plan('1.2.0', first.writeSeen);
      expect(second.show, isEmpty);
      expect(second.writeSeen, isNull);
    });

    test('minor-only update: silent, version stored', () {
      final p = plan('1.2.1', '1.2.0');
      expect(p.show, isEmpty);
      expect(p.writeSeen, '1.2.1');
    });

    test('several unseen majors: newest first, only majors', () {
      final p = plan('2.0.0', '1.1.0');
      expect(versions(p), ['2.0.0', '1.3.0', '1.2.0']);
      expect(p.writeSeen, '2.0.0');
    });

    test('a release newer than the running version is not shown', () {
      expect(versions(plan('1.2.5', '1.1.0')), ['1.2.0']);
    });

    test('equal version: nothing, nothing stored', () {
      final p = plan('1.2.0', '1.2.0');
      expect(p.show, isEmpty);
      expect(p.writeSeen, isNull);
    });

    test('(b) build number only: nothing', () {
      final p = plan('1.2.0+13', '1.2.0+12');
      expect(p.show, isEmpty);
      expect(p.writeSeen, isNull);
    });

    test('downgrade: nothing, stored version kept', () {
      final p = plan('1.2.0', '1.3.0');
      expect(p.show, isEmpty);
      expect(p.writeSeen, isNull);
    });

    test('(d) switch off: nothing shown, lastSeen still advances', () {
      final p = plan('1.2.0', '1.1.0', on: false);
      expect(p.show, isEmpty);
      expect(p.writeSeen, '1.2.0');
      expect(plan('1.2.0', null, on: false).writeSeen, '1.2.0');
    });

    test('after a factory reset: like a fresh install', () {
      // The reset clears the stored version and onboarding.
      final p = plan('1.2.0', null, onboarded: false);
      expect(p.show, isEmpty);
      expect(p.writeSeen, '1.2.0');
    });

    test('an unreadable stored value is treated as none', () {
      expect(versions(plan('1.2.0', 'garbage')), ['1.2.0']);
      expect(plan('1.2.0', 'garbage', onboarded: false).show, isEmpty);
    });
  });

  group('bundled notes', () {
    test('1.2.0 is major with 3-6 bullets', () {
      final r = kReleaseNotes.firstWhere((r) => r.version == '1.2.0');
      expect(r.major, isTrue);
      expect(r.bullets.length, inInclusiveRange(3, 6));
    });
    test('currentReleaseNote picks the newest not above current', () {
      expect(currentReleaseNote('1.2.5', releases: _all)!.version, '1.2.1');
      expect(currentReleaseNote('0.1.0', releases: _all)!.version, '2.0.0');
    });
  });
}
