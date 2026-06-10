import '../core/constants/api_config.dart';

class ApiConstants {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  // Auth
  static String get register => '$baseUrl/user/registration';
  static String get login => '$baseUrl/user/login';
  static String get profile => '$baseUrl/user/profile';

  // Game
  static String gameProgress(String gameId) => '$baseUrl/game/$gameId/progress';
  static String saveLevel(String gameId) => '$baseUrl/game/$gameId/level';
  static String leaderboard(String gameId) => '$baseUrl/game/$gameId/leaderboard';
  static String resetProgress(String gameId) => '$baseUrl/game/$gameId/progress';

  // Parent-child linking
  static String get generateLinkCode => '$baseUrl/user/generate-link-code';
  static String get getLinkCode => '$baseUrl/user/link-code';
  static String get linkChild => '$baseUrl/user/link-child';
  static String unlinkChild(String childId) => '$baseUrl/user/unlink-child/$childId';
  static String get linkedChildren => '$baseUrl/user/linked-children';

  // Classroom
  static String get joinClassroom => '$baseUrl/classroom/join';
  static String get myClassroom => '$baseUrl/classroom/my-classroom';
  static String get classroomMembers => '$baseUrl/classroom/members';
  static String get classroomActivity => '$baseUrl/classroom/activity';
  static String classroomLeaderboard(String gameId) => '$baseUrl/classroom/leaderboard/$gameId';
}
