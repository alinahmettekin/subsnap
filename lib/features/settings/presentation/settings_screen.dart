import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authUser = ref.watch(authUserProvider).value;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info
          if (authUser != null) ...[
            profileAsync.when(
              data: (profile) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: profile?.avatarUrl != null
                        ? ClipOval(
                            child: SvgPicture.network(
                              profile!.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            profile?.displayName?.isNotEmpty == true
                                ? profile!.displayName![0].toUpperCase()
                                : authUser.email?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  title: Text(profile?.displayName ?? 'Kullanıcı'),
                  subtitle: Text(authUser.email ?? 'E-posta yok'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/home/settings/edit-profile');
                  },
                ),
              ),
              loading: () => const Card(child: ListTile(title: LinearProgressIndicator())),
              error: (e, __) => Card(child: ListTile(title: Text('Hata: $e'))),
            ),
            const SizedBox(height: 16),
          ],

          // Theme Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Görünüm',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.brightness_auto, size: 20),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        label: Text('Açık'),
                        icon: Icon(Icons.light_mode, size: 20),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        label: Text('Koyu'),
                        icon: Icon(Icons.dark_mode, size: 20),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref.read(themeModeProvider.notifier).state = newSelection.first;
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Add Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlı Ekle',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hızlı Ekle Göster'),
                    subtitle: const Text('Ana sayfada hızlı ekle butonlarını göster'),
                    value: ref.watch(showQuickAddProvider),
                    onChanged: (value) {
                      ref.read(showQuickAddProvider.notifier).setShowQuickAdd(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
              onTap: () {
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
