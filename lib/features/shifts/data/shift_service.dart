import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/database/daos/shifts_dao.dart';
import 'package:pos_app/core/providers/database_provider.dart';

/// A gap longer than this is offered "Keep them separate".
const Duration kLongGap = Duration(hours: 12);

/// The note stored on an automatic gap close.
const kGapCloseNote =
    'Till was closed. Recorded automatically; cash was not counted.';

/// Sales, refunds and voids made between the last close and now, while no
/// shift was open. By the DAO's rule they land in the next shift opened.
class GapInfo {
  const GapInfo({
    required this.from,
    required this.to,
    required this.sales,
    required this.refunds,
    required this.voids,
  });

  final DateTime from;
  final DateTime to;
  final int sales;
  final int refunds;
  final int voids;

  bool get hasActivity => sales + refunds + voids > 0;

  /// Over 12 hours, or the last close was on an earlier calendar day.
  bool get isLong =>
      to.difference(from) > kLongGap ||
      from.year != to.year ||
      from.month != to.month ||
      from.day != to.day;

  /// Offer to record the gap as its own day: it has activity and is long.
  bool get canKeepSeparate => hasActivity && isLong;
}

/// The plain sentence shown when opening the till after a gap with
/// activity, or null when there is nothing to say.
String? gapMessage(GapInfo? gap) {
  if (gap == null || !gap.hasActivity) return null;
  final other = gap.refunds + gap.voids;
  final total = gap.sales + other;
  final parts = [
    if (gap.sales > 0) gap.sales == 1 ? '1 sale' : '${gap.sales} sales',
    if (other > 0) other == 1 ? '1 refund or void' : '$other refunds or voids',
  ];
  final was = total == 1 ? 'was' : 'were';
  final they = total == 1 ? 'It is' : 'They are';
  return '${parts.join(' and ')} $was made while the till was closed. '
      '$they included in this day.';
}

/// Shown under the opening cash when it comes from an uncounted close.
const kOpeningFromUncountedNote =
    'Expected cash from the last day (not counted)';

/// Shown under the opening cash when it comes from a counted close.
const kOpeningFromCountedNote = 'Cash counted at the last close';

/// The opening cash to suggest, and where it came from.
class OpeningSuggestion {
  const OpeningSuggestion(this.amount, {required this.fromUncounted});
  final double amount;

  /// True when the last close was not counted, so [amount] is what the
  /// drawer was expected to hold then, not what was counted.
  final bool fromUncounted;

  String get note =>
      fromUncounted ? kOpeningFromUncountedNote : kOpeningFromCountedNote;
}

/// Shown on the close screen when the device clock is behind the window
/// start: what it records now falls before the window and is never counted.
const kClockBehindNote =
    "This device's clock is earlier than the last close. Sales recorded "
    "with the earlier time aren't in this day.";

/// The open-form line when a day has been closed before.
const kTillClosedNote = 'No day is open. You can keep selling; sales made '
    'while the till is closed are counted in the next day you open.';

/// The open-form line before the first day ever: there is no earlier close
/// for the window to start from, so it starts at the opening.
const kFirstDayNote =
    "This is your first day. Sales made before you open it aren't included.";

/// [kClockBehindNote] when [now] is before [windowStart], else null.
String? clockBehindNote(DateTime now, DateTime? windowStart) =>
    windowStart != null && now.isBefore(windowStart) ? kClockBehindNote : null;

/// "This day has been open for N days." once the window passes 24 hours,
/// in hours while under 2 days; null before that.
String? longOpenNote(DateTime windowStart, DateTime now) {
  final d = now.difference(windowStart);
  if (d <= const Duration(hours: 24)) return null;
  final String n;
  if (d < const Duration(days: 2)) {
    final h = d.inHours;
    n = h == 1 ? '1 hour' : '$h hours';
  } else {
    final days = d.inDays;
    n = days == 1 ? '1 day' : '$days days';
  }
  return 'This day has been open for $n.';
}

