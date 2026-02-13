// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'card.freezed.dart';
part 'card.g.dart';

@freezed
abstract class PaymentCard with _$PaymentCard {
  const factory PaymentCard({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'card_name') required String cardName,
    @JsonKey(name: 'last_four') required String lastFour,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _PaymentCard;

  factory PaymentCard.fromJson(Map<String, dynamic> json) => _$PaymentCardFromJson(json);
}
