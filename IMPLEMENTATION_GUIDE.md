# 広告削除機能 実装ガイド

## 変更ファイル一覧

### 新規作成ファイル
1. `lib/shared/purchase/purchase_service.dart` - 購入状態管理サービス
2. `lib/shared/purchase/purchase_providers.dart` - 購入関連のRiverpod Provider
3. `lib/shared/ads/ad_banner_widget.dart` - バナー広告Widget
4. `lib/features/settings/presentation/settings_screen.dart` - 設定画面

### 修正ファイル
1. `pubspec.yaml` - 依存関係追加
2. `lib/main.dart` - 広告初期化と購入状態の初期化
3. `lib/app/router.dart` - 設定画面のルート追加
4. `lib/features/genres/presentation/genre_list_widget.dart` - 広告バナー追加、設定ボタン追加
5. `lib/features/memos/presentation/genre_detail_screen.dart` - 広告バナー追加、設定ボタン追加
6. `ios/Runner/Info.plist` - AdMob設定追加
7. `android/app/src/main/AndroidManifest.xml` - AdMob設定追加

## iOS設定手順

### 1. Info.plistの設定（既に追加済み）
- `GADApplicationIdentifier`: AdMob App ID（テスト用は設定済み）
- `SKAdNetworkItems`: 広告トラッキング用（最小限の設定済み）

### 2. AdMob App IDの設定
本番環境では、`Info.plist`の`GADApplicationIdentifier`を実際のAdMob App IDに変更：
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### 3. App Store Connectでの商品登録
1. App Store Connectにログイン
2. アプリを選択
3. 「アプリ内課金」→「作成」をクリック
4. 商品タイプ: **非消費型（Non-Consumable）**を選択
5. 商品ID: `remove_ads`
6. 価格を設定
7. 商品情報を入力
8. 保存

### 4. テスト用アカウントの設定
1. App Store Connect → 「ユーザーとアクセス」
2. 「サンドボックステスター」を追加
3. テスト用Apple IDでログインしてテスト

## Android設定手順

### 1. AndroidManifest.xmlの設定（既に追加済み）
- `com.google.android.gms.ads.APPLICATION_ID`: AdMob App ID（テスト用は設定済み）
- `INTERNET`権限: 追加済み

### 2. AdMob App IDの設定
本番環境では、`AndroidManifest.xml`の`APPLICATION_ID`を実際のAdMob App IDに変更：
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### 3. Google Play Consoleでの商品登録
1. Google Play Consoleにログイン
2. アプリを選択
3. 「収益化」→「アプリ内商品」→「商品を作成」
4. 商品ID: `remove_ads`
5. 名前: 「広告を削除」など
6. 説明: 商品の説明
7. 価格を設定
8. ステータス: 「アクティブ」に設定
9. 保存

### 4. ライセンステストの設定
1. Google Play Console → 「設定」→ 「ライセンステスト」
2. テスト用Googleアカウントを追加
3. テスト用アカウントでログインしてテスト

## ストア側で作る課金商品の注意点

### 必須設定
- **商品タイプ**: 非消費型（Non-Consumable / 非消費型）
- **商品ID**: `remove_ads`（iOS/Android共通）
- **復元対応**: 必須（再インストール/機種変更時に復元できるように）

### iOS (App Store Connect)
- 商品タイプ: 「非消費型」を選択
- 復元機能: 自動的に有効
- 注意: 同じApple IDで購入した場合、自動的に復元される

### Android (Google Play Console)
- 商品タイプ: 「管理対象商品」を選択（非消費型に相当）
- 復元機能: `restorePurchases()`で復元可能
- 注意: 同じGoogleアカウントで購入した場合、自動的に復元される

## 動作確認チェックリスト

### 基本動作
- [ ] アプリ起動時に広告が表示される（Premium未購入時）
- [ ] 設定画面が表示される
- [ ] 商品情報（価格）が表示される

### 購入フロー
- [ ] 「広告を削除（購入）」ボタンをタップ
- [ ] ストアの購入ダイアログが表示される
- [ ] 購入を完了すると広告が非表示になる
- [ ] 購入完了の通知が表示される

### 復元フロー
- [ ] 「購入を復元」ボタンをタップ
- [ ] 購入済みの場合、広告が非表示になる
- [ ] 未購入の場合、適切なエラーメッセージが表示される

### 再インストール/機種変更
- [ ] アプリを削除して再インストール
- [ ] 起動時に購入状態が復元される
- [ ] 広告が表示されない（Premium状態）

### エラーハンドリング
- [ ] ストア未接続時に適切なエラーメッセージが表示される
- [ ] 商品未登録時に適切なエラーメッセージが表示される
- [ ] 購入キャンセル時にエラーが表示されない（正常動作）

### 広告表示
- [ ] ジャンル一覧画面の下部に広告が表示される（Premium未購入時）
- [ ] ジャンル詳細画面の下部に広告が表示される（Premium未購入時）
- [ ] メモ編集画面（MemoEditor）には広告が表示されない
- [ ] Premium購入後、すべての広告が非表示になる

### テスト環境
- [ ] テスト用広告IDで広告が表示される
- [ ] サンドボックス/ライセンステストで購入が動作する
- [ ] テスト購入が正しく処理される

## テスト用広告ID

現在の実装では、テスト用広告IDを使用しています：

- **Android**: `ca-app-pub-3940256099942544/6300978111`
- **iOS**: `ca-app-pub-3940256099942544/2934735716`

本番環境では、AdMobで取得した実際の広告IDに置き換えてください。

## トラブルシューティング

### 広告が表示されない
1. AdMob App IDが正しく設定されているか確認
2. インターネット接続を確認
3. テスト用広告IDを使用しているか確認

### 購入が動作しない
1. ストアに接続されているか確認
2. 商品IDが正しく設定されているか確認（`remove_ads`）
3. 商品がストアで「アクティブ」になっているか確認
4. テスト用アカウントでログインしているか確認

### 購入状態が復元されない
1. 同じApple ID/Googleアカウントでログインしているか確認
2. ストアに接続されているか確認
3. `restorePurchases()`が正しく呼ばれているか確認
