import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card.dart' as card_model;
import '../providers/card_provider.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/paywall_view.dart';

class AddCardView extends ConsumerStatefulWidget {
  const AddCardView({super.key});

  @override
  ConsumerState<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends ConsumerState<AddCardView> {
  final _formKey = GlobalKey<FormState>();
  final _cardNameController = TextEditingController();
  final _lastFourController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardNameController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen formdaki eksikleri tamamlayın')));
      return;
    }

    setState(() => _isLoading = true);

    // Check card limit
    final cards = ref.read(cardsProvider).asData?.value ?? [];
    final isPremium = ref.read(isPremiumProvider).asData?.value ?? false;

    if (!isPremium && cards.length >= 2) {
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kart Limiti'),
            content: const Text(
              'Ücretsiz planda en fazla 2 kart ekleyebilirsiniz. Sınırsız kart eklemek için Premium\'a geçin.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
                },
                child: const Text('Premium\'a Geç'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi yapılmamış');
      }

      final card = card_model.PaymentCard(
        id: const Uuid().v4(),
        userId: userId,
        cardName: _cardNameController.text,
        lastFour: _lastFourController.text,
      );

      await ref.read(cardServiceProvider).addCard(card);

      if (mounted) {
        ref.invalidate(cardsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kart başarıyla eklendi!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Yeni Kart Ekle',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Kart Adı',
                  hintText: 'Örn: İş Kartım',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastFourController,
                decoration: InputDecoration(
                  labelText: 'Son 4 Hane',
                  hintText: '1234',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset('assets/services/credit_card.png', width: 20, height: 20, fit: BoxFit.contain),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Gerekli';
                  if (v.length != 4) return '4 hane olmalı';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_rounded),
                label: Text(_isLoading ? 'Ekleniyor...' : 'Ekle'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
