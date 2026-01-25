import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:subsnap/features/subscriptions/presentation/payments_provider.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';

enum AnalyticsPeriod { thisMonth, lastMonth, thisYear, lastYear, custom }

class AnalyticsData {
  final Map<String, double> subscriptionSpend; // Subscription Name -> Total Amount
  final double totalAmount;
  final DateTime startDate;
  final DateTime endDate;

  AnalyticsData({
    required this.subscriptionSpend,
    required this.totalAmount,
    required this.startDate,
    required this.endDate,
  });
}

final analyticsPeriodProvider = StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.thisMonth);
final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final analyticsDataProvider = Provider<AsyncValue<AnalyticsData>>((ref) {
  final paymentsAsync = ref.watch(paymentsProvider);
  final subscriptionsAsync = ref.watch(subscriptionsProvider);
  final period = ref.watch(analyticsPeriodProvider);
  final customRange = ref.watch(customDateRangeProvider);

  if (paymentsAsync.isLoading || subscriptionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (paymentsAsync.hasError) return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  if (subscriptionsAsync.hasError) return AsyncValue.error(subscriptionsAsync.error!, subscriptionsAsync.stackTrace!);

  final payments = paymentsAsync.value ?? [];
  final subscriptions = subscriptionsAsync.value ?? [];

  final now = DateTime.now();
  final DateTime startDate;
  DateTime endDate = now;

  switch (period) {
    case AnalyticsPeriod.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      break;
    case AnalyticsPeriod.lastMonth:
      startDate = DateTime(now.year, now.month - 1, 1);
      endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      break;
    case AnalyticsPeriod.thisYear:
      startDate = DateTime(now.year, 1, 1);
      break;
    case AnalyticsPeriod.lastYear:
      startDate = DateTime(now.year - 1, 1, 1);
      endDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
      break;
    case AnalyticsPeriod.custom:
      if (customRange != null) {
        startDate = customRange.start;
        endDate = customRange.end.copyWith(hour: 23, minute: 59, second: 59);
      } else {
        startDate = DateTime(now.year, now.month, 1);
      }
      break;
  }

  Map<String, double> subSpend = {};
  double total = 0;

  for (var p in payments) {
    if (p.paymentDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
        p.paymentDate.isBefore(endDate.add(const Duration(seconds: 1)))) {
      String subName = 'Bilinmeyen';
      try {
        subName = subscriptions.firstWhere((s) => s.id == p.subscriptionId).name;
      } catch (_) {}

      subSpend[subName] = (subSpend[subName] ?? 0) + p.amount;
      total += p.amount;
    }
  }

  return AsyncValue.data(AnalyticsData(
    subscriptionSpend: subSpend,
    totalAmount: total,
    startDate: startDate,
    endDate: endDate,
  ));
});
