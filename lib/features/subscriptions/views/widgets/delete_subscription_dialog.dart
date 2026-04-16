import 'package:flutter/material.dart';

enum DeleteOption { subscriptionOnly, subscriptionWithPayments }

class DeleteSubscriptionDialog extends StatefulWidget {
  final String subscriptionName;

  const DeleteSubscriptionDialog({super.key, required this.subscriptionName});

  @override
  State<DeleteSubscriptionDialog> createState() => _DeleteSubscriptionDialogState();
}

class _DeleteSubscriptionDialogState extends State<DeleteSubscriptionDialog> {
  DeleteOption _selectedOption = DeleteOption.subscriptionOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDestructive = _selectedOption == DeleteOption.subscriptionWithPayments;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 8,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 0. Drag Handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 1. Modern Header Icon with Background Glow
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDestructive ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.2),
                      (isDestructive ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isDestructive ? Colors.red : theme.colorScheme.primary).withValues(alpha: 0.1),
                    width: 4,
                  ),
                ),
                child: Icon(
                  isDestructive ? Icons.delete_forever_rounded : Icons.archive_rounded,
                  color: isDestructive ? Colors.red : theme.colorScheme.primary,
                  size: 36,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Title & Message
          Text(
            'Abonelik İşlemi',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '"${widget.subscriptionName}"',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' aboneliği ile ne yapmak istersiniz?'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 3. Selection Cards
          _buildOptionCard(
            theme: theme,
            option: DeleteOption.subscriptionOnly,
            title: 'Aboneliği İptal Et',
            subtitle: 'Abonelik arşive alınır, ödeme geçmişiniz korunur.',
            icon: Icons.inventory_2_outlined,
            isSelected: _selectedOption == DeleteOption.subscriptionOnly,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            theme: theme,
            option: DeleteOption.subscriptionWithPayments,
            title: 'Tamamen Kaldır',
            subtitle: 'Abonelik ve tüm geçmiş ödemeler kalıcı olarak temizlenir.',
            icon: Icons.delete_forever_outlined,
            isSelected: _selectedOption == DeleteOption.subscriptionWithPayments,
            isDestructiveOption: true,
          ),

          const SizedBox(height: 32),

          // 4. Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedOption),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: isDestructive ? Colors.red : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    isDestructive ? 'Tamamen Sil' : 'Aboneliği İptal Et & Arşivle',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required DeleteOption option,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    bool isDestructiveOption = false,
  }) {
    final activeColor = isDestructiveOption ? Colors.red : theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _selectedOption = option),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : theme.dividerColor.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.2) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? activeColor.withValues(alpha: 0.2) : theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isSelected ? activeColor : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.check_circle_rounded, color: activeColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
