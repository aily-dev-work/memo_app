import 'package:flutter/material.dart';

import '../../../shared/utils/color_utils.dart';
import '../domain/checklist_content.dart';
import '../domain/memo.dart';

/// チェックリスト形式のメモエディタ
class ChecklistMemoEditor extends StatefulWidget {
  final Memo memo;
  final void Function(String content) onContentChanged;
  final void Function(Memo memo, String content)? onWillDispose;

  const ChecklistMemoEditor({
    super.key,
    required this.memo,
    required this.onContentChanged,
    this.onWillDispose,
  });

  @override
  State<ChecklistMemoEditor> createState() => _ChecklistMemoEditorState();
}

class _ChecklistMemoEditorState extends State<ChecklistMemoEditor> {
  late List<ChecklistItem> _items;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _items = ChecklistContentCodec.decode(widget.memo.content);
    _syncControllers();
  }

  @override
  void didUpdateWidget(ChecklistMemoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memo.id != widget.memo.id) {
      _disposeControllers();
      _items = ChecklistContentCodec.decode(widget.memo.content);
      _syncControllers();
    } else if (oldWidget.memo.content != widget.memo.content) {
      final currentEncoded = ChecklistContentCodec.encode(_items);
      // 親からの更新（Undo 等）で、ローカル未編集時のみ反映
      if (currentEncoded == oldWidget.memo.content) {
        _disposeControllers();
        _items = ChecklistContentCodec.decode(widget.memo.content);
        _syncControllers();
      }
    }
  }

  @override
  void dispose() {
    widget.onWillDispose?.call(
      widget.memo,
      ChecklistContentCodec.encode(_items),
    );
    _disposeControllers();
    super.dispose();
  }

  void _syncControllers() {
    for (final item in _items) {
      _controllers.putIfAbsent(
        item.id,
        () => TextEditingController(text: item.text),
      );
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  void _notifyChanged() {
    widget.onContentChanged(ChecklistContentCodec.encode(_items));
  }

  void _updateItem(int index, ChecklistItem updated) {
    setState(() {
      _items[index] = updated;
    });
    _notifyChanged();
  }

  void _addItem() {
    final item = ChecklistItem.create();
    setState(() {
      _items.add(item);
      _controllers[item.id] = TextEditingController();
    });
    _notifyChanged();
  }

  void _removeItemById(String id) {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;

    if (_items.length <= 1) {
      // 最低1件は残す
      final item = _items[0];
      _controllers[item.id]?.text = '';
      _updateItem(0, item.copyWith(text: '', checked: false));
      return;
    }

    final removed = _items[index];
    setState(() {
      _items.removeAt(index);
      _controllers.remove(removed.id)?.dispose();
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final bg = getMemoColor(widget.memo, selected: true);
    final textColor = textColorOnBackground(bg);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final controller = _controllers[item.id]!;
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade400,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _removeItemById(item.id),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: item.checked,
                      activeColor: textColor,
                      checkColor: bg,
                      side: BorderSide(color: textColor.withValues(alpha: 0.6)),
                      onChanged: (checked) {
                        _updateItem(
                          index,
                          item.copyWith(checked: checked ?? false),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: textColor,
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: textColor.withValues(alpha: 0.5),
                            ),
                        cursorColor: textColor,
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '項目を入力...',
                          hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.45),
                          ),
                        ),
                        onChanged: (text) {
                          _items[index] = item.copyWith(text: text);
                          _notifyChanged();
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: textColor.withValues(alpha: 0.45),
                      ),
                      onPressed: () => _removeItemById(item.id),
                      tooltip: '削除',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: Icon(Icons.add, color: textColor),
                label: Text(
                  '項目を追加',
                  style: TextStyle(color: textColor),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
