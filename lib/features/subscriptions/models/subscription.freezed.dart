// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Subscription {

 String get id;@JsonKey(name: 'user_id') String get userId; String get name;@JsonKey(name: 'amount') double get price; String get currency;@JsonKey(name: 'category_id') String? get categoryId;@JsonKey(name: 'billing_period') String get billingCycle;@JsonKey(name: 'start_date') DateTime? get startDate;@JsonKey(name: 'next_payment_date') DateTime get nextBillingDate; String get status;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'card_id') String? get cardId;@JsonKey(name: 'service_id') String? get serviceId;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.nextBillingDate, nextBillingDate) || other.nextBillingDate == nextBillingDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,price,currency,categoryId,billingCycle,startDate,nextBillingDate,status,createdAt,cardId,serviceId);

@override
String toString() {
  return 'Subscription(id: $id, userId: $userId, name: $name, price: $price, currency: $currency, categoryId: $categoryId, billingCycle: $billingCycle, startDate: $startDate, nextBillingDate: $nextBillingDate, status: $status, createdAt: $createdAt, cardId: $cardId, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'amount') double price, String currency,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'billing_period') String billingCycle,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'next_payment_date') DateTime nextBillingDate, String status,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'card_id') String? cardId,@JsonKey(name: 'service_id') String? serviceId
});




}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? price = null,Object? currency = null,Object? categoryId = freezed,Object? billingCycle = null,Object? startDate = freezed,Object? nextBillingDate = null,Object? status = null,Object? createdAt = freezed,Object? cardId = freezed,Object? serviceId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,nextBillingDate: null == nextBillingDate ? _self.nextBillingDate : nextBillingDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'amount')  double price,  String currency, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'billing_period')  String billingCycle, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'next_payment_date')  DateTime nextBillingDate,  String status, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'card_id')  String? cardId, @JsonKey(name: 'service_id')  String? serviceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.price,_that.currency,_that.categoryId,_that.billingCycle,_that.startDate,_that.nextBillingDate,_that.status,_that.createdAt,_that.cardId,_that.serviceId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'amount')  double price,  String currency, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'billing_period')  String billingCycle, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'next_payment_date')  DateTime nextBillingDate,  String status, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'card_id')  String? cardId, @JsonKey(name: 'service_id')  String? serviceId)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.userId,_that.name,_that.price,_that.currency,_that.categoryId,_that.billingCycle,_that.startDate,_that.nextBillingDate,_that.status,_that.createdAt,_that.cardId,_that.serviceId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'user_id')  String userId,  String name, @JsonKey(name: 'amount')  double price,  String currency, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'billing_period')  String billingCycle, @JsonKey(name: 'start_date')  DateTime? startDate, @JsonKey(name: 'next_payment_date')  DateTime nextBillingDate,  String status, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'card_id')  String? cardId, @JsonKey(name: 'service_id')  String? serviceId)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.price,_that.currency,_that.categoryId,_that.billingCycle,_that.startDate,_that.nextBillingDate,_that.status,_that.createdAt,_that.cardId,_that.serviceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription implements Subscription {
  const _Subscription({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.name, @JsonKey(name: 'amount') required this.price, required this.currency, @JsonKey(name: 'category_id') this.categoryId, @JsonKey(name: 'billing_period') required this.billingCycle, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'next_payment_date') required this.nextBillingDate, required this.status, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'card_id') this.cardId, @JsonKey(name: 'service_id') this.serviceId});
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  String name;
@override@JsonKey(name: 'amount') final  double price;
@override final  String currency;
@override@JsonKey(name: 'category_id') final  String? categoryId;
@override@JsonKey(name: 'billing_period') final  String billingCycle;
@override@JsonKey(name: 'start_date') final  DateTime? startDate;
@override@JsonKey(name: 'next_payment_date') final  DateTime nextBillingDate;
@override final  String status;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'card_id') final  String? cardId;
@override@JsonKey(name: 'service_id') final  String? serviceId;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.billingCycle, billingCycle) || other.billingCycle == billingCycle)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.nextBillingDate, nextBillingDate) || other.nextBillingDate == nextBillingDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.cardId, cardId) || other.cardId == cardId)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,price,currency,categoryId,billingCycle,startDate,nextBillingDate,status,createdAt,cardId,serviceId);

@override
String toString() {
  return 'Subscription(id: $id, userId: $userId, name: $name, price: $price, currency: $currency, categoryId: $categoryId, billingCycle: $billingCycle, startDate: $startDate, nextBillingDate: $nextBillingDate, status: $status, createdAt: $createdAt, cardId: $cardId, serviceId: $serviceId)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'user_id') String userId, String name,@JsonKey(name: 'amount') double price, String currency,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'billing_period') String billingCycle,@JsonKey(name: 'start_date') DateTime? startDate,@JsonKey(name: 'next_payment_date') DateTime nextBillingDate, String status,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'card_id') String? cardId,@JsonKey(name: 'service_id') String? serviceId
});




}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? price = null,Object? currency = null,Object? categoryId = freezed,Object? billingCycle = null,Object? startDate = freezed,Object? nextBillingDate = null,Object? status = null,Object? createdAt = freezed,Object? cardId = freezed,Object? serviceId = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,billingCycle: null == billingCycle ? _self.billingCycle : billingCycle // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,nextBillingDate: null == nextBillingDate ? _self.nextBillingDate : nextBillingDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cardId: freezed == cardId ? _self.cardId : cardId // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
