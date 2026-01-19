# Flavor と dart-define による環境切り替え

dev / prod の切り替えと、AdMob ID のビルド時注入の仕方です。

---

## 1. Flavor（dev / prod）

### iOS
- **スキーム**: `dev`（テスト用ID）, `prod`（本番用ID）
- **ビルド構成**: `Debug-dev`, `Release-dev`, `Profile-dev`, `Debug-prod`, `Release-prod`, `Profile-prod`

### Android
- **productFlavors**: `dev`（`applicationIdSuffix = ".dev"`, テスト用 AdMob）, `prod`（本番用）

### 実行例

```bash
# Dev（テスト広告ID）
flutter run --flavor dev -d "iPhone 15" --dart-define=FLAVOR=dev
flutter run --flavor dev --dart-define=FLAVOR=dev

# Prod（本番。以下で本番IDを渡すか、xcconfig / gradle に設定すること）
flutter run --flavor prod -d "iPhone 15" --dart-define=FLAVOR=prod
flutter build ipa --flavor prod --dart-define=FLAVOR=prod
```

`--dart-define=FLAVOR=dev` か `=prod` は **Dart 側** の `app_env` 用なので、`--flavor` と一緒に付けてください。

---

## 2. dart-define で AdMob ID を上書き

**バナー広告ユニットID** だけ、`--dart-define` で渡せます（Dart で参照）。  
**AdMob アプリ ID** は iOS / Android のネイティブ設定で使うため、xcconfig / `gradle` 側で設定します。

### 例（prod で本番バナーIDを渡す）

```bash
flutter run --flavor prod --dart-define=FLAVOR=prod \
  --dart-define=ADMOB_BANNER_ID_IOS=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY \
  --dart-define=ADMOB_BANNER_ID_ANDROID=ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ
```

### 未指定時
- **FLAVOR**: 未指定なら `dev`
- **ADMOB_BANNER_ID_***: 未指定なら  
  - `dev` → テスト用ID  
  - `prod` → プレースホルダー（要差し替え）

---

## 3. 本番用 ID の設定場所

| 対象 | 場所 | 例 |
|------|------|-----|
| **iOS アプリ ID** | `ios/Flutter/AdMob-Prod.xcconfig` | `ADMOB_APP_ID_IOS = ca-app-pub-xxx~yyy` |
| **Android アプリ ID** | `android/gradle.properties` の `admobAppIdProd`、または `-PadmobAppIdProd=...` | `admobAppIdProd=ca-app-pub-xxx~yyy` |
| **Dart バナーID** | `--dart-define=ADMOB_BANNER_ID_IOS` / `ADMOB_BANNER_ID_ANDROID`、または `lib/shared/env/app_env.dart` のフォールバック | 上記 `flutter run` 例 |

---

## 4. 参考：app_env（Dart）

- `lib/shared/env/app_env.dart`
  - `kIsProd`（`FLAVOR=prod` のとき `true`）
  - `getAdMobBannerIdIos()` / `getAdMobBannerIdAndroid()`（`--dart-define` 未設定時は dev/prod 用のデフォルト）

---

## 5. Runner スキーム（従来どおり）

`Runner` スキームは `Debug` のままです。`--flavor` を付けずに `flutter run` するときは、**`dev` スキーム相当**にはならないので、dev 用には `--flavor dev` を指定してください。
