import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../shared/breakpoints.dart';
import '../../genres/application/genre_providers.dart';
import '../../genres/data/genre_repository_impl.dart';
import '../../genres/domain/genre.dart';
import '../application/memo_providers.dart';
import '../data/memo_repository_impl.dart';
import '../domain/memo.dart';
import '../../../shared/utils/color_utils.dart';
import '../../../shared/utils/undo_service.dart';
import '../../../shared/ads/ad_banner_widget.dart';
import 'memo_tab_bar_view.dart';

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
    
    // initState/postFrame内では ref.read を使用（ref.watch禁止）
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
    // build内でのみ ref.watch を使用
    final memosAsync = ref.watch(memosByGenreProvider(widget.genreId));
    final selectedMemoId = ref.watch(selectedMemoIdProvider);
    final genreAsync = ref.watch(genresProvider);

    return memosAsync.when(
      data: (memos) {
        if (memos.isEmpty) {
          // メモが0件の場合はDefaultTabControllerなしで空状態UIを表示
          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: _shouldShowBackButton(context)
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      color: Colors.grey.shade700,
                    )
                  : null,
              title: genreAsync.when(
                data: (genres) {
                  final genre = genres.firstWhere(
                    (g) => g.id == widget.genreId,
                    orElse: () => genres.first,
                  );
                  return Text(
                    genre.name,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  );
                },
                loading: () => const Text(''),
                error: (_, __) => const Text(''),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.grey.shade900,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _handleAddMemo(),
                  tooltip: 'メモを追加',
                  color: Colors.grey.shade700,
                ),
              ],
            ),
            body: const Center(
              child: Text('＋でメモを追加'),
            ),
          );
        }

        // メモがある場合: Scaffold を外側に置き、メモ削除で DefaultTabController が
        // 作り直されても Scaffold が残るようにする（SnackBar「元に戻す」が消えないため）
        final initialIndex = _calculateInitialIndex(memos, selectedMemoId);

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
                  Scaffold.of(ctx).openDrawer();
                },
                color: Colors.grey.shade700,
              ),
            ),
            title: genreAsync.when(
              data: (genres) {
                final genre = genres.firstWhere(
                  (g) => g.id == widget.genreId,
                  orElse: () => genres.first,
                );
                return Text(
                  genre.name,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                );
              },
              loading: () => const Text(''),
              error: (_, __) => const Text(''),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey.shade900,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: '設定',
                color: Colors.grey.shade700,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _handleAddMemo,
                tooltip: 'メモを追加',
                color: Colors.grey.shade700,
              ),
            ],
          ),
          drawer: _GenreDrawer(
            currentGenreId: widget.genreId,
            onGenreSelected: (genreId) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (genreId != widget.genreId) {
                context.push('/genre/$genreId');
              }
            },
          ),
          onDrawerChanged: (isOpened) {
            if (isOpened) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
          body: DefaultTabController(
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
            ),
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
      // まずタブ名称入力ダイアログを表示
      final controller = TextEditingController();
      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('タブの名称を入力'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'タブ名',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('追加'),
            ),
          ],
        ),
      );
      
      // キャンセルまたは空文字の場合は何もしない
      if (!mounted || title == null || title.isEmpty) {
        return;
      }
      
      // 続いてカラー選択ダイアログを表示
      final selectedColor = await showDialog<Color>(
        context: context,
        builder: (context) {
          final colors = <Color>[
            // イエロー系
            const Color(0xFFFFF9C4), // 明るいイエロー
            const Color(0xFFFFF59D), // レモンイエロー
            const Color(0xFFFFF176), // サンイエロー
            const Color(0xFFFFFDE7), // クリーム
            // オレンジ系
            const Color(0xFFFFE0B2), // オレンジ
            const Color(0xFFFFCCBC), // ピーチ
            const Color(0xFFFFE5B4), // アプリコット
            // ピンク系
            const Color(0xFFFFCDD2), // ピンク
            const Color(0xFFF8BBD0), // ローズピンク
            const Color(0xFFFFE1F5), // ライトピンク
            // パープル系
            const Color(0xFFD1C4E9), // パープル
            const Color(0xFFE1BEE7), // ラベンダー
            const Color(0xFFF3E5F5), // ライトパープル
            // ブルー系
            const Color(0xFFB3E5FC), // 水色
            const Color(0xFFBBDEFB), // スカイブルー
            const Color(0xFFC5CAE9), // ペールブルー
            const Color(0xFFE3F2FD), // ライトブルー
            // グリーン系
            const Color(0xFFC8E6C9), // グリーン
            const Color(0xFFDCEDC8), // ライムグリーン
            const Color(0xFFE8F5E9), // ミントグリーン
            // クールな色（男性向け）
            const Color(0xFF90CAF9), // コバルトブルー
            const Color(0xFF64B5F6), // ブライトブルー
            const Color(0xFF81C784), // エメラルドグリーン
            const Color(0xFFA5D6A7), // セージグリーン
            const Color(0xFFB0BEC5), // スレートグレー
            const Color(0xFF90A4AE), // ブルーグレー
            const Color(0xFF78909C), // チャコールグレー
            const Color(0xFF9E9E9E), // ミディアムグレー
            const Color(0xFF607D8B), // ブルーグレー（ダーク）
            const Color(0xFF546E7A), // スチールブルー
            const Color(0xFF455A64), // ダークスレート
            const Color(0xFF37474F), // ダークブルーグレー
            // その他
            const Color(0xFFCFD8DC), // ブルーグレー
            const Color(0xFFE0E0E0), // ライトグレー
            const Color(0xFFFFF3E0), // ベージュ
          ];
          return AlertDialog(
            title: const Text('カラーを選択'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: colors.map((color) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      );
      
      // カラー未選択の場合はデフォルトカラーを使用
      final colorToSave = selectedColor ?? const Color(0xFFFFF9C4);
      
      // 色の値をそのまま保存（Color.valueは既に0xAARRGGBB形式）
      final colorValue = colorToSave.value;
      
      // 非同期処理では ref.read を使用
      final repository = ref.read(memoRepositoryProvider);
      final memoId = await repository.create(
        genreId: widget.genreId,
        title: title,
        content: '',
        colorValue: colorValue,
      );
      
      if (!mounted) return;
      
      ref.invalidate(memosByGenreProvider(widget.genreId));
      ref.read(selectedMemoIdProvider.notifier).state = memoId;
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
        // 非同期処理では ref.read を使用
        final repository = ref.read(memoRepositoryProvider);
        await repository.update(memo.copyWith(title: result));
        ref.invalidate(memosByGenreProvider(widget.genreId));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteMemoDialog(BuildContext dialogContext, Memo memo) async {
    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('メモを削除'),
        content: const Text('このメモを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

        ref.read(undoServiceProvider.notifier).state = UndoData(
          deletedMemo: memo,
          genreId: widget.genreId,
        );

        await repository.delete(memo.id);
        ref.invalidate(memosByGenreProvider(widget.genreId));

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

        // SnackBar は State の context で表示（invalidate で DefaultTabController が作り直され
        // 子の Scaffold が dispose されるため、親の ScaffoldMessenger に出す必要がある）
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
      // 削除時に保存した UndoData.deletedMemo / genreId を優先。上書きされていれば閉包の memo / widget.genreId を使う。
      final data = ref.read(undoServiceProvider);
      final memoToRestore = data?.deletedMemo ?? memo;
      final genreId = data?.genreId ?? widget.genreId;

      final repository = ref.read(memoRepositoryProvider);
      await repository.restore(memoToRestore);
      ref.invalidate(memosByGenreProvider(genreId));
      ref.read(selectedMemoIdProvider.notifier).state = memoToRestore.id;
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
      // 非同期処理では ref.read を使用
      final repository = ref.read(memoRepositoryProvider);
      await repository.updateLastOpenedAt(memoId);
    } catch (e) {
      // エラーは無視（非同期処理のため）
    }
  }
}

/// TabControllerのラッパー（DefaultTabControllerの子として使用）
/// 
/// このWidgetは以下の条件で再構築される：
/// - memos.length が変わったとき（DefaultTabControllerがValueKeyで再作成される）
/// - selectedMemoId が変わったとき（didUpdateWidgetで検知）
/// - memos の内容が変わったとき（親のbuildで検知）
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
  });

  @override
  State<_TabControllerWrapper> createState() => _TabControllerWrapperState();
}

