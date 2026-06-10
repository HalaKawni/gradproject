import 'api_config.dart';

class ApiConstants {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Auth
  static String get register => '$baseUrl/user/registration';
  static String get login => '$baseUrl/user/login';
  static String get profile => '$baseUrl/user/profile';
  static String get resendVerification => '$baseUrl/user/resend-verification';
  static String get forgotPassword => '$baseUrl/user/forgot-password';
  static String get resetPassword => '$baseUrl/user/reset-password';
  static String verifyEmail(String token) =>
      '$baseUrl/user/verify-email?token=${Uri.encodeQueryComponent(token)}';

  // Game
  static String gameProgress(String gameId) => '$baseUrl/game/$gameId/progress';
  static String saveLevel(String gameId) => '$baseUrl/game/$gameId/level';
  static String leaderboard(String gameId) =>
      '$baseUrl/game/$gameId/leaderboard';
  static String resetProgress(String gameId) =>
      '$baseUrl/game/$gameId/progress';
}
