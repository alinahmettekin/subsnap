import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:subsnap/features/subscriptions/presentation/payments_provider.dart';
import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/utils/currency_formatter.dart';
import 'package:subsnap/core/widgets/wheel_date_picker.dart';

enum PaymentType { subscription, custom }

/// Full-page screen for adding a payment (subscription or custom).
/// Replaces the previous dialog-based flow.
class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  PaymentType _paymentType = PaymentType.subscription;
  Subscription? _selectedSubscription;
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showWheelDatePicker(
      context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tutar girin')),
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar girin')),
      );
      return;
    }
    if (_paymentType == PaymentType.subscription && _selectedSubscription == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir abonelik seçin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = ref.read(authUserProvider).value?.id;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');

      final payment = Payment(
        id: const Uuid().v4(),
        subscriptionId: _selectedSubscription?.id,
        userId: userId,
        paymentDate: _selectedDate,
        amount: amount,
        currency: _selectedSubscription?.currency ?? 'TRY',
      );

      await ref.read(paymentsRepositoryProvider).createPayment(payment);
      ref.invalidate(paymentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme eklendi'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Ödeme türü
            Text(
              'Ödeme türü',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.subscriptions,
                    title: 'Mevcut Abonelik',
                    subtitle: 'Aboneliğiniz için',
                    selected: _paymentType == PaymentType.subscription,
                    onTap: () {
                      setState(() {
                        _paymentType = PaymentType.subscription;
                        _selectedSubscription = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeCard(
                    icon: Icons.payment,
                    title: 'Farklı Ödeme',
                    subtitle: 'Abonelik dışı',
                    selected: _paymentType == PaymentType.custom,
                    onTap: () {
                      setState(() {
                        _paymentType = PaymentType.custom;
                        _selectedSubscription = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2) Abonelik seç (sadece “Mevcut Abonelik” ise)
            if (_paymentType == PaymentType.subscription) ...[
              Text(
                'Abonelik seçin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              subscriptionsAsync.when(
                data: (subscriptions) {
                  if (subscriptions.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Henüz aboneliğiniz yok.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: subscriptions.map((sub) {
                      final isSelected = _selectedSubscription?.id == sub.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : theme.cardTheme.color ?? theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => _selectedSubscription = sub),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.surface,
                                child: Text(
                                  sub.name.isNotEmpty ? sub.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              title: Text(sub.name),
                              subtitle: Text(
                                CurrencyFormatter.format(sub.amount, currency: sub.currency),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Hata: $err', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3) Tutar & Tarih
            Text(
              'Tutar ve tarih',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Tutar',
                prefixIcon: Icon(Icons.payments),
                suffixText: 'TL',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tarih',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ödemeyi Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? (theme.colorScheme.primaryContainer)
          : (theme.cardTheme.color ?? theme.cardColor),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 28,
                color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