class _TabControllerWrapperState extends State<_TabControllerWrapper> {
  // 前回のselectedMemoIdを保持（didUpdateWidgetで変更検知用）
  Id? _previousSelectedMemoId;
  TabController? _tabController;
  VoidCallback? _tabControllerListener;

  @override
  void initState() {
    super.initState();
    _previousSelectedMemoId = widget.selectedMemoId;
    
    // initState後のpostFrameで初期同期
    // 条件: 初回構築時のみ実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncTabController();
      _setupTabControllerListener();
    });
  }

  @override
  void didUpdateWidget(_TabControllerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // _syncTabController が走る条件:
    // 1. selectedMemoId が変わったとき（タブを切り替える必要がある）
    // 2. memos.length が変わったときは DefaultTabController が再作成されるため、
    //    このWidget自体が再構築される（initStateが呼ばれる）のでここでは処理しない
    final selectedMemoIdChanged = oldWidget.selectedMemoId != widget.selectedMemoId;
    
    if (selectedMemoIdChanged) {
      _previousSelectedMemoId = widget.selectedMemoId;
      // タブ切り替え時にSnackBarを消す
      _hideSnackBar();
      // postFrameで実行（build中にTabControllerを操作しない）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncTabController();
      });
    }
  }

  /// TabControllerのリスナーを設定（タブ切り替え時にSnackBarを消す）
  void _setupTabControllerListener() {
    if (!mounted) return;
    
    try {
      final tabController = DefaultTabController.of(context);
      if (tabController == _tabController) return; // 既に設定済み
      
      // 前のリスナーを削除
      if (_tabController != null && _tabControllerListener != null) {
        _tabController!.removeListener(_tabControllerListener!);
      }
      
      _tabController = tabController;
      int? previousIndex = tabController.index;
      _tabControllerListener = () {
        // タブが実際に切り替わった時のみSnackBarを消す
        if (tabController.index != previousIndex) {
          previousIndex = tabController.index;
          _hideSnackBar();
        }
      };
      tabController.addListener(_tabControllerListener!);
    } catch (e) {
      // DefaultTabControllerが見つからない場合は無視
    }
  }

  /// SnackBarを非表示にする
  void _hideSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  void dispose() {
    // リスナーを削除
    if (_tabController != null && _tabControllerListener != null) {
      _tabController!.removeListener(_tabControllerListener!);
    }
    super.dispose();
  }

  /// TabControllerを選択されたメモに同期
  /// 
  /// 実行条件:
  /// - initState後のpostFrame（初回構築時）
  /// - didUpdateWidgetでselectedMemoIdが変わったときのpostFrame
  /// 
  /// 注意: build内では呼ばない（TabController操作はpostFrameで行う）
  void _syncTabController() {
    if (!mounted) return;
    
    try {
      final tabController = DefaultTabController.of(context);
      if (!mounted) return;
      
      // TabControllerが変わった場合はリスナーを再設定
      if (tabController != _tabController) {
        _setupTabControllerListener();
      }
      
      if (widget.selectedMemoId != null) {
        final index = widget.memos.indexWhere((m) => m.id == widget.selectedMemoId);
        if (index >= 0 && index < widget.memos.length) {
          // TabControllerのindexが現在の選択と異なる場合のみ同期
          if (tabController.index != index) {
            tabController.animateTo(index);
          }
        }
      }
    } catch (e) {
      // DefaultTabControllerが見つからない場合（Widgetツリー外など）は無視
      // mountedチェックでdispose後の操作は防げるが、念のためtry-catch
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold は親（GenreDetailScreen）に移した。ここは body の Column のみ。
    // メモ削除で DefaultTabController が作り直されても親 Scaffold は残り、SnackBar が消えない。
    return Builder(
      builder: (context) {
        final tabController = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            final selectedIndex = tabController.index;
            final selectedMemo = selectedIndex >= 0 && selectedIndex < widget.memos.length
                ? widget.memos[selectedIndex]
                : null;
            final selectedColor = selectedMemo != null
                ? (selectedMemo.colorValue != null
                    ? Color(selectedMemo.colorValue!)
                    : getMemoColor(selectedMemo, selected: true))
                : Colors.white;

            return Column(
              children: [
                _CustomTabBar(
                  memos: widget.memos,
                  selectedMemoId: widget.selectedMemoId,
                  onTabChanged: (index) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    widget.onTabChanged(index, widget.memos);
                  },
                  onLongPress: (memo) {
                    widget.onShowMemoMenu(context, memo);
                  },
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: MemoTabBarView(
                        genreId: widget.genreId,
                        memos: widget.memos,
                        selectedMemoId: widget.selectedMemoId,
                        contentControllers: widget.contentControllers,
                        onContentControllerCreated: widget.onContentControllerCreated,
                      ),
                    ),
                  ),
                ),
                const AdBannerWidget(),
              ],
            );
          },
        );
      },
    );
  }
}

