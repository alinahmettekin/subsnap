import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/payments/presentation/revenuecat_provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:subsnap/core/providers/settings_provider.dart';
import 'package:subsnap/core/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.read(userProfileProvider);
    final displayName = profileAsync.value?.displayName ?? 'Kullanıcı';
    
    final controller = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Hesabı Sil'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu işlem geri alınamaz! Hesabınız ve tüm verileriniz kalıcı olarak silinecektir.',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hesabınızı silmek için kullanıcı adınızı yazın:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı adınızı yazın',
                    border: OutlineInputBorder(),
                    hintText: 'Kullanıcı adı',
                  ),
                  enabled: !isDeleting,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                    },
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (controller.text.trim() != displayName) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanıcı adı eşleşmiyor!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isDeleting = true;
                      });

                      try {
                        // Hesabı sil (içinde signOut var, bu router'ı tetikleyecek)
                        await ref.read(authRepositoryProvider).deleteAccount();
                        
                        // Dialog'u güvenli bir şekilde kapat
                        // deleteAccount içinde zaten delay var, bu yüzden burada ekstra delay gerekmez
                        if (dialogContext.mounted) {
                          // Navigator'ın unlock olmasını bekle
                          await Future.delayed(const Duration(milliseconds: 50));
                          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                        
                        // Router otomatik olarak login sayfasına yönlendirecek
                        // (auth state değiştiği için)
                      } catch (e) {
                        setState(() {
                          isDeleting = false;
                        });
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Hesap silme hatası: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Hesabı Sil'),
            ),
          ],
        ),
      ),
    );
  }

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
                              placeholderBuilder: (context) => const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('❌ [SETTINGS] SVG yükleme hatası: $error');
                                return const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(Icons.error_outline, size: 20, color: Colors.grey),
                                );
                              },
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

            // Pro Membership Card (RevenueCat)
            Builder(
              builder: (context) {
                final isPro = ref.watch(hasProProvider);
                return Card(
                  elevation: isPro ? 2 : 0,
                  color: isPro ? const Color(0xFF6366F1).withValues(alpha: 0.1) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isPro
                          ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPro ? const Color(0xFF6366F1) : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPro ? Icons.stars : Icons.stars_outlined,
                        color: isPro ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      isPro ? 'SubSnap Pro Üyesi' : 'Pro\'ya Yükselt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPro ? const Color(0xFF6366F1) : null,
                      ),
                    ),
                    subtitle: Text(
                      isPro
                          ? 'Sınırsız özelliklerin keyfini çıkarın.'
                          : 'Analizler, bildirimler ve daha fazlası.',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (isPro) {
                        RevenueCatUI.presentCustomerCenter();
                      } else {
                        context.push('/home/settings/paywall');
                      }
                    },
                  ),
                );
              },
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

          // Achievements
          Card(
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: const Text('Başarımlar'),
              subtitle: const Text('Kazandığın puanları ve başarımları gör'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/home/settings/achievements');
              },
            ),
          ),

          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bildirim Testleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => NotificationService().showTestNotification(),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Anlık Test'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => NotificationService().scheduleOneMinuteTest(),
                          icon: const Icon(Icons.timer_outlined),
                          label: const Text('1 Dakika'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bildirim Ayarları
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bildirim Ayarları',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tüm Bildirimler'),
                    subtitle: const Text('Tüm abonelik hatırlatıcılarını aç/kapat'),
                    value: ref.watch(appNotificationsProvider),
                    onChanged: (value) {
                      ref.read(appNotificationsProvider.notifier).setEnabled(value);
                      if (!value) {
                        NotificationService().cancelAllNotifications();
                      }
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulama Hatırlatıcıları'),
                    subtitle: const Text('Uygulamayı uzun süre açmadığında sana hatırlatmamızı ister misin?'),
                    value: ref.watch(retentionNotificationsProvider),
                    onChanged: (value) {
                      ref.read(retentionNotificationsProvider.notifier).setEnabled(value);
                      if (!value) {
                        NotificationService().cancelRetentionNotification();
                      } else {
                        NotificationService().scheduleRetentionNotification();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Clear Local Data
          Card(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Local Verileri Temizle'),
              subtitle: const Text('Tüm ayarlar ve cache verilerini temizle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Local Verileri Temizle'),
                    content: const Text(
                      'Tüm ayarlar ve cache verileri temizlenecek. Bu işlem geri alınamaz.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    
                    // Provider'ları resetle
                    ref.invalidate(showQuickAddProvider);
                    ref.invalidate(appNotificationsProvider);
                    ref.invalidate(retentionNotificationsProvider);
                    
                    // Bildirimleri iptal et
                    NotificationService().cancelAllNotifications();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Local veriler temizlendi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
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
              },
            ),
          ),

          const SizedBox(height: 16),

          // Delete Account
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Hesabı Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                _showDeleteAccountDialog(context, ref);
              },
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
