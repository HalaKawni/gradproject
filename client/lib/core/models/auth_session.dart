class AuthSession {
  final String token;
  final AuthUser user;

  const AuthSession({required this.token, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userJson = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};

    return AuthSession(
      token: json['token']?.toString() ?? '',
      user: AuthUser.fromJson(userJson),
    );
  }

  bool get isValid => token.isNotEmpty && user.id.isNotEmpty;

  String get userRole => user.role;
}

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool emailVerified;
  final String authProvider;
  final List<String> authProviders;
  final String lastSignInProvider;
  final String photoUrl;
  final String profileAvatarType;
  final String profileAvatarAssetPath;
  final String? profilePhotoBase64;
  final double profilePhotoFrameScale;
  final double profilePhotoFrameOffsetX;
  final double profilePhotoFrameOffsetY;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.emailVerified,
    required this.authProvider,
    required this.authProviders,
    required this.lastSignInProvider,
    required this.photoUrl,
    required this.profileAvatarType,
    required this.profileAvatarAssetPath,
    this.profilePhotoBase64,
    required this.profilePhotoFrameScale,
    required this.profilePhotoFrameOffsetX,
    required this.profilePhotoFrameOffsetY,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final rawAuthProviders = json['authProviders'];

    return AuthUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      emailVerified: json['emailVerified'] == true,
      authProvider: json['authProvider']?.toString() ?? 'local',
      authProviders: rawAuthProviders is List
          ? rawAuthProviders.map((value) => value.toString()).toList()
          : const <String>[],
      lastSignInProvider: json['lastSignInProvider']?.toString() ?? 'local',
      photoUrl: json['photoUrl']?.toString() ?? '',
      profileAvatarType: json['profileAvatarType']?.toString() == 'upload'
          ? 'upload'
          : 'asset',
      profileAvatarAssetPath:
          json['profileAvatarAssetPath']?.toString() ??
          json['photoUrl']?.toString() ??
          'assets/images/sprites/avatar00.png',
      profilePhotoBase64: _readNullableString(json['profilePhotoBase64']),
      profilePhotoFrameScale: _readDouble(
        json['profilePhotoFrameScale'],
        fallback: 1,
      ),
      profilePhotoFrameOffsetX: _readDouble(json['profilePhotoFrameOffsetX']),
      profilePhotoFrameOffsetY: _readDouble(json['profilePhotoFrameOffsetY']),
    );
  }
}

double _readDouble(Object? value, {double fallback = 0}) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _readNullableString(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
