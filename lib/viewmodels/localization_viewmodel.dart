import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationViewModel extends ChangeNotifier {
  static const _languageKey = 'local_language_code';

  LocalizationViewModel({Locale initialLocale = const Locale('ar')})
    : _currentLocale = initialLocale;

  Locale _currentLocale;

  Locale get currentLocale => _currentLocale;
  bool get isArabic => _currentLocale.languageCode == 'ar';

  void setLocale(Locale locale) {
    if (_currentLocale == locale) return;
    _currentLocale = locale;
    unawaited(_saveLocale(locale));
    notifyListeners();
  }

  void toggleLanguage() {
    setLocale(isArabic ? const Locale('en') : const Locale('ar'));
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, locale.languageCode);
  }
}
