import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'purchase_service.dart';

/// PurchaseServiceのProvider
final purchaseServiceProvider = Provider<PurchaseService>((ref) {
  final service = PurchaseService();
  
  // 初期化
  service.initialize().catchError((error) {
    // エラーは無視
  });
  
  // リソース解放
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// IAP初期化状態（初期化失敗時の再試行導線用）
final iapInitStateProvider = StreamProvider<IapInitState>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  return service.initStateStream;
});

/// 現在のIAP初期化状態（stream取りこぼし対策）
final currentIapInitStateProvider = Provider<IapInitState>((ref) {
  return ref.watch(purchaseServiceProvider).initState;
});

/// Premium状態のProvider
final premiumProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  return service.premiumStream;
});

/// 現在のPremium状態（stream取りこぼし対策）
final currentPremiumProvider = Provider<bool>((ref) {
  return ref.watch(purchaseServiceProvider).isPremium;
});

/// 現在のPremium状態（同期）
final isPremiumProvider = Provider<bool>((ref) {
  final premiumAsync = ref.watch(premiumProvider);
  return premiumAsync.when(
    data: (premium) => premium,
    loading: () => ref.watch(currentPremiumProvider),
    error: (_, __) => ref.watch(currentPremiumProvider),
  );
});

/// 商品情報のProvider
final productDetailsProvider = Provider<ProductDetails?>((ref) {
  return ref.watch(purchaseServiceProvider).productDetails;
});

/// 直近の商品クエリ失敗メッセージ（設定画面の説明用）
final lastProductQueryUserMessageProvider = Provider<String?>((ref) {
  return ref.watch(purchaseServiceProvider).lastProductQueryUserMessage;
});
