import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';
import 'package:subsnap/features/subscriptions/presentation/subscription_templates_provider.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:subsnap/core/providers/settings_provider.dart';
import 'package:subsnap/core/providers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:subsnap/core/utils/currency_formatter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Future<void> _navigateToAddWithTemplate(SubscriptionTemplate template) async {
    // Template ile add sayfasına git ve result'ı bekle
    final result = await context.push('/home/dashboard/add', extra: template);
    // Eğer başarıyla döndüyse refresh yap
    if (result == true && mounted) {
      ref.refresh(subscriptionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: false,
        actions: [
          profileAsync.when(
            data: (profile) => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: GestureDetector(
                onTap: () => context.push('/home/settings'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: profile?.avatarUrl != null
                      ? ClipOval(
                          child: SvgPicture.network(
                            profile!.avatarUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            placeholderBuilder: (context) => const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('❌ [DASHBOARD] SVG yükleme hatası: $error');
                              return const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(Icons.error_outline, size: 20, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      : Text(
                          profile?.displayName?.isNotEmpty == true ? profile!.displayName![0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Provider'ı refresh et - bu yeniden fetch yapar
          ref.refresh(subscriptionsProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            // Header / Stats - Swipeable Cards
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: _ExpenseCardsView(),
              ),
            ),

            // Quick Add Section
            Consumer(
              builder: (context, ref, child) {
                // Önce ayarı kontrol et
                final showQuickAdd = ref.watch(showQuickAddProvider);
                if (!showQuickAdd) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }

                final templatesAsync = ref.watch(subscriptionTemplatesProvider);
                final subscriptionsAsync = ref.watch(subscriptionsProvider);

                return templatesAsync.when(
                  data: (templates) {
                    return subscriptionsAsync.when(
                      data: (subs) {
                        // Kullanıcının mevcut aboneliklerinin isimlerini al
                        final existingSubscriptionNames = subs.map((s) => s.name.toLowerCase()).toSet();

                        // Template'leri filtrele: eğer kullanıcının zaten o isimde aboneliği varsa gösterilmesin
                        final availableTemplates = templates.where((template) {
                          return !existingSubscriptionNames.contains(template.name.toLowerCase());
                        }).toList();

                        if (availableTemplates.isEmpty) {
                          return const SliverToBoxAdapter(child: SizedBox.shrink());
                        }

                        return SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Hızlı Ekle',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        ref.read(showQuickAddProvider.notifier).setShowQuickAdd(false);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Hızlı Ekle\'yi Gizle',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 48,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: availableTemplates.length,
                                    itemBuilder: (context, index) {
                                      final template = availableTemplates[index];
                                      return _QuickAddButton(
                                        template: template,
                                        onTap: () => _navigateToAddWithTemplate(template),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                  error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                );
              },
            ),

            // Subscriptions List
            subscriptionsAsync.when(
              data: (subs) {
                if (subs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('No subscriptions yet.\nTap + to add one!', textAlign: TextAlign.center),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = subs[index];
                      return _SubscriptionTile(subscription: sub);
                    },
                    childCount: subs.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Hata: $err')),
              ),
            ),

            // Padding at bottom for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends ConsumerWidget {
  final Subscription subscription;

  const _SubscriptionTile({required this.subscription});

  String _getBillingCycleText(BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        return 'Aylık';
      case BillingCycle.yearly:
        return 'Yıllık';
      case BillingCycle.weekly:
        return 'Haftalık';
      case BillingCycle.daily:
        return 'Günlük';
    }
  }

  SubscriptionTemplate? _findMatchingTemplate(
    String subscriptionName,
    List<SubscriptionTemplate> templates,
  ) {
    try {
      final normalizedName = subscriptionName.toLowerCase().trim();
      for (var template in templates) {
        if (template.name.toLowerCase().trim() == normalizedName) {
          return template;
        }
      }
    } catch (e) {
      // Hata durumunda null döndür
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(subscriptionTemplatesProvider);

    // Template'lerden eşleşen birini bul
    final matchingTemplate = templatesAsync.maybeWhen(
      data: (templates) => _findMatchingTemplate(subscription.name, templates),
      orElse: () => null,
    );

    // Eğer eşleşen template varsa ve geçerli bir icon'u varsa onu kullan
    final bool hasValidTemplate =
        matchingTemplate != null && matchingTemplate.id.isNotEmpty && matchingTemplate.iconName.isNotEmpty;

    return ListTile(
      onTap: () async {
        final result = await context.push('/home/dashboard/edit', extra: subscription);
        // Eğer başarıyla döndüyse refresh yap (save veya delete sonrası)
        if (result == true && context.mounted) {
          ref.refresh(subscriptionsProvider);
        }
      },
      leading: hasValidTemplate
          ? CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                matchingTemplate.iconData,
                color: matchingTemplate.iconColor,
                size: 24,
              ),
            )
          : CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: Text(
                subscription.name.isNotEmpty ? subscription.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              subscription.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (subscription.isPaused)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Dondurulmuş',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subscription.isPaused && subscription.pausedUntil != null
            ? 'Donduruldu: ${DateFormat.MMMd('tr_TR').format(subscription.pausedUntil!)}'
            : 'Sonraki: ${DateFormat.MMMd('tr_TR').format(subscription.nextPaymentDate)} • ${_getBillingCycleText(subscription.billingCycle)}',
        style: subscription.isPaused
            ? TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              )
            : null,
      ),
      trailing: Text(
        CurrencyFormatter.format(subscription.amount, currency: subscription.currency),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final SubscriptionTemplate template;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 80,
            maxWidth: 120,
            minHeight: 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon - SimpleIcons kullanılıyor
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey.shade100,
                ),
                child: Icon(
                  template.iconData,
                  size: 14,
                  color: template.iconColor,
                ),
              ),
              const SizedBox(width: 6),
              // Text yanında
              Flexible(
                child: Text(
                  template.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Swipeable Expense Cards Widget
class _ExpenseCardsView extends ConsumerStatefulWidget {
  const _ExpenseCardsView();

  @override
  ConsumerState<_ExpenseCardsView> createState() => _ExpenseCardsViewState();
}

class _ExpenseCardsViewState extends ConsumerState<_ExpenseCardsView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthlyCost = ref.watch(totalMonthlyCostProvider);
    final yearlyCost = ref.watch(totalYearlyCostProvider);
    final weeklyCost = ref.watch(totalWeeklyCostProvider);
    final dailyCost = ref.watch(totalDailyCostProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 140,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _ExpenseCard(
                title: 'Aylık Giderler',
                amount: monthlyCost,
                icon: Icons.calendar_month,
                isDark: isDark,
              ),
              _ExpenseCard(
                title: 'Yıllık Giderler',
                amount: yearlyCost,
                icon: Icons.calendar_today,
                isDark: isDark,
              ),
              _ExpenseCard(
                title: 'Haftalık Giderler',
                amount: weeklyCost,
                icon: Icons.date_range,
                isDark: isDark,
              ),
              _ExpenseCard(
                title: 'Günlük Giderler',
                amount: dailyCost,
                icon: Icons.today,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Page Indicator
        SizedBox(
          height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isActive = _currentPage == index;
              return Container(
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isDark
                      ? (isActive ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.3))
                      : (isActive
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// Individual Expense Card
class _ExpenseCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final bool isDark;

  const _ExpenseCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Koyu mod için farklı renkler

    final gradientColors = isDark
        ? [
            const Color(0xFF1E293B), // Slate 800
            const Color(0xFF334155), // Slate 700
          ]
        : [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(amount, currency: 'TRY'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.green.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
