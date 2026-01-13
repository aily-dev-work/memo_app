import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../shared/breakpoints.dart';
import '../../genres/application/genre_providers.dart';
import '../../genres/domain/genre.dart';
import '../application/memo_providers.dart';
import '../data/memo_repository_impl.dart';
import '../domain/memo.dart';
import '../../../shared/utils/undo_service.dart';
import 'memo_tab_bar_view.dart';
import 'memo_search_bar.dart';

/// ジャンル詳細画面（タブ＋本文編集）
class GenreDetailScreen extends ConsumerStatefulWidget {
  final int genreId;

  const GenreDetailScreen({
    super.key,
    required this.genreId,
  });

  @override
  ConsumerState<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends ConsumerState<GenreDetailScreen> {
  final Map<Id, TextEditingController> _contentControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeLastOpenedMemo();
    });
  }

  @override
  void dispose() {
    for (final controller in _contentControllers.values) {
      controller.dispose();
    }
    _contentControllers.clear();
    super.dispose();
  }

  Future<void> _initializeLastOpenedMemo() async {
    if (!mounted) return;
    
    final memosAsync = ref.read(memosByGenreProvider(widget.genreId));
    final memos = memosAsync.value ?? [];
    
    if (!mounted) return;
    
    if (memos.isNotEmpty) {
      // 最後に開いたメモを探す
      Memo? lastOpened;
      for (final memo in memos) {
        if (memo.lastOpenedAt != null) {
          if (lastOpened == null ||
              memo.lastOpenedAt!.isAfter(lastOpened.lastOpenedAt!)) {
            lastOpened = memo;
          }
        }
      }
      
      final targetMemo = lastOpened ?? memos.first;
      if (mounted) {
        ref.read(selectedMemoIdProvider.notifier).state = targetMemo.id;
      }
    }
  }

  int _calculateInitialIndex(List<Memo> memos, Id? selectedMemoId) {
    if (memos.isEmpty) return 0;
    if (selectedMemoId == null) return 0;
    
    final index = memos.indexWhere((m) => m.id == selectedMemoId);
    return index >= 0 ? index.clamp(0, memos.length - 1) : 0;
  }

  void _handleTabChanged(int index, List<Memo> memos) {
    if (!mounted) return;
    if (index >= 0 && index < memos.length) {
      final memo = memos[index];
      ref.read(selectedMemoIdProvider.notifier).state = memo.id;
      _updateLastOpenedAt(memo.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memosAsync = ref.watch(filteredMemosProvider(widget.genreId));
    final selectedMemoId = ref.watch(selectedMemoIdProvider);
    final genreAsync = ref.watch(genresProvider);

    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
          // メモが0件の場合はDefaultTabControllerなしで空状態UIを表示
          return Scaffold(
            appBar: AppBar(
              leading: _shouldShowBackButton(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: genreAsync.when(
                data: (genres) {
                  final genre = genres.firstWhere(
                    (g) => g.id == widget.genreId,
                    orElse: () => genres.first,
                  );
                  return Text(genre.name);
                },
                loading: () => const Text(''),
                error: (_, __) => const Text(''),
              ),
              actions: [
                const MemoSearchBar(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _handleAddMemo(),
                  tooltip: 'メモを追加',
                ),
              ],
            ),
            body: const Center(
              child: Text('＋でメモを追加'),
            ),
          );
        }

        // メモがある場合はDefaultTabControllerでラップ
        final initialIndex = _calculateInitialIndex(memos, selectedMemoId);
        
        return DefaultTabController(
          key: ValueKey(memos.length),
          length: memos.length,
          initialIndex: initialIndex,
          child: _TabControllerWrapper(
            memos: memos,
            selectedMemoId: selectedMemoId,
            genreId: widget.genreId,
            genreAsync: genreAsync,
            contentControllers: _contentControllers,
            onContentControllerCreated: (memoId, controller) {
              _contentControllers[memoId] = controller;
            },
            onTabChanged: _handleTabChanged,
            onAddMemo: _handleAddMemo,
            onShowMemoMenu: _showMemoMenu,
            shouldShowBackButton: _shouldShowBackButton(context),
            onPop: () => context.pop(),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: genreAsync.when(
            data: (genres) {
              final genre = genres.firstWhere(
                (g) => g.id == widget.genreId,
                orElse: () => genres.first,
              );
              return Text(genre.name);
            },
            loading: () => const Text(''),
            error: (_, __) => const Text(''),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: genreAsync.when(
            data: (genres) {
              final genre = genres.firstWhere(
                (g) => g.id == widget.genreId,
                orElse: () => genres.first,
              );
              return Text(genre.name);
            },
            loading: () => const Text(''),
            error: (_, __) => const Text(''),
          ),
        ),
        body: Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }

  bool _shouldShowBackButton(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    return !Breakpoints.shouldShowTwoPane(
      width: width,
      isLandscape: orientation == Orientation.landscape,
    );
  }

  Future<void> _handleAddMemo() async {
    if (!mounted) return;
    
    try {
      final repository = ref.read(memoRepositoryProvider);
      final memoId = await repository.create(
        genreId: widget.genreId,
        title: '',
        content: '',
      );
      
      if (!mounted) return;
      
      ref.invalidate(memosByGenreProvider(widget.genreId));
      ref.invalidate(filteredMemosProvider(widget.genreId));
      ref.read(selectedMemoIdProvider.notifier).state = memoId;
      
      // 新規メモをアクティブにして本文へフォーカス
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = _contentControllers[memoId];
        if (controller != null) {
          // フォーカスはMemoTabBarView内で処理
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _showMemoMenu(BuildContext context, Memo memo) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('タイトルを変更'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'edit') {
      _showEditMemoTitleDialog(context, memo);
    } else if (result == 'delete') {
      _showDeleteMemoDialog(context, memo);
    }
  }

  Future<void> _showEditMemoTitleDialog(BuildContext context, Memo memo) async {
    final controller = TextEditingController(text: memo.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タイトルを変更'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'タイトル',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null) {
      try {
        final repository = ref.read(memoRepositoryProvider);
        await repository.update(memo.copyWith(title: result));
        ref.invalidate(memosByGenreProvider(widget.genreId));
        ref.invalidate(filteredMemosProvider(widget.genreId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteMemoDialog(BuildContext context, Memo memo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      try {
        final repository = ref.read(memoRepositoryProvider);
        final memos = await repository.getByGenreId(widget.genreId);
        final currentIndex = memos.indexWhere((m) => m.id == memo.id);
        
        // Undo用にデータを保存
        ref.read(undoServiceProvider.notifier).state = UndoData(
          deletedMemo: memo,
          genreId: widget.genreId,
        );
        
        await repository.delete(memo.id);
        ref.invalidate(memosByGenreProvider(widget.genreId));
        ref.invalidate(filteredMemosProvider(widget.genreId));
        
        // 削除後の選択メモを決定
        if (memos.length > 1) {
          if (currentIndex < memos.length - 1) {
            ref.read(selectedMemoIdProvider.notifier).state = memos[currentIndex + 1].id;
          } else if (currentIndex > 0) {
            ref.read(selectedMemoIdProvider.notifier).state = memos[currentIndex - 1].id;
          } else {
            ref.read(selectedMemoIdProvider.notifier).state = memos.first.id;
          }
        } else {
          ref.read(selectedMemoIdProvider.notifier).state = null;
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('メモを削除しました'),
              action: SnackBarAction(
                label: '元に戻す',
                onPressed: () => _undoMemoDelete(context, memo),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _undoMemoDelete(BuildContext context, Memo memo) async {
    if (!mounted) return;
    
    try {
      final repository = ref.read(memoRepositoryProvider);
      await repository.restore(memo);
      ref.invalidate(memosByGenreProvider(widget.genreId));
      ref.invalidate(filteredMemosProvider(widget.genreId));
      ref.read(selectedMemoIdProvider.notifier).state = memo.id;
      ref.read(undoServiceProvider.notifier).state = null;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを元に戻しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _updateLastOpenedAt(Id memoId) async {
    if (!mounted) return;
    
    try {
      final repository = ref.read(memoRepositoryProvider);
      await repository.updateLastOpenedAt(memoId);
    } catch (e) {
      // エラーは無視（非同期処理のため）
    }
  }
}

/// TabControllerのラッパー（Builderの代わりにStatefulWidgetを使用）
class _TabControllerWrapper extends StatefulWidget {
  final List<Memo> memos;
  final Id? selectedMemoId;
  final int genreId;
  final AsyncValue<List<Genre>> genreAsync;
  final Map<Id, TextEditingController> contentControllers;
  final void Function(Id memoId, TextEditingController controller)
      onContentControllerCreated;
  final void Function(int index, List<Memo> memos) onTabChanged;
  final VoidCallback onAddMemo;
  final void Function(BuildContext context, Memo memo) onShowMemoMenu;
  final bool shouldShowBackButton;
  final VoidCallback onPop;

  const _TabControllerWrapper({
    required this.memos,
    required this.selectedMemoId,
    required this.genreId,
    required this.genreAsync,
    required this.contentControllers,
    required this.onContentControllerCreated,
    required this.onTabChanged,
    required this.onAddMemo,
    required this.onShowMemoMenu,
    required this.shouldShowBackButton,
    required this.onPop,
  });

  @override
  State<_TabControllerWrapper> createState() => _TabControllerWrapperState();
}

class _TabControllerWrapperState extends State<_TabControllerWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTabController();
    });
  }

  @override
  void didUpdateWidget(_TabControllerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMemoId != widget.selectedMemoId ||
        oldWidget.memos.length != widget.memos.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncTabController();
        }
      });
    }
  }

  void _syncTabController() {
    if (!mounted) return;
    final tabController = DefaultTabController.of(context);
    if (widget.selectedMemoId != null) {
      final index = widget.memos.indexWhere((m) => m.id == widget.selectedMemoId);
      if (index >= 0 && index < widget.memos.length && tabController.index != index) {
        tabController.animateTo(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.shouldShowBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onPop,
              )
            : null,
        title: widget.genreAsync.when(
          data: (genres) {
            final genre = genres.firstWhere(
              (g) => g.id == widget.genreId,
              orElse: () => genres.first,
            );
            return Text(genre.name);
          },
          loading: () => const Text(''),
          error: (_, __) => const Text(''),
        ),
        actions: [
          const MemoSearchBar(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onAddMemo,
            tooltip: 'メモを追加',
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabs: widget.memos.map((memo) => _MemoTab(
            memo: memo,
            onLongPress: () => widget.onShowMemoMenu(context, memo),
          )).toList(),
          onTap: (index) {
            widget.onTabChanged(index, widget.memos);
          },
        ),
      ),
      body: MemoTabBarView(
        genreId: widget.genreId,
        memos: widget.memos,
        selectedMemoId: widget.selectedMemoId,
        contentControllers: widget.contentControllers,
        onContentControllerCreated: widget.onContentControllerCreated,
      ),
    );
  }
}

/// メモタブウィジェット
class _MemoTab extends StatelessWidget {
  final Memo memo;
  final VoidCallback onLongPress;

  const _MemoTab({
    required this.memo,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final title = memo.title.isEmpty
        ? (memo.content.split('\n').isNotEmpty
            ? memo.content.split('\n').first
            : '無題')
        : memo.title;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Tab(
        text: title,
      ),
    );
  }
}