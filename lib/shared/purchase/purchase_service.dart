import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 購入状態管理サービス
class PurchaseService {
  static const String _premiumKey = 'is_premium';
  static const String _productId = 'remove_ads';
  
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<bool> _premiumController = StreamController<bool>.broadcast();
  
  bool _isAvailable = false;
  bool _premium = false;
  ProductDetails? _productDetails;
  
  /// Premium状態のストリーム
  Stream<bool> get premiumStream => _premiumController.stream;
  
  /// 現在のPremium状態
  bool get isPremium => _premium;
  
  /// 商品情報
  ProductDetails? get productDetails => _productDetails;
  
  /// 初期化（起動時に呼ぶ）
  Future<void> initialize() async {
    // ローカル保存から復元
    final prefs = await SharedPreferences.getInstance();
    _premium = prefs.getBool(_premiumKey) ?? false;
    _premiumController.add(_premium);
    
    // IAPが利用可能か確認
    _isAvailable = await _iap.isAvailable();
    
    if (!_isAvailable) {
      return;
    }
    
    // 購入ストリームを監視
    _iap.purchaseStream.listen(
      _handlePurchaseUpdate,
      onDone: () => _premiumController.close(),
      onError: (error) {},
    );
    
    // 商品情報を取得
    await _loadProducts();
    
    // 購入状態を復元（ストアから確認）
    await restorePurchases();
  }
  
  /// 商品情報を読み込む
  Future<void> _loadProducts() async {
    if (!_isAvailable) return;
    
    try {
      final productIds = <String>{_productId};
      final response = await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        return;
      }
      
      if (response.productDetails.isEmpty) {
        return;
      }
      
      _productDetails = response.productDetails.first;
    } catch (e) {
      // エラーは無視
    }
  }
  
  /// 購入処理
  Future<PurchaseResult> buyPremium() async {
    if (!_isAvailable) {
      return PurchaseResult(
        success: false,
        error: 'アプリ内課金が利用できません。ストアに接続してください。',
      );
    }
    
    if (_productDetails == null) {
      return PurchaseResult(
        success: false,
        error: '商品情報を取得できませんでした。',
      );
    }
    
    try {
      final purchaseParam = PurchaseParam(
        productDetails: _productDetails!,
      );
      
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        return PurchaseResult(
          success: false,
          error: '購入処理を開始できませんでした。',
        );
      }
      
      // 購入ストリームで結果が来るので、ここでは待機しない
      return PurchaseResult(
        success: true,
        error: null,
      );
    } catch (e) {
      return PurchaseResult(
        success: false,
        error: '購入処理中にエラーが発生しました: $e',
      );
    }
  }
  
  /// 購入を復元
  Future<PurchaseResult> restorePurchases() async {
    if (!_isAvailable) {
      return PurchaseResult(
        success: false,
        error: 'アプリ内課金が利用できません。ストアに接続してください。',
      );
    }
    
    try {
      await _iap.restorePurchases();
      // 復元結果は購入ストリームで処理される
      return PurchaseResult(
        success: true,
        error: null,
      );
    } catch (e) {
      return PurchaseResult(
        success: false,
        error: '復元処理中にエラーが発生しました: $e',
      );
    }
  }
  
  /// 購入更新を処理
  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }
      
      if (purchase.status == PurchaseStatus.error) {
        continue;
      }
      
      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _productId) {
          await _setPremium(true);
          
          // 購入完了を通知
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      }
    }
  }
  
  /// Premium状態を設定
  Future<void> _setPremium(bool value) async {
    if (_premium == value) return;
    
    _premium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    _premiumController.add(value);
  }
  
  /// リソースを解放
  void dispose() {
    _premiumController.close();
  }
}

/// 購入結果
class PurchaseResult {
  final bool success;
  final String? error;
  
  PurchaseResult({
    required this.success,
    this.error,
  });
}
