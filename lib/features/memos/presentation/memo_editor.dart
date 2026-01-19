import 'package:flutter/material.dart';

import '../../../shared/utils/color_utils.dart';
import '../domain/memo.dart';

/// メモ本文エディタ
class MemoEditor extends StatefulWidget {
  final Memo memo;
  final void Function(String content) onContentChanged;
  final void Function(TextEditingController controller) onControllerCreated;
  final void Function(FocusNode focusNode)? onFocusNodeCreated;
  /// 破棄直前（未保存分を保存するために）呼ぶ。dispose の前に呼ばれる。
  final void Function(Memo memo, String content)? onWillDispose;

  const MemoEditor({
    super.key,
    required this.memo,
    required this.onContentChanged,
    required this.onControllerCreated,
    this.onFocusNodeCreated,
    this.onWillDispose,
  });

  @override
  State<MemoEditor> createState() => _MemoEditorState();
}

class _MemoEditorState extends State<MemoEditor> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.memo.content);
    widget.onControllerCreated(_controller);
    widget.onFocusNodeCreated?.call(_focusNode);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(MemoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memo.id != widget.memo.id) {
      _controller.removeListener(_onTextChanged);
      _controller.dispose();
      _controller = TextEditingController(text: widget.memo.content);
      widget.onControllerCreated(_controller);
      _controller.addListener(_onTextChanged);
    } else if (oldWidget.memo.content != widget.memo.content &&
        _controller.text == oldWidget.memo.content) {
      // 親の memo だけが変わったとき（Undo 等）のみ上書き。ユーザーが編集中（_controller がすでに変わっている）なら触らない
      _controller.text = widget.memo.content;
    }
  }

  @override
  void dispose() {
    // 破棄前に未保存の内容を親に渡して保存させる（デバウンス待ちの分が失われないように）
    widget.onWillDispose?.call(widget.memo, _controller.text);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onContentChanged(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final bg = getMemoColor(widget.memo, selected: true);
    final textColor = textColorOnBackground(bg);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        cursorColor: textColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'メモを入力...',
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
    );
  }
}
