import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kReleaseMode, TargetPlatform;

/// AdMob バナー広告ユニット ID。
/// [kReleaseMode] が true のとき本番、false のとき Google 公式テスト ID。
///
/// iOS を主対象とし、Android も同様に Debug/Release で分岐する（既存の本番・テスト ID に準拠）。
abstract final class AdIds {
  AdIds._();

  static const String _testBannerIos =
      'ca-app-pub-3940256099942544/2934735716';
  static const String _prodBannerIos =
      'ca-app-pub-1242789019874155/7831699962';

  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _prodBannerAndroid =
      'ca-app-pub-1242789019874155/2507414617';

  /// 現在プラットフォーム向けのバナー広告ユニット ID。
  static String get bannerId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return kReleaseMode ? _prodBannerIos : _testBannerIos;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return kReleaseMode ? _prodBannerAndroid : _testBannerAndroid;
    }
    return kReleaseMode ? _prodBannerAndroid : _testBannerAndroid;
  }
}
