// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaymentCard _$PaymentCardFromJson(Map<String, dynamic> json) => _PaymentCard(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  cardName: json['card_name'] as String,
  lastFour: json['last_four'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PaymentCardToJson(_PaymentCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'card_name': instance.cardName,
      'last_four': instance.lastFour,
      'created_at': instance.createdAt?.toIso8601String(),
    };
