import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../shared/data/isar_service.dart';
import '../domain/memo.dart';
import 'memo_repository.dart';

/// Memoリポジトリの実装
class MemoRepository {
  final Isar _isar;

  MemoRepository(this._isar);

  /// 指定ジャンルの全メモを取得（sortOrder順）
  Future<List<Memo>> getByGenreId(int genreId) async {
    final schemas = await _isar.memoSchemas
        .filter()
        .genreIdEqualTo(genreId)
        .sortBySortOrder()
        .findAll();
    final memos = schemas.map((s) => s.toDomain()).toList();
    return memos;
  }

  /// IDでメモを取得
  Future<Memo?> getById(Id id) async {
    final schema = await _isar.memoSchemas.get(id);
    return schema?.toDomain();
  }

  /// メモを追加
  Future<Id> create({
    required int genreId,
    required String title,
    required String content,
    int? colorValue,
  }) async {
    final now = DateTime.now();
    final memos = await getByGenreId(genreId);
    final maxSortOrder = memos.isEmpty
        ? 0
        : memos.map((m) => m.sortOrder).reduce((a, b) => a > b ? a : b);

    final schema = MemoSchema()
      ..genreId = genreId
      ..title = title
      ..content = content
      ..sortOrder = maxSortOrder + 1
      ..createdAt = now
      ..updatedAt = now
      ..lastOpenedAt = now
      ..colorValue = colorValue;

    await _isar.writeTxn(() async {
      await _isar.memoSchemas.put(schema);
    });

    return schema.id;
  }

  /// メモを更新
  Future<void> update(Memo memo) async {
    final schema = MemoSchema.fromDomain(
      memo.copyWith(updatedAt: DateTime.now()),
    );
    await _isar.writeTxn(() async {
      await _isar.memoSchemas.put(schema);
    });
  }

  /// メモを復元（Undo用）
  Future<void> restore(Memo memo) async {
    final schema = MemoSchema.fromDomain(memo);
    await _isar.writeTxn(() async {
      await _isar.memoSchemas.put(schema);
    });
  }

  /// メモを削除
  Future<void> delete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.memoSchemas.delete(id);
    });
  }

  /// 並び替えを更新
  Future<void> updateSortOrder(int genreId, List<Id> orderedIds) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        final schema = await _isar.memoSchemas.get(orderedIds[i]);
        if (schema != null && schema.genreId == genreId) {
          schema.sortOrder = i;
          await _isar.memoSchemas.put(schema);
        }
      }
    });
  }

  /// lastOpenedAtを更新
  Future<void> updateLastOpenedAt(Id id) async {
    final schema = await _isar.memoSchemas.get(id);
    if (schema != null) {
      schema.lastOpenedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.memoSchemas.put(schema);
      });
    }
  }

  /// ジャンル内で検索
  Future<List<Memo>> search(int genreId, String query) async {
    if (query.isEmpty) {
      return getByGenreId(genreId);
    }

    final lowerQuery = query.toLowerCase();
    final allMemos = await getByGenreId(genreId);
    return allMemos.where((memo) {
      return memo.title.toLowerCase().contains(lowerQuery) ||
          memo.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

/// MemoRepositoryのProvider
final memoRepositoryProvider = Provider<MemoRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return MemoRepository(isar);
});
