import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/genres/domain/genre.dart';
import '../../features/memos/domain/memo.dart';

/// Undo用のデータ保持
class UndoData {
  final Genre? deletedGenre;
  final Memo? deletedMemo;
  final int? genreId; // メモの場合は親ジャンルID

  UndoData({
    this.deletedGenre,
    this.deletedMemo,
    this.genreId,
  });
}

/// UndoサービスのProvider
final undoServiceProvider = StateProvider<UndoData?>((ref) => null);
