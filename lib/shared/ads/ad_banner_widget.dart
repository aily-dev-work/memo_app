import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import '../purchase/purchase_providers.dart';

/// バナー広告Widget
/// Premium状態でない場合のみ表示
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (!kShowAds) return;

    // Premium状態を確認
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      return; // Premiumユーザーには広告を表示しない
    }

    // テスト用広告ID（本番では実際の広告IDに置き換える）
    final adUnitId = _getAdUnitId();
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
        onAdOpened: (_) {},
        onAdClosed: (_) {},
      ),
    );

    _bannerAd?.load();
  }

  String _getAdUnitId() {
    // テスト用広告ID
    // 本番では、iOS/Androidそれぞれの実際の広告IDを使用
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android テスト用
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOS テスト用
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // デフォルト
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kShowAds) return const SizedBox.shrink();

    final isPremium = ref.watch(isPremiumProvider);

    // Premiumユーザーには広告を表示しない
    if (isPremium) {
      return const SizedBox.shrink();
    }

    // 広告が読み込まれていない場合は非表示
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
