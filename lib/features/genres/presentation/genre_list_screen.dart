import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../shared/breakpoints.dart';
import '../../../shared/utils/undo_service.dart';
import '../../../shared/ads/ad_banner_widget.dart';
import '../application/genre_providers.dart';
import '../data/genre_repository_impl.dart';
import '../domain/genre.dart';
import 'genre_list_widget.dart';
import '../../memos/presentation/genre_detail_screen.dart';

/// ジャンル一覧画面（1ペイン/2ペイン対応）
class GenreListScreen extends ConsumerStatefulWidget {
  const GenreListScreen({super.key});

  @override
  ConsumerState<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends ConsumerState<GenreListScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    final isTwoPane = Breakpoints.shouldShowTwoPane(
      width: width,
      isLandscape: orientation == Orientation.landscape,
    );

    final selectedGenreId = ref.watch(selectedGenreIdProvider);

    if (isTwoPane) {
      // 2ペイン表示：Collapsible Sidebar付き
      return Scaffold(
        body: Row(
          children: [
            // 左ペイン：Collapsible Sidebar
            _CollapsibleSidebar(
              onGenreSelected: (genreId) {
                ref.read(selectedGenreIdProvider.notifier).state = genreId;
              },
              selectedGenreId: selectedGenreId,
            ),
            // 右ペイン：選択ジャンルの詳細
            Expanded(
              child: selectedGenreId != null
                  ? GenreDetailScreen(genreId: selectedGenreId)
                  : const Center(
                      child: Text('ジャンルを選択してください'),
                    ),
            ),
          ],
        ),
      );
    } else {
      // 1ペイン表示：従来通り遷移
      return GenreListWidget(
        onGenreSelected: (genreId) {
          context.push('/genre/$genreId');
        },
        selectedGenreId: null,
      );
    }
  }
}

/// Collapsible Sidebar（2ペイン時用）
class _CollapsibleSidebar extends ConsumerStatefulWidget {
  final void Function(Id genreId) onGenreSelected;
  final Id? selectedGenreId;

  const _CollapsibleSidebar({
    required this.onGenreSelected,
    required this.selectedGenreId,
  });

  @override
  ConsumerState<_CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends ConsumerState<_CollapsibleSidebar> {
  @override
  Widget build(BuildContext context) {
    final isOpen = ref.watch(sidebarOpenProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isOpen ? 280.0 : 72.0,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ヘッダー（開閉ボタン）
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (isOpen) ...[
                  Expanded(
                    child: Text(
                      'LayerMemo',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isOpen ? Icons.chevron_left : Icons.menu,
                    size: 24,
                  ),
                  onPressed: () {
                    ref.read(sidebarOpenProvider.notifier).state = !isOpen;
                  },
                  tooltip: isOpen ? 'サイドバーを閉じる' : 'サイドバーを開く',
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ジャンル一覧
          Expanded(
            child: _SidebarGenreList(
              isOpen: isOpen,
              onGenreSelected: widget.onGenreSelected,
              selectedGenreId: widget.selectedGenreId,
            ),
          ),
        ],
      ),
    );
  }
}

/// サイドバー内のジャンル一覧
class _SidebarGenreList extends ConsumerWidget {
  final bool isOpen;
  final void Function(Id genreId) onGenreSelected;
  final Id? selectedGenreId;

  const _SidebarGenreList({
    required this.isOpen,
    required this.onGenreSelected,
    required this.selectedGenreId,
  });

  Future<void> _showEditGenreDialog(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    final controller = TextEditingController(text: genre.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ジャンル名を変更'),
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
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final repository = ref.read(genreRepositoryProvider);
        await repository.update(genre.copyWith(name: result));
        ref.invalidate(genresProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteGenreDialog(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ジャンルを削除'),
        content: Text('「${genre.name}」を削除しますか？'),
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

    if (result == true) {
      try {
        final repository = ref.read(genreRepositoryProvider);
        
        // Undo用にデータを保存
        ref.read(undoServiceProvider.notifier).state = UndoData(
          deletedGenre: genre,
        );
        
        await repository.delete(genre.id);
        ref.invalidate(genresProvider);
        
        // 削除されたジャンルが選択されていた場合、選択を解除
        final selectedId = ref.read(selectedGenreIdProvider);
        if (selectedId == genre.id) {
          ref.read(selectedGenreIdProvider.notifier).state = null;
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ジャンルを削除しました'),
              action: SnackBarAction(
                label: '元に戻す',
                onPressed: () => _undoGenreDelete(context, ref, genre),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _undoGenreDelete(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    try {
      // 削除時に保存した UndoData.deletedGenre を優先。上書きされていれば閉包の genre を使う。
      final data = ref.read(undoServiceProvider);
      final genreToRestore = data?.deletedGenre ?? genre;

      final repository = ref.read(genreRepositoryProvider);
      await repository.restore(genreToRestore);
      ref.invalidate(genresProvider);
      ref.read(undoServiceProvider.notifier).state = null;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ジャンルを元に戻しました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return genresAsync.when(
      data: (genres) {
        if (genres.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isOpen ? '＋でジャンルを追加' : '+',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: genres.length + 1, // +1 for add button
          itemBuilder: (context, index) {
            if (index == 0) {
              // 追加ボタン
              return _AddGenreButton(isOpen: isOpen);
            }
            
            final genre = genres[index - 1];
            final isSelected = genre.id == selectedGenreId;

            return _SidebarGenreItem(
              key: ValueKey(genre.id),
              genre: genre,
              isSelected: isSelected,
              isOpen: isOpen,
              onTap: () => onGenreSelected(genre.id),
              onEdit: () => _showEditGenreDialog(context, ref, genre),
              onDelete: () => _showDeleteGenreDialog(context, ref, genre),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'エラー: $error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}

/// サイドバー内のジャンルアイテム
class _SidebarGenreItem extends ConsumerWidget {
  final Genre genre;
  final bool isSelected;
  final bool isOpen;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SidebarGenreItem({
    super.key,
    required this.genre,
    required this.isSelected,
    required this.isOpen,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isOpen ? 16 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.grey.shade100
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: isOpen
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          genre.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // メニューボタン
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 12),
                                Text('名前を変更'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('削除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.grey.shade200
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Icon(
                        Icons.folder_outlined,
                        size: 18,
                        color: isSelected
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// ジャンル追加ボタン
class _AddGenreButton extends ConsumerWidget {
  final bool isOpen;

  const _AddGenreButton({required this.isOpen});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddGenreDialog(context, ref),
          borderRadius: BorderRadius.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isOpen ? 12 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: isOpen
                ? Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ジャンルを追加',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 22,
                      color: Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddGenreDialog(BuildContext context, WidgetRef ref) async {
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
        await repository.create(result);
        ref.invalidate(genresProvider);
        // ジャンルトップ（一覧）に留まる。追加したジャンルへは飛ばない。
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
