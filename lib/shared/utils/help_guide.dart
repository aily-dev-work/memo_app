/// アプリの使い方ガイド（初期メモ・設定画面で共有）
class HelpGuideSection {
  final String title;
  final String body;

  const HelpGuideSection({required this.title, required this.body});
}

abstract final class HelpGuide {
  HelpGuide._();

  static const String title = '使い方';

  /// 設定画面などでセクション表示する用
  /// タイトルは「調べたい操作」がそのまま見えるようにする
  static const List<HelpGuideSection> sections = [
    HelpGuideSection(
      title: 'ジャンルの作成',
      body:
          'ジャンル一覧（トップ）の右上「＋」をタップします。\n'
          '名前を入力するとジャンルが追加されます。\n'
          '例：仕事 / 買い物 / アイデア など。',
    ),
    HelpGuideSection(
      title: 'ジャンルの変更・削除',
      body:
          'ジャンル行の右側「⋮」メニューから行えます。\n'
          '・名前を変更\n'
          '・削除（元に戻すこともできます）',
    ),
    HelpGuideSection(
      title: 'メモ（タブ）の作成',
      body:
          'ジャンルを開いた画面の右上「＋」をタップします。\n'
          '形式を選んでから、メモの名前と色を設定します。\n'
          '・通常メモ … 普通の文章\n'
          '・チェックリスト … ToDo向き\n'
          '・表形式 … 行と列で整理',
    ),
    HelpGuideSection(
      title: 'メモ（タブ）の変更・削除',
      body:
          'タブを長押しするとメニューが開きます。\n'
          '・メモの名前を変更\n'
          '・削除（元に戻すこともできます）',
    ),
    HelpGuideSection(
      title: '本文の編集・保存',
      body:
          'タブを選んで本文を編集します。\n'
          '書いた内容は自動で保存されます（保存ボタンはありません）。',
    ),
    HelpGuideSection(
      title: '広告を消したいとき',
      body: '設定の「広告を削除（購入）」から、広告を非表示にできます。',
    ),
    HelpGuideSection(
      title: 'このガイドをあとから読む',
      body:
          '「使い方」ジャンルを消しても大丈夫です。\n'
          'いつでも 設定 → 使い方 から同じ内容を読めます。',
    ),
  ];

  /// 初期メモ用のプレーンテキスト
  static String get body {
    final buffer = StringBuffer()
      ..writeln('LayerMemoへようこそ。')
      ..writeln('下の見出しから、調べたい操作を選んでください。')
      ..writeln();
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      buffer.writeln('【${section.title}】');
      buffer.write(section.body);
      if (i < sections.length - 1) {
        buffer.writeln();
        buffer.writeln();
      }
    }
    return buffer.toString();
  }
}
