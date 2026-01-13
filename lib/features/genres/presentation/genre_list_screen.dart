import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../../../shared/breakpoints.dart';
import '../../../shared/utils/undo_service.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (isOpen) ...[
                  Expanded(
                    child: Text(
                      'Genres',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(isOpen ? Icons.chevron_left : Icons.menu),
                  onPressed: () {
                    ref.read(sidebarOpenProvider.notifier).state = !isOpen;
                  },
                  tooltip: isOpen ? 'サイドバーを閉じる' : 'サイドバーを開く',
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
      final repository = ref.read(genreRepositoryProvider);
      await repository.restore(genre);
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
    final firstChar = genre.name.isNotEmpty ? genre.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isOpen ? 12 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isOpen
                ? Row(
                    children: [
                      // アイコン（頭文字）
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            firstChar,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          genre.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // メニューボタン
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 20,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('名前を変更'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          firstChar,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isOpen ? 12 : 0,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isOpen
                ? Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'ジャンルを追加',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(
                      Icons.add,
                      size: 24,
                      color: colorScheme.primary,
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
        final genreId = await repository.create(result);
        ref.invalidate(genresProvider);
        // 追加したジャンルを選択
        ref.read(selectedGenreIdProvider.notifier).state = genreId;
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
