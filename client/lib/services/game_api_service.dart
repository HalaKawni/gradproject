import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_constants.dart';
import 'auth_service.dart';

class GameApiService {
  // ── Shared header builder ───────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Get progress ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProgress(String gameId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.gameProgress(gameId)),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return data['progress'];
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch progress');
    }
  }

  // ── Save level result ───────────────────────────────────────
  static Future<Map<String, dynamic>> saveLevelResult({
    required String gameId,
    required int level,
    required int stars,
    required int score,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.saveLevel(gameId)),
      headers: await _authHeaders(),
      body: jsonEncode({
        'level': level,
        'stars': stars,
        'score': score,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return data['progress'];
    } else {
      throw Exception(data['error'] ?? 'Failed to save level');
    }
  }

  // ── Get leaderboard ─────────────────────────────────────────
  static Future<List<dynamic>> getLeaderboard(String gameId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.leaderboard(gameId)),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return data['leaderboard'];
    } else {
      throw Exception(data['error'] ?? 'Failed to fetch leaderboard');
    }
  }

  // ── Reset progress ──────────────────────────────────────────
  static Future<void> resetProgress(String gameId) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.resetProgress(gameId)),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['status'] != true) {
      throw Exception(data['error'] ?? 'Failed to reset progress');
    }
  }
}