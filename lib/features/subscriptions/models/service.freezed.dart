// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Service {

 String get id; String get name;@JsonKey(name: 'icon_name') String? get iconName;@JsonKey(name: 'category_id') String? get categoryId;@JsonKey(name: 'default_billing_cycle') String? get defaultBillingCycle;
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCopyWith<Service> get copyWith => _$ServiceCopyWithImpl<Service>(this as Service, _$identity);

  /// Serializes this Service to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Service&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.defaultBillingCycle, defaultBillingCycle) || other.defaultBillingCycle == defaultBillingCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,categoryId,defaultBillingCycle);

@override
String toString() {
  return 'Service(id: $id, name: $name, iconName: $iconName, categoryId: $categoryId, defaultBillingCycle: $defaultBillingCycle)';
}


}

/// @nodoc
abstract mixin class $ServiceCopyWith<$Res>  {
  factory $ServiceCopyWith(Service value, $Res Function(Service) _then) = _$ServiceCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'default_billing_cycle') String? defaultBillingCycle
});




}
/// @nodoc
class _$ServiceCopyWithImpl<$Res>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._self, this._then);

  final Service _self;
  final $Res Function(Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? categoryId = freezed,Object? defaultBillingCycle = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,defaultBillingCycle: freezed == defaultBillingCycle ? _self.defaultBillingCycle : defaultBillingCycle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Service].
extension ServicePatterns on Service {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Service value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Service value)  $default,){
final _that = this;
switch (_that) {
case _Service():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Service value)?  $default,){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'default_billing_cycle')  String? defaultBillingCycle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.categoryId,_that.defaultBillingCycle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'default_billing_cycle')  String? defaultBillingCycle)  $default,) {final _that = this;
switch (_that) {
case _Service():
return $default(_that.id,_that.name,_that.iconName,_that.categoryId,_that.defaultBillingCycle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'icon_name')  String? iconName, @JsonKey(name: 'category_id')  String? categoryId, @JsonKey(name: 'default_billing_cycle')  String? defaultBillingCycle)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.categoryId,_that.defaultBillingCycle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Service implements Service {
  const _Service({required this.id, required this.name, @JsonKey(name: 'icon_name') this.iconName, @JsonKey(name: 'category_id') this.categoryId, @JsonKey(name: 'default_billing_cycle') this.defaultBillingCycle});
  factory _Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'icon_name') final  String? iconName;
@override@JsonKey(name: 'category_id') final  String? categoryId;
@override@JsonKey(name: 'default_billing_cycle') final  String? defaultBillingCycle;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCopyWith<_Service> get copyWith => __$ServiceCopyWithImpl<_Service>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Service&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.defaultBillingCycle, defaultBillingCycle) || other.defaultBillingCycle == defaultBillingCycle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,categoryId,defaultBillingCycle);

@override
String toString() {
  return 'Service(id: $id, name: $name, iconName: $iconName, categoryId: $categoryId, defaultBillingCycle: $defaultBillingCycle)';
}


}

/// @nodoc
abstract mixin class _$ServiceCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$ServiceCopyWith(_Service value, $Res Function(_Service) _then) = __$ServiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'icon_name') String? iconName,@JsonKey(name: 'category_id') String? categoryId,@JsonKey(name: 'default_billing_cycle') String? defaultBillingCycle
});




}
/// @nodoc
class __$ServiceCopyWithImpl<$Res>
    implements _$ServiceCopyWith<$Res> {
  __$ServiceCopyWithImpl(this._self, this._then);

  final _Service _self;
  final $Res Function(_Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? categoryId = freezed,Object? defaultBillingCycle = freezed,}) {
  return _then(_Service(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,defaultBillingCycle: freezed == defaultBillingCycle ? _self.defaultBillingCycle : defaultBillingCycle // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
