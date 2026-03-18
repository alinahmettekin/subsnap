import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import 'widgets/subscription_icon.dart';
import '../../../core/widgets/confirm_sheet.dart';

class ArchivedSubscriptionsView extends ConsumerWidget {
  const ArchivedSubscriptionsView({super.key});

  Future<void> _handleRestore(BuildContext context, WidgetRef ref, Subscription sub) async {
    final confirmed = await ConfirmSheet.show(
      context,
      title: 'Tekrar Aktifleştir?',
      message: '${sub.name} aboneliğini tekrar aktif aboneliklerinize eklemek istediğinize emin misiniz?',
      confirmLabel: 'Aktifleştir',
    );

    if (confirmed != true) return;

    try {
      await ref.read(subscriptionRepositoryProvider).restoreSubscription(sub.id);
      if (context.mounted) {
        ref.invalidate(subscriptionsProvider); // Refresh active
        ref.invalidate(archivedSubscriptionsProvider); // Refresh archived
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik tekrar aktif edildi'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _handleDeleteForever(BuildContext context, WidgetRef ref, Subscription sub) async {
    // Show confirmation dialog
    final confirm = await ConfirmSheet.show(
      context,
      title: 'Kalıcı Olarak Sil?',
      message: 'Bu işlem aboneliği ve TÜM GEÇMİŞ ÖDEMELERİ kalıcı olarak silecektir. Bu işlem geri alınamaz.',
      confirmLabel: 'Sil',
      isDestructive: true,
    );

    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(subscriptionRepositoryProvider).deleteSubscriptionWithPayments(sub.id);
      if (context.mounted) {
        ref.invalidate(archivedSubscriptionsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik kalıcı olarak silindi'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _handleEditPrice(BuildContext context, WidgetRef ref, Subscription sub) {
    final controller = TextEditingController(text: sub.price.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ücreti Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${sub.name} aboneliğinin arşivdeki ücretini güncelleyin:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tutar',
                suffixText: sub.currency,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                final updatedSub = sub.copyWith(price: newPrice);
                await ref.read(subscriptionRepositoryProvider).updateSubscription(updatedSub);
                ref.invalidate(archivedSubscriptionsProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  String _getBillingCycleText(String cycle) {
    switch (cycle) {
      case 'weekly':
        return 'Haftalık';
      case 'monthly':
        return 'Aylık';
      case '3_months':
        return '3 Aylık';
      case '6_months':
        return '6 Aylık';
      case 'yearly':
        return 'Yıllık';
      case 'custom':
        return 'Özel';
      default:
        return cycle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedSubscriptionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('İptal Edilen Abonelikler'), centerTitle: true),
      body: archivedAsync.when(
        data: (subs) {
          if (subs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_outlined, size: 64, color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'İptal edilen abonelik yok',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sub = subs[index];
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Opacity(opacity: 0.6, child: SubscriptionIcon(subscription: sub)),
                  title: Text(
                    sub.name,
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                  ),
                  subtitle: Text(
                    '${sub.price} ${sub.currency} • ${_getBillingCycleText(sub.billingCycle)}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ücreti Düzenle',
                        icon: const Icon(Icons.edit_rounded, size: 20),
                        color: theme.colorScheme.secondary,
                        onPressed: () => _handleEditPrice(context, ref, sub),
                      ),
                      IconButton(
                        tooltip: 'Tekrar Aktif Et',
                        icon: const Icon(Icons.restore_rounded),
                        color: theme.colorScheme.primary,
                        onPressed: () => _handleRestore(context, ref, sub),
                      ),
                      IconButton(
                        tooltip: 'Tamamen Sil',
                        icon: const Icon(Icons.delete_forever_rounded),
                        color: theme.colorScheme.error,
                        onPressed: () => _handleDeleteForever(context, ref, sub),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
    );
  }
}
