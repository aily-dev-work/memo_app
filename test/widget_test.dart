// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:memo_app/main.dart';
import 'package:memo_app/shared/data/isar_service.dart';
import 'package:memo_app/shared/utils/initial_data.dart';
import 'package:memo_app/features/genres/data/genre_repository.dart';
import 'package:memo_app/features/genres/data/genre_repository_impl.dart';
import 'package:memo_app/features/memos/data/memo_repository.dart';
import 'package:memo_app/features/memos/data/memo_repository_impl.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Isar初期化（テスト用）
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [
        GenreSchemaSchema,
        MemoSchemaSchema,
      ],
      directory: dir.path,
      name: 'test',
    );
    
    // 初期データ作成
    final genreRepository = GenreRepository(isar);
    final memoRepository = MemoRepository(isar);
    await createInitialData(
      genreRepository: genreRepository,
      memoRepository: memoRepository,
    );
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const MemoApp(),
      ),
    );

    // アプリが正常に起動することを確認
    await tester.pumpAndSettle();
    
    // クリーンアップ
    await isar.close(deleteFromDisk: true);
  });
}
