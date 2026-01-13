import '../../features/genres/data/genre_repository_impl.dart';
import '../../features/memos/data/memo_repository_impl.dart';

/// 初期データを作成する
Future<void> createInitialData({
  required GenreRepository genreRepository,
  required MemoRepository memoRepository,
}) async {
  // 既存データがあるかチェック
  final existingGenres = await genreRepository.getAll();
  if (existingGenres.isNotEmpty) {
    return; // 既にデータがある場合はスキップ
  }

  // サンプルジャンル1
  final genre1Id = await genreRepository.create('仕事');
  await memoRepository.create(
    genreId: genre1Id,
    title: 'プロジェクト計画',
    content: '新しいプロジェクトの計画を立てる\n\n- 要件定義\n- 設計\n- 実装',
  );
  await memoRepository.create(
    genreId: genre1Id,
    title: '会議メモ',
    content: '今日の会議で決定した事項\n\n1. スケジュール調整\n2. リソース配分',
  );

  // サンプルジャンル2
  final genre2Id = await genreRepository.create('プライベート');
  await memoRepository.create(
    genreId: genre2Id,
    title: '買い物リスト',
    content: '今週末の買い物リスト\n\n- 野菜\n- 肉\n- 調味料',
  );
  await memoRepository.create(
    genreId: genre2Id,
    title: '読書メモ',
    content: '最近読んだ本のメモ\n\n面白かったポイント：\n- ストーリー展開\n- キャラクター描写',
  );
}
