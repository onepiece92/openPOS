/// Reading CSV files for import.
///
/// Every cell is text. Nothing is guessed to be a number, so a SKU `00123`
/// or a phone `0412345678` keeps its zeros; the importer converts only the
/// columns it knows are numeric, with [CsvRow.numberOf] and friends.
library;

/// Splits [content] into rows of text cells.
///
/// * Rows end at `\r\n`, `\n` or `\r`, whichever the file uses (mixed is
///   fine). The app's own exports write `\r\n`.
/// * A leading UTF-8 byte-order mark is dropped.
/// * Cells may be quoted with `"`; inside quotes `""` is a literal quote and
///   commas and line breaks are data, kept exactly as written.
/// * Lines with nothing on them (including a trailing newline) are skipped.
List<List<String>> parseCsvText(String content) {
  const quote = 0x22, comma = 0x2C, cr = 0x0D, lf = 0x0A, bom = 0xFEFF;

  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  // True once the current cell has had a quoted part, so `""` is a cell.
  var cellQuoted = false;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
    cellQuoted = false;
  }

  void endRow() {
    final blankLine = row.isEmpty && cell.isEmpty && !cellQuoted;
    if (!blankLine) {
      endCell();
      rows.add(row);
    }
    row = <String>[];
  }

  var i = content.isNotEmpty && content.codeUnitAt(0) == bom ? 1 : 0;
  for (; i < content.length; i++) {
    final c = content.codeUnitAt(i);
    if (inQuotes) {
      if (c != quote) {
        cell.writeCharCode(c);
      } else if (i + 1 < content.length && content.codeUnitAt(i + 1) == quote) {
        cell.writeCharCode(quote);
        i++;
      } else {
        inQuotes = false;
      }
    } else if (c == quote) {
      inQuotes = true;
      cellQuoted = true;
    } else if (c == comma) {
      endCell();
    } else if (c == cr || c == lf) {
      if (c == cr && i + 1 < content.length && content.codeUnitAt(i + 1) == lf) {
        i++;
      }
      endRow();
    } else {
      cell.writeCharCode(c);
    }
  }
  endRow();
  return rows;
}

/// A parsed CSV file with a header row: cells are read by column name.
class CsvTable {
  CsvTable._(this._columns, this.rows);

  /// Parses [content]; the first non-blank line is the header. Column names
  /// are matched ignoring case and surrounding spaces.
  factory CsvTable.parse(String content) {
    final all = parseCsvText(content);
    if (all.isEmpty) return CsvTable._(const {}, const []);
    final columns = <String, int>{};
    for (var i = 0; i < all.first.length; i++) {
      columns.putIfAbsent(all.first[i].trim().toLowerCase(), () => i);
    }
    return CsvTable._(columns, [
      for (var r = 1; r < all.length; r++)
        // Row numbers count non-blank lines from 1, the header being row 1 —
        // what a spreadsheet shows for a file without blank lines.
        CsvRow._(columns, all[r], r + 1),
    ]);
  }

  final Map<String, int> _columns;

  /// Data rows (the header excluded).
  final List<CsvRow> rows;

  bool has(String column) => _columns.containsKey(column);

  /// Throws a [FormatException] naming the [columns] the file lacks.
  void require(List<String> columns) {
    final missing = [
      for (final c in columns)
        if (!has(c.toLowerCase())) c,
    ];
    if (missing.isNotEmpty) {
      throw FormatException(
          'Missing required column${missing.length == 1 ? '' : 's'}: '
          '${missing.join(', ')}');
    }
  }
}

/// One data row. A column the file lacks, or a row too short to reach it,
/// reads as blank — never an index error.
class CsvRow {
  CsvRow._(this._columns, this._cells, this.number);

  final Map<String, int> _columns;
  final List<String> _cells;

  /// 1-based position in the file (the header is row 1).
  final int number;

  bool get isBlank => _cells.every((c) => c.trim().isEmpty);

  /// The cell exactly as written; `''` when absent.
  String raw(String column) {
    final i = _columns[column];
    return i == null || i >= _cells.length ? '' : _cells[i];
  }

  /// The cell without surrounding spaces; `''` when absent.
  String text(String column) => raw(column).trim();

  /// [text], or null when blank.
  String? textOrNull(String column) {
    final t = text(column);
    return t.isEmpty ? null : t;
  }

  /// A numeric cell: null when blank, a [FormatException] naming the row
  /// and column when it holds something that is not a plain number.
  double? numberOf(String column) {
    final t = text(column);
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null || !v.isFinite) throw _bad(column, t, 'a number');
    return v;
  }

  /// A whole-number cell (`5` or `5.0`): null when blank.
  int? intOf(String column) {
    final v = numberOf(column);
    if (v == null) return null;
    if (v != v.truncateToDouble()) {
      throw _bad(column, text(column), 'a whole number');
    }
    return v.toInt();
  }

  /// A yes/no cell: `1`, `true`, `yes` (any case) are true, anything else
  /// false; null when blank.
  bool? boolOf(String column) {
    final t = text(column).toLowerCase();
    if (t.isEmpty) return null;
    return t == '1' || t == 'true' || t == 'yes';
  }

  /// A date cell in ISO form (`2026-03-01` or `2026-03-01T09:30:00`): null
  /// when blank.
  DateTime? dateOf(String column) {
    final t = text(column);
    if (t.isEmpty) return null;
    final v = DateTime.tryParse(t);
    if (v == null) {
      throw _bad(column, t, 'a date such as 2026-03-01 or 2026-03-01T09:30:00');
    }
    return v;
  }

  /// A [FormatException] for this row.
  FormatException error(String message) =>
      FormatException('Row $number: $message');

  FormatException _bad(String column, String value, String expected) =>
      error('${_title(column)} "$value" is not $expected');

  static String _title(String column) => column
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
