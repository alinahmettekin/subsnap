// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Service _$ServiceFromJson(Map<String, dynamic> json) => _Service(
  id: json['id'] as String,
  name: json['name'] as String,
  iconName: json['icon_name'] as String?,
  color: json['color'] as String?,
  defaultPrice: (json['default_price'] as num?)?.toDouble(),
  categoryId: json['category_id'] as String?,
);

Map<String, dynamic> _$ServiceToJson(_Service instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon_name': instance.iconName,
  'color': instance.color,
  'default_price': instance.defaultPrice,
  'category_id': instance.categoryId,
};
