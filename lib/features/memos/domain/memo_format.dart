import 'package:flutter/material.dart';

/// メモの形式
enum MemoFormat {
  /// 通常のテキストメモ
  normal,

  /// チェックリスト形式
  checklist,

  /// 表形式
  table,
}

extension MemoFormatX on MemoFormat {
  String get storageValue => name;

  String get displayName {
    switch (this) {
      case MemoFormat.normal:
        return '通常メモ';
      case MemoFormat.checklist:
        return 'チェックリスト';
      case MemoFormat.table:
        return '表形式';
    }
  }

  String get description {
    switch (this) {
      case MemoFormat.normal:
        return '普通の文章メモ';
      case MemoFormat.checklist:
        return 'ToDo向きのリスト';
      case MemoFormat.table:
        return '行と列で整理';
    }
  }

  IconData get icon {
    switch (this) {
      case MemoFormat.normal:
        return Icons.notes;
      case MemoFormat.checklist:
        return Icons.checklist;
      case MemoFormat.table:
        return Icons.table_chart_outlined;
    }
  }

  static MemoFormat fromStorage(String? value) {
    if (value == null || value.isEmpty) return MemoFormat.normal;
    for (final f in MemoFormat.values) {
      if (f.name == value) return f;
    }
    return MemoFormat.normal;
  }
}
