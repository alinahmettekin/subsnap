import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/auth/domain/entities/user_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  const ProfileSetupScreen({super.key, this.isEdit = false});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Varsayılan avatar seed'i
  String _selectedSeed = '';

  final List<Map<String, String>> _avatarStyles = [
    {'id': 'Easton', 'name': 'Easton'},
    {'id': 'Aiden', 'name': 'Aiden'},
    {'id': 'Christian', 'name': 'Christian'},
    {'id': 'Robert', 'name': 'Robert'},
    {'id': 'Jessica', 'name': 'Jessica'},
    {'id': 'Nolan', 'name': 'Nolan'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSeed = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized && widget.isEdit) {
      final profile = ref.read(userProfileProvider).value;
      if (profile != null) {
        _nameController.text = profile.displayName ?? '';
        if (profile.avatarUrl != null) {
          final uri = Uri.parse(profile.avatarUrl!);
          final seed = uri.queryParameters['seed'];
          if (seed != null) {
            _selectedSeed = seed;
          }
        }
      }
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _currentAvatarUrl => 'https://api.dicebear.com/9.x/avataaars/svg?seed=$_selectedSeed';

  Future<void> _handleSave() async {
    final user = ref.read(authUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      String displayName = _nameController.text.trim();

      // Eğer boş bırakılırsa email'den türet
      if (displayName.isEmpty) {
        final email = ref.read(supabaseClientProvider).auth.currentUser?.email ?? '';
        displayName = email.split('@')[0];
      }

      final profileRepo = ref.read(profileRepositoryProvider);

      final profile = UserProfile(
        id: user.id,
        email: ref.read(supabaseClientProvider).auth.currentUser?.email ?? '',
        displayName: displayName,
        avatarUrl: _currentAvatarUrl,
      );

      await profileRepo.updateProfile(profile);

      // Force refresh the profile and WAIT for it
      ref.invalidate(userProfileProvider);
      await ref.read(userProfileProvider.future);

      if (mounted) {
        if (widget.isEdit) {
          context.pop();
        } else {
          context.go('/home/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEdit ? AppBar(title: const Text('Profili Düzenle')) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!widget.isEdit) ...[
                  const Icon(Icons.face_retouching_natural, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  Text(
                    'Profilini Özelleştir',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // Avatar Önizleme
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.2), width: 4),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.indigo.shade50,
                    child: ClipOval(
                      child: SvgPicture.network(
                        _currentAvatarUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        placeholderBuilder: (BuildContext context) => const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Avatar Değiştir Butonu
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSeed = DateTime.now().millisecondsSinceEpoch.toString();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rastgele Değiştir'),
                ),
                const SizedBox(height: 24),

                // Karakter Seçici
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatarStyles.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _avatarStyles[index];
                      final isSelected = _selectedSeed == item['id'];
                      return ChoiceChip(
                        label: Text(item['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSeed = item['id']!;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // İsim alanı
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Adı',
                    hintText: 'Örn: subsnap_fan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '* Boş bırakırsanız e-posta adresiniz kullanılacaktır.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 48),

                // Buton
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _handleSave,
                      child: Text(
                        widget.isEdit ? 'Değişiklikleri Kaydet' : 'Hadi Başlayalım',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
