// ignore_for_file: constant_identifier_names

// ビルド時に --dart-define で注入する環境設定。
//
// 例:
//   flutter run --flavor dev --dart-define=FLAVOR=dev
//   flutter run --flavor prod --dart-define=FLAVOR=prod \
//     --dart-define=ADMOB_BANNER_ID_IOS=ca-app-pub-xxx/yyy \
//     --dart-define=ADMOB_BANNER_ID_ANDROID=ca-app-pub-xxx/zzz
//
// 未指定時: FLAVOR=dev はテスト用ID、prod は本番バナーID（_prodBannerId*）。
// --dart-define=ADMOB_BANNER_ID_* で上書き可。

const String _kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

bool get kIsProd => _kFlavor == 'prod';

// 未指定時は空。getAdMobBannerId* でフォールバック。
const String _kAdMobBannerIdIos = String.fromEnvironment('ADMOB_BANNER_ID_IOS', defaultValue: '');
const String _kAdMobBannerIdAndroid =
    String.fromEnvironment('ADMOB_BANNER_ID_ANDROID', defaultValue: '');

const String _testBannerIdIos = 'ca-app-pub-3940256099942544/2934735716';
const String _testBannerIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
const String _prodBannerIdIos = 'ca-app-pub-1242789019874155/7831699962';
const String _prodBannerIdAndroid = 'ca-app-pub-1242789019874155/2507414617';

String getAdMobBannerIdIos() {
  if (_kAdMobBannerIdIos.isNotEmpty) return _kAdMobBannerIdIos;
  return kIsProd ? _prodBannerIdIos : _testBannerIdIos;
}

String getAdMobBannerIdAndroid() {
  if (_kAdMobBannerIdAndroid.isNotEmpty) return _kAdMobBannerIdAndroid;
  return kIsProd ? _prodBannerIdAndroid : _testBannerIdAndroid;
}
