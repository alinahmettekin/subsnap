import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';

abstract class PaymentsRepository {
  /// Kullanıcının tüm ödemelerini getir
  Future<List<Payment>> fetchPayments(String userId);
  
  /// Belirli bir aboneliğin ödemelerini getir
  Future<List<Payment>> fetchPaymentsBySubscription(String subscriptionId);
  
  /// Ödeme kaydı oluştur
  Future<void> createPayment(Payment payment);
  
  /// Ödeme kaydı sil
  Future<void> deletePayment(String paymentId);
}
