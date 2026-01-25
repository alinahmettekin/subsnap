import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';

/// Hazır abonelik şablonları için model (DB'den gelir)
class SubscriptionTemplate {
  final String id;
  final String name;
  final String iconName; // SimpleIcons icon name (örn: 'netflix')
  final BillingCycle defaultBillingCycle;
  final String? categoryId;
  final String? categoryName; // Join'den gelir
  final int displayOrder;

  const SubscriptionTemplate({
    required this.id,
    required this.name,
    required this.iconName,
    this.defaultBillingCycle = BillingCycle.monthly,
    this.categoryId,
    this.categoryName,
    this.displayOrder = 0,
  });

  /// IconData'yı SimpleIcons'tan al
  IconData? get iconData {
    try {
      // SimpleIcons'tan icon'u al
      switch (iconName.toLowerCase()) {
        // Entertainment & Streaming
        case 'netflix':
          return SimpleIcons.netflix;
        case 'youtube':
          return SimpleIcons.youtube;
        case 'spotify':
          return SimpleIcons.spotify;
        case 'applemusic':
          return SimpleIcons.applemusic;
        
        case 'amazon':
          return SimpleIcons.amazon;
        case 'twitch':
          return SimpleIcons.twitch;
        // Productivity & Software
        case 'openai':
          return SimpleIcons.openai;
        case 'canva':
          return SimpleIcons.canva;
        case 'notion':
          return SimpleIcons.notion;
        case 'figma':
          return SimpleIcons.figma;
        case 'google':
          return SimpleIcons.google;
        // Cloud Storage
        case 'dropbox':
          return SimpleIcons.dropbox;
        case 'icloud':
          return SimpleIcons.icloud;
        // Gaming
        
        case 'playstation':
          return SimpleIcons.playstation;
        case 'steam':
          return SimpleIcons.steam;
        // Social & Communication
        case 'discord':
          return SimpleIcons.discord;
        
        default:
          return Icons.category_outlined; // Fallback
      }
    } catch (e) {
      return Icons.category_outlined;
    }
  }

  /// IconColor'ı SimpleIconColors'tan al
  Color? get iconColor {
    try {
      switch (iconName.toLowerCase()) {
        // Entertainment & Streaming
        case 'netflix':
          return SimpleIconColors.netflix;
        case 'youtube':
          return SimpleIconColors.youtube;
        case 'spotify':
          return SimpleIconColors.spotify;
        case 'applemusic':
          return SimpleIconColors.applemusic;
        case 'amazon':
          return SimpleIconColors.amazon;
        case 'twitch':
          return SimpleIconColors.twitch;
        // Productivity & Software
        case 'openai':
          return SimpleIconColors.openai;
        case 'canva':
          return SimpleIconColors.canva;
        case 'notion':
          return SimpleIconColors.notion;
        case 'figma':
          return SimpleIconColors.figma;
        case 'google':
          return SimpleIconColors.google;
        // Cloud Storage
        case 'dropbox':
          return SimpleIconColors.dropbox;
        case 'icloud':
          return SimpleIconColors.icloud;
        // Gaming       
        case 'playstation':
          return SimpleIconColors.playstation;
        case 'steam':
          return SimpleIconColors.steam;
        // Social & Communication
        case 'discord':
          return SimpleIconColors.discord;
        
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  factory SubscriptionTemplate.fromMap(Map<String, dynamic> map) {
    return SubscriptionTemplate(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      iconName: map['icon_name']?.toString() ?? '',
      defaultBillingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == map['default_billing_cycle']?.toString(),
        orElse: () => BillingCycle.monthly,
      ),
      categoryId: map['category_id']?.toString(),
      categoryName: map['category_name']?.toString() ?? 
          (map['categories'] != null && map['categories'] is Map 
              ? (map['categories'] as Map)['name']?.toString() 
              : null),
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
    );
  }

  /// Template'den Subscription oluştur
  Subscription toSubscription(String userId) {
    return Subscription(
      id: '', // Yeni oluşturulurken UUID generate edilecek
      userId: userId,
      name: name,
      amount: 0.0, // Kullanıcı girecek
      currency: 'TRY', // Default TRY
      billingCycle: defaultBillingCycle,
      nextPaymentDate: DateTime.now().add(const Duration(days: 30)),
      categoryId: categoryId,
      categoryName: categoryName,
    );
  }
}
