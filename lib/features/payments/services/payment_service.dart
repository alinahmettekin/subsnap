import 'dart:async';
import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';
import '../../subscriptions/providers/subscription_provider.dart';

part 'payment_service.g.dart';

class PaymentService {
  final SupabaseClient _client;

  PaymentService(this._client);

  Future<List<Payment>> getPayments({bool history = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final baseQuery = _client.from('payments').select().eq('user_id', userId);

    // We expect a List of Maps
    dynamic query;

    if (history) {
      query = baseQuery.filter('status', 'in', ['paid', 'skipped']).order('due_date', ascending: false);
    } else {
      query = baseQuery.filter('status', 'in', ['pending', 'overdue']).order('due_date', ascending: true);
    }

    try {
      final response = await query;

      final list = (response as List).map((json) {
        try {
          return Payment.fromJson(json);
        } catch (e) {
          log('Error parsing payment JSON', error: e, name: 'PaymentService');
          rethrow;
        }
      }).toList();

      log('Parsed ${list.length} payments.', name: 'PaymentService');
      return list;
    } catch (e, stack) {
      log('Error in getPayments', error: e, stackTrace: stack, name: 'PaymentService');
      rethrow;
    }
  }

  Future<void> createPayment(Payment payment) async {
    // Ensure we don't send the temporary ID to the database if we're inserting
    // We let Supabase generate the ID or generate a real UUID here.
    // Best practice: Let Supabase handle ID or use UUID v4.
    // For simplicity, we'll exclude ID from the insert map if it's temporary,
    // but Payment.toJson() includes it.
    // So we'll create a map and remove ID if it starts with 'temp_'.

    final data = payment.toJson();
    if (payment.id.startsWith('temp_') || payment.id.startsWith('new_')) {
      data.remove('id');
    }
    // Remove category_id if it exists in the json (defensive programming for outdated g.dart)
    data.remove('category_id');
    // Remove name if it exists (defensive programming for outdated g.dart)
    data.remove('name');

    // Set paid_at to now if not set
    if (payment.paidAt == null) {
      data['paid_at'] = DateTime.now().toIso8601String();
    }

    // Set status to paid
    data['status'] = 'paid';

    await _client.from('payments').insert(data);
  }

  // Deprecated: Use createPayment instead for new flows
  Future<void> markAsPaid(String paymentId) async {
    await _client
        .from('payments')
        .update({'status': 'paid', 'paid_at': DateTime.now().toIso8601String()})
        .eq('id', paymentId);
  }

  Future<void> markAsUnpaid(String paymentId) async {
    await _client.from('payments').update({'status': 'pending', 'paid_at': null}).eq('id', paymentId);
  }

  Future<void> deletePayment(String paymentId) async {
    await _client.from('payments').delete().eq('id', paymentId);
  }
}

@Riverpod(keepAlive: true)
PaymentService paymentService(Ref ref) {
  return PaymentService(Supabase.instance.client);
}

@riverpod
Future<List<Payment>> upcomingPayments(Ref ref) async {
  final subscriptions = await ref.watch(subscriptionsProvider.future);
  final payments = <Payment>[];

  for (final sub in subscriptions) {
    payments.add(
      Payment(
        id: 'temp_${sub.id}_${sub.nextBillingDate.millisecondsSinceEpoch}', // Temporary ID
        userId: sub.userId,
        subscriptionId: sub.id,
        amount: sub.price,
        currency: sub.currency,
        dueDate: sub.nextBillingDate,
        status: 'pending',
        cardId: sub.cardId,
      ),
    );
  }

  // Sort by due date (soonest first)
  payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return payments;
}

@riverpod
Future<List<Payment>> paymentHistory(Ref ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return ref.watch(paymentServiceProvider).getPayments(history: true);
}
