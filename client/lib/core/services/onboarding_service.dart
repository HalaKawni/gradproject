import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _welcomeKey = 'onboarding_welcome_v1';
  static const _hintPrefix = 'hint_dismissed_';

  static Future<String> _resolveUserScope([
    String? userScope,
  ]) async {
    if (userScope != null && userScope.trim().isNotEmpty) {
      return userScope.trim();
    }

    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString('user');
    if (rawUser == null || rawUser.isEmpty) {
      return 'guest';
    }

    try {
      final decoded = jsonDecode(rawUser);
      if (decoded is Map) {
        final user = Map<String, dynamic>.from(decoded);
        final id = user['id']?.toString().trim();
        if (id != null && id.isNotEmpty) {
          return id;
        }
        final email = user['email']?.toString().trim().toLowerCase();
        if (email != null && email.isNotEmpty) {
          return email;
        }
      }
    } catch (_) {
      // Fall back to a guest scope if the cached user payload is invalid.
    }

    return 'guest';
  }

  static Future<String> _scopedKey(
    String key, [
    String? userScope,
  ]) async {
    final scope = await _resolveUserScope(userScope);
    return '$scope::$key';
  }

  static Future<bool> hasShownWelcome([String? userScope]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_welcomeKey, userScope);
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markWelcomeShown([String? userScope]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_welcomeKey, userScope);
    await prefs.setBool(key, true);
  }

  static Future<void> resetWelcome([String? userScope]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey(_welcomeKey, userScope);
    await prefs.remove(key);
  }

  // ── Per-hint dismissal ────────────────────────────────────────────────────

  static Future<bool> isHintDismissed(
    String hintKey, [
    String? userScope,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey('$_hintPrefix$hintKey', userScope);
    return prefs.getBool(key) ?? false;
  }

  static Future<void> dismissHint(
    String hintKey, [
    String? userScope,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _scopedKey('$_hintPrefix$hintKey', userScope);
    await prefs.setBool(key, true);
  }

  static Future<void> resetAllHints([String? userScope]) async {
    final prefs = await SharedPreferences.getInstance();
    final scope = await _resolveUserScope(userScope);
    final scopedPrefix = '$scope::$_hintPrefix';
    final keys = prefs.getKeys().where((k) => k.startsWith(scopedPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
