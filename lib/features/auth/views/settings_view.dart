import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/paywall_view.dart';
import '../../cards/views/cards_list_view.dart';
import '../../cards/providers/card_provider.dart';
import '../../support/views/help_and_support_view.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  Future<void> _manageSubscription() async {
    final Uri url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAccountDialog(String? userEmail) {
    if (userEmail == null) return;

    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final isMatch = emailController.text.trim() == userEmail;

          return AlertDialog(
            title: const Text('Hesabımı Sil', style: TextStyle(color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm abonelikleriniz, ödemeleriniz ve verileriniz kalıcı olarak silinecektir.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Onaylamak için lütfen e-posta adresinizi yazınız:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: userEmail,
                    border: const OutlineInputBorder(),
                    errorText: emailController.text.isNotEmpty && !isMatch ? 'E-posta eşleşmiyor' : null,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
              FilledButton(
                onPressed: isMatch
                    ? () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        try {
                          // Hemen diyaloğu kapat
                          navigator.pop();

                          // Hesabı sil
                          await ref.read(authServiceProvider).deleteAccount();
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.red.withOpacity(0.3),
                ),
                child: const Text('Hesabımı Sil'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person_rounded, size: 50, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.userMetadata?['full_name'] ?? 'Kullanıcı',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          isPremiumAsync.when(
            data: (isPremium) => Column(
              children: [
                _SettingsTile(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Abonelik Durumu',
                  value: isPremium ? 'Premium' : 'Ücretsiz Plan',
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  iconWidget: Image.asset(
                    'assets/services/credit_card.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                  ),
                  title: 'Ödeme Yöntemlerim',
                  value: ref
                      .watch(cardCountProvider)
                      .when(data: (count) => '$count Kart', loading: () => '...', error: (_, _) => 'Hata'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardsListView())),
                ),
                const SizedBox(height: 8),
                if (isPremium)
                  _SettingsTile(icon: Icons.subscriptions, title: 'Abonelikleri Yönet', onTap: _manageSubscription)
                else
                  _SettingsTile(
                    icon: Icons.rocket_launch_rounded,
                    title: "Premium'a Yükselt",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView())),
                    iconColor: Colors.deepPurple,
                  ),
              ],
            ),
            loading: () =>
                const _SettingsTile(icon: Icons.workspace_premium_rounded, title: 'Abonelik Durumu', value: '...'),
            error: (_, _) => const _SettingsTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Abonelik Durumu',
              value: 'Bilinmiyor',
            ),
          ),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Yardım ve Destek',
            value: 'SSS & İletişim',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpAndSupportView())),
          ),
          const Divider(height: 32),
          Text(
            'Görünüm',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Sistem')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Açık')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Koyu')),
            ],
            selected: {ref.watch(themeSettingsProvider)},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeSettingsProvider.notifier).setTheme(newSelection.first);
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.primary,
              selectedForegroundColor: theme.colorScheme.onPrimary,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 48),
          OutlinedButton.icon(
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Çıkış Yap'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _showDeleteAccountDialog(user?.email),
            icon: const Icon(Icons.delete_forever_rounded, size: 20),
            label: const Text('Hesabımı Sil'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({this.icon, this.iconWidget, required this.title, this.value, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading:
          iconWidget ?? (icon != null ? Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary) : null),
      title: Text(title),
      trailing: value != null
          ? Text(value!, style: const TextStyle(fontWeight: FontWeight.bold))
          : const Icon(Icons.chevron_right_rounded),
      contentPadding: EdgeInsets.zero,
    );
  }
}
