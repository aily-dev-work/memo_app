import 'dart:async';
import 'dart:developer';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 課金（IAP）初期化の状態
enum IapInitState {
  /// queryProductDetails や purchaseStream購読の準備中
  initializing,
  /// 商品情報が取得でき、購入/復元が可能
  ready,
  /// 初期化に失敗（原因切り分けのためログを残す）
  failed,
}

/// 購入状態管理サービス
class PurchaseService {
  static const String _premiumKey = 'is_premium';
  static const String _productId = 'remove_ads';
  
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<bool> _premiumController = StreamController<bool>.broadcast();
  final StreamController<IapInitState> _initStateController = StreamController<IapInitState>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  IapInitState _initState = IapInitState.initializing;
  String? _lastInitError;
  
  bool _isAvailable = false;
  bool _premium = false;
  bool _isInitializing = false;
  bool _disposed = false;
  Future<void>? _initFuture;
  bool _isLoadingProducts = false;
  Future<bool>? _loadProductsFuture;
  bool _isPurchasing = false;
  ProductDetails? _productDetails;
  /// 直近の queryProductDetails 失敗時にユーザーへ見せる説明（成功時は null）
  String? _lastProductQueryUserMessage;
  
  /// Premium状態のストリーム
  Stream<bool> get premiumStream => _premiumController.stream;
  
  /// IAP初期化状態のストリーム
  /// Riverpod の StreamProvider は購読が遅れるとブロードキャストの過去イベントを取りこぼすため、
  /// 購読直後に必ず現在の [_initState] を1回 yield してから本体を追従する。
  Stream<IapInitState> get initStateStream async* {
    yield _initState;
    yield* _initStateController.stream;
  }
  IapInitState get initState => _initState;
  String? get lastInitError => _lastInitError;

  /// 現在のPremium状態
  bool get isPremium => _premium;
  
  /// 商品情報
  ProductDetails? get productDetails => _productDetails;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isPurchasing => _isPurchasing;
  String? get lastProductQueryUserMessage => _lastProductQueryUserMessage;

  /// [ProductDetailsResponse] からユーザー向けメッセージを組み立てる
  String _userFacingMessageForProductResponse(ProductDetailsResponse response) {
    final err = response.error;
    if (err != null) {
      return 'ストアから商品情報を取得できませんでした（${err.code}）。'
          '通信状況を確認し、時間をおいて再度お試しください。';
    }
    if (response.notFoundIDs.contains(_productId)) {
      return 'ストアに商品「$_productId」が見つかりません。'
          'App Store Connect で IAP がアプリに紐付けられ、販売可能な状態か、'
          '有料アプリの契約が有効かをご確認ください。';
    }
    if (response.productDetails.isEmpty) {
      return '商品一覧が空のまま返りました。ネットワークと App Store Connect 側の設定をご確認ください。';
    }
    return '商品情報を取得できませんでした。';
  }

  void _emitInitState(IapInitState state, {String? error}) {
    if (_disposed) return;
    if (_initState == state && _lastInitError == error) return;
    _initState = state;
    _lastInitError = error;
    _initStateController.add(state);
    if (error == null) {
      log('[IAP][INIT] state=$state');
    } else {
      log('[IAP][INIT] state=$state error=$error');
    }
  }

  /// 失敗時の再試行用（initialize に集約し、failed / 商品未取得のどちらでも同じ経路で再実行する）
  Future<void> retryIapSetup() async {
    log('[IAP][UI] retryIapSetup requested initState=$_initState productDetailsNull=${_productDetails == null}');
    await initialize();
  }
  
