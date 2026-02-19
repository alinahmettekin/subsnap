import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../subscriptions/models/subscription.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';
import '../../../../core/widgets/custom_date_picker.dart';

class AddPaymentView extends ConsumerStatefulWidget {
  const AddPaymentView({super.key});

  @override
  ConsumerState<AddPaymentView> createState() => _AddPaymentViewState();
}

class _AddPaymentViewState extends ConsumerState<AddPaymentView> {
  final _formKey = GlobalKey<FormState>();
  Subscription? _selectedSubscription;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onSubscriptionChanged(Subscription? sub) {
    setState(() {
      _selectedSubscription = sub;
      if (sub != null) {
        _amountController.text = sub.price.toString();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedSubscription == null) return;

    setState(() => _isLoading = true);

    try {
      final sub = _selectedSubscription!;
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      final payment = Payment(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        userId: sub.userId,
        subscriptionId: sub.id,
        amount: amount,
        currency: sub.currency,
        dueDate: _selectedDate,
        paidAt: _selectedDate,
        status: 'paid',
        cardId: sub.cardId,
      );

      await ref.read(paymentServiceProvider).createPayment(payment);

      if (mounted) {
        ref.invalidate(paymentHistoryProvider);
        ref.invalidate(subscriptionsProvider);
        ref.invalidate(allSubscriptionsProvider);
        ref.invalidate(upcomingPaymentsProvider);
        ref.invalidate(paymentHistoryProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ödeme başarıyla eklendi'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show active subscriptions for adding new payment
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Ödeme Ekle',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          subscriptionsAsync.when(
            data: (subs) {
              if (subs.isEmpty) {
                return const Center(child: Text('Önce bir abonelik ekleyin.'));
              }

              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<Subscription>(
                      initialValue: _selectedSubscription,
                      dropdownColor: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      decoration: InputDecoration(
                        labelText: 'Abonelik Seç',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      items: subs
                          .map(
                            (sub) => DropdownMenuItem(
                              value: sub,
                              child: Text(
                                '${sub.name} (${sub.price} ${sub.currency})',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onSubscriptionChanged,
                      validator: (val) => val == null ? 'Lütfen abonelik seçin' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Tutar',
                        suffixText: _selectedSubscription?.currency ?? '',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Tutar girin';
                        if (double.tryParse(val) == null) return 'Geçersiz tutar';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () async {
                        await showCustomDatePicker(
                          context,
                          initialDate: _selectedDate,
                          minDate: DateTime(2024),
                          maxDate: DateTime.now(), // Payment date cannot be in future? Usually yes for past payments.
                          onDateChanged: (val) => setState(() => _selectedDate = val),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ödeme Tarihi',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Center(
              child: Padding(padding: EdgeInsets.all(32), child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
