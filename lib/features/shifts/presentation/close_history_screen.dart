import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/core/utils/money.dart';
import 'package:pos_app/features/products/domain/products_provider.dart';
import 'package:pos_app/features/shifts/domain/shift_summary.dart';
import 'package:pos_app/features/shifts/presentation/shift_summary_panel.dart';
import 'package:pos_app/features/shifts/shift_settings.dart';

/// How many closes the history lists per page.
const int kHistoryPage = 30;

/// A closed shift's real window start and its net sales. Computed when its
/// row is first shown (a few indexed range queries), so only the rows on
/// screen cost anything.
final _shiftWindowProvider = FutureProvider.autoDispose
    .family<({DateTime from, double net}), int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  final shift =
      await (db.select(db.shifts)..where((s) => s.id.equals(id))).getSingle();
  final from = await db.shiftsDao.windowStart(shift);
  final f = await db.shiftsDao
      .figuresForWindow(from, shift.closedAt ?? shift.openedAt);
  return (from: from, net: f.netSales);
});

final _closedShiftProvider =
    FutureProvider.autoDispose.family<Shift?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.shifts)
        ..where((s) => s.id.equals(id))
        ..where((s) => s.closedAt.isNotNull()))
      .getSingleOrNull();
});

/// Past closes, newest first. Tap one to see its frozen summary.
class CloseHistoryScreen extends ConsumerStatefulWidget {
  const CloseHistoryScreen({super.key});

  @override
  ConsumerState<CloseHistoryScreen> createState() => _CloseHistoryState();
}

class _CloseHistoryState extends ConsumerState<CloseHistoryScreen> {
  int _limit = kHistoryPage;
  late Future<List<Shift>> _future = _fetch();

  Future<List<Shift>> _fetch() =>
      ref.read(databaseProvider).shiftsDao.closedShifts(limit: _limit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Past closes')),
      body: FutureBuilder<List<Shift>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Could not load: ${snap.error}'));
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('No days have been closed yet.'));
          }
          final more = rows.length >= _limit;
          return ListView.builder(
            itemCount: rows.length + (more ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == rows.length) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    key: const ValueKey('history-more'),
                    onPressed: () => setState(() {
                      _limit += kHistoryPage;
                      _future = _fetch();
                    }),
                    child: const Text('Show older'),
                  ),
                );
              }
              return _HistoryRow(shift: rows[i]);
            },
          );
        },
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.shift});
  final Shift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.watch(currencyFormatterProvider);
    final closedAt = shift.closedAt ?? shift.openedAt;
    final win = ref.watch(_shiftWindowProvider(shift.id));
    final cents =
        (roundMoney((shift.countedCash ?? 0) - (shift.expectedCash ?? 0)) * 100)
            .round();
    final os = cents == 0
        ? overShortLabel(0)
        : '${overShortLabel(cents)} ${fmt.format(cents.abs() / 100)}';
    return ListTile(
      key: ValueKey('history-${shift.id}'),
      title: Text(summaryRange(
          win.maybeWhen(data: (w) => w.from, orElse: () => shift.openedAt),
          closedAt)),
      subtitle: Text(
        'Net sales ${win.maybeWhen(data: (w) => fmt.format(w.net), orElse: () => '...')}'
        '  ·  $os',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => context.push('$kCloseDayHistoryRoute/${shift.id}'),
    );
  }
}

/// One past close: its frozen summary text, with Print and Share.
class CloseDetailScreen extends ConsumerWidget {
  const CloseDetailScreen({super.key, required this.shiftId});

  /// Null when the route's id was not a number.
  final int? shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(_closedShiftProvider(shiftId ?? -1));
    return Scaffold(
      appBar: AppBar(title: const Text('Day summary')),
      body: shift.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (s) => s == null
            ? const Center(child: Text('This close was not found.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ShiftSummaryPanel(
                    text: s.summaryText ?? 'No summary was saved.',
                    subject:
                        'End of day, ${summaryTime(s.closedAt ?? s.openedAt)}',
                  ),
                ],
              ),
      ),
    );
  }
}
