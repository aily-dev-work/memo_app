import 'package:isar/isar.dart';
import '../domain/memo.dart';
import '../domain/memo_format.dart';

part 'memo_repository.g.dart';

/// MemoのIsarコレクション
@collection
class MemoSchema {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int genreId;
  
  late String title;
  
  late String content;

  /// メモ形式（normal / checklist）。既存データは空文字 → Domain 側で normal 扱い
  String format = MemoFormat.normal.storageValue;
  
  late int sortOrder;
  
  late DateTime createdAt;
  
  late DateTime updatedAt;
  
  DateTime? lastOpenedAt;
  
  /// タブ／メモのカラー（ARGB値をintで保持）
  int? colorValue;
  
  /// 無名コンストラクタ（Isar必須）
  MemoSchema();
  
  /// Domainモデルに変換
  Memo toDomain() {
    return Memo(
      id: id,
      genreId: genreId,
      title: title,
      content: content,
      format: MemoFormatX.fromStorage(format),
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: lastOpenedAt,
      colorValue: colorValue,
    );
  }
  
  /// Domainモデルから作成
  factory MemoSchema.fromDomain(Memo memo) {
    return MemoSchema()
      ..id = memo.id
      ..genreId = memo.genreId
      ..title = memo.title
      ..content = memo.content
      ..format = memo.format.storageValue
      ..sortOrder = memo.sortOrder
      ..createdAt = memo.createdAt
      ..updatedAt = memo.updatedAt
      ..lastOpenedAt = memo.lastOpenedAt
      ..colorValue = memo.colorValue;
  }
}
