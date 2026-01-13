import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:memo_app/features/genres/data/genre_repository.dart';
import 'package:memo_app/features/genres/data/genre_repository_impl.dart';

void main() {
  late Isar isar;
  late GenreRepository repository;

  setUpAll(() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        GenreSchemaSchema,
      ],
      directory: dir.path,
      name: 'test',
    );
    repository = GenreRepository(isar);
  });

  tearDownAll(() async {
    await isar.clear();
    await isar.close(deleteFromDisk: true);
  });

  test('ジャンルのCRUD操作', () async {
    // Create
    final genreId = await repository.create('テストジャンル');
    expect(genreId, isNotNull);

    // Read
    final genre = await repository.getById(genreId);
    expect(genre, isNotNull);
    expect(genre!.name, 'テストジャンル');

    // Update
    final updatedGenre = genre.copyWith(name: '更新されたジャンル');
    await repository.update(updatedGenre);
    final fetchedGenre = await repository.getById(genreId);
    expect(fetchedGenre!.name, '更新されたジャンル');

    // Delete
    await repository.delete(genreId);
    final deletedGenre = await repository.getById(genreId);
    expect(deletedGenre, isNull);
  });
}
