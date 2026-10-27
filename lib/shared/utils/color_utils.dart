import 'package:flutter/material.dart';

import '../../features/memos/domain/memo.dart';
import '../theme/app_colors.dart';

/// 背景色に応じた文字色（淡い色なら黒、濃い色なら白）
Color textColorOnBackground(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.light
      ? AppColors.ink
      : AppColors.surface;
}

/// メモのカラー（タブ／本文背景）を取得
///
/// - colorValue が設定されていればその色を使う
/// - 未設定の場合はパレットから安定して割り当て
Color getMemoColor(Memo memo, {bool selected = false}) {
  if (memo.colorValue != null) {
    return Color(memo.colorValue!);
  }
  final palette = AppColors.memoPalette;
  final base = palette[memo.id.abs() % palette.length];
  return selected ? base.withValues(alpha: 0.85) : base;
}

/// メモ色選択ダイアログを表示する
Future<Color?> showMemoColorPicker(BuildContext context) {
  return showDialog<Color>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('カラーを選択'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: AppColors.memoPalette.map((color) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, color),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outline,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    },
  );
}
