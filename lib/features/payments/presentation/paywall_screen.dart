import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/payments/presentation/iap_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedProductId = proPlanYearlyId;

  @override
  Widget build(BuildContext context) {
    final iapState = ref.watch(iapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final monthlyProduct = iapState.products.where((p) => p.id == proPlanMonthlyId).firstOrNull;
    final yearlyProduct = iapState.products.where((p) => p.id == proPlanYearlyId).firstOrNull;
    final selectedProduct = _selectedProductId == proPlanMonthlyId ? monthlyProduct : yearlyProduct;

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

                        // Monthly Plan Card
                        _buildPlanCard(
                          context: context,
                          title: 'Aylık',
                          price: monthlyProduct?.price ?? '₺9.99',
                          subtitle: 'Aydan aya ödeme esnekliği',
                          isSelected: _selectedProductId == proPlanMonthlyId,
                          onTap: () => setState(() => _selectedProductId = proPlanMonthlyId),
                        ),
                        const SizedBox(height: 12),

                        // Yearly Plan Card
                        _buildPlanCard(
                          context: context,
                          title: 'Yıllık',
                          price: yearlyProduct?.price ?? '₺99.99',
                          subtitle: 'En iyi değer, yıllık tasarruf',
                          isSelected: _selectedProductId == proPlanYearlyId,
                          onTap: () => setState(() => _selectedProductId = proPlanYearlyId),
                          isBestValue: true,
                        ),

                        const SizedBox(height: 32),
                        if (iapState.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              iapState.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: FilledButton(
                            onPressed: (iapState.isLoading || selectedProduct == null)
                                ? null
                                : () => ref.read(iapProvider.notifier).buyPro(selectedProduct),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: iapState.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    '${_selectedProductId == proPlanMonthlyId ? "Aylık" : "Yıllık"} Pro\'ya Geç',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'İstediğiniz zaman iptal edebilirsiniz.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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
