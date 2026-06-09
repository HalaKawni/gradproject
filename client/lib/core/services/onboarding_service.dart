import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _welcomeKey = 'onboarding_welcome_v1';
  static const _hintPrefix = 'hint_dismissed_';

  static Future<bool> hasShownWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_welcomeKey) ?? false;
  }

  static Future<void> markWelcomeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
  }

  static Future<void> resetWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_welcomeKey);
  }

  // ── Per-hint dismissal ────────────────────────────────────────────────────

  static Future<bool> isHintDismissed(String hintKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_hintPrefix$hintKey') ?? false;
  }

  static Future<void> dismissHint(String hintKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_hintPrefix$hintKey', true);
  }

  static Future<void> resetAllHints() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_hintPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
