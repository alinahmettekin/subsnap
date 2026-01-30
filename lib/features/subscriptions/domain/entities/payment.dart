import 'package:equatable/equatable.dart';

/// Ödeme kaydı modeli
class Payment extends Equatable {
  final String id;
  final String? subscriptionId; // Nullable: Farklı ödemeler için null olabilir
  final String userId;
  final DateTime paymentDate;
  final double amount;
  final String currency;

  const Payment({
    required this.id,
    this.subscriptionId,
    required this.userId,
    required this.paymentDate,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        userId,
        paymentDate,
        amount,
        currency,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      'user_id': userId,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'currency': currency,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    try {
      return Payment(
        id: map['id']?.toString() ?? '',
        subscriptionId: map['subscription_id']?.toString(),
        userId: map['user_id']?.toString() ?? '',
        paymentDate: map['payment_date'] != null
            ? DateTime.parse(map['payment_date'].toString())
            : DateTime.now(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency']?.toString() ?? 'TRY',
      );
    } catch (e) {
      return Payment(
        id: map['id']?.toString() ?? '',
        subscriptionId: map['subscription_id']?.toString(),
        userId: map['user_id']?.toString() ?? '',
        paymentDate: DateTime.now(),
        amount: 0.0,
        currency: 'TRY',
      );
    }
  }
}
