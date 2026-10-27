import '../../features/genres/data/genre_repository_impl.dart';
import '../../features/memos/data/memo_repository_impl.dart';
import '../theme/app_colors.dart';
import 'help_guide.dart';

/// 初期データを作成する
Future<void> createInitialData({
  required GenreRepository genreRepository,
  required MemoRepository memoRepository,
}) async {
  // 既存データがあるかチェック
  final existingGenres = await genreRepository.getAll();
  if (existingGenres.isNotEmpty) {
    return; // 既にデータがある場合はスキップ（既存ユーザーデータは変更しない）
  }

  // 初回は「使い方」用の最小データのみ作成する
  final guideGenreId = await genreRepository.create(HelpGuide.title);
  await memoRepository.create(
    genreId: guideGenreId,
    title: 'はじめに',
    content: HelpGuide.body,
    colorValue: AppColors.memoPalette[5].toARGB32(), // ミント
  );
}
