# In-App Purchase (IAP) Strateji Raporu ve Entegrasyon Rehberi

Bu rapor, mevcut projedeki ödeme altyapısındaki eksiklikleri analiz eder ve MVP (Minimum Viable Product) prensiplerine uygun, sürdürülebilir ve basit bir entegrasyon stratejisi sunar.

## 1. Mevcut Durum Analizi (Sorunlar)

Mevcut kod tabanı (`IAPNotifier` ve `in_app_purchase` paketi) incelendiğinde aşağıdaki kritik sorunlar tespit edilmiştir:

1.  **Abonelik Yenileme Takibinin Eksikliği (En Kritik Sorun):**
    *   Mevcut sistemde kullanıcı satın alma yaptığında, Supabase veritabanındaki `expiryDate` (bitiş tarihi) sadece **bir kez** ileri atılıyor.
    *   Ancak abonelikler (Subscription) doğası gereği Apple/Google tarafından otomatik olarak yenilenir.
    *   **Sonuç:** Kullanıcı parasını ödemeye devam etse bile, Supabase veritabanınızın bundan haberi olmaz ve uygulamanız bir ay/yıl sonra kullanıcının "Pro" yetkilerini elinden alır. Bunu çözmek için Apple/Google sunucularından gelen "Webhook"ları dinleyen bir backend sunucusuna ihtiyacınız vardır.

2.  **Güvenlik Açığı (Client-Side Trust):**
    *   `_verifyAndUpgrade` fonksiyonu sadece cihazdan gelen "başarılı" sinyaline güveniyor. "Receipt Validation" (Makbuz doğrulama) yapılmıyor.
    *   Teknik bilgisi olan bir kullanıcı, sahte satın alma sinyalleri ile sistemi kandırabilir.

3.  **Karmaşık Durum Yönetimi:**
    *   `in_app_purchase` ham paketi ile "pending" (bekleyen), "restored" (geri yüklenen), "error" durumlarını yönetmek ve bunları Supabase ile senkronize etmek çok efor gerektirir ve hataya açıktır.

## 2. Önerilen Çözüm: RevenueCat

MVP aşamasındaki ve Flutter kullanan projeler için endüstri standardı çözüm **RevenueCat** kullanmaktır.

*   **Neden RevenueCat?**
    *   **Backend Gerektirmez:** Kendi sunucunuzda Apple/Google ile konuşan kodlar yazmanıza gerek kalmaz. RevenueCat bunu sizin yerinize yapar.
    *   **Otomatik Yenileme Takibi:** Abonelik yenilendiğinde RevenueCat bunu bilir. Uygulamanız sadece "Bu kullanıcının aktif aboneliği var mı?" diye RevenueCat'e sorar.
    *   **Platformlar Arası Senkronizasyon:** iOS'ta alan kullanıcı Android'de de kullanabilir (Supabase User ID ile eşleştirilerek).
    *   **Basit Kod:** 300 satırlık karmaşık `IAPNotifier` yerine 50 satırlık temiz bir servis yazarsınız.
    *   **Analitik:** Kim ne zaman aldı, ne kadar kazandınız gibi verileri kendi panelinde gösterir.

## 3. Entegrasyon Rehberi (Kod Önerileri)

Aşağıda, mevcut karmaşık yapıyı RevenueCat ile nasıl değiştireceğinizi adım adım anlattım.

### Adım 1: Paket Kurulumu

`pubspec.yaml` dosyanıza `in_app_purchase` yerine şu paketi ekleyin:

```yaml
dependencies:
  purchases_flutter: ^6.0.0 # Sürümü kontrol ediniz
```

### Adım 2: RevenueCat Hesabı
1.  RevenueCat.com'da hesap açın.
2.  Project oluşturun.
3.  Apple App Store ve Google Play Store için uygulama ayarlarını girin (Bundle ID vb.).
4.  RevenueCat panelinde "Entitlements" (Yetkiler) oluşturun. Örn: `pro_access`.
5.  Panelde "Offerings" ve "Products" tanımlayın. (Örn: `subsnap_monthly`, `subsnap_yearly`).

