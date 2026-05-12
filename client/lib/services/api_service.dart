import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Change this to your server IP/URL ──
  static const String baseUrl = 'http://localhost:3000/api';

  // ── Save token after login ──
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // ── Get saved token ──
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ── Clear token on logout ──
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ── Auth headers ──
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ──────────────────────────────────────────
  // USER ENDPOINTS
  // ──────────────────────────────────────────

  // POST /api/user/registration
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/registration'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    return jsonDecode(response.body);
  }

  // POST /api/user/login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    // Save token if login successful
    if (data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  }

  // GET /api/user/profile
  static Future<Map<String, dynamic>> getProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // ──────────────────────────────────────────
  // GAME ENDPOINTS
  // ──────────────────────────────────────────

  // GET /api/game/:gameId/progress
  static Future<Map<String, dynamic>> getProgress(String gameId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/game/$gameId/progress'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // POST /api/game/:gameId/level
  static Future<Map<String, dynamic>> saveLevelResult({
    required String gameId,
    required int level,
    required bool completed,
    int score = 0,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/game/$gameId/level'),
      headers: headers,
      body: jsonEncode({
        'level': level,
        'completed': completed,
        'score': score,
      }),
    );
    return jsonDecode(response.body);
  }

  // GET /api/game/:gameId/leaderboard
  static Future<Map<String, dynamic>> getLeaderboard(String gameId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/game/$gameId/leaderboard'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }

  // DELETE /api/game/:gameId/progress
  static Future<Map<String, dynamic>> resetProgress(String gameId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/game/$gameId/progress'),
      headers: headers,
    );
    return jsonDecode(response.body);
  }
}