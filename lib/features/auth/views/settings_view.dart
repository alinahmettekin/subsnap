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
import '../../../core/widgets/confirm_sheet.dart';

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

  void _showDeleteAccountSheet(String? userEmail) {
    if (userEmail == null) return;

    final emailController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final isMatch = emailController.text.trim() == userEmail;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
              top: 12,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person_remove_rounded, color: theme.colorScheme.error, size: 32),
                ),
                const SizedBox(height: 20),

                Text(
                  'Hesabımı Sil',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                Text(
                  'Onaylamak için lütfen e-posta adresinizi yazınız:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: userEmail,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    errorText: emailController.text.isNotEmpty && !isMatch ? 'E-posta eşleşmiyor' : null,
                  ),
                  onChanged: (_) => setSheetState(() {}),
                  // Fix for keyboard visibility in bottom sheet
                  onFieldSubmitted: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isMatch
                            ? () async {
                                final navigator = Navigator.of(context);
                                final scaffoldMessenger = ScaffoldMessenger.of(context);

                                try {
                                  // Hemen sheet'i kapat
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
                          backgroundColor: theme.colorScheme.error,
                          disabledBackgroundColor: theme.colorScheme.error.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hesabımı Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              final confirmed = await ConfirmSheet.show(
                context,
                title: 'Çıkış Yap',
                message: 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                confirmLabel: 'Çıkış Yap',
                isDestructive: true,
              );

              if (confirmed == true && mounted) {
                await ref.read(authServiceProvider).signOut();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
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
            onPressed: () => _showDeleteAccountSheet(user?.email),
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
