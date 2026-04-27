class ApiConstants {
static const String baseUrl = 'http://localhost:3000/api';  // 👆 Use 10.0.2.2 for Android emulator
  // Use 127.0.0.1 for Windows desktop
  // Use your actual IP (e.g. 192.168.1.5) for a real phone

  // Auth
  static const String register = '$baseUrl/user/registration';
  static const String login = '$baseUrl/user/login';
  static const String profile = '$baseUrl/user/profile';

  // Game
  static String gameProgress(String gameId) => '$baseUrl/game/$gameId/progress';
  static String saveLevel(String gameId) => '$baseUrl/game/$gameId/level';
  static String leaderboard(String gameId) => '$baseUrl/game/$gameId/leaderboard';
  static String resetProgress(String gameId) => '$baseUrl/game/$gameId/progress';
}