import 'package:drift/drift.dart';

/// Records every SELECT (with its arguments) and counts transactions, so a
/// test can inspect what a DAO call actually sent to SQLite.
class QueryRecorder extends QueryInterceptor {
  final selects = <({String sql, List<Object?> args})>[];
  int transactionsBegun = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    selects.add((sql: statement, args: args));
    return executor.runSelect(statement, args);
  }

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    transactionsBegun++;
    return super.beginTransaction(parent);
  }
}
