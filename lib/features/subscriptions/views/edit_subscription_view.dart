import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../../cards/providers/card_provider.dart';
import '../../cards/views/add_card_view.dart';
import '../../../../core/utils/icon_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../payments/services/payment_service.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/subscription_service.dart';
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

    if (!isPremium && currentSubscriptions.length > 6) {
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
    final cardsAsync = ref.watch(cardsProvider);

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
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      decoration: _inputDecoration('Tutar'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'))],
                      validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: _inputDecoration('Döviz'),
                      items: ['₺', '€', r'$'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _billingCycle,
                decoration: _inputDecoration('Ödeme Periyodu'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Haftalık')),
                  DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                  DropdownMenuItem(value: '3_months', child: Text('3 Aylık')),
                  DropdownMenuItem(value: '6_months', child: Text('6 Aylık')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                ],
                onChanged: (v) => setState(() => _billingCycle = v!),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (cats) {
                  final currentId = cats.any((c) => c['id'] == _selectedCategoryId) ? _selectedCategoryId : null;
                  return DropdownButtonFormField<String>(
                    value: currentId,
                    decoration: _inputDecoration('Kategori'),
                    hint: const Text('Kategori Seçin'),
                    items: cats.map((c) {
                      return DropdownMenuItem(
                        value: c['id'] as String,
                        child: Row(
                          children: [
                            if (c['icon_name'] != null)
                              FaIcon(
                                IconHelper.getIcon(c['icon_name'] as String),
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              )
                            else if (c['icon'] != null)
                              Icon(_getIconData(c['icon'] as String), size: 18),
                            const SizedBox(width: 8),
                            Text(c['name'] as String),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedServiceId != null ? null : (v) => setState(() => _selectedCategoryId = v),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Kategoriler yüklenemedi'),
              ),
              const SizedBox(height: 16),
              cardsAsync.when(
                data: (cards) {
                  final currentCardId = cards.any((c) => c.id == _selectedCardId) ? _selectedCardId : null;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: currentCardId,
                        decoration: _inputDecoration('Ödeme Yöntemi').copyWith(hintText: 'Kart Seçin (İsteğe Bağlı)'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Seçilmedi')),
                          ...cards.map(
                            (c) => DropdownMenuItem(value: c.id, child: Text('${c.cardName} ${c.lastFour}')),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedCardId = v),
                      ),
                      if (cards.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AddCardView(),
                              );
                            },
                            child: Text(
                              '+ Yeni Kart Ekle',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
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

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'movie':
        return Icons.movie_rounded;
      case 'play_circle':
        return Icons.play_circle_rounded;
      case 'code':
        return Icons.code_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  InputDecoration _inputDecoration(String label) {
    final radius = BorderRadius.circular(24);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
