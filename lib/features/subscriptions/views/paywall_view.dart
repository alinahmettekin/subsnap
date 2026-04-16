import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/constants.dart';
import '../../../core/services/subscription_service.dart';
import 'widgets/pricing_card.dart';

class PaywallView extends ConsumerStatefulWidget {
  const PaywallView({super.key});

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  bool _isLoading = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    setState(() => _isLoading = true);
    try {
      _offerings = await Purchases.getOfferings();
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
            const SnackBar(
              content: Text('Premium üyeliğiniz aktif edildi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Purchase error: $e');
      if (mounted) {
        final errorStr = e.toString();
        final isCancelled = errorStr.contains('userCancelled: true') ||
            errorStr.contains('PurchaseCancelledError') ||
            errorStr.contains('USER_CANCELED');

        if (!isCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bir sorun oluştu. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Analizler ve Daha Fazlası',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const _BenefitItem(
                    icon: Icons.all_inclusive_rounded,
                    text: 'Sınırsız abonelik ekle ve yönet',
                  ),
                  const _BenefitItem(
                    icon: Icons.credit_card_rounded,
                    text: 'Sınırsız ödeme kartı oluştur ve düzenle',
                  ),
                  const _BenefitItem(
                    icon: Icons.analytics_rounded,
                    text: 'Detaylı harcama analizleri ve grafikler',
                  ),
                  const _BenefitItem(
                    icon: Icons.notifications_active_rounded,
                    text: 'Akıllı ödeme hatırlatıcıları',
                  ),
                  const _BenefitItem(
                    icon: Icons.cloud_done_rounded,
                    text: 'Cihazlar arası anlık senkronizasyon',
                  ),
                  const SizedBox(height: 48),
                  if (_offerings != null &&
                      (_offerings!.current != null ||
                          _offerings!.all.isNotEmpty)) ...[
                    ...(_offerings!.current?.availablePackages ??
                            _offerings!.all['subsnappro']?.availablePackages ??
                            [])
                        .map(
                      (pkg) => PricingCard(
                        package: pkg,
                        onTap: () => _purchasePackage(pkg),
                        isSelected: true,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Şu an uygun teklif bulunamadı.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              CustomerInfo info =
                                  await Purchases.restorePurchases();
                              if (SubscriptionService.checkPremium(info)) {
                                if (mounted) {
                                  ref.invalidate(isPremiumProvider);
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Premium aboneliğiniz geri yüklendi!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Geri yüklenecek premium abonelik bulunamadı.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Geri yükleme sırasında bir sorun oluştu.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                    child: const Text('Satın alımları geri yükle'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Abonelik Bilgileri: Ödemeniz onaylandığında Apple ID hesabınıza yansıtılacaktır. Abonelik, mevcut dönemin bitiminden en az 24 saat önce iptal edilmediği sürece otomatik olarak yenilenir. Yenileme ücreti mevcut dönemin bitiminden 24 saat önce hesabınızdan tahsil edilecektir. Aboneliklerinizi App Store hesap ayarlarından yönetebilir ve iptal edebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color:
                            theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(AppConstants.termsOfUseUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          'Kullanım Koşulları',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                      TextButton(
                        onPressed: () => launchUrl(
                          Uri.parse(AppConstants.privacyPolicyUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(
                          'Gizlilik Politikası',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
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
