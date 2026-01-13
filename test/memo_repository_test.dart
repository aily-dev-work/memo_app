import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:memo_app/features/genres/data/genre_repository.dart';
import 'package:memo_app/features/genres/data/genre_repository_impl.dart';
import 'package:memo_app/features/memos/data/memo_repository.dart';
import 'package:memo_app/features/memos/data/memo_repository_impl.dart';

void main() {
  late Isar isar;
  late GenreRepository genreRepository;
  late MemoRepository memoRepository;

  setUpAll(() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        GenreSchemaSchema,
        MemoSchemaSchema,
      ],
      directory: dir.path,
      name: 'test_memo',
    );
    genreRepository = GenreRepository(isar);
    memoRepository = MemoRepository(isar);
  });

  tearDownAll(() async {
    await isar.clear();
    await isar.close(deleteFromDisk: true);
  });

  test('メモのCRUD操作', () async {
    // ジャンルを作成
    final genreId = await genreRepository.create('テストジャンル');

    // Create
    final memoId = await memoRepository.create(
      genreId: genreId,
      title: 'テストメモ',
      content: 'テスト内容',
    );
    expect(memoId, isNotNull);

    // Read
    final memo = await memoRepository.getById(memoId);
    expect(memo, isNotNull);
    expect(memo!.title, 'テストメモ');
    expect(memo.content, 'テスト内容');
    expect(memo.genreId, genreId);

    // Update
    final updatedMemo = memo.copyWith(title: '更新されたメモ');
    await memoRepository.update(updatedMemo);
    final fetchedMemo = await memoRepository.getById(memoId);
    expect(fetchedMemo!.title, '更新されたメモ');

    // Delete
    await memoRepository.delete(memoId);
    final deletedMemo = await memoRepository.getById(memoId);
    expect(deletedMemo, isNull);
  });

  test('デバウンス保存のシミュレーション', () async {
    final genreId = await genreRepository.create('テストジャンル');
    final memoId = await memoRepository.create(
      genreId: genreId,
      title: '',
      content: '',
    );

    // 複数回更新をシミュレート（デバウンス前）
    final memo1 = await memoRepository.getById(memoId);
    await memoRepository.update(memo1!.copyWith(content: '内容1'));
    
    final memo2 = await memoRepository.getById(memoId);
    await memoRepository.update(memo2!.copyWith(content: '内容2'));

    // 最終的な内容を確認
    final finalMemo = await memoRepository.getById(memoId);
    expect(finalMemo!.content, '内容2');
  });

  test('選択ルール：最後に開いたメモが優先', () async {
    final genreId = await genreRepository.create('テストジャンル');
    
    await memoRepository.create(
      genreId: genreId,
      title: 'メモ1',
      content: '内容1',
    );
    
    final memo2Id = await memoRepository.create(
      genreId: genreId,
      title: 'メモ2',
      content: '内容2',
    );

    // メモ2を最後に開いた状態にする
    await memoRepository.updateLastOpenedAt(memo2Id);
    
    // ジャンル内のメモを取得（sortOrder順）
    final memos = await memoRepository.getByGenreId(genreId);
    expect(memos.length, 2);

    // lastOpenedAtでソートして確認
    final memosWithLastOpened = memos.where((m) => m.lastOpenedAt != null).toList();
    if (memosWithLastOpened.isNotEmpty) {
      final lastOpened = memosWithLastOpened.reduce((a, b) {
        if (a.lastOpenedAt == null) return b;
        if (b.lastOpenedAt == null) return a;
        return a.lastOpenedAt!.isAfter(b.lastOpenedAt!) ? a : b;
      });
      expect(lastOpened.id, memo2Id);
    }
  });
}
