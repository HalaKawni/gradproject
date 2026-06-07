import 'dart:convert';
import 'dart:typed_data';
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
        body: jsonEncode({'email': email, 'password': password}),
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
      return {'success': false, 'message': 'Login error: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? role,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/login/google');
      final body = <String, dynamic>{'idToken': idToken};

      if (role != null) {
        body['role'] = role;
      }

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data,
          'message': _extractSuccessMessage(data, 'Google login successful'),
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Google login failed'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Google login error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/resend-verification');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'email': email}),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': data,
          'message': _extractSuccessMessage(
            data,
            'Verification email sent successfully',
          ),
        };
      }

      return {
        'success': false,
        'message': _extractErrorMessage(
          data,
          'Failed to send verification email',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send verification email: $e',
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
          'message': _extractSuccessMessage(data, 'Registration successful'),
        };
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Registration failed'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Registration error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getProfile({required String authToken}) {
    return _sendRequest(
      method: 'GET',
      path: '/profile',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch profile',
    );
  }

  static Future<Map<String, dynamic>> changePassword({
    required String authToken,
    required String currentPassword,
    required String newPassword,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/profile/password',
      authToken: authToken,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      defaultSuccessMessage: 'Password changed successfully',
      defaultErrorMessage: 'Failed to change password',
    );
  }

  static Future<Map<String, dynamic>> updateProfileAvatar({
    required String authToken,
    required Map<String, dynamic> avatarJson,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/profile/avatar',
      authToken: authToken,
      body: avatarJson,
      defaultSuccessMessage: 'Profile photo updated successfully',
      defaultErrorMessage: 'Failed to update profile photo',
    );
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
      return {'success': false, 'message': 'Create project error: $e'};
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
      return {'success': false, 'message': 'Update project error: $e'};
    }
  }

  /// Updates only builder project metadata/settings.
  ///
  /// Endpoint:
  /// PATCH /api/builder/projects/:id/settings
  static Future<Map<String, dynamic>> updateBuilderProjectSettings({
    required String authToken,
    required String projectId,
    required Map<String, dynamic> settingsJson,
  }) {
    return _sendRequest(
      method: 'PATCH',
      path: '/api/builder/projects/$projectId/settings',
      authToken: authToken,
      body: settingsJson,
      defaultSuccessMessage: 'Project settings updated successfully',
      defaultErrorMessage: 'Failed to update project settings',
    );
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
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to fetch project'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Get project error: $e'};
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
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(data, 'Failed to fetch projects'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Get all projects error: $e'};
    }
  }

  /// Fetches published builder projects for discovery.
  ///
  /// Endpoint:
  /// GET /api/builder/projects/published
  static Future<Map<String, dynamic>> getPublishedBuilderProjects({
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/projects/published');

      final response = await http.get(
        url,
        headers: _headersWithAuth(authToken),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {'success': true, 'data': data['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(
            data,
            'Failed to fetch published projects',
          ),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Get published projects error: $e'};
    }
  }

  /// Fetches one published builder project for the discover/play flow.
  ///
  /// Endpoint:
  /// GET /api/builder/projects/published/:id
  static Future<Map<String, dynamic>> getPublishedBuilderProjectById({
    required String authToken,
    required String projectId,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/builder/projects/published/$projectId',
      );

      final response = await http.get(
        url,
        headers: _headersWithAuth(authToken),
      );

      final data = _decodeResponseBody(response);

      if (_isSuccessful(response.statusCode)) {
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        return {
          'success': false,
          'message': _extractErrorMessage(
            data,
            'Failed to fetch published project',
          ),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Get published project error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadBuilderAsset({
    required String authToken,
    required String name,
    required String type,
    required String mimeType,
    required String imageBase64,
    bool isPublic = false,
  }) {
    return _sendRequest(
      method: 'POST',
      path: '/api/builder/assets',
      authToken: authToken,
      body: {
        'name': name,
        'type': type,
        'mimeType': mimeType,
        'imageBase64': imageBase64,
        'isPublic': isPublic,
      },
      defaultSuccessMessage: 'Asset uploaded successfully',
      defaultErrorMessage: 'Failed to upload asset',
    );
  }

  static Future<Map<String, dynamic>> getBuilderAssets({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/builder/assets',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch assets',
    );
  }

  static Future<Map<String, dynamic>> getPublishedBuilderAssets({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/builder/assets/public',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch published assets',
    );
  }

  static Future<Map<String, dynamic>> getBuilderAsset({
    required String authToken,
    required String assetId,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/builder/assets/$assetId',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch asset',
    );
  }

  static Future<Map<String, dynamic>> updateBuilderAsset({
    required String authToken,
    required String assetId,
    required Map<String, dynamic> assetJson,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/api/builder/assets/$assetId',
      authToken: authToken,
      body: assetJson,
      defaultSuccessMessage: 'Asset updated successfully',
      defaultErrorMessage: 'Failed to update asset',
    );
  }

  static Future<Map<String, dynamic>> deleteBuilderAsset({
    required String authToken,
    required String assetId,
  }) {
    return _sendRequest(
      method: 'DELETE',
      path: '/api/builder/assets/$assetId',
      authToken: authToken,
      defaultSuccessMessage: 'Asset deleted successfully',
      defaultErrorMessage: 'Failed to delete asset',
    );
  }

  static Future<Uint8List?> getBuilderAssetData({
    required String authToken,
    required String assetId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/builder/assets/$assetId/data');
      final response = await http.get(
        url,
        headers: _headersWithAuth(authToken),
      );

      if (_isSuccessful(response.statusCode)) {
        return response.bodyBytes;
      }

      return null;
    } catch (_) {
      return null;
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
      return {'success': false, 'message': 'Delete project error: $e'};
    }
  }

  // =========================
  // PUBLIC COURSES
  // =========================

  static Future<Map<String, dynamic>> getPublicCourses({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/courses/public',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch courses',
    );
  }

  static Future<Map<String, dynamic>> getPublicCourseLevels({
    required String authToken,
    required String courseId,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/courses/$courseId/levels',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch course levels',
    );
  }

  static Future<Map<String, dynamic>> getPublicCourseProgress({
    required String authToken,
    required String courseId,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/courses/$courseId/progress',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch course progress',
    );
  }

  static Future<Map<String, dynamic>> completePublicCourseLevel({
    required String authToken,
    required String courseId,
    required String levelId,
    int? score,
    int? totalScore,
    int? stars,
  }) {
    final body = <String, dynamic>{};
    if (score != null) {
      body['score'] = score;
    }
    if (totalScore != null) {
      body['totalScore'] = totalScore;
    }
    if (stars != null) {
      body['stars'] = stars;
    }

    return _sendRequest(
      method: 'POST',
      path: '/api/courses/$courseId/levels/$levelId/complete',
      authToken: authToken,
      body: body,
      defaultSuccessMessage: 'Course progress saved successfully',
      defaultErrorMessage: 'Failed to save course progress',
    );
  }

  // =========================
  // ADMIN
  // =========================

  static Future<Map<String, dynamic>> getAdminDashboard({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/dashboard',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch dashboard',
    );
  }

  static Future<Map<String, dynamic>> getAdminStatistics({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/statistics',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch statistics',
    );
  }

  static Future<Map<String, dynamic>> getAdminCourses({
    required String authToken,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/courses',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch courses',
    );
  }

  static Future<Map<String, dynamic>> createAdminCourse({
    required String authToken,
    required Map<String, dynamic> courseJson,
  }) {
    return _sendRequest(
      method: 'POST',
      path: '/api/admin/courses',
      authToken: authToken,
      body: courseJson,
      defaultSuccessMessage: 'Course created successfully',
      defaultErrorMessage: 'Failed to create course',
    );
  }

  static Future<Map<String, dynamic>> updateAdminCourse({
    required String authToken,
    required String courseId,
    required Map<String, dynamic> courseJson,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/api/admin/courses/$courseId',
      authToken: authToken,
      body: courseJson,
      defaultSuccessMessage: 'Course updated successfully',
      defaultErrorMessage: 'Failed to update course',
    );
  }

  static Future<Map<String, dynamic>> deleteAdminCourse({
    required String authToken,
    required String courseId,
  }) {
    return _sendRequest(
      method: 'DELETE',
      path: '/api/admin/courses/$courseId',
      authToken: authToken,
      defaultSuccessMessage: 'Course deleted successfully',
      defaultErrorMessage: 'Failed to delete course',
    );
  }

  static Future<Map<String, dynamic>> getAdminLevels({
    required String authToken,
    String? status,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/levels',
      authToken: authToken,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
      defaultErrorMessage: 'Failed to fetch levels',
    );
  }

  static Future<Map<String, dynamic>> getAdminLevelById({
    required String authToken,
    required String levelId,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/levels/$levelId',
      authToken: authToken,
      defaultErrorMessage: 'Failed to fetch level',
    );
  }

  static Future<Map<String, dynamic>> updateAdminLevel({
    required String authToken,
    required String levelId,
    required Map<String, dynamic> levelJson,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/api/admin/levels/$levelId',
      authToken: authToken,
      body: levelJson,
      defaultSuccessMessage: 'Level updated successfully',
      defaultErrorMessage: 'Failed to update level',
    );
  }

  static Future<Map<String, dynamic>> deleteAdminLevel({
    required String authToken,
    required String levelId,
  }) {
    return _sendRequest(
      method: 'DELETE',
      path: '/api/admin/levels/$levelId',
      authToken: authToken,
      defaultSuccessMessage: 'Level deleted successfully',
      defaultErrorMessage: 'Failed to delete level',
    );
  }

  static Future<Map<String, dynamic>> getAdminUsers({
    required String authToken,
    String search = '',
    int page = 1,
    int limit = 20,
  }) {
    return _sendRequest(
      method: 'GET',
      path: '/api/admin/users',
      authToken: authToken,
      queryParameters: {
        'page': '$page',
        'limit': '$limit',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
      defaultErrorMessage: 'Failed to fetch users',
    );
  }

  static Future<Map<String, dynamic>> createAdminUser({
    required String authToken,
    required Map<String, dynamic> userJson,
  }) {
    return _sendRequest(
      method: 'POST',
      path: '/api/admin/users/admin',
      authToken: authToken,
      body: userJson,
      defaultSuccessMessage: 'Admin user created successfully',
      defaultErrorMessage: 'Failed to create admin user',
    );
  }

  static Future<Map<String, dynamic>> promoteUserToAdmin({
    required String authToken,
    required String email,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/api/admin/users/admin/promote',
      authToken: authToken,
      body: {'email': email},
      defaultSuccessMessage: 'User promoted to admin successfully',
      defaultErrorMessage: 'Failed to promote user to admin',
    );
  }

  static Future<Map<String, dynamic>> deleteAdminUser({
    required String authToken,
    required String userId,
  }) {
    return _sendRequest(
      method: 'DELETE',
      path: '/api/admin/users/$userId',
      authToken: authToken,
      defaultSuccessMessage: 'User deleted successfully',
      defaultErrorMessage: 'Failed to delete user',
    );
  }

  static Future<Map<String, dynamic>> updateAdminUserSuspension({
    required String authToken,
    required String userId,
    required bool isSuspended,
  }) {
    return _sendRequest(
      method: 'PUT',
      path: '/api/admin/users/$userId/suspension',
      authToken: authToken,
      body: {'isSuspended': isSuspended},
      defaultSuccessMessage: isSuspended
          ? 'User suspended successfully'
          : 'User restored successfully',
      defaultErrorMessage: isSuspended
          ? 'Failed to suspend user'
          : 'Failed to restore user',
    );
  }

  static Future<Map<String, dynamic>> _sendRequest({
    required String method,
    required String path,
    required String authToken,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    String defaultSuccessMessage = 'Request completed successfully',
    String defaultErrorMessage = 'Request failed',
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl$path',
      ).replace(queryParameters: queryParameters);
      final headers = _headersWithAuth(authToken);
      late final http.Response response;

      if (method == 'POST') {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      } else if (method == 'PUT') {
        response = await http.put(
          url,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      } else if (method == 'PATCH') {
        response = await http.patch(
          url,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else {
        response = await http.get(url, headers: headers);
      }

      final decoded = _decodeJsonBody(response);
      final decodedMap = _asMap(decoded);

      if (_isSuccessful(response.statusCode)) {
        return {
          'success': true,
          'data': _extractPayload(decoded),
          'message': _extractSuccessMessage(decodedMap, defaultSuccessMessage),
        };
      }

      return {
        'success': false,
        'message': _extractErrorMessage(decodedMap, defaultErrorMessage),
        'errors': decodedMap['errors'],
      };
    } catch (e) {
      return {'success': false, 'message': '$defaultErrorMessage: $e'};
    }
  }

  static Map<String, dynamic> _decodeResponseBody(http.Response response) {
    final decoded = _decodeJsonBody(response);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  static dynamic _decodeJsonBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body);
  }

  static Map<String, dynamic> _asMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return {};
  }

  static dynamic _extractPayload(dynamic decoded) {
    final data = _asMap(decoded);

    if (data.containsKey('data')) {
      return data['data'];
    }

    return decoded;
  }

  static bool _isSuccessful(int statusCode) {
    return statusCode == 200 || statusCode == 201;
  }

  static Map<String, String> _headersWithAuth(String authToken) {
    return {..._headers, 'Authorization': 'Bearer $authToken'};
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
