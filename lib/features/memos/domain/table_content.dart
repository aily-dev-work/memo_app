import 'dart:convert';
import 'dart:math' as math;

/// 表形式メモの内容
class TableContent {
  /// 各列の見出し（空文字可）
  final List<String> headers;

  /// 行データ。各行の長さは [headers.length] に揃える
  final List<List<String>> rows;

  const TableContent({
    required this.headers,
    required this.rows,
  });

  int get columnCount => headers.length;
  int get rowCount => rows.length;

  TableContent copyWith({
    List<String>? headers,
    List<List<String>>? rows,
  }) {
    return TableContent(
      headers: headers ?? this.headers,
      rows: rows ?? this.rows,
    );
  }

  Map<String, dynamic> toJson() => {
        'headers': headers,
        'rows': rows,
      };

  factory TableContent.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final rowsRaw = json['rows'];
    final headers = headersRaw is List
        ? headersRaw.map((e) => e?.toString() ?? '').toList()
        : <String>['', ''];
    final colCount = math.max(1, headers.length);
    final normalizedHeaders = List<String>.generate(
      colCount,
      (i) => i < headers.length ? headers[i] : '',
    );

    final rows = <List<String>>[];
    if (rowsRaw is List) {
      for (final row in rowsRaw) {
        if (row is! List) continue;
        rows.add(
          List<String>.generate(
            colCount,
            (i) => i < row.length ? (row[i]?.toString() ?? '') : '',
          ),
        );
      }
    }
    if (rows.isEmpty) {
      rows.add(List<String>.filled(colCount, ''));
    }

    return TableContent(headers: normalizedHeaders, rows: rows);
  }

  /// 初期表（見出し行 + データ2行、列2）
  factory TableContent.empty() {
    return const TableContent(
      headers: ['', ''],
      rows: [
        ['', ''],
        ['', ''],
      ],
    );
  }
}

/// 表形式メモの JSON エンコード / デコード
class TableContentCodec {
  TableContentCodec._();

  static String emptyContent() => encode(TableContent.empty());

  static String encode(TableContent table) => jsonEncode(table.toJson());

  static TableContent decode(String content) {
    if (content.trim().isEmpty) {
      return TableContent.empty();
    }
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return TableContent.fromJson(decoded);
      }
      if (decoded is Map) {
        return TableContent.fromJson(Map<String, dynamic>.from(decoded));
      }
      return TableContent.empty();
    } catch (_) {
      return TableContent.empty();
    }
  }
}
