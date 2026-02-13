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

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: theme.colorScheme.error, size: 28),
          const SizedBox(width: 12),
          const Expanded(child: Text('Aboneliği Sil')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${widget.subscriptionName}" aboneliğini silmek istediğinize emin misiniz?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Text('Silme Seçeneği:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Option 1: Subscription Only
          InkWell(
            onTap: () => setState(() => _selectedOption = DeleteOption.subscriptionOnly),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedOption == DeleteOption.subscriptionOnly
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedOption == DeleteOption.subscriptionOnly
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Radio<DeleteOption>(
                    value: DeleteOption.subscriptionOnly,
                    groupValue: _selectedOption,
                    onChanged: (value) => setState(() => _selectedOption = value!),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sadece aboneliği sil',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Geçmiş ödemeler korunur',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: Subscription + Payments
          InkWell(
            onTap: () => setState(() => _selectedOption = DeleteOption.subscriptionWithPayments),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedOption == DeleteOption.subscriptionWithPayments
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedOption == DeleteOption.subscriptionWithPayments
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Radio<DeleteOption>(
                    value: DeleteOption.subscriptionWithPayments,
                    groupValue: _selectedOption,
                    onChanged: (value) => setState(() => _selectedOption = value!),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abonelik + geçmiş ödemeleri sil',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tüm veriler kalıcı olarak silinir',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Warning message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu işlem geri alınamaz!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('İptal')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedOption),
          style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}
