import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/subscriptions/domain/entities/category.dart';

/// Tüm kategorileri DB'den çeken provider (1 kere çekilir, uygulama açıldığında)
final allCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final repo = ref.read(categoriesRepositoryProvider);
    return await repo.fetchAllCategories();
  } catch (e) {
    return [];
  }
});

/// Kategori isimlerini string listesi olarak döndüren provider
final allCategoryNamesProvider = Provider<List<String>>((ref) {
  final categoriesAsync = ref.watch(allCategoriesProvider);
  
  return categoriesAsync.when(
    data: (categories) => categories.map((c) => c.name).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
