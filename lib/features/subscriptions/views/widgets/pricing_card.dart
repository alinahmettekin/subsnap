import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PricingCard extends StatelessWidget {
  final Package package;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isBestValue;

  const PricingCard({
    super.key,
    required this.package,
    required this.onTap,
    this.isSelected = false,
    this.isBestValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isYearly = package.packageType == PackageType.annual;
    final isMonthly = package.packageType == PackageType.monthly;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.colorScheme.surface,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    // Radio Circle
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                          width: 2,
                        ),
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isYearly ? 'Yıllık Plan' : (isMonthly ? 'Aylık Plan' : package.storeProduct.title),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (isMonthly)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '🔥 1 ay ücretsiz deneme',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (isYearly)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'En avantajlı seçim',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          package.storeProduct.priceString,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          isYearly ? '/yıl' : '/ay',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Best Value Badge
          if (isYearly)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiary]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'EN POPÜLER',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
