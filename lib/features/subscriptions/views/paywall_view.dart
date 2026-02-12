import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/subscription_service.dart';

class PaywallView extends ConsumerStatefulWidget {
  const PaywallView({super.key});

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  bool _isLoading = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  bool _showDebugInfo = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
    _fetchCustomerInfo();
  }

  Future<void> _fetchCustomerInfo() async {
    try {
      _customerInfo = await Purchases.getCustomerInfo();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error fetching customer info: $e');
    }
  }

  Future<void> _fetchOfferings() async {
    setState(() => _isLoading = true);
    try {
      _offerings = await Purchases.getOfferings();

      // Debug logging
      debugPrint('=== OFFERINGS DEBUG ===');
      debugPrint('Offerings fetched: ${_offerings != null}');
      debugPrint('Current offering: ${_offerings?.current?.identifier}');
      debugPrint('Available offerings count: ${_offerings?.all.length}');

      if (_offerings?.current != null) {
        debugPrint('Current offering packages: ${_offerings!.current!.availablePackages.length}');
        for (var pkg in _offerings!.current!.availablePackages) {
          debugPrint('Package: ${pkg.identifier}');
          debugPrint('  - Product ID: ${pkg.storeProduct.identifier}');
          debugPrint('  - Title: ${pkg.storeProduct.title}');
          debugPrint('  - Price: ${pkg.storeProduct.priceString}');
        }
      } else {
        debugPrint('No current offering found!');
        debugPrint('All offerings: ${_offerings?.all.keys.toList()}');
      }
      debugPrint('======================');
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() => _isLoading = true);
    try {
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;
      if (SubscriptionService.checkPremium(customerInfo)) {
        if (mounted) {
          ref.invalidate(isPremiumProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Premium üyeliğiniz aktif edildi!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Satın alma başarısız: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium\'u Keşfedin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
            tooltip: 'Debug bilgisini ${_showDebugInfo ? 'gizle' : 'göster'}',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Debug Info Panel
                    if (_showDebugInfo) ...[
                      _DebugInfoPanel(offerings: _offerings, customerInfo: _customerInfo),
                      const SizedBox(height: 24),
                      const Divider(thickness: 2),
                      const SizedBox(height: 24),
                    ],
                    const Icon(Icons.workspace_premium_rounded, size: 80, color: Colors.amber),
                    const SizedBox(height: 24),
                    Text(
                      'Analizler ve Daha Fazlası',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const _BenefitItem(icon: Icons.analytics_rounded, text: 'Detaylı harcama analizleri ve grafikler'),
                    const _BenefitItem(icon: Icons.notifications_active_rounded, text: 'Akıllı ödeme hatırlatıcıları'),
                    const _BenefitItem(icon: Icons.all_inclusive_rounded, text: 'Sınırsız abonelik ekleme'),
                    const _BenefitItem(icon: Icons.cloud_done_rounded, text: 'Cihazlar arası anlık senkronizasyon'),
                    const SizedBox(height: 48),
                    if (_offerings != null && (_offerings!.current != null || _offerings!.all.isNotEmpty)) ...[
                      // Use current offering or fallback to 'subsnappro'
                      ...(_offerings!.current?.availablePackages ??
                              _offerings!.all['subsnappro']?.availablePackages ??
                              [])
                          .map(
                            (pkg) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: OutlinedButton(
                                onPressed: () => _purchasePackage(pkg),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: Column(
                                  children: [
                                    Text(pkg.storeProduct.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(pkg.storeProduct.priceString, style: theme.textTheme.titleMedium),
                                    if (pkg.packageType == PackageType.monthly)
                                      const Text(
                                        '1 Ay Ücretsiz Deneme Dahil',
                                        style: TextStyle(color: Colors.green, fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ] else ...[
                      const Text('Şu an uygun teklif bulunamadı.', textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                debugPrint('=== RESTORE PURCHASES ===');
                                CustomerInfo info = await Purchases.restorePurchases();

                                debugPrint('Restore completed. Customer Info:');
                                debugPrint('Active entitlements: ${info.entitlements.active.keys}');
                                debugPrint('All entitlements: ${info.entitlements.all.keys}');

                                if (SubscriptionService.checkPremium(info)) {
                                  if (mounted) {
                                    ref.invalidate(isPremiumProvider);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Premium aboneliğiniz geri yüklendi!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Geri yüklenecek premium abonelik bulunamadı.'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                debugPrint('Restore error: $e');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Geri yükleme hatası: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                      child: const Text('Satın alımları geri yükle'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _DebugInfoPanel extends StatelessWidget {
  final Offerings? offerings;
  final CustomerInfo? customerInfo;

  const _DebugInfoPanel({required this.offerings, required this.customerInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = customerInfo != null ? SubscriptionService.checkPremium(customerInfo!) : false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'DEBUG BİLGİSİ',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.amber),
          const SizedBox(height: 8),

          // Premium Status
          _InfoRow(
            label: 'Premium Durumu',
            value: isPremium ? '✅ AKTİF' : '❌ AKTİF DEĞİL',
            valueColor: isPremium ? Colors.green : Colors.red,
          ),

          const SizedBox(height: 12),
          Text('📦 OFFERINGS', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber)),
          const SizedBox(height: 4),

          if (offerings == null) ...[
            const _InfoRow(label: 'Durum', value: '⚠️ Offerings yüklenmedi'),
          ] else ...[
            _InfoRow(label: 'Current Offering', value: offerings!.current?.identifier ?? '❌ YOK'),
            _InfoRow(label: 'Toplam Offering Sayısı', value: '${offerings!.all.length}'),
            if (offerings!.all.isNotEmpty) ...[
              _InfoRow(label: 'Tüm Offering\'ler', value: offerings!.all.keys.join(', ')),
            ],
            const SizedBox(height: 8),

            // Packages
            if (offerings!.current != null) ...[
              Text(
                '📋 PAKETLER (${offerings!.current!.availablePackages.length})',
                style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber),
              ),
              const SizedBox(height: 4),
              ...offerings!.current!.availablePackages.map(
                (pkg) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: 'ID', value: pkg.identifier),
                      _InfoRow(label: 'Ürün ID', value: pkg.storeProduct.identifier),
                      _InfoRow(label: 'Başlık', value: pkg.storeProduct.title),
                      _InfoRow(label: 'Fiyat', value: pkg.storeProduct.priceString),
                      _InfoRow(label: 'Tip', value: pkg.packageType.toString()),
                    ],
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 12),
          Text('👤 CUSTOMER INFO', style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber)),
          const SizedBox(height: 4),

          if (customerInfo == null) ...[
            const _InfoRow(label: 'Durum', value: '⚠️ Customer Info yüklenmedi'),
          ] else ...[
            _InfoRow(
              label: 'Aktif Entitlement\'lar',
              value: customerInfo!.entitlements.active.isEmpty
                  ? '❌ YOK'
                  : customerInfo!.entitlements.active.keys.join(', '),
              valueColor: customerInfo!.entitlements.active.isEmpty ? Colors.red : Colors.green,
            ),
            _InfoRow(
              label: 'Tüm Entitlement\'lar',
              value: customerInfo!.entitlements.all.isEmpty ? '❌ YOK' : customerInfo!.entitlements.all.keys.join(', '),
            ),
            _InfoRow(
              label: '\'subsnap\' Entitlement',
              value: customerInfo!.entitlements.active.containsKey('subsnap') ? '✅ AKTİF' : '❌ AKTİF DEĞİL',
              valueColor: customerInfo!.entitlements.active.containsKey('subsnap') ? Colors.green : Colors.red,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
