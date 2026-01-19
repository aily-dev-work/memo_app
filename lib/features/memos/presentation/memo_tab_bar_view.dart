import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../application/memo_providers.dart';
import '../data/memo_repository_impl.dart';
import '../domain/memo.dart';
import 'memo_editor.dart';

/// メモのTabBarView
class MemoTabBarView extends ConsumerStatefulWidget {
  final int genreId;
  final List<Memo> memos;
  final Id? selectedMemoId;
  final Map<Id, TextEditingController> contentControllers;
  final void Function(Id memoId, TextEditingController controller)
      onContentControllerCreated;

  const MemoTabBarView({
    super.key,
    required this.genreId,
    required this.memos,
    required this.selectedMemoId,
    required this.contentControllers,
    required this.onContentControllerCreated,
  });

  @override
  ConsumerState<MemoTabBarView> createState() => _MemoTabBarViewState();
}

class _MemoTabBarViewState extends ConsumerState<MemoTabBarView> {
  final Map<Id, Timer> _debounceTimers = {};

  @override
  void dispose() {
    // デバウンス待ちの残りがあれば、dispose 時に controller は子が先に破棄されるため
    // ここではタイマーをキャンセルするのみ。保存は MemoEditor.onWillDispose で行う。
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.memos.isEmpty) {
      return const Center(
        child: Text('＋でメモを追加'),
      );
    }

    return TabBarView(
      children: widget.memos.map((memo) {
        return MemoEditor(
          key: ValueKey(memo.id),
          memo: memo,
          onContentChanged: (content) => _handleContentChanged(memo, content),
          onControllerCreated: (controller) {
            widget.onContentControllerCreated(memo.id, controller);
          },
          onWillDispose: (m, content) {
            _debounceTimers[m.id]?.cancel();
            _debounceTimers.remove(m.id);
            _saveMemo(m, content);
          },
        );
      }).toList(),
    );
  }

  void _handleContentChanged(Memo memo, String content) {
    // 既存のタイマーをキャンセル
    final existingTimer = _debounceTimers[memo.id];
    existingTimer?.cancel();

    // 新しいタイマーを設定（300msデバウンス）
    final timer = Timer(const Duration(milliseconds: 300), () {
      _saveMemo(memo, content);
    });
    _debounceTimers[memo.id] = timer;
  }

  Future<void> _saveMemo(Memo memo, String content) async {
    try {
      final repository = ref.read(memoRepositoryProvider);
      
      // タイトルが空なら本文の先頭1行をタイトルに
      String title = memo.title;
      if (title.isEmpty && content.isNotEmpty) {
        title = content.split('\n').first.trim();
        if (title.isEmpty) {
          title = '無題';
        }
      }

      await repository.update(
        memo.copyWith(
          title: title,
          content: content,
        ),
      );

      // 保存のたびに一覧を無効化し、DB から再取得させる（本文のみの変更でも古いキャッシュで上書きされないように）
      ref.invalidate(memosByGenreProvider(widget.genreId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存エラー: $e')),
        );
      }
    }
  }
}
