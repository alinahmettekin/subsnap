import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const DashboardHeader({super.key, required this.onProfileTap});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Günaydın';
    } else if (hour < 18) {
      return 'İyi Günler';
    } else {
      return 'İyi Akşamlar';
    }
  }

  String _getUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return '';
    final metadata = user.userMetadata;
    if (metadata != null && metadata.containsKey('full_name')) {
      final fullName = metadata['full_name'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        return ', ${fullName.split(' ').first}';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting() + _getUserName(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aboneliklerinizi kontrol edin',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                ),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
