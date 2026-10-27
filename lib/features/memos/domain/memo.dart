import 'package:isar/isar.dart';

import 'memo_format.dart';

/// メモのドメインモデル
class Memo {
  final Id id;
  final int genreId;
  final String title;
  final String content;
  final MemoFormat format;
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
    this.format = MemoFormat.normal,
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
    MemoFormat? format,
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
      format: format ?? this.format,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
