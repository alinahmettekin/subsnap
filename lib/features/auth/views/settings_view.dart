import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/paywall_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  Future<void> _manageSubscription() async {
    final Uri url = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;
    final isPremiumAsync = ref.watch(isPremiumProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
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
            error: (_, __) => const _SettingsTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Abonelik Durumu',
              value: 'Bilinmiyor',
            ),
          ),
          const Divider(height: 32),
          _SettingsTile(icon: Icons.help_outline_rounded, title: 'Yardım & Destek', onTap: () {}),
          _SettingsTile(icon: Icons.info_outline_rounded, title: 'Uygulama Hakkında', onTap: () {}),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
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
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _SettingsTile({required this.icon, required this.title, this.value, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: value != null
          ? Text(value!, style: const TextStyle(fontWeight: FontWeight.bold))
          : const Icon(Icons.chevron_right_rounded),
      contentPadding: EdgeInsets.zero,
    );
  }
}
