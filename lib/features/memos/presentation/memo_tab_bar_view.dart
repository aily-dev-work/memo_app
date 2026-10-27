import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../application/memo_providers.dart';
import '../data/memo_repository_impl.dart';
import '../domain/memo.dart';
import '../domain/memo_format.dart';
import '../../../shared/theme/app_colors.dart';
import 'checklist_memo_editor.dart';
import 'memo_editor.dart';
import 'table_memo_editor.dart';

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'メモ（タブ）がありません',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.inkSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '右上の「＋」でメモを追加できます',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      children: widget.memos.map((memo) {
        switch (memo.format) {
          case MemoFormat.checklist:
            return ChecklistMemoEditor(
              key: ValueKey('checklist-${memo.id}'),
              memo: memo,
              onContentChanged: (content) =>
                  _handleContentChanged(memo, content),
              onWillDispose: (m, content) {
                _debounceTimers[m.id]?.cancel();
                _debounceTimers.remove(m.id);
                _saveMemo(m, content);
              },
            );
          case MemoFormat.table:
            return TableMemoEditor(
              key: ValueKey('table-${memo.id}'),
              memo: memo,
              onContentChanged: (content) =>
                  _handleContentChanged(memo, content),
              onWillDispose: (m, content) {
                _debounceTimers[m.id]?.cancel();
                _debounceTimers.remove(m.id);
                _saveMemo(m, content);
              },
            );
          case MemoFormat.normal:
            return MemoEditor(
              key: ValueKey('normal-${memo.id}'),
              memo: memo,
              onContentChanged: (content) =>
                  _handleContentChanged(memo, content),
              onControllerCreated: (controller) {
                widget.onContentControllerCreated(memo.id, controller);
              },
              onWillDispose: (m, content) {
                _debounceTimers[m.id]?.cancel();
                _debounceTimers.remove(m.id);
                _saveMemo(m, content);
              },
            );
        }
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
      
      // タイトルが空なら本文の先頭1行をタイトルに（通常メモのみ）
      String title = memo.title;
      if (memo.format == MemoFormat.normal &&
          title.isEmpty &&
          content.isNotEmpty) {
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
