import 'package:flutter/material.dart';
import '../../features/genres/data/genre_repository_impl.dart';
import '../../features/memos/data/memo_repository_impl.dart';

/// 初期データを作成する
Future<void> createInitialData({
  required GenreRepository genreRepository,
  required MemoRepository memoRepository,
}) async {
  // 既存データがあるかチェック
  final existingGenres = await genreRepository.getAll();
  if (existingGenres.isNotEmpty) {
    return; // 既にデータがある場合はスキップ
  }

  // サンプルジャンル1: 仕事
  final genre1Id = await genreRepository.create('仕事');
  await memoRepository.create(
    genreId: genre1Id,
    title: 'プロジェクト計画',
    content: '新しいプロジェクトの計画を立てる\n\n- 要件定義\n- 設計\n- 実装\n- テスト',
    colorValue: const Color(0xFFB3E5FC).value, // 水色
  );
  await memoRepository.create(
    genreId: genre1Id,
    title: '会議メモ',
    content: '今日の会議で決定した事項\n\n1. スケジュール調整\n2. リソース配分\n3. 次回ミーティング日程',
    colorValue: const Color(0xFFC8E6C9).value, // グリーン
  );
  await memoRepository.create(
    genreId: genre1Id,
    title: 'タスクリスト',
    content: '今週のタスク\n\n□ 資料作成\n□ プレゼン準備\n□ クライアント対応',
    colorValue: const Color(0xFFFFF9C4).value, // 明るいイエロー
  );

  // サンプルジャンル2: プライベート
  final genre2Id = await genreRepository.create('プライベート');
  await memoRepository.create(
    genreId: genre2Id,
    title: '買い物リスト',
    content: '今週末の買い物リスト\n\n- 野菜\n- 肉\n- 調味料\n- 日用品',
    colorValue: const Color(0xFFFFCDD2).value, // ピンク
  );
  await memoRepository.create(
    genreId: genre2Id,
    title: '読書メモ',
    content: '最近読んだ本のメモ\n\n面白かったポイント：\n- ストーリー展開\n- キャラクター描写\n- 世界観の構築',
    colorValue: const Color(0xFFD1C4E9).value, // パープル
  );
  await memoRepository.create(
    genreId: genre2Id,
    title: 'レシピ',
    content: '美味しかったレシピ\n\n材料：\n- 鶏肉\n- 野菜\n- 調味料\n\n作り方：\n1. 下準備\n2. 調理\n3. 盛り付け',
    colorValue: const Color(0xFFFFE0B2).value, // オレンジ
  );

  // サンプルジャンル3: 学習
  final genre3Id = await genreRepository.create('学習');
  await memoRepository.create(
    genreId: genre3Id,
    title: 'Flutter学習',
    content: 'Flutterの学習メモ\n\n- Widgetの使い方\n- State管理\n- ナビゲーション',
    colorValue: const Color(0xFFBBDEFB).value, // スカイブルー
  );
  await memoRepository.create(
    genreId: genre3Id,
    title: '英語単語',
    content: '覚えた英単語\n\n- application: アプリケーション\n- repository: リポジトリ\n- provider: プロバイダー',
    colorValue: const Color(0xFFDCEDC8).value, // ライムグリーン
  );

  // サンプルジャンル4: アイデア
  final genre4Id = await genreRepository.create('アイデア');
  await memoRepository.create(
    genreId: genre4Id,
    title: 'アプリのアイデア',
    content: '新しいアプリのアイデア\n\n- 機能要件\n- UIデザイン\n- 技術スタック',
    colorValue: const Color(0xFFE1BEE7).value, // ラベンダー
  );
  await memoRepository.create(
    genreId: genre4Id,
    title: 'ブログネタ',
    content: 'ブログのネタ帳\n\n- 技術記事\n- 体験談\n- レビュー',
    colorValue: const Color(0xFFFFF59D).value, // レモンイエロー
  );
}
