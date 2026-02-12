// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  subscriptionId: json['subscription_id'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  dueDate: DateTime.parse(json['due_date'] as String),
  status: json['status'] as String,
  paidAt: json['paid_at'] == null
      ? null
      : DateTime.parse(json['paid_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'subscription_id': instance.subscriptionId,
  'amount': instance.amount,
  'currency': instance.currency,
  'due_date': instance.dueDate.toIso8601String(),
  'status': instance.status,
  'paid_at': instance.paidAt?.toIso8601String(),
};

