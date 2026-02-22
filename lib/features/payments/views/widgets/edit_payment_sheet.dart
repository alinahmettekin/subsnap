import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../../cards/providers/card_provider.dart';
import '../../../cards/models/card.dart';
import '../../../cards/views/add_card_view.dart';
import '../../../../features/subscriptions/models/subscription.dart';

class EditPaymentSheet extends ConsumerStatefulWidget {
  final Payment payment;
  final Subscription? subscription;

  const EditPaymentSheet({super.key, required this.payment, this.subscription});

  @override
  ConsumerState<EditPaymentSheet> createState() => _EditPaymentSheetState();
}

class _EditPaymentSheetState extends ConsumerState<EditPaymentSheet> {
  late TextEditingController _amountController;
  String? _selectedCardId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.payment.amount.toString());
    _selectedCardId = widget.payment.cardId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(paymentServiceProvider).updatePayment(widget.payment.id, {
        'amount': amount,
        'card_id': _selectedCardId,
      });

      if (mounted) {
        ref.invalidate(paymentHistoryProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ödeme güncellendi'), backgroundColor: Colors.green));
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
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(allCardsProvider);

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Ödemeyi Düzenle',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.subscription?.name ?? 'Bilinmeyen Abonelik',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
            decoration: InputDecoration(
              labelText: 'Tutar',
              suffixText: widget.payment.currency,
              prefixIcon: const Icon(Icons.payments_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 16),
          cardsAsync.when(
            data: (cards) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String?>(
                  value: _selectedCardId,
                  dropdownColor: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  decoration: InputDecoration(
                    labelText: 'Ödeme Yöntemi',
                    prefixIcon: const Icon(Icons.credit_card_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Kart Seçilmedi')),
                    ...cards
                        .where((c) => !c.isDeleted || c.id == widget.payment.cardId)
                        .map(
                          (card) => DropdownMenuItem<String?>(
                            value: card.id,
                            child: Text(
                              '${card.cardName} (**** ${card.lastFour})${card.isDeleted ? ' (Silinmiş)' : ''}',
                              style: TextStyle(
                                color: card.isDeleted ? theme.colorScheme.error : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                  ],
                  onChanged: (val) => setState(() => _selectedCardId = val),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const AddCardView(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Yeni Kart Ekle'),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Kartlar yüklenemedi'),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _isLoading ? null : _update,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Güncelle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
