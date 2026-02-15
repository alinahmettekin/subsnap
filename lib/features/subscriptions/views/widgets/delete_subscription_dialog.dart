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

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent, // Remove default tint for cleaner look
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.delete_rounded, color: theme.colorScheme.error, size: 32),
            ),
            const SizedBox(height: 20),

            // 2. Title & Message
            Text(
              'Abonelik İşlemi',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                children: [
                  TextSpan(
                    text: '"${widget.subscriptionName}"',
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const TextSpan(text: ' aboneliği ile ne yapmak istersiniz?'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 3. Selection Cards
            _buildOptionCard(
              theme: theme,
              option: DeleteOption.subscriptionOnly,
              title: 'Aboneliği İptal Et',
              subtitle: 'Abonelik askıya alınır, ödeme geçmişi korunur.',
              icon: Icons.inventory_2_outlined,
              isSelected: _selectedOption == DeleteOption.subscriptionOnly,
            ),
            const SizedBox(height: 12),
            _buildOptionCard(
              theme: theme,
              option: DeleteOption.subscriptionWithPayments,
              title: 'Tamamen Kaldır',
              subtitle: 'Abonelik ve tüm geçmiş veriler kalıcı olarak silinir.',
              icon: Icons.delete_forever_outlined,
              isSelected: _selectedOption == DeleteOption.subscriptionWithPayments,
              isDestructiveOption: true,
            ),

            const SizedBox(height: 32),

            // 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedOption);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: isDestructive ? theme.colorScheme.onError : theme.colorScheme.onSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isDestructive ? 'Tamamen Sil' : 'İptal Et',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDestructive ? theme.colorScheme.onError : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    final activeColor = isDestructiveOption ? theme.colorScheme.error : theme.colorScheme.primary;
    final borderColor = isSelected ? activeColor : theme.colorScheme.outline.withValues(alpha: 0.15);
    final bgColor = isSelected ? activeColor.withValues(alpha: 0.05) : Colors.transparent;
    final iconColor = isSelected ? activeColor : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return InkWell(
      onTap: () => setState(() => _selectedOption = option),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle_rounded, color: activeColor, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
