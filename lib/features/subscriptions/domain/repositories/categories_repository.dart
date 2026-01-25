import 'package:subsnap/features/subscriptions/domain/entities/category.dart';

abstract class CategoriesRepository {
  /// Fetches all categories (global, kullanıcı bazlı değil).
  Future<List<Category>> fetchAllCategories();
}
