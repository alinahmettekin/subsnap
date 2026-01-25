import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// Tema modunu yöneten provider (StateProvider legacy import'tan geliyor)
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});
