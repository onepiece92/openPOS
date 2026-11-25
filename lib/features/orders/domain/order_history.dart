import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pos_app/core/database/app_database.dart';
import 'package:pos_app/core/providers/database_provider.dart';
import 'package:pos_app/features/reports/domain/report_data.dart';

/// What the order-history screen shows: the pages loaded so far (newest
/// first), whether older orders remain, and today's summary.
class OrderHistoryState {
  const OrderHistoryState({
    this.orders = const [],
    this.search = '',
    this.hasMore = false,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.todayOrders = 0,
    this.todayRevenue = 0,
    this.error,
  });

  final List<Order> orders;
  final String search;

  /// Older orders exist beyond [orders]; [OrderHistoryNotifier.loadMore]
  /// fetches the next page.
  final bool hasMore;

  /// True until the first page (of this search) has arrived.
  final bool isLoading;
  final bool isLoadingMore;

  /// Orders rung up today, of any status.
  final int todayOrders;

  /// Today's takings net of refunds — the same figure as the dashboard's
  /// revenue for "Today".
  final double todayRevenue;
  final Object? error;

  OrderHistoryState copyWith({
    List<Order>? orders,
    String? search,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    int? todayOrders,
    double? todayRevenue,
    Object? error,
  }) =>
      OrderHistoryState(
        orders: orders ?? this.orders,
        search: search ?? this.search,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        todayOrders: todayOrders ?? this.todayOrders,
        todayRevenue: todayRevenue ?? this.todayRevenue,
        error: error,
      );
}

/// Loads order history a page at a time (keyed on created_at, so the whole
/// history is reachable by scrolling), runs the search in SQL, and re-reads
/// what is on screen when an order, refund or customer changes.
class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  OrderHistoryNotifier(this._db, {this.pageSize = 50})
      : super(const OrderHistoryState()) {
    _changes = _db
        .tableUpdates(TableUpdateQuery.onAllTables(
            [_db.orders, _db.returns, _db.customers]))
        .listen((_) => refresh());
    refresh();
  }

  final AppDatabase _db;
  final int pageSize;
  late final StreamSubscription<void> _changes;

  /// Bumped whenever the list is replaced, so a slower, older read cannot
  /// overwrite a newer one.
  int _generation = 0;

  /// Narrows the list to orders matching [search] (see
  /// `OrdersDao.historyPage`); '' shows everything again.
  Future<void> setSearch(String search) {
    final q = search.trim();
    if (q == state.search) return Future.value();
    state = state.copyWith(search: q, isLoading: true);
    return refresh(keepLoaded: false);
  }

  /// Re-reads the rows already on screen (or just the first page) plus
  /// today's summary.
  Future<void> refresh({bool keepLoaded = true}) async {
    final generation = ++_generation;
    final search = state.search;
    final want = keepLoaded && state.orders.length > pageSize
        ? state.orders.length
        : pageSize;
    try {
      final rows =
          await _db.ordersDao.historyPage(search: search, limit: want + 1);
      const today = ReportPeriod.today;
      final count =
          await _db.ordersDao.orderCountForPeriod(today.from, today.to);
      final revenue =
          await _db.ordersDao.totalRevenueForPeriod(today.from, today.to);
      if (!mounted || generation != _generation) return;
      state = OrderHistoryState(
        orders: rows.take(want).toList(),
        search: search,
        hasMore: rows.length > want,
        isLoading: false,
        todayOrders: count,
        todayRevenue: revenue,
      );
    } catch (e) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
          isLoading: false, isLoadingMore: false, error: e);
    }
  }

  /// Appends the next (older) page. No-op while a read is in flight or when
  /// the history is exhausted.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true);
    try {
      final rows = await _db.ordersDao.historyPage(
        search: state.search,
        before: state.orders.last,
        limit: pageSize + 1,
      );
      if (!mounted || generation != _generation) return;
      state = state.copyWith(
        orders: [...state.orders, ...rows.take(pageSize)],
        hasMore: rows.length > pageSize,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted || generation != _generation) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }
}

/// Owned by the order-history screen: created when it opens, disposed (and
/// its table listener cancelled) when it closes.
final orderHistoryProvider = StateNotifierProvider.autoDispose<
    OrderHistoryNotifier, OrderHistoryState>(
  (ref) => OrderHistoryNotifier(ref.watch(databaseProvider)),
);
