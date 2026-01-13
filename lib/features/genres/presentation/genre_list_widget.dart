import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../application/genre_providers.dart';
import '../data/genre_repository_impl.dart';
import '../domain/genre.dart';
import '../../../shared/utils/undo_service.dart';

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
      appBar: AppBar(
        title: const Text('ジャンル'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGenreDialog(context),
            tooltip: 'ジャンルを追加',
          ),
        ],
      ),
      body: genresAsync.when(
        data: (genres) {
          if (genres.isEmpty) {
            return const Center(
              child: Text('＋でジャンルを追加'),
            );
          }

          return ReorderableListView.builder(
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
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
      final repository = ref.read(genreRepositoryProvider);
      await repository.restore(genre);
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
    return ListTile(
      selected: isSelected,
      title: Text(genre.name),
      onTap: onTap,
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('名前を変更'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('削除'),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
      ),
    );
  }
}
