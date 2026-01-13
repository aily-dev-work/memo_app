# メモ帳アプリ

ジャンル → タブ（メモ） → 本文編集の3階層構造のメモ帳アプリです。

## 機能

- ジャンル管理（追加/編集/削除/並び替え）
- メモ管理（追加/タイトル変更/削除）
- 本文編集（デバウンス自動保存 500ms）
- 検索機能
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

3. アプリの実行
```bash
flutter run
```

## テスト

```bash
flutter test
```

## アーキテクチャ

- feature-first構成
- ドメイン/データ/アプリケーション/プレゼンテーション層の分離
- Riverpodによる状態管理