/// カスタムタブバー（各タブに色を付ける）
class _CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Memo> memos;
  final Id? selectedMemoId;
  final void Function(int index) onTabChanged;
  final void Function(Memo memo) onLongPress;

  const _CustomTabBar({
    required this.memos,
    required this.selectedMemoId,
    required this.onTabChanged,
    required this.onLongPress,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);
    
    // TabControllerの変更を監視
    return _ScrollableTabBar(
      tabController: tabController,
      memos: memos,
      onTabChanged: onTabChanged,
      onLongPress: onLongPress,
    );
  }
}

/// 選択タブを左端にスクロールするための内部ウィジェット
class _ScrollableTabBar extends StatefulWidget {
  final TabController tabController;
  final List<Memo> memos;
  final void Function(int index) onTabChanged;
  final void Function(Memo memo) onLongPress;

  const _ScrollableTabBar({
    required this.tabController,
    required this.memos,
    required this.onTabChanged,
    required this.onLongPress,
  });

  @override
  State<_ScrollableTabBar> createState() => _ScrollableTabBarState();
}

class _ScrollableTabBarState extends State<_ScrollableTabBar> {
  final ScrollController _scrollController = ScrollController();
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.tabController.index;
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    const estimatedTabWidth = 160.0 + 12.0; // タブ最大幅＋左右マージンのざっくりした幅
    final target = (index * estimatedTabWidth)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tabController,
      builder: (context, child) {
        final currentIndex = widget.tabController.index;
        if (currentIndex != _lastIndex) {
          _lastIndex = currentIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToIndex(currentIndex);
          });
        }

        return Container(
          height: 60.0, // タブバーの高さを少し高めにしてテキストの余白を確保
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade100,
                width: 1.0,
              ),
            ),
          ),
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemExtent: null,
            itemCount: widget.memos.length,
            itemBuilder: (context, index) {
              final memo = widget.memos[index];
              final isSelected = widget.tabController.index == index;
              return _MemoTab(
                memo: memo,
                isSelected: isSelected,
                onTap: () => widget.onTabChanged(index),
                onLongPress: () => widget.onLongPress(memo),
              );
            },
          ),
        );
      },
    );
  }
}