/// Till-session operations on top of [ShiftsDao]: the clock clamp, the gap
/// rule and the "keep them separate" close. No money math lives here.
class ShiftService {
  ShiftService(this.db) : _dao = db.shiftsDao;

  final AppDatabase db;
  final ShiftsDao _dao;

  /// What happened since the last close, or null when no shift has ever
  /// been closed (the first-ever shift starts at its own opening).
  Future<GapInfo?> gapBeforeOpen({DateTime? now}) async {
    final last = await _dao.lastClosedShift();
    final from = last?.closedAt;
    if (from == null) return null;
    final to = _clamp(now ?? DateTime.now(), from);
    final figures = await _dao.figuresForWindow(from, to);
    return GapInfo(
      from: from,
      to: to,
      sales: figures.sales.count,
      refunds: figures.refunds.count,
      voids: figures.voids.count,
    );
  }

  /// Opens the till. If the clock is behind the previous close, `opened_at`
  /// is moved up to that close so history never shows a day that opened
  /// before the one before it ended.
  Future<int> openTill({required double openingCash, DateTime? now}) async {
    final last = await _dao.lastClosedShift();
    return _dao.openShift(
      openingCash: openingCash,
      openedAt: _clamp(now ?? DateTime.now(), last?.closedAt),
    );
  }

  /// The opening cash for the next day, or null when nothing has been
  /// closed yet. After an uncounted close it is that close's stored
  /// expected cash; otherwise the last counted close's counted cash
  /// ("counted" = closed_at and counted_cash both set).
  Future<OpeningSuggestion?> suggestedOpeningCash() async {
    final last = await _dao.lastClosedShift();
    if (last == null) return null;
    final counted = last.countedCash;
    if (counted != null) {
      return OpeningSuggestion(counted, fromUncounted: false);
    }
    final expected = last.expectedCash;
    if (expected != null) {
      return OpeningSuggestion(expected, fromUncounted: true);
    }
    // Defensive: an uncounted close always stores expected_cash.
    final prev = (await _dao.lastCountedShift())?.countedCash;
    return prev == null ? null : OpeningSuggestion(prev, fromUncounted: false);
  }

  /// Records the gap as its own closed day: a shift opened and closed at
  /// [now] whose window is [last close, now), so the activity stays out of
  /// the day about to open. Cash was not counted, so counted_cash is NULL:
  /// the summary says "Not counted" and there is no over/short. It opens
  /// with the same opening cash the next day would get
  /// ([suggestedOpeningCash]). Throws [ShiftStateException] if a shift is
  /// open or nothing has been closed yet.
  Future<void> keepGapSeparate({
    required String Function(ShiftClose close, String notes) summary,
    DateTime? now,
  }) =>
      _dao.transaction(() async {
        final last = await _dao.lastClosedShift();
        if (last == null) {
          throw const ShiftStateException('There is no earlier close');
        }
        final at = _clamp(now ?? DateTime.now(), last.closedAt);
        final opening = (await suggestedOpeningCash())?.amount ?? 0;
        final id = await _dao.openShift(openingCash: opening, openedAt: at);
        await _dao.closeShift(
          id,
          countedCash: null,
          at: at,
          notes: kGapCloseNote,
          summary: (c) => summary(c, kGapCloseNote),
        );
      });

  /// The shop's tax name for the summary: the default tax rate, else the
  /// first active one, else "Tax".
  Future<String> taxName({int? defaultTaxId}) async {
    if (defaultTaxId != null) {
      final r = await db.taxDao.getById(defaultTaxId);
      if (r != null && r.name.trim().isNotEmpty) return r.name.trim();
    }
    for (final r in await db.taxDao.getAll()) {
      if (r.isActive && r.name.trim().isNotEmpty) return r.name.trim();
    }
    return 'Tax';
  }

  static DateTime _clamp(DateTime t, DateTime? floor) =>
      floor != null && t.isBefore(floor) ? floor : t;
}

final shiftServiceProvider =
    Provider<ShiftService>((ref) => ShiftService(ref.watch(databaseProvider)));
