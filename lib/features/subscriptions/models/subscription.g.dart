// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      price: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      categoryId: json['category_id'] as String?,
      billingCycle: json['billing_period'] as String,
      nextBillingDate: DateTime.parse(json['next_payment_date'] as String),
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      cardId: json['card_id'] as String?,
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'amount': instance.price,
      'currency': instance.currency,
      'category_id': instance.categoryId,
      'billing_period': instance.billingCycle,
      'next_payment_date': instance.nextBillingDate.toIso8601String(),
      'status': instance.status,
      'created_at': instance.createdAt?.toIso8601String(),
      'card_id': instance.cardId,
    };
