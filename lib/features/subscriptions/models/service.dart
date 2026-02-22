import 'package:freezed_annotation/freezed_annotation.dart';

part 'service.freezed.dart';
part 'service.g.dart';

@freezed
sealed class Service with _$Service {
  const factory Service({
    required String id,
    required String name,
    @JsonKey(name: 'icon_name') String? iconName,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'default_billing_cycle') String? defaultBillingCycle,
  }) = _Service;

  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);
}
