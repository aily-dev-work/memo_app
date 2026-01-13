import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/genre_repository_impl.dart';
import '../domain/genre.dart';

/// ジャンル一覧のProvider
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final repository = ref.watch(genreRepositoryProvider);
  return repository.getAll();
});

/// 選択中のジャンルIDのProvider
final selectedGenreIdProvider = StateProvider<Id?>((ref) => null);

/// 選択中のジャンルのProvider
final selectedGenreProvider = Provider<Genre?>((ref) {
  final genreId = ref.watch(selectedGenreIdProvider);
  if (genreId == null) return null;
  
  final genresAsync = ref.watch(genresProvider);
  return genresAsync.whenData((genres) {
    try {
      return genres.firstWhere((g) => g.id == genreId);
    } catch (e) {
      return genres.isNotEmpty ? genres.first : null;
    }
  }).value;
});

/// サイドバーの開閉状態のProvider（2ペイン時のみ使用）
final sidebarOpenProvider = StateProvider<bool>((ref) => true);
