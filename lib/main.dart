import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'shared/ads/ad_config.dart';
import 'shared/theme/app_theme.dart';
import 'shared/data/isar_service.dart';
import 'shared/utils/initial_data.dart';
import 'shared/purchase/purchase_providers.dart';
import 'features/genres/data/genre_repository.dart';
import 'features/genres/data/genre_repository_impl.dart';
import 'features/memos/data/memo_repository.dart';
import 'features/memos/data/memo_repository_impl.dart';
import 'app/router.dart';

bool get _supportsMobileAds {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android;
}

Future<Isar> _openIsar(String directory) async {
  try {
    return await Isar.open(
      [
        GenreSchemaSchema,
        MemoSchemaSchema,
      ],
      directory: directory,
    );
  } catch (_) {
    // スキーマ変更（例: format 追加）で開けない場合は作り直す
    await Isar.getInstance()?.close(deleteFromDisk: true);
    return Isar.open(
      [
        GenreSchemaSchema,
        MemoSchemaSchema,
      ],
      directory: directory,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Mobile Ads は iOS / Android のみ（macOS ではプラグイン未実装で落ちる）
  if (kShowAds && _supportsMobileAds) {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      // 広告初期化失敗でもアプリ本体は起動する
    }
  }

  // Isar初期化
  final dir = await getApplicationDocumentsDirectory();
  final isar = await _openIsar(dir.path);
  
  // 初期データ作成
  final genreRepository = GenreRepository(isar);
  final memoRepository = MemoRepository(isar);
  await createInitialData(
    genreRepository: genreRepository,
    memoRepository: memoRepository,
  );
  
  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MemoApp(),
    ),
  );
}

class MemoApp extends ConsumerWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    // 起動時に購入状態を初期化（Providerを参照することで初期化をトリガー）
    ref.watch(premiumProvider);
    
    return MaterialApp.router(
      title: 'メモ帳',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
