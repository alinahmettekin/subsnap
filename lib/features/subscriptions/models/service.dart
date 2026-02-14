import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

@freezed
sealed class Service with _$Service {
  const factory Service({
    required String id,
    required String name,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'color') String? color,
    @JsonKey(name: 'default_price') double? defaultPrice,
    @JsonKey(name: 'category_id') String? categoryId,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);
}
