import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';

/// Tüm subscription template'lerini DB'den çeken provider (1 kere çekilir, uygulama açıldığında)
final subscriptionTemplatesProvider = FutureProvider<List<SubscriptionTemplate>>((ref) async {
  try {
    final repo = ref.read(subscriptionTemplatesRepositoryProvider);
    return await repo.fetchAllTemplates();
  } catch (e) {
    return [];
  }
});
