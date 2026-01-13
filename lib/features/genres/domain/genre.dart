import 'package:isar/isar.dart';

/// ジャンルのドメインモデル
class Genre {
  final Id id;
  final String name;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Genre({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Genre copyWith({
    Id? id,
    String? name,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