/// メモタブウィジェット
class _MemoTab extends StatelessWidget {
  final Memo memo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MemoTab({
    required this.memo,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final title = memo.title.isEmpty
        ? (memo.content.split('\n').isNotEmpty
            ? memo.content.split('\n').first
            : '無題')
        : memo.title;

    // 選択時は濃い色、非選択時は淡い色（メモ）
    final backgroundColor = getMemoColor(memo, selected: isSelected);
    // 淡い色なら黒、濃い色なら白
    final textColor = textColorOnBackground(backgroundColor);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(
          minWidth: 80.0, // タブの最小幅を統一（小さく）
          maxWidth: 160.0, // タブの最大幅を設定（少し広げる）
        ),
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// ジャンル一覧Drawer
class _GenreDrawer extends ConsumerWidget {
  final Id currentGenreId;
  final void Function(Id genreId) onGenreSelected;

  const _GenreDrawer({
    required this.currentGenreId,
    required this.onGenreSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: Colors.grey.shade800, // 落ち着いたグレー色
      child: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Text(
                    'LayerMemo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white54, height: 1),
            // ホームボタン
            _HomeButtonInDrawer(),
            const Divider(color: Colors.white54, height: 1),
            // ジャンル一覧
            Expanded(
              child: genresAsync.when(
                data: (genres) {
                  if (genres.isEmpty) {
                    return const Center(
                      child: Text(
                        'ジャンルがありません',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: genres.length,
                    itemBuilder: (context, index) {
                      final genre = genres[index];
                      final isSelected = genre.id == currentGenreId;
                      return _GenreDrawerItem(
                        genre: genre,
                        isSelected: isSelected,
                        onTap: () => onGenreSelected(genre.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    'エラー: $error',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddGenreDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ジャンルを追加'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ジャンル名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final repository = ref.read(genreRepositoryProvider);
        final genreId = await repository.create(result);
        ref.invalidate(genresProvider);
        onGenreSelected(genreId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }
}

/// Drawer内のジャンルアイテム
class _GenreDrawerItem extends StatelessWidget {
  final Genre genre;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreDrawerItem({
    required this.genre,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.zero,
      ),
      child: ListTile(
        title: Text(
          genre.name,
          style: TextStyle(
            color: isSelected ? Colors.grey.shade900 : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16.0,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Drawer内のホームボタン
class _HomeButtonInDrawer extends StatelessWidget {
  const _HomeButtonInDrawer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
      ),
      child: ListTile(
        leading: const Icon(Icons.home_outlined, color: Colors.white, size: 24),
        title: const Text(
          'ホーム',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Drawerを閉じる
          context.go('/'); // ジャンル一覧画面に遷移
        },
      ),
    );
  }
}

