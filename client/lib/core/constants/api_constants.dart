class ApiConstants {
  static const String baseUrl =
      'http://192.168.1.13:3000/api'; // PC's local WiFi IP for real device testing

  // Auth
  static const String register = '$baseUrl/user/registration';
  static const String login = '$baseUrl/user/login';
  static const String profile = '$baseUrl/user/profile';
  static const String resendVerification = '$baseUrl/user/resend-verification';
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
