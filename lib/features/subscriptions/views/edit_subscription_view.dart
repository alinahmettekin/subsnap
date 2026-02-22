import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../../cards/providers/card_provider.dart';
import '../../cards/views/add_card_view.dart';
import '../../payments/services/payment_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/subscription_service.dart';
import '../../cards/models/card.dart';
import 'paywall_view.dart';

class EditSubscriptionView extends ConsumerStatefulWidget {
  final Subscription subscription;

  const EditSubscriptionView({super.key, required this.subscription});

  @override
  ConsumerState<EditSubscriptionView> createState() => _EditSubscriptionViewState();
}

class _EditSubscriptionViewState extends ConsumerState<EditSubscriptionView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  final _priceFocusNode = FocusNode();
  late String _billingCycle;
  late String _currency;
  late DateTime _nextBillingDate;
  String? _selectedCategoryId;
  String? _selectedServiceId;
  String? _selectedCardId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub.name);
    _priceController = TextEditingController(text: sub.price.toString());
    _billingCycle = sub.billingCycle;
    _currency = sub.currency;
    _nextBillingDate = sub.nextBillingDate;
    _selectedCategoryId = sub.categoryId;
    _selectedServiceId = sub.serviceId;
    _selectedCardId = sub.cardId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bitti', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: _nextBillingDate,
                mode: CupertinoDatePickerMode.date,
                dateOrder: DatePickerDateOrder.dmy,
                use24hFormat: true,
                minimumDate: DateTime(2000),
                maximumDate: DateTime.now().add(const Duration(days: 365 * 10)),
                onDateTimeChanged: (val) {
                  setState(() => _nextBillingDate = val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isPremium = ref.read(isPremiumProvider).asData?.value ?? false;
    final currentSubscriptions = ref.read(subscriptionsProvider).asData?.value ?? [];

    if (!isPremium && currentSubscriptions.length >= 6) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Düzenleme Kısıtlı'),
            content: const Text(
              'Ücretsiz planda limitiniz (6) aşıldığı için düzenleme yapamazsınız. Önce bazı abonelikleri silin veya Premium\'a geçin.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
                },
                child: const Text('Premium\'a Geç'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

      final updatedSub = widget.subscription.copyWith(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        currency: _currency,
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        categoryId: _selectedCategoryId,
        cardId: _selectedCardId,
        serviceId: _selectedServiceId,
      );

      await ref.read(subscriptionRepositoryProvider).updateSubscription(updatedSub);

      if (mounted) {
        ref.invalidate(subscriptionsProvider);
        ref.invalidate(allSubscriptionsProvider);
        ref.invalidate(upcomingPaymentsProvider);
        ref.invalidate(paymentHistoryProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik güncellendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _hasChanges() {
    final sub = widget.subscription;
    final currentPrice = double.tryParse(_priceController.text) ?? 0.0;
    final isSameDate =
        sub.nextBillingDate.year == _nextBillingDate.year &&
        sub.nextBillingDate.month == _nextBillingDate.month &&
        sub.nextBillingDate.day == _nextBillingDate.day;

    return sub.name != _nameController.text ||
        sub.price != currentPrice ||
        sub.currency != _currency ||
        sub.billingCycle != _billingCycle ||
        !isSameDate ||
        sub.categoryId != _selectedCategoryId ||
        sub.cardId != _selectedCardId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cardsAsync = ref.watch(allCardsProvider);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aboneliği Düzenle',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Abonelik Adı'),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
                enabled: _selectedServiceId == null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                focusNode: _priceFocusNode,
                decoration: _inputDecoration('Tutar').copyWith(
                  hintText: '79.99',
                  suffixText: '₺',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildSelectionField(
                label: 'Ödeme Periyodu',
                value: _getBillingCycleText(_billingCycle),
                icon: Icons.repeat_rounded,
                onTap: _showBillingCycleSheet,
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (cats) {
                  final selectedCat = cats.firstWhere(
                    (c) => c['id'] == _selectedCategoryId,
                    orElse: () => <String, dynamic>{},
                  );
                  final hasSelection = selectedCat.isNotEmpty;
                  return _buildSelectionField(
                    label: 'Kategori',
                    value: hasSelection ? selectedCat['name'] as String : 'Diğer',
                    icon: Icons.category_outlined,
                    onTap: _selectedServiceId != null ? null : () => _showCategorySheet(cats),
                    prefixIcon: hasSelection
                        ? Image.asset(
                            'assets/categories/${selectedCat['icon_name']}.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset('assets/categories/other.png', width: 20, height: 20),
                          )
                        : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              cardsAsync.when(
                data: (cards) {
                  final selectedCard = cards.cast<PaymentCard?>().firstWhere(
                    (c) => c?.id == _selectedCardId,
                    orElse: () => null,
                  );
                  return _buildSelectionField(
                    label: 'Ödeme Yöntemi',
                    value: selectedCard != null
                        ? '${selectedCard.cardName} (**** ${selectedCard.lastFour})${selectedCard.isDeleted ? ' (Silinmiş)' : ''}'
                        : 'Seçilmedi',
                    prefixIcon: Image.asset(
                      'assets/services/credit_card.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.credit_card_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    onTap: () => _showCardSheet(cards),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sıradaki Ödeme', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr_TR').format(_nextBillingDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_hasChanges())
                FilledButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_isLoading ? 'Güncelleniyor...' : 'Güncelle'),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionField({
    required String label,
    required String value,
    IconData? icon,
    required VoidCallback? onTap,
    Widget? prefixIcon,
  }) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(24);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: radius,
        ),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              prefixIcon,
              const SizedBox(width: 12),
            ] else ...[
              Icon(icon, size: 22, color: theme.hintColor.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.hintColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onTap == null ? theme.disabledColor : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: theme.hintColor),
          ],
        ),
      ),
    );
  }

  void _showBillingCycleSheet() {
    final cycles = {
      'weekly': 'Haftalık',
      'monthly': 'Aylık',
      '3_months': '3 Aylık',
      '6_months': '6 Aylık',
      'yearly': 'Yıllık',
    };

    _showModernSheet(
      title: 'Ödeme Periyodu Seç',
      children: cycles.entries.map((e) {
        return _buildSheetItem(
          title: e.value,
          isSelected: _billingCycle == e.key,
          onTap: () {
            setState(() => _billingCycle = e.key);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showCardSheet(List<PaymentCard> cards) {
    final theme = Theme.of(context);
    _showModernSheet(
      title: 'Ödeme Yöntemi Seç',
      children: [
        ...cards.where((c) => !c.isDeleted || c.id == _selectedCardId).map((c) {
          return _buildSheetItem(
            title: '${c.cardName} (**** ${c.lastFour})${c.isDeleted ? ' (Silinmiş)' : ''}',
            isSelected: _selectedCardId == c.id,
            prefix: Image.asset(
              'assets/services/credit_card.png',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.credit_card_rounded, size: 20, color: theme.colorScheme.primary),
            ),
            onTap: () {
              setState(() => _selectedCardId = c.id);
              Navigator.pop(context);
            },
          );
        }),
        _buildSheetItem(
          title: 'Seçilmedi',
          isSelected: _selectedCardId == null,
          prefix: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
          onTap: () {
            setState(() => _selectedCardId = null);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddCardView(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              foregroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Kart Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(List<dynamic> cats) {
    _showModernSheet(
      title: 'Kategori Seç',
      children: cats.map((c) {
        return _buildSheetItem(
          title: c['name'] as String,
          isSelected: _selectedCategoryId == c['id'],
          prefix: Image.asset(
            'assets/categories/${c['icon_name']}.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/categories/other.png', width: 22, height: 22),
          ),
          onTap: () {
            setState(() => _selectedCategoryId = c['id'] as String);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showModernSheet({required String title, required List<Widget> children}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.45,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32, left: 16, right: 16),
                child: Column(children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    Widget? prefix,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? theme.primaryColor.withOpacity(0.3) : theme.dividerColor.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix, const SizedBox(width: 16)],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? theme.primaryColor : null,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 20),
            ],
          ),
        ),
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
      default:
        return 'Aylık';
    }
  }

  InputDecoration _inputDecoration(String label) {
    final radius = BorderRadius.circular(24);
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
      ),
    );
  }
}
