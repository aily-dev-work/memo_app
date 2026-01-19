import 'package:isar/isar.dart';

/// メモのドメインモデル
class Memo {
  final Id id;
  final int genreId;
  final String title;
  final String content;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  /// タブ／メモのカラー（ARGB値をintで保持）
  final int? colorValue;

  Memo({
    required this.id,
    required this.genreId,
    required this.title,
    required this.content,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.lastOpenedAt,
    this.colorValue,
  });

  Memo copyWith({
    Id? id,
    int? genreId,
    String? title,
    String? content,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastOpenedAt,
    int? colorValue,
  }) {
    return Memo(
      id: id ?? this.id,
      genreId: genreId ?? this.genreId,
      title: title ?? this.title,
      content: content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