### Adım 3: Subscription Service (Yeni Kod)

Mevcut `iap_provider.dart` dosyasını silip yerine çok daha basit bir yapı kuracağız.

**`lib/features/subscriptions/data/subscription_service.dart`** (Yeni dosya önerisi)

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // RevenueCat API Keyleri (RevenueCat panelinden alınacak)
  static const _apiKeyIOS = 'appl_...';
  static const _apiKeyAndroid = 'goog_...';

  // RevenueCat'te tanımladığınız Entitlement ID
  static const _entitlementID = 'pro_access';

  static Future<void> init(String appUserId) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    }

    // Kullanıcı ID'sini Supabase ID ile eşleştiriyoruz
    configuration.appUserID = appUserId;

    await Purchases.configure(configuration);
  }

  /// Mevcut paketleri (Offerings) getirir
  static Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
    } on PlatformException catch (e) {
      // Hata yönetimi
      print(e);
    }
    return [];
  }

  /// Satın alma işlemi
  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        print("Satın alma hatası: $e");
      }
      return false;
    }
  }

  /// Kullanıcının PRO olup olmadığını kontrol eder
  static Future<bool> getIsPro() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Satın almaları geri yükle (Restore Purchases)
  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}
```

### Adım 4: Riverpod ile Entegrasyon

Servisi UI'da kullanmak için basit bir Provider:

**`lib/features/subscriptions/presentation/subscription_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/subscription_service.dart';

// Kullanıcının PRO olup olmadığını tutan state
final isProUserProvider = StateProvider<bool>((ref) => false);

// Paketleri (Fiyatları) tutan provider
final offeringsProvider = FutureProvider<List<Package>>((ref) async {
  return await SubscriptionService.getPackages();
});

// Başlangıçta durumu kontrol eden metod (main.dart veya auth state change'de çağrılmalı)
Future<void> checkSubscriptionStatus(WidgetRef ref) async {
  final isPro = await SubscriptionService.getIsPro();
  ref.read(isProUserProvider.notifier).state = isPro;
}
```

### Adım 5: Analiz Sayfası Koruması

Kullanıcının şikayet ettiği "Analiz Sayfası"nı korumak için `AnalyticsScreen` içinde kontrol:

**`lib/features/analytics/presentation/analytics_screen.dart`** (Güncelleme Önerisi)

```dart
// ... importlar
import 'package:subsnap/features/subscriptions/presentation/subscription_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProUserProvider);

    if (!isPro) {
      // Eğer kullanıcı Pro değilse, içeriği gösterme, Paywall'a yönlendir veya kilitli göster
      return Scaffold(
        appBar: AppBar(title: Text('Analiz')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              Text("Bu özellik sadece PRO kullanıcılara açıktır."),
              ElevatedButton(
                onPressed: () {
                   // Paywall sayfasını aç
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PaywallScreen()));
                },
                child: Text("Pro'ya Geç"),
              )
            ],
          ),
        ),
      );
    }

    // Kullanıcı Pro ise normal sayfayı göster
    return Scaffold(
       // ... mevcut kodlar
    );
  }
}
```

### Adım 6: Paywall Sayfası (Basitleştirilmiş)

**`lib/features/payments/presentation/paywall_screen.dart`** içinde artık `IAPNotifier` yerine `SubscriptionService` metodları çağrılacak:

```dart
// Satın al butonuna basınca:
onPressed: () async {
    // Seçilen paketi al
    final success = await SubscriptionService.purchasePackage(selectedPackage);
    if (success) {
        // State'i güncelle
        ref.read(isProUserProvider.notifier).state = true;
        Navigator.pop(context); // Paywall'ı kapat
    } else {
        // Hata mesajı göster
    }
}
```

## Özet

Mevcut sisteminiz abonelikleri yönetmek için yetersizdir. En hızlı ve güvenli çözüm **RevenueCat** entegrasyonudur. Yukarıdaki adımları takip ederek:

1.  Supabase veritabanı ile boğuşmaktan kurtulursunuz.
2.  Abonelik yenilemelerini otomatik takip edersiniz.
3.  Kod tabanınız %80 oranında sadeleşir.
