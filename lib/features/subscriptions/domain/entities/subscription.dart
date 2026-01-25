import 'package:equatable/equatable.dart';

enum BillingCycle { monthly, yearly, weekly, daily }

class Subscription extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime nextPaymentDate;
  final String? categoryId; // Category ID (foreign key)
  final String? categoryName; // Category name (join'den gelir, nullable)
  final bool isPaused; // Abonelik dondurulmuş mu?
  final DateTime? pausedUntil; // Ne zamana kadar dondurulmuş?

  const Subscription({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.nextPaymentDate,
    this.categoryId,
    this.categoryName,
    this.isPaused = false,
    this.pausedUntil,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        amount,
        currency,
        billingCycle,
        nextPaymentDate,
        categoryId,
        categoryName,
        isPaused,
        pausedUntil,
      ];

  // Helper to copy object
  Subscription copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? nextPaymentDate,
    String? categoryId,
    String? categoryName,
    bool? isPaused,
    DateTime? pausedUntil,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      isPaused: isPaused ?? this.isPaused,
      pausedUntil: pausedUntil ?? this.pausedUntil,
    );
  }

  // Basic toMap/fromMap for Supabase/DB (Manual serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId, // Supabase convention usually snake_case
      'name': name,
      'amount': amount,
      'currency': currency,
      'billing_cycle': billingCycle.name,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      'category_id': categoryId,
      'is_paused': isPaused,
      'paused_until': pausedUntil?.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    try {
      return Subscription(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency']?.toString() ?? 'USD',
        billingCycle: BillingCycle.values.firstWhere(
          (e) => e.name == map['billing_cycle']?.toString(),
          orElse: () => BillingCycle.monthly,
        ),
        nextPaymentDate: map['next_payment_date'] != null
            ? DateTime.parse(map['next_payment_date'].toString())
            : DateTime.now(),
        categoryId: map['category_id']?.toString(),
        categoryName: map['category_name']?.toString() ?? 
            (map['categories'] != null && map['categories'] is Map 
                ? (map['categories'] as Map)['name']?.toString() 
                : null),
        isPaused: (map['is_paused'] as bool?) ?? false,
        pausedUntil: map['paused_until'] != null
            ? DateTime.parse(map['paused_until'].toString())
            : null,
      );
    } catch (e) {
      // Return a default subscription on error
      return Subscription(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unknown',
        amount: 0.0,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        nextPaymentDate: DateTime.now(),
        categoryId: null,
        categoryName: null,
        isPaused: false,
        pausedUntil: null,
      );
    }
  }
}
