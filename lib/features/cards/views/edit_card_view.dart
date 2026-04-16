import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart'
    as card_model;
import '../models/card.dart' as card_model;
import '../providers/card_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../subscriptions/views/widgets/subscription_icon.dart';

class EditCardView extends ConsumerStatefulWidget {
  final card_model.PaymentCard card;

  const EditCardView({super.key, required this.card});

  @override
  ConsumerState<EditCardView> createState() => _EditCardViewState();
}

class _EditCardViewState extends ConsumerState<EditCardView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cardNameController;
  late TextEditingController _lastFourController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cardNameController = TextEditingController(text: widget.card.cardName);
    _lastFourController = TextEditingController(text: widget.card.lastFour);

    _cardNameController.addListener(() => setState(() {}));
    _lastFourController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _lastFourController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedCard = widget.card.copyWith(
        cardName: _cardNameController.text,
        lastFour: _lastFourController.text,
      );

      await ref.read(cardServiceProvider).updateCard(updatedCard);

      if (mounted) {
        ref.invalidate(cardsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kart başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
    final subscriptionsAsync = ref.watch(allSubscriptionsProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
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
                'Kartı Düzenle',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildCardPreview(theme),

              const SizedBox(height: 32),
              TextFormField(
                controller: _cardNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Kart Takma Adı',
                  hintText: 'Örn: İş Kartım',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Lütfen bir ad girin' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastFourController,
                decoration: InputDecoration(
                  labelText: 'Son 4 Hane',
                  hintText: '1234',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/services/credit_card.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Gerekli';
                  if (v.length != 4) return '4 hane olmalı';
                  return null;
                },
              ),

              // Linked Subscriptions Section
              const SizedBox(height: 32),
              _buildLinkedSubscriptions(subscriptionsAsync, theme),

              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isLoading ? 'Güncelleniyor...' : 'Değişiklikleri Kaydet',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkedSubscriptions(
    AsyncValue<List<card_model.Subscription>> subscriptionsAsync,
    ThemeData theme,
  ) {
    return subscriptionsAsync.when(
      data: (subs) {
        final linkedSubs = subs
            .where((s) => s.cardId == widget.card.id)
            .toList();

        if (linkedSubs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.link_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bağlı Abonelikler (${linkedSubs.length})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: linkedSubs.map((sub) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    leading: SubscriptionIcon(subscription: sub, size: 32),
                    title: Text(
                      sub.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      '${sub.price} ${sub.currency}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCardPreview(ThemeData theme) {
    String name = _cardNameController.text.toUpperCase();
    if (name.isEmpty) name = "KART ADI";

    String lastFour = _lastFourController.text;
    if (lastFour.isEmpty) lastFour = "****";

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.8),
            theme.colorScheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.credit_card,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BANKA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.nfc, color: Colors.white70, size: 28),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '**** **** **** ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                            fontFamily: 'Courier',
                          ),
                        ),
                        Text(
                          lastFour,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PREMIUM MEMBER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(-12, 0),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
