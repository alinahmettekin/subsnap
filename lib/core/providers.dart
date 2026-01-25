import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:subsnap/features/subscriptions/data/supabase_subscriptions_repository.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/categories_repository.dart';
import 'package:subsnap/features/subscriptions/data/supabase_categories_repository.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/subscription_templates_repository.dart';
import 'package:subsnap/features/subscriptions/data/supabase_subscription_templates_repository.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/payments_repository.dart';
import 'package:subsnap/features/subscriptions/data/supabase_payments_repository.dart';
import 'package:subsnap/features/auth/domain/auth_repository.dart';
import 'package:subsnap/features/auth/data/supabase_auth_repository.dart';
import 'package:subsnap/features/auth/domain/repositories/profile_repository.dart';
import 'package:subsnap/features/auth/data/supabase_profile_repository.dart';
import 'package:subsnap/features/auth/domain/entities/user_profile.dart';
export 'package:subsnap/core/providers/theme_provider.dart';

// --- Core ---

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  try {
    return Supabase.instance.client;
  } catch (e) {
    // If Supabase is not initialized, throw a clear error
    throw StateError(
        'Supabase is not initialized. Make sure Supabase.initialize() is called before using this provider.');
  }
});

// --- Repositories ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseAuthRepository(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseProfileRepository(client);
});

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSubscriptionsRepository(client);
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCategoriesRepository(client);
});

final subscriptionTemplatesRepositoryProvider = Provider<SubscriptionTemplatesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSubscriptionTemplatesRepository(client);
});

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabasePaymentsRepository(client);
});

// --- Auth (Simplified for MVP: Just exposing the current user stream) ---

final authUserProvider = StreamProvider<User?>((ref) {
  try {
    final client = ref.watch(supabaseClientProvider);
    return client.auth.onAuthStateChange
        .map((event) => event.session?.user)
        .distinct((a, b) => a?.id == b?.id); // Only emit if user ID changes
  } catch (e) {
    // If Supabase is not initialized, return a stream with null
    return Stream.value(null);
  }
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return null;

  final profileRepo = ref.watch(profileRepositoryProvider);
  return profileRepo.getProfile(user.id);
});
