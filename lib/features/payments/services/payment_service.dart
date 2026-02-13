import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment.dart';

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

@riverpod
PaymentService paymentService(Ref ref) {
  return PaymentService(Supabase.instance.client);
}

@riverpod
Future<List<Payment>> upcomingPayments(Ref ref) async {
  return ref.watch(paymentServiceProvider).getPayments(history: false);
}

@riverpod
Future<List<Payment>> paymentHistory(Ref ref) async {
  return ref.watch(paymentServiceProvider).getPayments(history: true);
}
