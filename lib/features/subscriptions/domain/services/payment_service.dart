import 'package:flutter/foundation.dart';
import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/payments_repository.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:uuid/uuid.dart';

/// Otomatik ödeme işlemlerini yöneten service
class PaymentService {
  final PaymentsRepository _paymentsRepo;
  final SubscriptionsRepository _subscriptionsRepo;

  PaymentService(this._paymentsRepo, this._subscriptionsRepo);

  /// Aboneliğin ödeme tarihi geçmişse otomatik ödeme kaydı oluştur ve next_payment_date'i güncelle
  Future<void> processAutomaticPayments(Subscription subscription) async {
    final now = DateTime.now();
    debugPrint('🔍 [PAYMENT_SERVICE] Kontrol ediliyor: ${subscription.name}');
    debugPrint('   📅 Ödeme tarihi: ${subscription.nextPaymentDate}');
    debugPrint('   📅 Şu anki tarih: $now');
    debugPrint('   ⏸️  Dondurulmuş mu: ${subscription.isPaused}');

    // Abonelik dondurulmuşsa veya ödeme tarihi henüz gelmemişse işlem yapma
    if (subscription.isPaused) {
      debugPrint('   ⏸️  Abonelik dondurulmuş, kontrol ediliyor...');
      // Eğer paused_until geçmişse, dondurmayı kaldır
      if (subscription.pausedUntil != null && subscription.pausedUntil!.isBefore(now)) {
        debugPrint('   ✅ Dondurma süresi dolmuş, dondurma kaldırılıyor...');
        try {
          final updatedSub = subscription.copyWith(
            isPaused: false,
            pausedUntil: null,
          );
          await _subscriptionsRepo.updateSubscription(updatedSub);
          debugPrint('   ✅ Dondurma başarıyla kaldırıldı');
        } catch (e, stackTrace) {
          debugPrint('   ❌ Dondurma kaldırma hatası: $e');
          debugPrint('   ❌ Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        debugPrint('   ⏸️  Dondurma devam ediyor, işlem yapılmıyor');
      }
      return;
    }

    // Ödeme tarihi geçmişse otomatik ödeme kaydı oluştur
    if (!subscription.nextPaymentDate.isBefore(now)) {
      debugPrint('   ✅ Ödeme tarihi henüz gelmemiş, işlem yapılmıyor');
      return;
    }

    debugPrint('   💰 Ödeme tarihi geçmiş, otomatik ödeme kayıtları oluşturuluyor...');
    // Birden fazla döngü geçmiş olabilir, hepsini işle
    var currentPaymentDate = subscription.nextPaymentDate;
    int paymentCount = 0;
    const maxPayments = 12; // Maksimum 12 ödeme döngüsü (güvenlik için)

    while (currentPaymentDate.isBefore(now) && paymentCount < maxPayments) {
      debugPrint(
          '   💳 Ödeme kaydı oluşturuluyor: $currentPaymentDate (${subscription.amount} ${subscription.currency})');

      try {
        // Ödeme kaydı oluştur
        final payment = Payment(
          id: const Uuid().v4(),
          subscriptionId: subscription.id,
          paymentDate: currentPaymentDate,
          amount: subscription.amount,
          currency: subscription.currency,
        );

        await _paymentsRepo.createPayment(payment);
        debugPrint('   ✅ Ödeme kaydı oluşturuldu: ${payment.id}');

        // Bir sonraki ödeme tarihini hesapla
        currentPaymentDate = _calculateNextPaymentDate(
          currentPaymentDate,
          subscription.billingCycle,
        );

        paymentCount++;
        debugPrint('   📅 Bir sonraki ödeme tarihi: $currentPaymentDate');
      } catch (e, stackTrace) {
        debugPrint('   ❌ Ödeme kaydı oluşturma hatası: $e');
        debugPrint('   ❌ Stack trace: $stackTrace');
        debugPrint('   ❌ Ödeme tarihi: $currentPaymentDate');
        debugPrint('   ❌ Abonelik ID: ${subscription.id}');
        rethrow; // Hata durumunda işlemi durdur
      }
    }

    // Eğer ödeme yapıldıysa, next_payment_date'i güncelle
    if (paymentCount > 0) {
      debugPrint('   📝 $paymentCount ödeme kaydı oluşturuldu, abonelik güncelleniyor...');
      try {
        final updatedSub = subscription.copyWith(
          nextPaymentDate: currentPaymentDate,
        );

        await _subscriptionsRepo.updateSubscription(updatedSub);
        debugPrint('   ✅ Abonelik başarıyla güncellendi');
      } catch (e, stackTrace) {
        debugPrint('   ❌ Abonelik güncelleme hatası: $e');
        debugPrint('   ❌ Stack trace: $stackTrace');
        rethrow;
      }
    } else {
      debugPrint('   ℹ️  Ödeme kaydı oluşturulmadı');
    }
  }

  /// Bir sonraki ödeme tarihini hesapla
  DateTime _calculateNextPaymentDate(DateTime currentDate, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.monthly:
        // Aylık: 1 ay ekle
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case BillingCycle.yearly:
        // Yıllık: 1 yıl ekle
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
      case BillingCycle.weekly:
        // Haftalık: 7 gün ekle
        return currentDate.add(const Duration(days: 7));
      case BillingCycle.daily:
        // Günlük: 1 gün ekle
        return currentDate.add(const Duration(days: 1));
    }
  }
}
