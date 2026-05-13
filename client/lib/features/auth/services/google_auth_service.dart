import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const String clientId =
      '285752649985-a8c6gp0bogkgiq3jpjau40vrhndnhv2r.apps.googleusercontent.com';
  static const List<String> scopes = <String>['email', 'profile'];

  static Future<void>? _initialization;

  static Future<void> initialize() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? clientId : null,
    );
  }

  static Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      GoogleSignIn.instance.authenticationEvents;

  static bool get supportsAuthenticate =>
      GoogleSignIn.instance.supportsAuthenticate();

  static Future<GoogleSignInAccount> signIn() async {
    await initialize();

    if (!supportsAuthenticate) {
      throw UnsupportedError(
        'This platform requires the rendered Google sign-in button.',
      );
    }

    return GoogleSignIn.instance.authenticate(scopeHint: scopes);
  }

  static String idTokenFor(GoogleSignInAccount account) {
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token.');
    }

    return idToken;
  }
}
