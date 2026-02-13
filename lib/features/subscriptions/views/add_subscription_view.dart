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
import '../data/popular_subscriptions.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
                minimumDate: DateTime.now().subtract(const Duration(days: 1)),
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

      final sub = Subscription(
        id: Uuid().v4(),
        userId: userId,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        currency: _currency,
        billingCycle: _billingCycle,
        nextBillingDate: _nextBillingDate,
        status: 'active',
        categoryId: _selectedCategoryId,
        cardId: _selectedCardId,
      );

      debugPrint('DEBUG: Subscription object created: ${sub.toJson()}');

      await ref.read(subscriptionRepositoryProvider).addSubscription(sub);

      if (mounted) {
        debugPrint('DEBUG: Insertion successful');
        ref.invalidate(subscriptionsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik başarıyla eklendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e, stack) {
      debugPrint('DEBUG: ERROR in _submit: $e');
      debugPrint('DEBUG: STACKTRACE: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
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
              _buildPopularServices(categoriesAsync.asData?.value),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Abonelik Adı'),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
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
                  value: _selectedCategoryId,
                  decoration: _inputDecoration('Kategori'),
                  items: cats
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Row(
                            children: [
                              if (c['icon'] != null) Icon(_getIconData(c['icon'] as String), size: 18),
                              const SizedBox(width: 8),
                              Text(c['name'] as String),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
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
                        value: _selectedCardId,
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
                            DateFormat('dd MMMM yyyy').format(_nextBillingDate),
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

  Widget _buildPopularServices(List<dynamic>? categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Popüler Servisler',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: popularSubscriptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = popularSubscriptions[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _nameController.text = service.name;

                    // Find category logic
                    if (categories != null) {
                      try {
                        final cat = categories.firstWhere(
                          (c) => (c['name'] as String).toLowerCase() == service.category.toLowerCase(),
                        );
                        _selectedCategoryId = cat['id'] as String;
                      } catch (_) {
                        // Default logic or ignore if not found
                        _selectedCategoryId = null;
                      }
                    }
                  });
                  // Focus price
                  _priceFocusNode.requestFocus();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(service.icon, color: service.color, size: 20),
                      const SizedBox(width: 8),
                      Text(service.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
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
