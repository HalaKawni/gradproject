import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this based on where your backend is running
  static const String baseUrl = 'http://localhost:3000';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': data,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/users/registration');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': data,
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Registration failed',
      };
    }
  }
}