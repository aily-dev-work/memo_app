import 'package:flutter/material.dart';
import '../domain/memo.dart';

/// メモ本文エディタ
class MemoEditor extends StatefulWidget {
  final Memo memo;
  final void Function(String content) onContentChanged;
  final void Function(TextEditingController controller) onControllerCreated;
  final void Function(FocusNode focusNode)? onFocusNodeCreated;

  const MemoEditor({
    super.key,
    required this.memo,
    required this.onContentChanged,
    required this.onControllerCreated,
    this.onFocusNodeCreated,
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
    } else if (oldWidget.memo.content != widget.memo.content) {
      _controller.text = widget.memo.content;
    }
  }

  @override
  void dispose() {
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'メモを入力...',
        ),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
