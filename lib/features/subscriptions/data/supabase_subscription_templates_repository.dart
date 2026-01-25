import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/subscription_templates_repository.dart';

class SupabaseSubscriptionTemplatesRepository implements SubscriptionTemplatesRepository {
  final SupabaseClient _client;

  SupabaseSubscriptionTemplatesRepository(this._client);

  @override
  Future<List<SubscriptionTemplate>> fetchAllTemplates() async {
    try {
      final response = await _client
          .from('subscription_templates')
          .select('*, categories(name)')
          .order('display_order', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      final data = response as List<dynamic>;
      return data.map((e) {
        try {
          return SubscriptionTemplate.fromMap(e as Map<String, dynamic>);
        } catch (e) {
          return null;
        }
      }).whereType<SubscriptionTemplate>().toList();
    } catch (e) {
      return [];
    }
  }
}
