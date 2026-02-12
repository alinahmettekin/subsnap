import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../../../core/services/subscription_service.dart';
import 'paywall_view.dart';

class AddSubscriptionView extends ConsumerStatefulWidget {
  const AddSubscriptionView({super.key});

  @override
  ConsumerState<AddSubscriptionView> createState() => _AddSubscriptionViewState();
}

class _AddSubscriptionViewState extends ConsumerState<AddSubscriptionView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _billingCycle = 'monthly';
  String _currency = '₺';
  DateTime _nextBillingDate = DateTime.now();
  String? _selectedCategoryId;
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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _nextBillingDate = picked);
    }
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Abonelik Adı', prefixIcon: Icon(Icons.label_rounded)),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Tutar', prefixIcon: Icon(Icons.payments_rounded)),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Döviz'),
                      items: ['₺', '€', r'$'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _billingCycle,
                decoration: const InputDecoration(labelText: 'Ödeme Periyodu', prefixIcon: Icon(Icons.repeat_rounded)),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                ],
                onChanged: (v) => setState(() => _billingCycle = v!),
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.category_rounded)),
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
              ListTile(
                onTap: _selectDate,
                tileColor: theme.colorScheme.surfaceContainerHighest.withAlpha(75),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Sıradaki Ödeme'),
                subtitle: Text(DateFormat('dd MMMM yyyy').format(_nextBillingDate)),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
}
