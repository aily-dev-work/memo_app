import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/purchase/purchase_providers.dart';
import '../../../shared/purchase/purchase_service.dart';
import '../../../shared/theme/app_colors.dart';
import 'help_guide_screen.dart';

/// 設定画面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;
  bool _previousPremium = false;

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final productDetails = ref.watch(productDetailsProvider);
    final purchaseService = ref.watch(purchaseServiceProvider);
    final iapStateAsync = ref.watch(iapInitStateProvider);
    final currentIapState = ref.watch(currentIapInitStateProvider);
    final iapState = iapStateAsync.when(
      data: (s) => s,
      loading: () => currentIapState,
      error: (_, __) => currentIapState,
    );
    final iapReady = iapState == IapInitState.ready;
    final canPurchase = !isPremium && iapReady && productDetails != null;
    final showInitializing = iapState == IapInitState.initializing;
    
    // 購入状態の変化を監視
    if (isPremium && !_previousPremium && _previousPremium != isPremium) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('広告が削除されました！'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }
    _previousPremium = isPremium;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // 使い方
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppColors.borderRadius,
              border: Border.all(
                color: AppColors.outline,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              leading: const Icon(
                Icons.help_outline,
                color: AppColors.inkSecondary,
              ),
              title: const Text(
                '使い方',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: const Text(
                '基本操作を確認する',
                style: TextStyle(
                  fontSize: 14.0,
                  color: AppColors.inkSecondary,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.inkTertiary,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpGuideScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // 広告削除セクション
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppColors.borderRadius,
              border: Border.all(
                color: AppColors.outline,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPremium ? Icons.check_circle : Icons.ads_click,
                      color: isPremium ? Colors.green : AppColors.inkSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '広告を削除',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: AppColors.borderRadius,
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '広告は表示されません',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (productDetails != null) ...[
                    Text(
                      '価格: ${productDetails.price}',
                      style: const TextStyle(
                        fontSize: 16.0,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showInitializing) ...[
                    const Text(
                      '課金情報を読み込み中です。',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    '一度購入すると、広告が表示されなくなります。',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !canPurchase)
                          ? null
                          : () => _handlePurchase(context, purchaseService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppColors.borderRadius,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              '広告を削除（購入）',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
                if (!isPremium) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_isLoading || !iapReady)
                          ? null
                          : () => _handleRestore(context, purchaseService),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(color: AppColors.outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppColors.borderRadius,
                        ),
                      ),
                      child: const Text(
                        '購入を復元',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, PurchaseService service) async {
    log('[IAP][UI] purchase button tapped');
    if (service.initState != IapInitState.ready || service.productDetails == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('課金情報を準備中です。しばらくしてからお試しください。'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await service.buyPremium();

      if (!mounted) return;

      if (result.success) {
        // 購入処理はストリームで完了を待つ
        // ここでは成功メッセージを表示しない（ストリームで処理される）
      } else {
        _showErrorDialog(context, result.error ?? '購入処理に失敗しました。');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, 'エラーが発生しました: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, PurchaseService service) async {
    log('[IAP][UI] restore button tapped');
    setState(() => _isLoading = true);

    try {
      final result = await service.restorePurchases();

      if (!mounted) return;

      if (result.success) {
        // 復元結果はストリームで処理される
        // 少し待ってから結果を確認
        await Future.delayed(const Duration(seconds: 2));
        
        final isPremium = ref.read(isPremiumProvider);
        if (isPremium) {
          _showSuccessDialog(context, '購入が復元されました。');
        } else {
          _showErrorDialog(context, '復元できる購入が見つかりませんでした。');
        }
      } else {
        _showErrorDialog(context, result.error ?? '復元処理に失敗しました。');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, 'エラーが発生しました: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
