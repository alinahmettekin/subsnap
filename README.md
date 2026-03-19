# SubSnap 🚀

**SubSnap** is a modern, high-performance subscription management application built with **Flutter**. It helps you take full control of your recurring expenses, visualize your spending, and ensure you never miss a renewal again.

Designed with a focus on simplicity, premium aesthetics, and reliable security.

---

## ✨ Key Features

- **Intuitive Dashboard:** Get a bird's-eye view of your monthly and yearly spending with beautiful, interactive charts.
- **Subscription Tracking:** Easily add, edit, and organize all your subscriptions (Netflix, Spotify, Gym, Cloud Storage, etc.).
- **Smart Reminders:** (Coming Soon) Get notified before your subscriptions renew.
- **Robust Authentication:** Secure sign-in via **Email, Google, and Apple**, powered by **Supabase**.
- **Deep Linking:** Seamless password recovery flow with native deep link handling.
- **Premium Experience:** Tiered features and subscription verification handled by **RevenueCat**.
- **Dark & Light Mode:** Seamlessly adapts to your system preferences using the sophisticated **FlexColorScheme**.
- **Multi-Platform:** Fully optimized for both **iOS and Android**.

---

## 🛠 Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (v3.10.x+)
- **State Management:** [Riverpod](https://riverpod.dev/) (Generator based)
- **Backend & Auth:** [Supabase](https://supabase.com/)
- **Payments & Subscriptions:** [RevenueCat](https://www.revenuecat.com/)
- **Deep Linking:** [app_links](https://pub.dev/packages/app_links)
- **Notifications:** [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- **Styling:** [FlexColorScheme](https://pub.dev/packages/flex_color_scheme) & [font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter)
- **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)

---

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- [Supabase Project](https://supabase.com/) configured with Email Auth and Database.
- [RevenueCat Project](https://www.revenuecat.com/) set up for iOS/Android entitlements.

### 2. Installation
Clone the repository:
```bash
git clone https://github.com/alinahmettekin/subsnap.git
cd subsnap
```

Install dependencies:
```bash
flutter pub get
```

### 3. Configuration
Ensure your `lib/core/utils/constants.dart` (or `.env`) is populated with your specific keys:
- `supabaseUrl`
- `supabaseAnonKey`
- `revenueCatPublicApiKey`

### 4. Running the App
For Android:
```bash
flutter run
```

For iOS:
```bash
cd ios && pod install && cd ..
flutter run
```

---

## 📁 Project Structure

```text
lib/
├── core/             # Services, Utils, Theme, Constants
│   ├── services/     # Auth, Subscription, RevenueCat logic
│   └── theme/        # Global style definitions
├── features/         # Feature-based folder structure
│   ├── auth/         # Login, Sign Up, Password Reset, AuthWrapper
│   ├── subscriptions/ # Dashboard, Add/Edit/View Subscriptions
│   ├── payments/      # Paywall and subscription verification
│   └── support/       # Help and Support views
└── main.dart         # App entry point & initialization
```

---

## 🔐 Privacy & Security

We take your privacy seriously. Your data is stored securely using **Supabase Row-Level Security (RLS)**, ensuring that only you can access your subscription data. For more details, see our [Privacy Policy](https://github.com/alinahmettekin/subsnap/wiki/Privacy-Policy).

---

## 👨‍💻 Author

Developed by **AATStudio** (Alin Ahmet Tekin)  
Contact: [alinahmettekin@icloud.com](mailto:alinahmettekin@icloud.com)

---

## ⚖️ License

All rights reserved to **AATStudio**. Portions of the code are licensed under the MIT License where applicable.
