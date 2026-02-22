// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Service _$ServiceFromJson(Map<String, dynamic> json) => _Service(
  id: json['id'] as String,
  name: json['name'] as String,
  iconName: json['icon_name'] as String?,
  categoryId: json['category_id'] as String?,
  defaultBillingCycle: json['default_billing_cycle'] as String?,
);

Map<String, dynamic> _$ServiceToJson(_Service instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon_name': instance.iconName,
  'category_id': instance.categoryId,
  'default_billing_cycle': instance.defaultBillingCycle,
};
