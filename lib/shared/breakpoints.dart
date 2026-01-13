/// レスポンシブレイアウトのブレークポイント定数
class Breakpoints {
  /// 2ペイン表示に切り替わる最小幅（ピクセル）
  static const double twoPaneWidth = 900.0;
  
  /// スマホ横向きで2ペイン表示に切り替わる最小幅（ピクセル）
  static const double twoPaneWidthLandscape = 700.0;
  
  /// 指定された幅と向きで2ペイン表示すべきか判定
  static bool shouldShowTwoPane({
    required double width,
    required bool isLandscape,
  }) {
    if (width >= twoPaneWidth) {
      return true;
    }
    if (isLandscape && width >= twoPaneWidthLandscape) {
      return true;
    }
    return false;
  }
}
