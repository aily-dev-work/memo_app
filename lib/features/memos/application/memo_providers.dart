import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/memo_repository_impl.dart';
import '../domain/memo.dart';
import '../../genres/application/genre_providers.dart';

/// 選択ジャンルのメモ一覧のProvider
final memosByGenreProvider = FutureProvider.family<List<Memo>, int>((ref, genreId) async {
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getByGenreId(genreId);
});

/// 選択中のメモIDのProvider
final selectedMemoIdProvider = StateProvider<Id?>((ref) => null);

/// 選択中のメモのProvider
final selectedMemoProvider = Provider<Memo?>((ref) {
  final genreId = ref.watch(selectedGenreIdProvider);
  final memoId = ref.watch(selectedMemoIdProvider);
  
  if (genreId == null || memoId == null) return null;
  
  final memosAsync = ref.watch(memosByGenreProvider(genreId));
  return memosAsync.whenData((memos) {
    try {
      return memos.firstWhere((m) => m.id == memoId);
    } catch (e) {
      return memos.isNotEmpty ? memos.first : null;
    }
  }).value;
});

/// 検索クエリのProvider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// フィルタ済みメモのProvider
final filteredMemosProvider = FutureProvider.family<List<Memo>, int>((ref, genreId) async {
  final query = ref.watch(searchQueryProvider);
  final repository = ref.watch(memoRepositoryProvider);
  
  if (query.isEmpty) {
    return repository.getByGenreId(genreId);
  }
  
  return repository.search(genreId, query);
});
