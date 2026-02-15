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
import '../../../../core/utils/icon_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../payments/services/payment_service.dart';

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
  String? _selectedCategoryId;
  String? _selectedServiceId;
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
    debugPrint('DEBUG: _submit called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('DEBUG: Validation failed');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen formdaki eksikleri tamamlayın')));
      return;
    }

    setState(() => _isLoading = true);

    // Check subscription limit
    final isPremium = ref.read(isPremiumProvider).asData?.value ?? false;
    final currentSubscriptions = ref.read(subscriptionsProvider).asData?.value ?? [];

    if (!isPremium && currentSubscriptions.length >= 3) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Üyelik Limiti'),
            content: const Text(
              'Ücretsiz planda en fazla 3 abonelik ekleyebilirsiniz. Sınırsız ekleme yapmak için Premium\'a geçin.',
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
        serviceId: _selectedServiceId,
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
                'Yeni Abonelik',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              servicesAsync.when(
                data: (services) => _buildPopularServices(categoriesAsync.asData?.value, services),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                readOnly: _selectedServiceId != null,
                decoration: _inputDecoration('Abonelik Adı').copyWith(
                  prefixIcon: const Icon(Icons.subscriptions_outlined),
                  suffixIcon: _selectedServiceId != null
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _selectedServiceId = null;
                              _nameController.clear();
                              _priceController.clear(); // clearing price too as requested implicitly "clear selection"
                              _selectedCategoryId = null;
                            });
                          },
                          tooltip: 'Seçimi Temizle',
                        )
                      : null,
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 16),

              // Price and Currency Row (skipping for now, target next block)
              // Wait, I need to find where Category dropdown is.
              // It is probably further down.
              // Let's target the Category Dropdown specifically.
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      decoration: _inputDecoration('Tutar'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
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
                  DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                ],
                onChanged: (v) => setState(() => _billingCycle = v!),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId, // Changed from initialValue to value
                  decoration: _inputDecoration('Kategori'),
                  hint: const Text('Kategori (Varsayılan: Diğer)'),
                  items: cats
                      .map(
                        (c) => DropdownMenuItem(
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
                        ),
                      )
                      .toList(),
                  onChanged: _selectedServiceId != null ? null : (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => null, // Optional, defaults to Other
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Kategoriler yüklenemedi'),
              ),
              const SizedBox(height: 16),
              cardsAsync.when(
                data: (cards) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCardId,
                        decoration: _inputDecoration('Ödeme Yöntemi').copyWith(hintText: 'Kart Seçin (İsteğe Bağlı)'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Seçilmedi')),
                          ...cards.map(
                            (c) => DropdownMenuItem(value: c.id, child: Text('${c.cardName} (**** ${c.lastFour})')),
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
                error: (_, _) => const SizedBox(),
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

  Widget _buildPopularServices(List<dynamic>? categories, List<Service> services) {
    if (services.isEmpty) return const SizedBox.shrink();

    void selectService(Service service) {
      debugPrint('DEBUG: Selected service: ${service.name} (CatID: ${service.categoryId})');

      setState(() {
        _nameController.text = service.name;
        _selectedServiceId = service.id;

        if (service.defaultPrice != null) {
          _priceController.text = service.defaultPrice!.toStringAsFixed(2);
        }

        // Set category if available
        if (service.categoryId != null) {
          _selectedCategoryId = service.categoryId;
        } else if (categories != null) {
          // Fallback: try to match by name logical if no ID (though DB should have IDs)
          // For now, simpler is better: rely on service.categoryId
        }
      });

      // Auto-focus price if empty
      if (_priceController.text.isEmpty || _priceController.text == '0.00') {
        _priceFocusNode.requestFocus();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popüler Servisler',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DraggableScrollableSheet(
                      initialChildSize: 0.8,
                      minChildSize: 0.5,
                      maxChildSize: 0.95,
                      builder: (_, controller) => _ServiceSelectionSheet(
                        services: services,
                        onSelected: (s) {
                          Navigator.pop(context);
                          selectService(s);
                        },
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Tümünü Gör', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: services.map((service) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ServiceCard(service: service, onTap: () => selectService(service)),
              );
            }).toList(),
          ),
        ),
      ],
    );
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

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  // ... rest of ServiceCard

  @override
  Widget build(BuildContext context) {
    var color = _hexToColor(service.color);
    final iconData = IconHelper.getIcon(service.iconName);

    // Visibility logic
    final isLight = color.computeLuminance() > 0.8;
    final isDark = color.computeLuminance() < 0.1;

    final avatarBg = isLight
        ? const Color(0xFF202124)
        : (isDark ? const Color(0xFFF1F3F4) : color.withValues(alpha: 0.2));

    final iconColor = isLight ? Colors.white : (isDark ? Colors.black : color);

    final containerBg = isLight
        ? Colors.grey.withValues(alpha: 0.1)
        : (isDark ? Colors.white.withValues(alpha: 0.1) : color.withValues(alpha: 0.08));

    final borderColor = isLight
        ? Colors.grey.withValues(alpha: 0.3)
        : (isDark ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.15));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: avatarBg,
              radius: 11,
              child: FaIcon(iconData, color: iconColor, size: 11),
            ),
            const SizedBox(width: 6),
            Text(service.name, maxLines: 1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class _ServiceSelectionSheet extends StatefulWidget {
  final List<Service> services;
  final ValueChanged<Service> onSelected;

  const _ServiceSelectionSheet({required this.services, required this.onSelected});

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

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.grey;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('Servis Seç', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Ara...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredServices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                var color = _hexToColor(service.color);
                final iconData = IconHelper.getIcon(service.iconName);

                // Handle white/light colors specially for visibility
                final isLight = color.computeLuminance() > 0.8;
                final isDark = color.computeLuminance() < 0.1;

                final avatarBg = isLight
                    ? const Color(0xFF202124)
                    : (isDark ? const Color(0xFFF1F3F4) : color.withValues(alpha: 0.15));

                final iconColor = isLight ? Colors.white : (isDark ? Colors.black : color);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: avatarBg,
                    child: FaIcon(iconData, color: iconColor, size: 20),
                  ),
                  title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () => widget.onSelected(service),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
