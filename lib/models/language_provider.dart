import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _language = 'fr';
  bool _isInitialized = false;

  String get language => _language;
  bool get isInitialized => _isInitialized;
  String get languageName => _language == 'fr' ? 'Français' : 'English';
  String get flagEmoji => _language == 'fr' ? '🇫🇷' : '🇬🇧';

  LanguageProvider() {
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language');

    if (savedLanguage != null) {
      _language = savedLanguage;
    } else {
      _language = _detectSystemLanguage();
      await prefs.setString('language', _language);
    }

    _isInitialized = true;
    notifyListeners();
  }

  String _detectSystemLanguage() {
    final systemLocale = WidgetsBinding.instance.window.locale;
    final languageCode = systemLocale.languageCode;
    print('📱 Langue du téléphone: $languageCode');
    return languageCode.startsWith('en') ? 'en' : 'fr';
  }

  Future<void> setLanguage(String newLanguage) async {
    if (newLanguage != _language) {
      _language = newLanguage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', newLanguage);
      notifyListeners();
    }
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_language == 'fr' ? 'en' : 'fr');
  }

  Future<void> resetToSystemLanguage() async {
    final systemLang = _detectSystemLanguage();
    await setLanguage(systemLang);
  }
}