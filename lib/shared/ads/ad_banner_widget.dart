import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_ids.dart';
import '../purchase/purchase_providers.dart';

/// バナー広告Widget
/// Premium状態でない場合のみ表示
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key});

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  static const int _maxLoadRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 3);

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _failedLoadRetries = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // IAP の SharedPreferences 反映後に読み込む（initState 直後だと未課金判定がずれる可能性）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!ref.read(isPremiumProvider)) _loadAd(resetRetries: true);
    });
  }

  void _disposeBannerOnly() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _bannerAd?.dispose();
    _bannerAd = null;
    _isAdLoaded = false;
  }

  void _loadAd({bool resetRetries = false}) {
    if (!kShowAds) return;

    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      return;
    }

    if (resetRetries) {
      _failedLoadRetries = 0;
    }

    _bannerAd?.dispose();
    _bannerAd = null;
    if (mounted) {
      setState(() {
        _isAdLoaded = false;
      });
    }

    final adUnitId = AdIds.bannerId;
    developer.log('バナー読み込み開始 unit=$adUnitId', name: 'Ads');

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _failedLoadRetries = 0;
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          developer.log(
            'バナー読み込み失敗 code=${error.code} domain=${error.domain} message=${error.message}',
            name: 'Ads',
            level: 1000,
          );
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
          _scheduleRetryIfNeeded();
        },
        onAdOpened: (_) {},
        onAdClosed: (_) {},
      ),
    );

    _bannerAd?.load();
  }

  void _scheduleRetryIfNeeded() {
    if (!mounted) return;
    if (ref.read(isPremiumProvider)) return;
    if (_failedLoadRetries >= _maxLoadRetries) {
      developer.log('バナー再試行上限（$_maxLoadRetries回）に達しました', name: 'Ads');
      return;
    }
    _failedLoadRetries++;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      if (ref.read(isPremiumProvider)) return;
      _loadAd();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kShowAds) return const SizedBox.shrink();

    ref.listen<bool>(isPremiumProvider, (previous, next) {
      if (next) {
        _retryTimer?.cancel();
        _disposeBannerOnly();
      } else if (previous == true) {
        // 課金状態が Premium → 非Premium に変わったときのみ再読み込み（初回の postFrame と二重にならない）
        _loadAd(resetRetries: true);
      }
    });

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
