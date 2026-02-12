import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'subscription_id') required String subscriptionId,
    required double amount,
    required String currency,
    @JsonKey(name: 'due_date') required DateTime dueDate,
    required String status, // 'pending', 'paid', 'overdue', 'skipped'
    @JsonKey(name: 'paid_at') DateTime? paidAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}

