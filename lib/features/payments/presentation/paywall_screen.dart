import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/subscriptions/data/subscription_service.dart';
import 'package:subsnap/features/subscriptions/presentation/subscription_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Package? _selectedPackage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SubSnap Pro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark ? [const Color(0xFF1E1E2E), const Color(0xFF11111B)] : [const Color(0xFF6366F1), Colors.white],
            stops: const [0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.stars, size: 60, color: Colors.amber),
              const SizedBox(height: 12),
              const Text(
                'Sınırsız Güç, Sınırsız Takip',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeatureRow(context, Icons.analytics, 'Gelişmiş Analizler',
                            'Harcamalarınızı detaylı grafiklerle inceleyin.'),
                        _buildFeatureRow(context, Icons.notifications_active, 'Akıllı Hatırlatıcılar',
                            'Ödeme günlerini asla kaçırmayın.'),
                        _buildFeatureRow(
                            context, Icons.cloud_done, 'Sınırsız Veri', 'Sınırsız abonelik ve ödeme kaydı ekleyin.'),
                        _buildFeatureRow(
                            context, Icons.block, 'Reklamsız Deneyim', 'Sadece aboneliklerinize odaklanın.'),

                        const SizedBox(height: 20),
                        const Text(
                          'Plan Seçin',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 12),

                        offeringsAsync.when(
                          data: (packages) {
                            if (packages.isEmpty) {
                              return const Center(child: Text('Paketler yüklenemedi.'));
                            }

                            // Initialize selection if needed
                            if (_selectedPackage == null && packages.isNotEmpty) {
                               // Default to annual/yearly if available, or first
                               final yearly = packages.where((p) => p.packageType == PackageType.annual).firstOrNull;
                               WidgetsBinding.instance.addPostFrameCallback((_) {
                                 setState(() {
                                    _selectedPackage = yearly ?? packages.first;
                                 });
                               });
                            }

                            return Column(
                              children: packages.map((package) {
                                final isYearly = package.packageType == PackageType.annual;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildPlanCard(
                                    context: context,
                                    title: package.storeProduct.title,
                                    price: package.storeProduct.priceString,
                                    subtitle: package.storeProduct.description,
                                    isSelected: _selectedPackage?.identifier == package.identifier,
                                    onTap: () => setState(() => _selectedPackage = package),
                                    isBestValue: isYearly,
                                  ),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Hata: $err')),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: FilledButton(
                            onPressed: (_isLoading || _selectedPackage == null)
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    try {
                                      final success = await SubscriptionService.purchasePackage(_selectedPackage!);
                                      if (success) {
                                        ref.read(isProUserProvider.notifier).state = true;
                                        if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("SubSnap Pro'ya hoşgeldiniz!")),
                                            );
                                        }
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isLoading = false);
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _selectedPackage != null
                                      ? '${_selectedPackage!.storeProduct.priceString} ile Pro\'ya Geç'
                                      : 'Plan Seçiniz',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              setState(() => _isLoading = true);
                              try {
                                final success = await SubscriptionService.restorePurchases();
                                if (success) {
                                  ref.read(isProUserProvider.notifier).state = true;
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Satın alımlar geri yüklendi.")),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Aktif abonelik bulunamadı.")),
                                    );
                                  }
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                            child: const Text(
                              'Satın Alımları Geri Yükle',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String price,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isBestValue = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EN AVANTAJLI',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6366F1)),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
