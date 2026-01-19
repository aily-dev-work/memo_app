import 'package:flutter/foundation.dart';
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

/// Premium状態のProvider
final premiumProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(purchaseServiceProvider);
  return service.premiumStream;
});

/// 現在のPremium状態（同期）
final isPremiumProvider = Provider<bool>((ref) {
  final premiumAsync = ref.watch(premiumProvider);
  return premiumAsync.when(
    data: (premium) => premium,
    loading: () => ref.watch(purchaseServiceProvider).isPremium,
    error: (_, __) => ref.watch(purchaseServiceProvider).isPremium,
  );
});

/// 商品情報のProvider
final productDetailsProvider = Provider<ProductDetails?>((ref) {
  return ref.watch(purchaseServiceProvider).productDetails;
});
