# Proje İnceleme ve Hata Raporu

Merhaba, **subsnap** projenizi MVP standartları ve Flutter best practice'leri çerçevesinde inceledim. Aşağıda kritik hatalar, yanlış entegrasyonlar ve iyileştirme önerilerimi bulabilirsiniz.

## 🚨 Kritik Hatalar (Acil Müdahale Gerekli)

1.  **Eksik Dosya (`lib/core/utils/constants.dart`):**
    -   Proje şu haliyle **derlenemiyor**. `main.dart` ve `subscription_service.dart` dosyaları `AppConstants` sınıfına ihtiyaç duyuyor ancak bu dosya repo'da yok (muhtemelen `.gitignore`'a takıldı).
    -   **Çözüm:** `constants.dart` dosyasını oluşturun ve `supabaseUrl`, `supabaseAnonKey`, `revenueCatApiKey` gibi sabitleri buraya ekleyin.

2.  **Hardcoded Hassas Veriler:**
    -   `AuthService` içinde Google `webClientId` açık bir şekilde yazılmış.
    -   `SubscriptionService` içinde RevenueCat entitlement ID (`'subsnap'`) hardcoded olarak duruyor.
    -   **Çözüm:** Bu değerleri `AppConstants` veya `.env` dosyasına taşıyın.

## ⚠️ Yanlış Entegrasyonlar ve Mantık Hataları

### 1. RevenueCat Entegrasyonu (SubscriptionService)
*   **Hata:** `Stream<bool>` oluşturmak için manuel `StreamController` kullanılmış. Bu yöntem bellek sızıntılarına açıktır ve Riverpod'un gücünü kullanmaz.
*   **Doğru Kullanım:** `StreamProvider` kullanarak RevenueCat'in stream'ini direkt dinleyin:
    ```dart
    @riverpod
    Stream<CustomerInfo> customerInfo(Ref ref) {
      return Purchases.getCustomerInfoStream();
    }

    @riverpod
    Stream<bool> isPremium(Ref ref) {
      return ref.watch(customerInfoProvider.select((info) =>
        info.value?.entitlements.active.containsKey(AppConstants.entitlementId) ?? false
      ));
    }
    ```

### 2. Gereksiz Veritabanı İşlemleri (SubscriptionRepository)
*   **Hata 1:** `addSubscription` metodunda her seferinde `_ensureProfileExists` çağrılıyor.
    -   **Neden Yanlış:** `supabase_schema.sql` dosyanızda `handle_new_user` trigger'ı var. Kullanıcı kayıt olduğunda profil zaten otomatik oluşuyor. Bu kontrol gereksiz bir API çağrısıdır ve uygulamayı yavaşlatır.
*   **Hata 2:** `deleteSubscriptionWithPayments` metodunda önce ödemeler, sonra abonelik siliniyor.
    -   **Neden Yanlış:** Veritabanınızda `ON DELETE CASCADE` tanımlı. Sadece aboneliği sildiğinizde, ona bağlı ödemeler veritabanı tarafından otomatik silinir. Kod tarafında bunu yapmak gereksizdir.

### 3. Navigasyon Yapısı (GoRouter Eksikliği)
*   **Durum:** Proje modern bir yapı (Riverpod, Supabase) kullanıyor ancak navigasyon `Navigator.push` ile ve `NavigationContainer` içindeki manuel index değişimiyle yapılmış.
*   **MVP Değerlendirmesi:** MVP için "çalışıyorsa dokunma" denebilir, ancak Deep Linking (örn. şifre sıfırlama mailleri) veya Web desteği düşünülüyorsa **GoRouter**'a geçmek şarttır. Şu anki `AuthWrapper` yapısı GoRouter'ın `redirect` özelliği ile çok daha temiz yazılabilir.

## 🛠 Kod Kalitesi ve MVP Önerileri

1.  **UI State Yönetimi:**
    -   `NavigationContainer` sayfa değiştirdiğinde diğer sayfaların (Dashboard, Payments) state'ini sıfırlıyor. `IndexedStack` kullanarak sayfaların state'ini koruyabilirsiniz.
    -   *Örnek:* `body: IndexedStack(index: _currentIndex, children: _screens)`

2.  **Performans:**
    -   `DashboardView` içinde `subscriptions` ve `categories` (eğer kullanılacaksa) ayrı ayrı `await` edilmemeli. Riverpod bu konuda iyidir ancak `Future.wait` mantığını repository seviyesinde değil, provider seviyesinde (örneğin bir `dashboardViewModel` içinde) kurmak daha doğrudur.

3.  **Küçük Düzeltmeler:**
    -   `SubscriptionRepository.getSubscriptions`: `(response as List)` cast işlemi yerine Supabase'in `.withConverter` özelliğini veya `.select()....withConverter(...)` yapısını kullanmak daha güvenlidir (Type safety).

## ✅ Özet Aksiyon Planı

1.  `lib/core/utils/constants.dart` dosyasını oluşturun.
2.  `SubscriptionRepository` içindeki gereksiz `_ensureProfileExists` ve `delete payments` kodlarını silin.
3.  RevenueCat provider'ını `StreamProvider` ile sadeleştirin.
4.  `NavigationContainer` içinde `IndexedStack` kullanın.

Başarılar dilerim! 🚀
