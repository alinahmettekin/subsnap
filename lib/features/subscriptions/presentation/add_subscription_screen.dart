import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/services/notification_service.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';
import 'package:subsnap/features/subscriptions/domain/entities/category.dart';
import 'package:subsnap/features/subscriptions/presentation/categories_provider.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:subsnap/core/utils/achievement_notification_helper.dart';
import 'package:subsnap/router.dart';
import 'package:uuid/uuid.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription? subscriptionToEdit;
  final SubscriptionTemplate? template;

  const AddSubscriptionScreen({
    super.key,
    this.subscriptionToEdit,
    this.template,
  });

  @override
  ConsumerState<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _categoryController;

  String _currency = 'TRY'; // Default TRY
  BillingCycle _billingCycle = BillingCycle.monthly;
  DateTime _nextPaymentDate = DateTime.now().add(const Duration(days: 30));
  bool _isPaused = false;
  DateTime? _pausedUntil;
  bool _notify1DayBefore = true;
  bool _notify3DaysBefore = false;

  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    try {
      // Önce template varsa onu kullan
      if (widget.template != null) {
        final template = widget.template!;
        _nameController = TextEditingController(text: template.name);
        _amountController = TextEditingController(text: ''); // Boş bırak, kullanıcı girecek
        _categoryController = TextEditingController(text: template.categoryName ?? '');
        _currency = 'TRY'; // Default TRY
        _billingCycle = template.defaultBillingCycle;
        _nextPaymentDate = DateTime.now().add(const Duration(days: 30));
      } else {
        // Yoksa edit edilen subscription'ı kullan
        final sub = widget.subscriptionToEdit;
        _nameController = TextEditingController(text: sub?.name ?? '');
        _amountController = TextEditingController(text: sub?.amount.toString() ?? '');
        _categoryController = TextEditingController(text: sub?.categoryName ?? '');

        if (sub != null) {
          _currency = sub.currency;
          _billingCycle = sub.billingCycle;
          _nextPaymentDate = sub.nextPaymentDate;
          _isPaused = sub.isPaused;
          _pausedUntil = sub.pausedUntil;
          _notify1DayBefore = sub.notify1DayBefore;
          _notify3DaysBefore = sub.notify3DaysBefore;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in initState: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _nameController.dispose();
      _amountController.dispose();
      _categoryController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        throw Exception('Amount must be greater than 0');
      }

      // Kategori ismini ID'ye çevir
      String? categoryId;
      final categoryName = _categoryController.text.trim();
      if (categoryName.isNotEmpty) {
        // Kategorilerin yüklendiğinden emin ol
        final allCategoriesAsync = ref.read(allCategoriesProvider);
        final categories = allCategoriesAsync.value;

        if (categories != null && categories.isNotEmpty) {
          final foundCategory = categories.firstWhere(
            (c) => c.name.toLowerCase().trim() == categoryName.toLowerCase().trim(),
            orElse: () => const Category(id: '', name: ''),
          );

          if (foundCategory.id.isNotEmpty) {
            categoryId = foundCategory.id;
          } else {
            // Kategori bulunamadı - null bırak (foreign key hatası önlemek için)
            debugPrint('Uyarı: "$categoryName" kategorisi bulunamadı. Abonelik kategori olmadan kaydedilecek.');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$categoryName" kategorisi bulunamadı. Abonelik kategori olmadan kaydedilecek.'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            categoryId = null;
          }
        } else {
          // Kategoriler henüz yüklenmemiş veya boş - null bırak
          debugPrint('Uyarı: Kategoriler henüz yüklenmemiş. Abonelik kategori olmadan kaydedilecek.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kategoriler henüz yüklenmemiş. Lütfen birkaç saniye bekleyip tekrar deneyin.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          categoryId = null;
        }
      }

      final newSub = Subscription(
        id: widget.subscriptionToEdit?.id ?? const Uuid().v4(),
        userId: user.id,
        name: _nameController.text.trim(),
        amount: amount,
        currency: _currency,
        billingCycle: _billingCycle,
        nextPaymentDate: _nextPaymentDate,
        categoryId: categoryId,
        categoryName: categoryName.isEmpty ? null : categoryName,
        isPaused: _isPaused,
        pausedUntil: _pausedUntil,
        notify1DayBefore: _notify1DayBefore,
        notify3DaysBefore: _notify3DaysBefore,
      );

      final repo = ref.read(subscriptionsRepositoryProvider);

      if (widget.subscriptionToEdit != null) {
        await repo.updateSubscription(newSub);
        // Reschedule notification
        await NotificationService().cancelNotification(newSub.id);
        await NotificationService().scheduleSubscriptionReminder(newSub);
      } else {
        await repo.addSubscription(newSub);
        // Schedule new notification
        await NotificationService().scheduleSubscriptionReminder(newSub);
        // Check for achievements
        try {
          final subsCount = ref.read(subscriptionsProvider).value?.length ?? 0;
          debugPrint('🎯 [ADD_SUB] Current subsCount: $subsCount, awarding for ${subsCount + 1}');
          final newlyEarned = await ref.read(achievementsRepositoryProvider).checkAndAwardSubscriptionAchievements(
                user.id,
                subsCount + 1, // Current + the new one
              );

          if (newlyEarned.isNotEmpty && mounted) {
            final goRouter = ref.read(routerProvider);
            for (final achievement in newlyEarned) {
              AchievementNotificationHelper.showAchievementEarned(
                context,
                achievement,
                onNotificationTap: () => goRouter.push('/home/settings/achievements'),
              );
            }
          }
          ref.invalidate(achievementsProvider);
        } catch (e) {
          debugPrint('❌ [ADD_SUB] Achievement check error: $e');
        }
      }

      // Navigate back only if still mounted
      if (mounted) {
        context.pop(true); // Go back to dashboard with success result
      }
    } catch (e, stackTrace) {
      debugPrint('Error saving subscription: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kaydetme hatası: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tamam',
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSubscription() async {
    if (!mounted) return;

    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription'),
        content: Text('Are you sure you want to delete "${_nameController.text}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(subscriptionsRepositoryProvider);
      await repo.deleteSubscription(widget.subscriptionToEdit!.id);

      // Cancel notification
      await NotificationService().cancelNotification(widget.subscriptionToEdit!.id);

      // Navigate back only if still mounted
      if (mounted) {
        context.pop(true); // Go back to dashboard with success result
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting subscription: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextPaymentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && !_isDisposed && mounted) {
      setState(() => _nextPaymentDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    try {
      final isEditing = widget.subscriptionToEdit != null;

      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Aboneliği Düzenle' : 'Yeni Abonelik'),
        ),
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Abonelik Adı',
                    hintText: 'Netflix, Spotify, vb.',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Amount & Currency Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Tutar',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Gerekli';
                          if (double.tryParse(val) == null) return 'Geçersiz';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _currency,
                        decoration: const InputDecoration(labelText: 'Currency'),
                        items: const [
                          DropdownMenuItem(
                              value: 'TRY', child: Row(children: [Text('₺'), SizedBox(width: 8), Text('TRY')])),
                          DropdownMenuItem(
                              value: 'USD', child: Row(children: [Text('\$'), SizedBox(width: 8), Text('USD')])),
                          DropdownMenuItem(
                              value: 'EUR', child: Row(children: [Text('€'), SizedBox(width: 8), Text('EUR')])),
                          DropdownMenuItem(
                              value: 'GBP', child: Row(children: [Text('£'), SizedBox(width: 8), Text('GBP')])),
                          DropdownMenuItem(
                              value: 'JPY', child: Row(children: [Text('¥'), SizedBox(width: 8), Text('JPY')])),
                        ],
                        onChanged: (val) {
                          if (!_isDisposed && mounted && val != null) {
                            setState(() => _currency = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Billing Cycle
                DropdownButtonFormField<BillingCycle>(
                  initialValue: _billingCycle,
                  decoration: const InputDecoration(
                    labelText: 'Ödeme Sıklığı',
                    prefixIcon: Icon(Icons.loop),
                  ),
                  items: const [
                    DropdownMenuItem(value: BillingCycle.monthly, child: Text('Aylık')),
                    DropdownMenuItem(value: BillingCycle.yearly, child: Text('Yıllık')),
                    DropdownMenuItem(value: BillingCycle.weekly, child: Text('Haftalık')),
                    DropdownMenuItem(value: BillingCycle.daily, child: Text('Günlük')),
                  ],
                  onChanged: (val) {
                    if (!_isDisposed && mounted && val != null) {
                      setState(() => _billingCycle = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Next Payment Date
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'First / Next Payment',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(_nextPaymentDate),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category (Optional) - Autocomplete
                _CategoryAutocompleteWidget(
                  controller: _categoryController,
                  onCategorySelected: (category) {
                    _categoryController.text = category;
                  },
                ),

                // Dondurma seçeneği (sadece edit modunda)
                if (isEditing) ...[
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Aboneliği Dondur'),
                    subtitle: _isPaused
                        ? Text(
                            _pausedUntil != null
                                ? 'Donduruldu: ${DateFormat.yMMMd('tr_TR').format(_pausedUntil!)}'
                                : 'Abonelik dondurulmuş',
                          )
                        : const Text('Aboneliği geçici olarak durdur'),
                    value: _isPaused,
                    onChanged: (value) async {
                      if (value) {
                        // Dondurma tarihi seç
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _isPaused = true;
                            _pausedUntil = picked;
                          });
                        }
                      } else {
                        setState(() {
                          _isPaused = false;
                          _pausedUntil = null;
                        });
                      }
                    },
                    secondary: Icon(
                      _isPaused ? Icons.pause_circle : Icons.play_circle_outline,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Bildirim Ayarları
                Text(
                  'Bildirim Ayarları',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('1 Gün Önce'),
                        subtitle: const Text('Ödemeden 1 gün önce hatırlat'),
                        value: _notify1DayBefore,
                        onChanged: (value) => setState(() => _notify1DayBefore = value),
                        secondary: const Icon(Icons.notifications_active_outlined),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('3 Gün Önce'),
                        subtitle: const Text('Ödemeden 3 gün önce hatırlat'),
                        value: _notify3DaysBefore,
                        onChanged: (value) => setState(() => _notify3DaysBefore = value),
                        secondary: const Icon(Icons.notification_important_outlined),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton.icon(
                    onPressed: _saveSubscription,
                    icon: const Icon(Icons.check),
                    label: Text(isEditing ? 'Update Subscription' : 'Add Subscription'),
                  ),

                if (isEditing) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _isLoading ? null : _deleteSubscription,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Aboneliği Sil'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ]
              ],
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in build: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        appBar: AppBar(title: const Text('Hata')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Bir hata oluştu: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Kategori autocomplete widget
class _CategoryAutocompleteWidget extends ConsumerWidget {
  final TextEditingController controller;
  final ValueChanged<String> onCategorySelected;

  const _CategoryAutocompleteWidget({
    required this.controller,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final allCategories = allCategoriesAsync.value ?? [];
    final categoryNames = allCategories.map((c) => c.name).toList();

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return categoryNames;
        }
        final query = textEditingValue.text.toLowerCase();
        return categoryNames.where((c) => c.toLowerCase().contains(query)).toList();
      },
      onSelected: (String selection) {
        controller.text = selection;
        onCategorySelected(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Controller'ı senkronize et
        if (textEditingController.text != controller.text) {
          textEditingController.text = controller.text;
        }
        controller.addListener(() {
          if (textEditingController.text != controller.text) {
            textEditingController.text = controller.text;
          }
        });

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Kategori (İsteğe Bağlı)',
            hintText: 'Kategori ara veya oluştur...',
            prefixIcon: const Icon(Icons.category_outlined),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      controller.clear();
                    },
                  )
                : null,
          ),
          onFieldSubmitted: (String value) {
            onFieldSubmitted();
            // Kategori yazıldığında otomatik olarak subscription kaydedilirken kullanılır
            // Ayrı bir ekleme işlemi gerekmez
            if (value.isNotEmpty) {
              onCategorySelected(value);
            }
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
