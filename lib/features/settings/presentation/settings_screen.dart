import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/purchase/purchase_providers.dart';
import '../../../shared/purchase/purchase_service.dart';

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
      backgroundColor: const Color(0xFFE8E6E1),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFE8E6E1),
        foregroundColor: Colors.grey.shade900,
        title: const Text(
          '設定',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // 広告削除セクション
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.zero,
              border: Border.all(
                color: Colors.grey.shade200,
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
                      color: isPremium ? Colors.green : Colors.grey.shade600,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '広告を削除',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade900,
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
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
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
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    '一度購入すると、広告が表示されなくなります。',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _handlePurchase(context, purchaseService),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleRestore(context, purchaseService),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
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
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, PurchaseService service) async {
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
