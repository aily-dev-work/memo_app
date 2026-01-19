import 'package:flutter/material.dart';

import '../../features/memos/domain/memo.dart';

/// 背景色に応じた文字色（淡い色なら黒、濃い色なら白）
Color textColorOnBackground(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.light
      ? Colors.black
      : Colors.white;
}

/// メモのカラー（タブ／本文背景）を取得
///
/// - colorValue が設定されていればその色を使う
/// - 未設定の場合はメモIDから淡い色を生成
Color getMemoColor(Memo memo, {bool selected = false}) {
  if (memo.colorValue != null) {
    return Color(memo.colorValue!);
  }
  final hash = memo.id.hashCode;
  final hue = (hash % 360).abs().toDouble();
  final base = HSVColor.fromAHSV(1.0, hue, 0.15, 0.98).toColor();
  return selected ? base.withValues(alpha: 0.6) : base;
}