  /// 初期化（起動時に呼ぶ）
  Future<void> initialize() async {
    if (_disposed) return;

    // ready & 商品取得済みなら何もしない（失敗時や商品未取得時は再実行する）
    if (_initState == IapInitState.ready && _productDetails != null) {
      log('[IAP][INIT] initialize skipped: already ready');
      return;
    }

    // 多重呼び出し防止
    if (_isInitializing) {
      log('[IAP][INIT] initialize skipped: already initializing');
      if (_initFuture != null) {
        return await _initFuture;
      }
      return;
    }
    if (_initFuture != null) {
      log('[IAP][INIT] initialize skipped: initFuture in progress');
      return await _initFuture;
    }

    _isInitializing = true;
    _emitInitState(IapInitState.initializing);

    final initCompleter = Completer<void>();
    _initFuture = initCompleter.future;

    log('[IAP][INIT] initialize start');
    try {
      // ローカル保存から復元
      final prefs = await SharedPreferences.getInstance();
      _premium = prefs.getBool(_premiumKey) ?? false;
      _premiumController.add(_premium);

      // IAPが利用可能か確認
      _isAvailable = await _iap.isAvailable();
      log('[IAP][INIT] isAvailable=$_isAvailable');
      if (!_isAvailable) {
        throw Exception('IAP is not available');
      }

      // purchaseStream は二重登録しない
      if (_purchaseSubscription == null) {
        _purchaseSubscription = _iap.purchaseStream.listen(
          _handlePurchaseUpdate,
          onDone: () {
            log('[IAP][UPDATE] purchaseStream onDone');
            _purchaseSubscription = null;
          },
          onError: (error, stackTrace) {
            log('[IAP][UPDATE] purchaseStream onError error=$error stackTrace=$stackTrace');
          },
        );
      }

      // 商品情報を取得
      final productLoaded = await _loadProducts(reason: 'initialize');

      // restore はユーザー操作時のみ実行する。
      // 初期化中に restore を毎回走らせると購入準備が遅れ、
      // 「購入ボタン押下時にエラー」の再現率を上げるため。

      if (!productLoaded || _productDetails == null) {
        throw Exception('productDetails is empty after queryProductDetails');
      }

      _emitInitState(IapInitState.ready);
      log('[IAP][INIT] initialize done');
    } catch (e, st) {
      _emitInitState(IapInitState.failed, error: e.toString());
      log('[IAP][INIT] initialize failed error=$e stackTrace=$st');
    } finally {
      _isInitializing = false;
      initCompleter.complete();
      _initFuture = null;
    }
  }
  
  /// 商品情報を読み込む
  Future<bool> _loadProducts({required String reason}) async {
    if (!_isAvailable) return false;
    if (_disposed) return false;

    if (_isLoadingProducts) {
      log('[IAP][QUERY] _loadProducts skipped: already loading reason=$reason');
      return await (_loadProductsFuture ?? Future<bool>.value(_productDetails != null));
    }

    _isLoadingProducts = true;
    final completer = Completer<bool>();
    _loadProductsFuture = completer.future;

    // 方針B: 既存値を保持し、再取得成功時のみ上書きする。
    // 空結果や一時失敗で毎回nullにするとUIが不安定になり、原因切り分け時にもノイズが増えるため。
    try {
      // productIds は元値としてログ出力（順序のため list 化）
      final productIds = <String>[_productId];
      log(
        '[IAP][QUERY] _loadProducts start reason=$reason '
        'initState=$_initState isAvailable=$_isAvailable productIds=$productIds',
      );

      final response = await _iap.queryProductDetails(productIds.toSet());
      String notFoundLogValue = '<unavailable>';

      log('[IAP][QUERY] response.error=${response.error}');
      // notFoundIDs は型が不明なため dynamic 経由で取得（存在しない場合でも落とさない）
      notFoundLogValue = '${response.notFoundIDs}';
      log('[IAP][QUERY] notFoundIDs=$notFoundLogValue');

      log('[IAP][QUERY] productDetails.length=${response.productDetails.length}');
      if (response.productDetails.isEmpty) {
        log(
          '[IAP][QUERY] result=empty reason=$reason productIds=$productIds '
          'notFoundIDs=$notFoundLogValue responseType=${response.runtimeType}',
        );
        _lastProductQueryUserMessage = _userFacingMessageForProductResponse(response);
        completer.complete(false);
        return false;
      }

      _lastProductQueryUserMessage = null;
      _productDetails = response.productDetails.first;
      log('[IAP][QUERY] _productDetails set productID=${_productDetails?.id} price=${_productDetails?.price}');
      completer.complete(true);
      return true;
    } catch (e, st) {
      log('[IAP][QUERY] _loadProducts exception error=$e stackTrace=$st');
      _lastProductQueryUserMessage =
          '商品情報の取得中にエラーが発生しました。通信状況を確認のうえ、再度お試しください。';
      completer.complete(false);
      return false;
    } finally {
      if (!completer.isCompleted) {
        completer.complete(_productDetails != null);
      }
      _isLoadingProducts = false;
      _loadProductsFuture = null;
    }
  }
  
