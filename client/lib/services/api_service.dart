import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this depending on your environment:
  // Android emulator: http://10.0.2.2:3000
  // iOS simulator / web: http://localhost:3000
  // Physical device: http://YOUR_LOCAL_IP:3000
  static const String baseUrl = 'http://localhost:3000';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  // =========================
  // AUTH
  // =========================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/login');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data,
          'message': _extractSuccessMessage(data, 'Login successful'),
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Login failed'),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/registration');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data,
          'message': _extractSuccessMessage(
            data,
            'Registration successful',
          ),
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Registration failed'),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration error: $e',
      };
    }
  }

  // =========================
  // BUILDER PROJECTS
  // =========================

  /// Creates a new builder project in the backend.
  ///
  /// Endpoint:
  /// POST /api/builder/projects
  static Future<Map<String, dynamic>> createBuilderProject({
    required String authToken,
    required Map<String, dynamic> projectJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects');

      final response = await http.post(
        url,
        headers: _headersWithAuth(authToken),
        body: jsonEncode(projectJson),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Project created successfully',
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to create project'),
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Create project error: $e',
      };
    }
  }

  /// Updates an existing builder project.
  ///
  /// Endpoint:
  /// PUT /api/builder/projects/:id
  static Future<Map<String, dynamic>> updateBuilderProject({
    required String authToken,
    required String projectId,
    required Map<String, dynamic> projectJson,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects/$projectId');

      final response = await http.put(
        url,
        headers: _headersWithAuth(authToken),
        body: jsonEncode(projectJson),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Project updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to update project'),
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Update project error: $e',
      };
    }
  }

  /// Fetches a single builder project by MongoDB id.
  ///
  /// Endpoint:
  /// GET /api/builder/projects/:id
  static Future<Map<String, dynamic>> getBuilderProjectById({
    required String authToken,
    required String projectId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects/$projectId');

      final response = await http.get(
        url,
        headers: _headersWithAuth(authToken),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data['data'] ?? data,
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to fetch project'),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Get project error: $e',
      };
    }
  }

  /// Fetches all builder projects.
  ///
  /// Endpoint:
  /// GET /api/builder/projects
  static Future<Map<String, dynamic>> getAllBuilderProjects({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects');

      final response = await http.get(
        url,
        headers: _headersWithAuth(authToken),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to fetch projects'),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Get all projects error: $e',
      };
    }
  }

  // =========================
  // OPTIONAL HELPERS
  // =========================

  /// Deletes a builder project.
  ///
  /// Add this only if you later create:
  /// DELETE /api/builder/projects/:id
  static Future<Map<String, dynamic>> deleteBuilderProject({
    required String authToken,
    required String projectId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects/$projectId');

      final response = await http.delete(
        url,
        headers: _headersWithAuth(authToken),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Project deleted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to delete project'),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Delete project error: $e',
      };
    }
  }

  static Map<String, dynamic> _decodeResponseBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  static bool _isSuccessful(int statusCode) {
    return statusCode == 200 || statusCode == 201;
  }

  static Map<String, String> _headersWithAuth(String authToken) {
    return {
      ..._headers,
      'Authorization': 'Bearer $authToken',
    };
  }

  static String _extractSuccessMessage(
    Map<String, dynamic> data,
    String fallback,
  ) {
    final rawMessage = data['success'] ?? data['message'];

    if (rawMessage is String && rawMessage.isNotEmpty) {
      return rawMessage;
    }

    return fallback;
  }

  static String _extractErrorMessage(
    Map<String, dynamic> data,
    String fallback,
  ) {
    final rawMessage = data['error'] ?? data['message'] ?? data['success'];

    if (rawMessage is String && rawMessage.isNotEmpty) {
      return rawMessage;
    }

    return fallback;
  }
}
