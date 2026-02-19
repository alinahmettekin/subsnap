import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required String name,
    @JsonKey(name: 'amount') required double price,
    required String currency,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'billing_period') required String billingCycle,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'next_payment_date') required DateTime nextBillingDate,
    required String status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'card_id') String? cardId,
    @JsonKey(name: 'service_id') String? serviceId,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);
}