  /// 購入処理
  Future<PurchaseResult> buyPremium() async {
    log(
      '[IAP][PURCHASE] entry initState=$_initState isAvailable=$_isAvailable '
      'productDetailsNull=${_productDetails == null} loadingProducts=$_isLoadingProducts '
      'isPurchasing=$_isPurchasing',
    );
    if (_isPurchasing) {
      log('[IAP][PURCHASE] buyPremium skipped: already purchasing');
      return PurchaseResult(
        success: false,
        error: '購入処理を実行中です。しばらくしてからお試しください。',
      );
    }
    if (_initState != IapInitState.ready || _productDetails == null) {
      log(
        '[IAP][PURCHASE] ensure initialize before purchase '
        'initState=$_initState productDetailsNull=${_productDetails == null}',
      );
      await initialize();
      log(
        '[IAP][PURCHASE] after ensure initialize '
        'initState=$_initState isAvailable=$_isAvailable '
        'productDetailsNull=${_productDetails == null}',
      );
    }
    if (!_isAvailable) {
      return PurchaseResult(
        success: false,
        error: 'アプリ内課金が利用できません。ストアに接続してください。',
      );
    }

    // 商品情報未取得のまま押下された場合、再取得する（一時的なストア不調向けに短い待機後に1回だけ追試行）
    if (_productDetails == null) {
      log('[IAP][PURCHASE] buyPremium tapped but productDetails is null. retry _loadProducts()...');
      await _loadProducts(reason: 'buyPremium_retry');
      log('[IAP][PURCHASE] after retry productDetailsNull=${_productDetails == null}');
      if (_productDetails == null) {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        await _loadProducts(reason: 'buyPremium_retry_delayed');
        log(
          '[IAP][PURCHASE] after delayed retry productDetailsNull=${_productDetails == null}',
        );
      }
      if (_productDetails == null) {
        return PurchaseResult(
          success: false,
          error: _lastProductQueryUserMessage ?? '商品情報を取得できませんでした。',
        );
      }
    }

    _isPurchasing = true;
    try {
      log('[IAP][PURCHASE] buyNonConsumable invoked productId=$_productId productDetails.id=${_productDetails?.id}');
      final purchaseParam = PurchaseParam(
        productDetails: _productDetails!,
      );

      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        log('[IAP][PURCHASE] buyNonConsumable returned success=false (purchase flow not started)');
        return PurchaseResult(
          success: false,
          error: '購入処理を開始できませんでした。',
        );
      }

      log('[IAP][PURCHASE] buyNonConsumable returned success=true (purchase flow started; waiting purchaseStream)');

      // 購入ストリームで結果が来るので、ここでは待機しない
      return PurchaseResult(
        success: true,
        error: null,
      );
    } catch (e, st) {
      log('[IAP][PURCHASE] buyPremium exception error=$e stackTrace=$st');
      return PurchaseResult(
        success: false,
        error: '購入処理中にエラーが発生しました: $e',
      );
    } finally {
      _isPurchasing = false;
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
      log('[IAP][RESTORE] restorePurchases invoked');
      await _iap.restorePurchases();
      log('[IAP][RESTORE] restorePurchases completed (waiting purchaseStream)');
      // 復元結果は購入ストリームで処理される
      return PurchaseResult(
        success: true,
        error: null,
      );
    } catch (e, st) {
      log('[IAP][RESTORE] restorePurchases exception error=$e stackTrace=$st');
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
        log('[IAP][UPDATE] purchaseUpdate PENDING productID=${purchase.productID}');
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        log('[IAP][UPDATE] purchaseUpdate CANCELED productID=${purchase.productID}');
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        log('[IAP][UPDATE] purchaseUpdate ERROR productID=${purchase.productID} error=${purchase.error}');
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || 
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _productId) {
          log('[IAP][UPDATE] purchaseUpdate OK status=${purchase.status} productID=${purchase.productID}');
          await _setPremium(true);
          
          // 購入完了を通知
          if (purchase.pendingCompletePurchase) {
            try {
              log('[IAP][UPDATE] completePurchase invoked');
              await _iap.completePurchase(purchase);
              log('[IAP][UPDATE] completePurchase completed');
            } catch (e, st) {
              log('[IAP][UPDATE] completePurchase exception error=$e stackTrace=$st');
            }
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
    _disposed = true;
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _premiumController.close();
    _initStateController.close();
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
