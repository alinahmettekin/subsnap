import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/domain/entities/category.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/categories_repository.dart';

class SupabaseCategoriesRepository implements CategoriesRepository {
  final SupabaseClient _client;

  SupabaseCategoriesRepository(this._client);

  @override
  Future<List<Category>> fetchAllCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final data = response as List<dynamic>;
      return data.map((e) {
        try {
          return Category.fromMap(e as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).whereType<Category>().toList();
    } catch (e) {
      return [];
    }
  }
}
