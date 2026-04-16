import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/auth/providers/profile_provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/confirm_sheet.dart';

class AppSettingsView extends ConsumerWidget {
  const AppSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userEmail = ref.watch(authServiceProvider).currentUser?.email;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(theme, 'GÖRÜNÜM'),
          const SizedBox(height: 12),
          _buildModernThemeSelector(ref, theme),
          const SizedBox(height: 32),
          _buildSectionHeader(theme, 'BİLDİRİMLER'),
          const SizedBox(height: 12),
          _buildSettingsGroup(theme, [
            ref
                .watch(userProfileProvider)
                .when(
                  data: (profile) => SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    secondary: _buildIconBox(
                      Icons.notifications_outlined,
                      Colors.purple,
                    ),
                    title: const Text(
                      'Bildirimler',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    value: profile?.notificationsEnabled ?? true,
                    onChanged: (val) => ref
                        .read(userProfileProvider.notifier)
                        .toggleNotifications(val),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const ListTile(title: Text('Yüklenemedi')),
                ),
          ]),
          const SizedBox(height: 32),
          _buildSectionHeader(theme, 'HESAP VE GÜVENLİK'),
          const SizedBox(height: 12),
          _buildSettingsGroup(theme, [
            _buildActionTile(
              theme,
              icon: Icons.logout_rounded,
              iconColor: Colors.orange,
              title: 'Çıkış Yap',
              onTap: () async {
                final confirmed = await ConfirmSheet.show(
                  context,
                  title: 'Çıkış Yap',
                  message:
                      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                  confirmLabel: 'Çıkış Yap',
                  isDestructive: true,
                );

                if (confirmed == true) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
          ]),
          const SizedBox(height: 12),
          _buildSettingsGroup(theme, [
            _buildActionTile(
              theme,
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.red,
              title: 'Hesabımı Sil',
              isDestructive: true,
              onTap: () => _showDeleteAccountSheet(context, ref, userEmail),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildModernThemeSelector(WidgetRef ref, ThemeData theme) {
    final currentTheme = ref.watch(themeSettingsProvider);

    return Row(
      children: [
        _buildThemeCard(
          ref,
          theme,
          ThemeMode.system,
          'Sistem',
          Icons.brightness_auto_rounded,
          currentTheme == ThemeMode.system,
        ),
        const SizedBox(width: 10),
        _buildThemeCard(
          ref,
          theme,
          ThemeMode.light,
          'Açık',
          Icons.light_mode_rounded,
          currentTheme == ThemeMode.light,
        ),
        const SizedBox(width: 10),
        _buildThemeCard(
          ref,
          theme,
          ThemeMode.dark,
          'Koyu',
          Icons.dark_mode_rounded,
          currentTheme == ThemeMode.dark,
        ),
      ],
    );
  }

  Widget _buildThemeCard(
    WidgetRef ref,
    ThemeData theme,
    ThemeMode mode,
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(themeSettingsProvider.notifier).setTheme(mode),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildIconBox(icon, iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDestructive ? Colors.red : theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showDeleteAccountSheet(
    BuildContext context,
    WidgetRef ref,
    String? userEmail,
  ) {
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
              bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  24,
              top: 12,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Büyük Bir Karar!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hesabınızı sildiğinizde tüm abonelikleriniz, kartlarınız ve ayarlarınız sonsuza dek silinir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Onay için e-postanızı yazın',
                    hintText: userEmail,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    errorText: emailController.text.isNotEmpty && !isMatch
                        ? 'E-posta eşleşmiyor'
                        : null,
                  ),
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text(
                          'Vazgeç',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isMatch
                            ? () async {
                                final navigator = Navigator.of(context);
                                try {
                                  navigator.pop();
                                  await ref
                                      .read(authServiceProvider)
                                      .deleteAccount();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Hata: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Hesabımı Sil',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
}
