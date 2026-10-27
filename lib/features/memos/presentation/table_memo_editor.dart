import 'package:flutter/material.dart';

import '../../../shared/utils/color_utils.dart';
import '../domain/memo.dart';
import '../domain/table_content.dart';

/// 表形式のメモエディタ
class TableMemoEditor extends StatefulWidget {
  final Memo memo;
  final void Function(String content) onContentChanged;
  final void Function(Memo memo, String content)? onWillDispose;

  const TableMemoEditor({
    super.key,
    required this.memo,
    required this.onContentChanged,
    this.onWillDispose,
  });

  @override
  State<TableMemoEditor> createState() => _TableMemoEditorState();
}

class _TableMemoEditorState extends State<TableMemoEditor> {
  static const double _cellWidth = 120;
  static const double _cellMinHeight = 44;

  late TableContent _table;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _table = TableContentCodec.decode(widget.memo.content);
    _syncControllers();
  }

  @override
  void didUpdateWidget(TableMemoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memo.id != widget.memo.id) {
      _disposeControllers();
      _table = TableContentCodec.decode(widget.memo.content);
      _syncControllers();
    } else if (oldWidget.memo.content != widget.memo.content) {
      final currentEncoded = TableContentCodec.encode(_table);
      if (currentEncoded == oldWidget.memo.content) {
        _disposeControllers();
        _table = TableContentCodec.decode(widget.memo.content);
        _syncControllers();
      }
    }
  }

  @override
  void dispose() {
    widget.onWillDispose?.call(
      widget.memo,
      TableContentCodec.encode(_table),
    );
    _disposeControllers();
    super.dispose();
  }

  String _headerKey(int col) => 'h-$col';
  String _cellKey(int row, int col) => 'c-$row-$col';

  void _syncControllers() {
    for (var c = 0; c < _table.columnCount; c++) {
      final key = _headerKey(c);
      _controllers.putIfAbsent(
        key,
        () => TextEditingController(text: _table.headers[c]),
      );
      _controllers[key]!.text = _table.headers[c];
    }
    for (var r = 0; r < _table.rowCount; r++) {
      for (var c = 0; c < _table.columnCount; c++) {
        final key = _cellKey(r, c);
        _controllers.putIfAbsent(
          key,
          () => TextEditingController(text: _table.rows[r][c]),
        );
        _controllers[key]!.text = _table.rows[r][c];
      }
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  void _rebuildControllers() {
    _disposeControllers();
    _syncControllers();
  }

  void _notifyChanged() {
    widget.onContentChanged(TableContentCodec.encode(_table));
  }

  void _setHeader(int col, String value) {
    final headers = List<String>.from(_table.headers);
    headers[col] = value;
    _table = _table.copyWith(headers: headers);
    _notifyChanged();
  }

  void _setCell(int row, int col, String value) {
    final rows = _table.rows.map((r) => List<String>.from(r)).toList();
    rows[row][col] = value;
    _table = _table.copyWith(rows: rows);
    _notifyChanged();
  }

  void _addRow() {
    setState(() {
      final rows = _table.rows.map((r) => List<String>.from(r)).toList();
      rows.add(List<String>.filled(_table.columnCount, ''));
      _table = _table.copyWith(rows: rows);
      _rebuildControllers();
    });
    _notifyChanged();
  }

  void _addColumn() {
    setState(() {
      final headers = List<String>.from(_table.headers)..add('');
      final rows = _table.rows
          .map((r) => List<String>.from(r)..add(''))
          .toList();
      _table = TableContent(headers: headers, rows: rows);
      _rebuildControllers();
    });
    _notifyChanged();
  }

  void _removeRow(int row) {
    if (_table.rowCount <= 1) return;
    setState(() {
      final rows = _table.rows.map((r) => List<String>.from(r)).toList()
        ..removeAt(row);
      _table = _table.copyWith(rows: rows);
      _rebuildControllers();
    });
    _notifyChanged();
  }

  void _removeColumn(int col) {
    if (_table.columnCount <= 1) return;
    setState(() {
      final headers = List<String>.from(_table.headers)..removeAt(col);
      final rows = _table.rows.map((r) {
        final copy = List<String>.from(r)..removeAt(col);
        return copy;
      }).toList();
      _table = TableContent(headers: headers, rows: rows);
      _rebuildControllers();
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bg = getMemoColor(widget.memo, selected: true);
    final textColor = textColorOnBackground(bg);
    final borderColor = textColor.withValues(alpha: 0.25);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(textColor, borderColor, bg),
                  ...List.generate(
                    _table.rowCount,
                    (row) => _buildDataRow(row, textColor, borderColor, bg),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _addRow,
                  icon: Icon(Icons.table_rows, color: textColor, size: 18),
                  label: Text('行を追加', style: TextStyle(color: textColor)),
                ),
                TextButton.icon(
                  onPressed: _addColumn,
                  icon: Icon(Icons.view_column, color: textColor, size: 18),
                  label: Text('列を追加', style: TextStyle(color: textColor)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderRow(Color textColor, Color borderColor, Color bg) {
    return Row(
      children: [
        ...List.generate(_table.columnCount, (col) {
          return _buildCell(
            controller: _controllers[_headerKey(col)]!,
            textColor: textColor,
            borderColor: borderColor,
            background: textColor.withValues(alpha: 0.08),
            isHeader: true,
            onChanged: (v) => _setHeader(col, v),
            trailing: _table.columnCount > 1
                ? IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      size: 16,
                      color: textColor.withValues(alpha: 0.45),
                    ),
                    tooltip: '列を削除',
                    onPressed: () => _removeColumn(col),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  )
                : null,
          );
        }),
        SizedBox(
          width: 40,
          height: _cellMinHeight,
          child: Icon(
            Icons.tag,
            size: 16,
            color: textColor.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(
    int row,
    Color textColor,
    Color borderColor,
    Color bg,
  ) {
    return Row(
      children: [
        ...List.generate(_table.columnCount, (col) {
          return _buildCell(
            controller: _controllers[_cellKey(row, col)]!,
            textColor: textColor,
            borderColor: borderColor,
            background: Colors.transparent,
            isHeader: false,
            onChanged: (v) => _setCell(row, col, v),
          );
        }),
        SizedBox(
          width: 40,
          height: _cellMinHeight,
          child: _table.rowCount > 1
              ? IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: textColor.withValues(alpha: 0.45),
                  ),
                  tooltip: '行を削除',
                  onPressed: () => _removeRow(row),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildCell({
    required TextEditingController controller,
    required Color textColor,
    required Color borderColor,
    required Color background,
    required bool isHeader,
    required ValueChanged<String> onChanged,
    Widget? trailing,
  }) {
    return Container(
      width: _cellWidth,
      constraints: const BoxConstraints(minHeight: _cellMinHeight),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: textColor,
                fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
              cursorColor: textColor,
              maxLines: null,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                hintText: isHeader ? '見出し' : '',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
