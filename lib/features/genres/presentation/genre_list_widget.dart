import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import '../application/genre_providers.dart';
import '../data/genre_repository_impl.dart';
import '../domain/genre.dart';
import '../../../shared/utils/undo_service.dart';
import '../../../shared/ads/ad_banner_widget.dart';

/// ジャンル一覧ウィジェット
class GenreListWidget extends ConsumerStatefulWidget {
  final void Function(Id genreId) onGenreSelected;
  final Id? selectedGenreId;

  const GenreListWidget({
    super.key,
    required this.onGenreSelected,
    this.selectedGenreId,
  });

  @override
  ConsumerState<GenreListWidget> createState() => _GenreListWidgetState();
}

class _GenreListWidgetState extends ConsumerState<GenreListWidget> {
  @override
  Widget build(BuildContext context) {
    final genresAsync = ref.watch(genresProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFE8E6E1), // グレージュっぽい色
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFE8E6E1), // グレージュっぽい色
        foregroundColor: Colors.grey.shade900,
        title: const Text(
          'LayerMemo',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            fontFamily: 'SF Pro Display',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '設定',
            color: Colors.grey.shade700,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddGenreDialog(context),
            tooltip: 'ジャンルを追加',
            color: Colors.grey.shade700,
          ),
        ],
      ),
      body: genresAsync.when(
        data: (genres) {
          if (genres.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ジャンルがありません',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ジャンルを追加'),
                    onPressed: () => _showAddGenreDialog(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: ReorderableListView.builder(
                    itemCount: genres.length,
                    onReorder: (oldIndex, newIndex) {
                      _handleReorder(genres, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final genre = genres[index];
                      final isSelected = genre.id == widget.selectedGenreId;

                      return _GenreListItem(
                        key: ValueKey(genre.id),
                        genre: genre,
                        isSelected: isSelected,
                        onTap: () => widget.onGenreSelected(genre.id),
                        onEdit: () => _showEditGenreDialog(context, genre),
                        onDelete: () => _showDeleteGenreDialog(context, genre),
                      );
                    },
                  ),
                ),
              ),
              // 広告バナー（編集画面以外）
              const AdBannerWidget(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'エラー: $error',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddGenreDialog(BuildContext context) async {
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
        widget.onGenreSelected(genreId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _showEditGenreDialog(BuildContext context, Genre genre) async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteGenreDialog(BuildContext context, Genre genre) async {
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ジャンルを削除しました'),
              action: SnackBarAction(
                label: '元に戻す',
                onPressed: () => _undoGenreDelete(context, genre),
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

  Future<void> _undoGenreDelete(BuildContext context, Genre genre) async {
    try {
      // 削除時に保存した UndoData.deletedGenre を優先。上書きされていれば閉包の genre を使う。
      final data = ref.read(undoServiceProvider);
      final genreToRestore = data?.deletedGenre ?? genre;

      final repository = ref.read(genreRepositoryProvider);
      await repository.restore(genreToRestore);
      ref.invalidate(genresProvider);
      ref.read(undoServiceProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ジャンルを元に戻しました')),
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

  Future<void> _handleReorder(
    List<Genre> genres,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reordered = List<Genre>.from(genres);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    try {
      final repository = ref.read(genreRepositoryProvider);
      final orderedIds = reordered.map((g) => g.id).toList();
      await repository.updateSortOrder(orderedIds);
      ref.invalidate(genresProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }
}

class _GenreListItem extends StatelessWidget {
  final Genre genre;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GenreListItem({
    super.key,
    required this.genre,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: isSelected 
                  ? Colors.grey.shade300 
                  : Colors.grey.shade200,
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  genre.name,
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: Colors.grey.shade900,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
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
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
