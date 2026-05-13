import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class LocalizationNotifier extends Notifier<Locale> {
  static const String _key = 'selected_language';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedLang = prefs.getString(_key);
    
    if (savedLang != null) {
      return Locale(savedLang);
    }

    // Auto detect device language
    final deviceLocale = PlatformDispatcher.instance.locale;
    if (deviceLocale.languageCode == 'hi') {
      return const Locale('hi');
    }
    return const Locale('en');
  }

  void setLanguage(String langCode) {
    state = Locale(langCode);
    ref.read(sharedPreferencesProvider).setString(_key, langCode);
  }
}

final localizationProvider = NotifierProvider<LocalizationNotifier, Locale>(() {
  return LocalizationNotifier();
});

