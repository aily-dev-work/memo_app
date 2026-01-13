import 'package:isar/isar.dart';
import '../domain/memo.dart';

part 'memo_repository.g.dart';

/// MemoのIsarコレクション
@collection
class MemoSchema {
  Id id = Isar.autoIncrement;
  
  @Index()
  late int genreId;
  
  late String title;
  
  late String content;
  
  late int sortOrder;
  
  late DateTime createdAt;
  
  late DateTime updatedAt;
  
  DateTime? lastOpenedAt;
  
  /// 無名コンストラクタ（Isar必須）
  MemoSchema();
  
  /// Domainモデルに変換
  Memo toDomain() {
    return Memo(
      id: id,
      genreId: genreId,
      title: title,
      content: content,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastOpenedAt: lastOpenedAt,
    );
  }
  
  /// Domainモデルから作成
  factory MemoSchema.fromDomain(Memo memo) {
    return MemoSchema()
      ..id = memo.id
      ..genreId = memo.genreId
      ..title = memo.title
      ..content = memo.content
      ..sortOrder = memo.sortOrder
      ..createdAt = memo.createdAt
      ..updatedAt = memo.updatedAt
      ..lastOpenedAt = memo.lastOpenedAt;
  }
}
