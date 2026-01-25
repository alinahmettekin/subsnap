import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';

abstract class SubscriptionTemplatesRepository {
  /// Fetches all subscription templates (global, kullanıcı bazlı değil).
  Future<List<SubscriptionTemplate>> fetchAllTemplates();
}
