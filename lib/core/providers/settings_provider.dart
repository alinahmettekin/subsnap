import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quick Add gösterim ayarı provider
final showQuickAddProvider = NotifierProvider<ShowQuickAddNotifier, bool>(() {
  return ShowQuickAddNotifier();
});

class ShowQuickAddNotifier extends Notifier<bool> {
  static const String _key = 'show_quick_add';

  @override
  bool build() {
    // İlk build'de default değer döndür, sonra async yükle
    Future.microtask(() => _loadSetting());
    return true; // Default: true (göster)
  }

  Future<void> _loadSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key) ?? true;
      if (state != value) {
        state = value;
      }
    } catch (e) {
      // Hata durumunda default değeri koru
    }
  }

  Future<void> setShowQuickAdd(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
      state = value;
    } catch (e) {
      // Hata durumunda state'i güncelle ama kaydetme
      state = value;
    }
  }
}
