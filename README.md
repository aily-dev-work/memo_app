# メモ帳アプリ

ジャンル → タブ（メモ） → 本文編集の3階層構造のメモ帳アプリです。

## 機能

- ジャンル管理（追加/編集/削除/並び替え）
- メモ管理（追加/タイトル変更/削除）
- 本文編集（デバウンス自動保存 500ms）
- Undo機能（削除後の元に戻す）
- レスポンシブ対応（1ペイン/2ペイン自動切り替え）

## 技術スタック

- Flutter (stable)
- Riverpod (状態管理)
- go_router (ルーティング)
- Isar (ローカル永続化)
- Material 3 + ダークモード

## セットアップ

1. 依存関係のインストール
```bash
flutter pub get
```

2. Isarコード生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. iOSシミュレーターのセットアップ（初回のみ）
```bash
# Xcodeの開発者ディレクトリを設定（パスワード入力が必要）
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Xcodeの初回起動設定
sudo xcodebuild -runFirstLaunch

# CocoaPodsのインストール（iOS/macOSの依存関係管理ツール）
sudo gem install cocoapods

# iOSプロジェクトの依存関係をインストール
cd ios && pod install && cd ..
```

4. アプリの実行
```bash
# 利用可能なデバイスを確認
flutter devices

# iOSシミュレーターで実行（デバイス名を指定）
flutter run -d "iPhone 15"

# Androidエミュレーターで実行（デバイスIDを指定）
flutter run -d emulator-5554

# またはデバイスIDを直接指定
flutter run -d D15E038C-3096-4FFD-B0D4-0FB38FBEEC4C
```

### 複数デバイスで同時実行

Android StudioとXcodeの両方で同時にアプリを起動するには、**2つのターミナルウィンドウ**を開いて、それぞれで異なるデバイスを指定して実行します：

**ターミナル1（Android用）:**
```bash
cd /Users/yuki/dev/memo_app
flutter run -d emulator-5554
```

**ターミナル2（iOS用）:**
```bash
cd /Users/yuki/dev/memo_app
flutter run -d "iPhone 15"
```

または、デバイスIDを直接指定することもできます：
```bash
# Android（デバイスIDを確認してから指定）
flutter run -d emulator-5554

# iOS（デバイスIDを確認してから指定）
flutter run -d D15E038C-3096-4FFD-B0D4-0FB38FBEEC4C
```

**注意:** `flutter run -d ios` や `flutter run -d android` は動作しません。必ず具体的なデバイス名またはデバイスIDを指定してください。

**注意:** 両方のデバイスでHot Reloadが同時に動作するため、コードを変更すると両方のデバイスに反映されます。

**簡単な方法（スクリプト使用）:**
```bash
# スクリプトで両方同時に起動
./run_both.sh
```

## テスト

```bash
flutter test
```

## アーキテクチャ

- feature-first構成
- ドメイン/データ/アプリケーション/プレゼンテーション層の分離
- Riverpodによる状態管理
