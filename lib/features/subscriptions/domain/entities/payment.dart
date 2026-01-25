import 'package:equatable/equatable.dart';

/// Ödeme kaydı modeli
class Payment extends Equatable {
  final String id;
  final String subscriptionId;
  final DateTime paymentDate;
  final double amount;
  final String currency;

  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.paymentDate,
    required this.amount,
    required this.currency,
  });

  @override
  List<Object?> get props => [
        id,
        subscriptionId,
        paymentDate,
        amount,
        currency,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'payment_date': paymentDate.toIso8601String(),
      'amount': amount,
      'currency': currency,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    try {
      return Payment(
        id: map['id']?.toString() ?? '',
        subscriptionId: map['subscription_id']?.toString() ?? '',
        paymentDate: map['payment_date'] != null
            ? DateTime.parse(map['payment_date'].toString())
            : DateTime.now(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency']?.toString() ?? 'USD',
      );
    } catch (e) {
      return Payment(
        id: map['id']?.toString() ?? '',
        subscriptionId: map['subscription_id']?.toString() ?? '',
        paymentDate: DateTime.now(),
        amount: 0.0,
        currency: 'USD',
      );
    }
  }
}
