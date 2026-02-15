import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'support_service.g.dart';

@riverpod
SupportService supportService(Ref ref) {
  return SupportService(Supabase.instance.client);
}

class SupportService {
  final SupabaseClient _client;

  SupportService(this._client);

  Future<void> submitServiceRequest(String name, String description) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

    await _client.from('support_requests').insert({
      'user_id': user.id,
      'type': 'service_request',
      'service_name': name,
      'content': description, // Description goes to content
      'status': 'pending',
    });
  }

  Future<void> submitFeedback(String message) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı girişi yapılmamış');

    await _client.from('support_requests').insert({
      'user_id': user.id,
      'type': 'feedback',
      'content': message,
      'status': 'pending',
    });
  }
}
