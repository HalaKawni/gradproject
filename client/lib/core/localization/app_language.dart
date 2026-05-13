import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();
  static const String _storageKey = 'app_language_code';

  Locale _locale = const Locale('en');
  Map<String, String> _translations = {};

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';
  TextDirection get textDirection =>
      isArabic ? TextDirection.rtl : TextDirection.ltr;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey) ?? 'en';
    await setLanguage(code, persist: false);
  }

  Future<void> setLanguage(String code, {bool persist = true}) async {
    final normalizedCode = code == 'ar' ? 'ar' : 'en';
    final rawJson = await rootBundle.loadString(
      'assets/i18n/$normalizedCode.json',
    );
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;

    _locale = Locale(normalizedCode);
    _translations = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, normalizedCode);
    }

    notifyListeners();
  }

  String t(String key, {Map<String, String> params = const {}}) {
    var value = _translations[key] ?? key;

    for (final entry in params.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }

    return value;
  }

  static AppLanguage of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LanguageScope>();
    return scope?.notifier ?? instance;
  }
}

class LanguageScope extends StatelessWidget {
  const LanguageScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _LanguageScope(notifier: AppLanguage.instance, child: child);
  }
}

class _LanguageScope extends InheritedNotifier<AppLanguage> {
  const _LanguageScope({
    required AppLanguage super.notifier,
    required super.child,
  });
}
