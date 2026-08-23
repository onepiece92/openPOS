import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';
import 'package:pos_app/features/reports/presentation/widgets/dashboard_body.dart';
import 'package:pos_app/features/side_nav/presentation/side_nav.dart';

/// Reports dashboard. Query building + models + provider live in
/// `domain/report_data.dart`; the rendered sections in `widgets/`.
// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  ReportPeriod _period = ReportPeriod.today;
  DateTimeRange? _customRange;

  static final _rangeLabelFmt = DateFormat('d MMM');

  ReportQuery get _activeQuery {
    if (_customRange != null) {
      return ReportQuery(
        from: _customRange!.start,
        to: _customRange!.end
            .add(const Duration(hours: 23, minutes: 59, seconds: 59)),
        label: 'Custom Range',
      );
    }
    return ReportQuery(from: _period.from, to: _period.to, label: _period.label);
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      builder: (context, child) => child!,
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _activeQuery;
    final reportAsync = ref.watch(reportProvider(query));
    final symbol = ref.watch(currencySymbolProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const PosDrawer(),
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
              color: _customRange != null ? cs.primary : null,
            ),
            tooltip: 'Custom date range',
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: SegmentedButton<ReportPeriod>(
              segments: ReportPeriod.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              selected: _customRange != null ? {} : {_period},
              onSelectionChanged: (s) {
                if (s.isEmpty) return;
                setState(() {
                  _period = s.first;
                  _customRange = null;
                });
              },
            ),
          ),
          // Custom range indicator
          if (_customRange != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_rangeLabelFmt.format(_customRange!.start)} – ${_rangeLabelFmt.format(_customRange!.end)}',
                    style: TextStyle(
                        color: cs.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _customRange = null),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(reportProvider(query));
                await ref.read(reportProvider(query).future);
              },
              child: reportAsync.when(
                data: (data) => DashboardBody(
                  data: data,
                  symbol: symbol,
                  cs: cs,
                  periodLabel: query.label,
                  isCustomRange: _customRange != null,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text('Error: $e')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
