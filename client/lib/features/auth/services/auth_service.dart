import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class AuthService {
  // ── Save token locally ──────────────────────────────────────
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
    await prefs.remove('user');
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  // ── Register ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? classroomCode,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (classroomCode != null && classroomCode.isNotEmpty) {
      body['classroomCode'] = classroomCode.toUpperCase();
    }
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['status'] == true) {
      await saveUser(data['user']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await http.get(Uri.parse(ApiConstants.verifyEmail(token)));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Email verification failed');
    }
  }

  // ── Login ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.resendVerification),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      return data;
    } else {
      throw Exception(data['error'] ?? 'Failed to resend verification email');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      await saveToken(data['token']);
      await saveUser(data['user']);
      return data;
    } else {
      throw Exception(data['error'] ?? 'Login failed');
    }
  }

  // ── Logout ──────────────────────────────────────────────────
  static Future<void> logout() async {
    await clearToken();
  }

  // ── Check if logged in ──────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
