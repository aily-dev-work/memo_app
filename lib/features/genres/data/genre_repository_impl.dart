import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../shared/data/isar_service.dart';
import '../domain/genre.dart';
import 'genre_repository.dart';

/// Genreリポジトリの実装
class GenreRepository {
  final Isar _isar;

  GenreRepository(this._isar);

  /// 全ジャンルを取得（sortOrder順）
  Future<List<Genre>> getAll() async {
    final schemas = await _isar.genreSchemas
        .where()
        .sortBySortOrder()
        .findAll();
    return schemas.map((s) => s.toDomain()).toList();
  }

  /// IDでジャンルを取得
  Future<Genre?> getById(Id id) async {
    final schema = await _isar.genreSchemas.get(id);
    return schema?.toDomain();
  }

  /// ジャンルを追加
  Future<Id> create(String name) async {
    final now = DateTime.now();
    final genres = await getAll();
    final maxSortOrder = genres.isEmpty
        ? 0
        : genres.map((g) => g.sortOrder).reduce((a, b) => a > b ? a : b);

    final schema = GenreSchema()
      ..name = name
      ..sortOrder = maxSortOrder + 1
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.genreSchemas.put(schema);
    });

    return schema.id;
  }

  /// ジャンルを更新
  Future<void> update(Genre genre) async {
    final schema = GenreSchema.fromDomain(
      genre.copyWith(updatedAt: DateTime.now()),
    );
    await _isar.writeTxn(() async {
      await _isar.genreSchemas.put(schema);
    });
  }

  /// ジャンルを復元（Undo用）
  ///
  /// sortOrder は既存の最大値+1にし、並び替え後のリストとの衝突を防ぐ。
  Future<void> restore(Genre genre) async {
    final all = await getAll();
    final maxOrder = all.isEmpty
        ? 0
        : all.map((g) => g.sortOrder).reduce((a, b) => a > b ? a : b);
    final toPut = genre.copyWith(sortOrder: maxOrder + 1);
    final schema = GenreSchema.fromDomain(toPut);
    await _isar.writeTxn(() async {
      await _isar.genreSchemas.put(schema);
    });
  }

  /// ジャンルを削除
  Future<void> delete(Id id) async {
    await _isar.writeTxn(() async {
      await _isar.genreSchemas.delete(id);
    });
  }

  /// 並び替えを更新
  Future<void> updateSortOrder(List<Id> orderedIds) async {
    await _isar.writeTxn(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        final schema = await _isar.genreSchemas.get(orderedIds[i]);
        if (schema != null) {
          schema.sortOrder = i;
          await _isar.genreSchemas.put(schema);
        }
      }
    });
  }
}

/// GenreRepositoryのProvider
final genreRepositoryProvider = Provider<GenreRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return GenreRepository(isar);
});
