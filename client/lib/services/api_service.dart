import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.26:3000/api';

  // ── Token management ──────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── USER ENDPOINTS ────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/registration'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ── GAME ENDPOINTS ────────────────────────────────────────

  // GET /api/game/:gameId/progress
  // Backend returns the progress doc directly:
  // { _id, userId, gameId, levelResults: [{level, stars, score}...], ... }
  static Future<Map<String, dynamic>> getProgress(String gameId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game/$gameId/progress'),
        headers: await _authHeaders(),
      );

      if (response.statusCode != 200) return _emptyProgress();

      final raw = jsonDecode(response.body);
      Map<String, dynamic> progress;

      if (raw is Map<String, dynamic>) {
        // Backend may return { progress: {...} } or the object directly
        if (raw.containsKey('progress') && raw['progress'] is Map) {
          progress = Map<String, dynamic>.from(raw['progress']);
        } else if (raw.containsKey('levelResults')) {
          progress = Map<String, dynamic>.from(raw);
        } else {
          progress = _emptyProgress();
        }
      } else {
        progress = _emptyProgress();
      }

      // Build completedLevels from levelResults (only levels with stars > 0)
      final results = (progress['levelResults'] as List<dynamic>? ?? []);
      progress['completedLevels'] = results
          .where((r) => ((r['stars'] ?? 0) as num) > 0)
          .map((r) => r['level'])
          .toList();

      return progress;
    } catch (e) {
      return _emptyProgress();
    }
  }

  static Map<String, dynamic> _emptyProgress() => {
        'completedLevels': [],
        'levelResults': [],
        'highestLevelReached': 0,
        'totalScore': 0,
        'totalStars': 0,
      };

  // POST /api/game/:gameId/level
  // Backend REQUIRES: { level: int, stars: int, score: int }
  // stars must be 0-3 — NOT a boolean "completed" field!
  static Future<Map<String, dynamic>> saveLevelResult({
    required String gameId,
    required int level,
    required bool completed,
    int score = 0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game/$gameId/level'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'level': level,
          'stars': completed ? 3 : 1, // convert bool → stars number
          'score': score,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getLeaderboard(String gameId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/game/$gameId/leaderboard'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> resetProgress(String gameId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/game/$gameId/progress'),
      headers: await _authHeaders(),
    );
    return jsonDecode(response.body);
  }

  // ── DIGITAL LITERACY ACTIVITY HELPERS ────────────────────

  // Word Match → levels 201, 202, 203
  static Future<void> saveWordMatchScore({
    required String gameId,
    required int lessonNumber,
    required int matched,
    required int total,
  }) async {
    await saveLevelResult(
      gameId: gameId,
      level: 200 + lessonNumber,
      completed: matched == total,
      score: ((matched / total) * 100).round(),
    );
  }

  // Fill-in-Blanks → levels 301, 302, 303
  static Future<void> saveFillBlanksScore({
    required String gameId,
    required int lessonNumber,
    required int correct,
    required int total,
  }) async {
    await saveLevelResult(
      gameId: gameId,
      level: 300 + lessonNumber,
      completed: correct == total,
      score: ((correct / total) * 100).round(),
    );
  }

  // Word Search → levels 401, 402, 403
  static Future<void> saveWordSearchScore({
    required String gameId,
    required int lessonNumber,
    required int found,
    required int total,
  }) async {
    await saveLevelResult(
      gameId: gameId,
      level: 400 + lessonNumber,
      completed: found == total,
      score: ((found / total) * 100).round(),
    );
  }

  // ── AI ENDPOINTS ─────────────────────────────────────────

  // POST /api/ai/lesson-chat
  static Future<String?> chatWithAI({
    required String message,
    required String lessonTitle,
    required int lessonNumber,
    required List<Map<String, String>> history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/lesson-chat'),
        headers: await _authHeaders(),
        body: jsonEncode({
          'message': message,
          'lessonTitle': lessonTitle,
          'lessonNumber': lessonNumber,
          'history': history,
        }),
      );
      print('[AI-chat] status=${response.statusCode} body=${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == true) return data['text'] as String;
      }
      return null;
    } catch (e) {
      print('[AI-chat] error: $e');
      return null;
    }
  }

  // POST /api/ai/wordsearch-words
  static Future<List<String>> generateWordSearchWords({
    required int lessonNumber,
    required List<String> slideTexts,
  }) async {
    try {
      final url = '$baseUrl/ai/wordsearch-words';
      print('[AI] Calling $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _authHeaders(),
        body: jsonEncode({'lessonNumber': lessonNumber, 'slideTexts': slideTexts}),
      );
      print('[AI] Status: ${response.statusCode}  Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['words'] != null) {
          return List<String>.from(data['words']);
        }
      }
      return [];
    } catch (e) {
      print('[AI] Error: $e');
      return [];
    }
  }

  // POST /api/ai/wordmatch-pairs
  static Future<List<Map<String, String>>> generateWordMatchPairs({
    required int lessonNumber,
    required List<String> slideTexts,
  }) async {
    try {
      final url = '$baseUrl/ai/wordmatch-pairs';
      print('[AI] Calling $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _authHeaders(),
        body: jsonEncode({'lessonNumber': lessonNumber, 'slideTexts': slideTexts}),
      );
      print('[AI] Status: ${response.statusCode}  Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['pairs'] != null) {
          return List<Map<String, String>>.from(
            (data['pairs'] as List).map((p) => {
              'word': p['word'].toString(),
              'definition': p['definition'].toString(),
            }),
          );
        }
      }
      return [];
    } catch (e) {
      print('[AI] Error: $e');
      return [];
    }
  }

  // POST /api/ai/fill-blanks
  static Future<Map<String, dynamic>> generateFillBlanks({
    required int lessonNumber,
    required List<String> slideTexts,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/fill-blanks'),
        headers: await _authHeaders(),
        body: jsonEncode({'lessonNumber': lessonNumber, 'slideTexts': slideTexts}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) return data;
      }
      return {};
    } catch (e) {
      print('[AI] Error: $e');
      return {};
    }
  }

  // POST /api/ai/quiz-questions
  static Future<List<Map<String, dynamic>>> generateQuizQuestions({
    required int lessonNumber,
    required List<String> slideTexts,
  }) async {
    try {
      final url = '$baseUrl/ai/quiz-questions';
      print('[AI] Calling $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _authHeaders(),
        body: jsonEncode({'lessonNumber': lessonNumber, 'slideTexts': slideTexts}),
      );
      print('[AI] Status: ${response.statusCode}  Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['questions'] != null) {
          return List<Map<String, dynamic>>.from(data['questions']);
        }
      }
      return [];
    } catch (e) {
      print('[AI] Error: $e');
      return [];
    }
  }

  // POST /api/ai/swipe-concepts
  static Future<List<Map<String, dynamic>>> generateSwipeConcepts({
    required int lessonNumber,
    required List<String> slideTexts,
  }) async {
    try {
      final url = '$baseUrl/ai/swipe-concepts';
      print('[AI] Calling $url');
      final response = await http.post(
        Uri.parse(url),
        headers: await _authHeaders(),
        body: jsonEncode({'lessonNumber': lessonNumber, 'slideTexts': slideTexts}),
      );
      print('[AI] Status: ${response.statusCode}  Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && data['concepts'] != null) {
          return List<Map<String, dynamic>>.from(
            (data['concepts'] as List).map((c) => {
              'text': c['text'].toString(),
              'positive': c['positive'] as bool,
              'sender': c['sender'].toString(),
              'preview': c['preview'].toString(),
            }),
          );
        }
      }
      return [];
    } catch (e) {
      print('[AI] Error: $e');
      return [];
    }
  }

  // Final Quiz → levels 101, 102, 103
  static Future<void> saveQuizScore({
    required String gameId,
    required int lessonNumber,
    required int correctAnswers,
    required int totalQuestions,
  }) async {
    await saveLevelResult(
      gameId: gameId,
      level: 100 + lessonNumber,
      completed: correctAnswers == totalQuestions,
      score: ((correctAnswers / totalQuestions) * 100).round(),
    );
  }
}