import 'package:flutter/material.dart';

/// LayerMemo のブランド色とメモ識別用パレット
abstract final class AppColors {
  AppColors._();

  /// 画面全体のベース（グレージュ）
  static const Color canvas = Color(0xFFE8E6E1);

  /// カード・AppBar・本文まわりの明るい面
  static const Color surface = Color(0xFFFAF9F7);

  /// 選択中のリスト行など
  static const Color surfaceMuted = Color(0xFFF1F0EC);

  /// 主要テキスト
  static const Color ink = Color(0xFF1F1F1E);

  /// 補助テキスト
  static const Color inkSecondary = Color(0xFF6B6A66);

  /// アイコン・薄いラベル
  static const Color inkTertiary = Color(0xFF8E8D88);

  /// 区切り線
  static const Color outline = Color(0xFFD4D2CC);

  /// Drawer（キャンバスと同系の暗いグレージュ）
  static const Color drawer = Color(0xFF3D3C39);

  /// 破壊的操作
  static const Color danger = Color(0xFFC62828);

  /// カード・リスト行などの角丸
  static const double radius = 10;

  static final BorderRadius borderRadius = BorderRadius.circular(radius);

  /// メモ未選択時のデフォルト色（やわらかいサンド）
  static const Color defaultMemo = Color(0xFFE8DCC8);

  /// メモ（タブ）識別用。彩度・明度をそろえた 10 色
  static const List<Color> memoPalette = [
    Color(0xFFE8DCC8), // サンド
    Color(0xFFF0D0B8), // アプリコット
    Color(0xFFEBC4C4), // ローズ
    Color(0xFFD9CDE8), // ライラック
    Color(0xFFC5D9E8), // スカイ
    Color(0xFFC5DFD4), // ミント
    Color(0xFFD4DBC4), // セージ
    Color(0xFFE4D4C0), // ベージュ
    Color(0xFFD5D5D0), // フォグ
    Color(0xFFC5CBD0), // スレート
  ];
}
