import 'package:isar/isar.dart';
import '../domain/genre.dart';

part 'genre_repository.g.dart';

/// GenreのIsarコレクション
@collection
class GenreSchema {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String name;
  
  late int sortOrder;
  
  late DateTime createdAt;
  
  late DateTime updatedAt;
  
  /// 無名コンストラクタ（Isar必須）
  GenreSchema();
  
  /// Domainモデルに変換
  Genre toDomain() {
    return Genre(
      id: id,
      name: name,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  /// Domainモデルから作成
  factory GenreSchema.fromDomain(Genre genre) {
    return GenreSchema()
      ..id = genre.id
      ..name = genre.name
      ..sortOrder = genre.sortOrder
      ..createdAt = genre.createdAt
      ..updatedAt = genre.updatedAt;
  }
}
