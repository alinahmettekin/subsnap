import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import 'paywall_view.dart';
import '../../cards/providers/card_provider.dart';
import '../../cards/views/add_card_view.dart';
import '../models/service.dart';
import '../../payments/services/payment_service.dart';
import '../../cards/models/card.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/custom_date_picker.dart';

class AddSubscriptionView extends ConsumerStatefulWidget {
  const AddSubscriptionView({super.key});

  @override
  ConsumerState<AddSubscriptionView> createState() => _AddSubscriptionViewState();
}

class _AddSubscriptionViewState extends ConsumerState<AddSubscriptionView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();
  String _billingCycle = 'monthly';
  String _currency = '₺';
  DateTime _nextBillingDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedServiceId = 'custom';
  String? _selectedCardId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: AddSubscriptionView initialized');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    FocusScope.of(context).unfocus();
    await showCustomDatePicker(
      context,
      initialDate: _startDate,
      minDate: DateTime(2024),
      onDateChanged: (val) {
        setState(() {
          _startDate = val;
          _calculateNextBillingDate();
        });
      },
    );
  }

  void _calculateNextBillingDate() {
    DateTime calculatedDate = _startDate;
    final now = DateTime.now();

    // If start date is in the future, next billing is start date
    if (calculatedDate.isAfter(now)) {
      _nextBillingDate = calculatedDate;
      return;
    }

    // Otherwise, add periods until we pass today
    while (calculatedDate.isBefore(now) || isSameDay(calculatedDate, now)) {
      if (_billingCycle == 'weekly') {
        calculatedDate = calculatedDate.add(const Duration(days: 7));
      } else if (_billingCycle == 'monthly') {
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month + 1, calculatedDate.day);
      } else if (_billingCycle == '3_months') {
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month + 3, calculatedDate.day);
      } else if (_billingCycle == '6_months') {
        calculatedDate = DateTime(calculatedDate.year, calculatedDate.month + 6, calculatedDate.day);
      } else {
        calculatedDate = DateTime(calculatedDate.year + 1, calculatedDate.month, calculatedDate.day);
      }
    }
    _nextBillingDate = calculatedDate;
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _submit() async {
    debugPrint('DEBUG: _submit called');
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Validation failed');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen formdaki eksikleri tamamlayın')));
      return;
    }

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir servis veya "Özel" seçin')));
      return;
    }

    setState(() => _isLoading = true);

    // Check subscription limit
    final isPremium = ref.read(isPremiumProvider).asData?.value ?? false;
    final currentSubscriptions = ref.read(subscriptionsProvider).asData?.value ?? [];

    if (!isPremium && currentSubscriptions.length >= 6) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Üyelik Limiti'),
            content: const Text(
              'Ücretsiz planda en fazla 6 abonelik ekleyebilirsiniz. Sınırsız ekleme yapmak için Premium\'a geçin.',
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

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      debugPrint('DEBUG: Current User ID: $userId');

      if (userId == null) {
        throw Exception('Kullanıcı girişi yapılmamış (User ID null)');
      }

      // Default to "Diğer" category if none selected
      if (_selectedCategoryId == null) {
        final categories = ref.read(categoriesProvider).asData?.value;
        if (categories != null) {
          try {
            final otherCat = categories.firstWhere(
              (c) => (c['name'] as String) == 'Diğer' || (c['name'] as String) == 'Other',
            );
            _selectedCategoryId = otherCat['id'] as String;
          } catch (e) {
            // If "Diğer" not found, default to the first available category
            if (categories.isNotEmpty) {
              _selectedCategoryId = categories.first['id'] as String;
            }
          }
        }
      }

      final sub = Subscription(
        id: const Uuid().v4(),
        userId: userId,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        currency: _currency,
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        status: 'active',
        categoryId: _selectedCategoryId,
        cardId: _selectedCardId,
        serviceId: _selectedServiceId == 'custom' ? null : _selectedServiceId,
        startDate: _startDate,
      );

      debugPrint('DEBUG: Subscription object created: ${sub.toJson()}');

      await ref.read(subscriptionRepositoryProvider).addSubscription(sub);

      if (mounted) {
        debugPrint('DEBUG: Insertion successful');
        ref.invalidate(subscriptionsProvider);
        ref.invalidate(allSubscriptionsProvider);
        ref.invalidate(upcomingPaymentsProvider);
        ref.invalidate(paymentHistoryProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik başarıyla eklendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint('DEBUG: ERROR in _submit: $e');
      debugPrint('DEBUG: STACKTRACE: $stack');

      String errorMessage = 'Beklenmeyen bir hata oluştu.';

      if (e is PostgrestException) {
        if (e.code == '23503') {
          errorMessage = 'Seçilen servis veritabanında bulunamadı. Lütfen uygulamayı yeniden başlatıp tekrar deneyin.';
        } else {
          errorMessage = e.message;
        }
      } else {
        errorMessage = e.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesAsync = ref.watch(servicesProvider);
    final cardsAsync = ref.watch(cardsProvider);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
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
              servicesAsync.when(
                data: (services) {
                  final hasService = _selectedServiceId != null;
                  final isCustom = _selectedServiceId == 'custom';

                  final selectedService = isCustom
                      ? Service(id: 'custom', name: 'Özel Oluştur', iconName: 'plus')
                      : services.firstWhere(
                          (s) => s.id == _selectedServiceId,
                          orElse: () => Service(id: '', name: '', iconName: ''),
                        );

                  return _buildSelectionField(
                    label: 'Servis Seçin',
                    value: hasService ? selectedService.name : 'Popüler Servisler',
                    icon: Icons.search_rounded,
                    onTap: () => _showServiceSelectionSheet(categoriesAsync.asData?.value, services),
                    prefixIcon: hasService
                        ? (isCustom
                              ? Icon(Icons.add_circle_outline_rounded, size: 22, color: theme.colorScheme.primary)
                              : Image.asset(
                                  'assets/services/${selectedService.iconName}.png',
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    'assets/categories/other.png',
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
                                ))
                        : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (_selectedServiceId == 'custom') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  autofocus: false,
                  decoration: _inputDecoration(
                    'Abonelik Adı',
                  ).copyWith(prefixIcon: const Icon(Icons.edit_note_rounded)),
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Zorunlu' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                focusNode: _priceFocusNode,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: _inputDecoration('Tutar').copyWith(
                  hintText: '79.99',
                  suffixText: '₺',
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  if (value.contains(',')) {
                    final newText = value.replaceAll(',', '.');
                    _priceController.value = _priceController.value.copyWith(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  }
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
                ],
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              _buildSelectionField(
                label: 'Ödeme Periyodu',
                value: _getBillingCycleText(_billingCycle),
                icon: Icons.repeat_rounded,
                onTap: _showBillingCycleSheet,
              ),
              const SizedBox(height: 12),
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
                    onTap: () => _showCategorySheet(cats),
                    prefixIcon: Image.asset(
                      hasSelection && selectedCat['icon_name'] != null
                          ? 'assets/categories/${selectedCat['icon_name']}.png'
                          : 'assets/categories/other.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset('assets/categories/other.png', width: 20, height: 20),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              cardsAsync.when(
                data: (cards) {
                  final selectedCard = cards.cast<PaymentCard?>().firstWhere(
                    (c) => c?.id == _selectedCardId,
                    orElse: () => null,
                  );
                  return _buildSelectionField(
                    label: 'Ödeme Yöntemi',
                    value: selectedCard != null
                        ? '${selectedCard.cardName} (**** ${selectedCard.lastFour})'
                        : 'Seçilmedi',
                    prefixIcon: Image.asset(
                      'assets/services/credit_card.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    onTap: () => _showCardSheet(cards),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectStartDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Başlangıç Tarihi', style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr_TR').format(_startDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
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
                    : const Icon(Icons.add_rounded),
                label: Text(_isLoading ? 'Ekleniyor...' : 'Ekle'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showServiceSelectionSheet(List<dynamic>? categories, List<Service> services) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _ServiceSelectionSheet(
          services: services,
          categories: categories ?? [],
          onSelected: (service) {
            setState(() {
              if (service.id == 'custom') {
                _selectedServiceId = 'custom';
                _nameController.clear();
                _selectedCategoryId = null;
              } else {
                _selectedServiceId = service.id;
                _nameController.text = service.name;
                _selectedCategoryId = service.categoryId;
                if (service.defaultBillingCycle != null) {
                  _billingCycle = service.defaultBillingCycle!;
                  _calculateNextBillingDate();
                }
              }
            });
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
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
    FocusScope.of(context).unfocus();
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
            setState(() {
              _billingCycle = e.key;
              _calculateNextBillingDate();
            });
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showCardSheet(List<PaymentCard> cards) {
    FocusScope.of(context).unfocus();
    final theme = Theme.of(context);
    _showModernSheet(
      title: 'Ödeme Yöntemi Seç',
      children: [
        ...cards.map((c) {
          return _buildSheetItem(
            title: '${c.cardName} (**** ${c.lastFour})',
            isSelected: _selectedCardId == c.id,
            prefix: Image.asset('assets/services/credit_card.png', width: 20, height: 20, fit: BoxFit.contain),
            onTap: () {
              setState(() => _selectedCardId = c.id);
              FocusScope.of(context).unfocus();
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
            FocusScope.of(context).unfocus();
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
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              foregroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showCategorySheet(List<dynamic> cats) {
    FocusScope.of(context).unfocus();
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
            FocusScope.of(context).unfocus();
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
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
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
            color: isSelected ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : theme.dividerColor.withValues(alpha: 0.05),
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

// _ServiceCard removed as it is no longer used.

// _hexToColor is defined at the top-level.

class _ServiceSelectionSheet extends StatefulWidget {
  final List<Service> services;
  final List<dynamic> categories;
  final ValueChanged<Service> onSelected;

  const _ServiceSelectionSheet({required this.services, required this.categories, required this.onSelected});

  @override
  State<_ServiceSelectionSheet> createState() => _ServiceSelectionSheetState();
}

class _ServiceSelectionSheetState extends State<_ServiceSelectionSheet> {
  late List<Service> _filteredServices;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredServices = widget.services;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServices = widget.services;
      } else {
        _filteredServices = widget.services.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
      }
    });
  }

  Map<String, List<Service>> get _groupedServices {
    final Map<String, List<Service>> groups = {};

    // Internal mapping for sorting priority
    final priority = {
      'Mobil Operatörler': 0,
      'Fatura': 1,
      'İnternet Servis Sağlayıcıları': 2,
      'Araçlar': 3,
      'Dijital Platformlar': 4,
      'Yapay Zeka': 5,
      'Yazılım': 6,
    };

    // Sort categories based on priority, others at the end
    final sortedCats = List.from(widget.categories);
    sortedCats.sort((a, b) {
      final aName = a['name'] as String;
      final bName = b['name'] as String;
      final aPrio = priority[aName] ?? 100;
      final bPrio = priority[bName] ?? 100;
      if (aPrio != bPrio) return aPrio.compareTo(bPrio);
      return aName.compareTo(bName);
    });

    for (var cat in sortedCats) {
      final catId = cat['id'] as String;
      final catName = cat['name'] as String;
      final catServices = _filteredServices.where((s) => s.categoryId == catId).toList();
      if (catServices.isNotEmpty) {
        groups[catName] = catServices;
      }
    }

    // Add uncategorized if they exist
    final otherServices = _filteredServices.where((s) => s.categoryId == null).toList();
    if (otherServices.isNotEmpty) {
      groups['Diğer Servisler'] = otherServices;
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = _groupedServices;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text('Servis Seç', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                title: const Text('Özel Abonelik Oluştur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Listede olmayan farklı bir servis ekle', style: TextStyle(fontSize: 12)),
                onTap: () => widget.onSelected(Service(id: 'custom', name: 'Özel', iconName: 'plus')),
                trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Servis Ara (Netflix, Turk Telekom, Spotify..)',
                hintStyle: TextStyle(fontSize: 14, color: theme.hintColor),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: grouped.length,
              itemBuilder: (context, groupIndex) {
                final groupName = grouped.keys.elementAt(groupIndex);
                final services = grouped[groupName]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Text(
                        groupName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...services.map((service) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: SizedBox(
                            width: 24,
                            height: 40,
                            child: Center(
                              child: Image.asset(
                                'assets/services/${service.iconName}.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Image.asset(
                                  'assets/categories/other.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          onTap: () => widget.onSelected(service),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
