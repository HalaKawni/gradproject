import 'dart:async';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/auth/services/google_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_util) 'google_sign_in_button_web.dart'
    as google_button;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _googleSignInSubscription;

  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _isOpeningGoogleSession = false;

  @override
  void initState() {
    super.initState();
    unawaited(_setUpGoogleSignIn());
  }

  @override
  void dispose() {
    unawaited(_googleSignInSubscription?.cancel());
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _setUpGoogleSignIn() async {
    try {
      await GoogleAuthService.initialize();

      if (!mounted) {
        return;
      }

      _googleSignInSubscription =
          GoogleAuthService.authenticationEvents.listen(
            _handleGoogleAuthenticationEvent,
          )..onError(_handleGoogleSignInError);
    } catch (e) {
      _handleGoogleSignInError(e);
    }
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.login(email: email, password: password);

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final rawData = result['data'];
        final session = AuthSession.fromJson(
          rawData is Map ? Map<String, dynamic>.from(rawData) : {},
        );

        if (!session.isValid) {
          throw Exception('Login succeeded but no valid session was returned.');
        }

        if (session.userRole == 'admin') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.admin,
            (route) => false,
            arguments: AdminRouteData(session: session),
          );
          return;
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dashboard,
          (route) => false,
          arguments: DashboardRouteData(session: session),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Login failed'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openRegisterPage() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final account = await GoogleAuthService.signIn();
      await _openGoogleSession(account);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('User cancelled sign in');
        return;
      }

      debugPrint('Google sign in error: $e');
      _showGoogleSignInError(e.toString());
    } catch (e) {
      debugPrint('Google sign in error: $e');
      _showGoogleSignInError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(user: final account):
        await _openGoogleSession(account);
      case GoogleSignInAuthenticationEventSignOut():
        debugPrint('Google user signed out');
    }
  }

  void _handleGoogleSignInError(Object error) {
    debugPrint('Google sign in error: $error');
    _showGoogleSignInError(error.toString());
  }

  Future<void> _openGoogleSession(GoogleSignInAccount account) async {
    if (_isOpeningGoogleSession) {
      return;
    }

    _isOpeningGoogleSession = true;
    if (mounted) {
      setState(() {
        isGoogleLoading = true;
      });
    }

    try {
      final result = await ApiService.loginWithGoogle(
        idToken: GoogleAuthService.idTokenFor(account),
        role: 'child',
      );

      if (!mounted) {
        return;
      }

      if (result['success'] != true) {
        _showGoogleSignInError(
          result['message']?.toString() ?? 'Google login failed',
        );
        return;
      }

      final rawData = result['data'];
      final session = AuthSession.fromJson(
        rawData is Map ? Map<String, dynamic>.from(rawData) : {},
      );

      if (!session.isValid) {
        _showGoogleSignInError(
          'Google login succeeded but no valid session was returned.',
        );
        return;
      }

      if (session.userRole == 'admin') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.admin,
          (route) => false,
          arguments: AdminRouteData(session: session),
        );
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
        arguments: DashboardRouteData(session: session),
      );
    } catch (e) {
      _handleGoogleSignInError(e);
    } finally {
      _isOpeningGoogleSession = false;
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  void _showGoogleSignInError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Google sign in error: $message')));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'Learny',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  color: Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: emailController,
                          focusNode: emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          focusNode: passwordFocusNode,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 12),
                        google_button.buildGoogleSignInButton(
                          onPressed: isLoading ? null : _signInWithGoogle,
                          isLoading: isGoogleLoading,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: isLoading ? null : _openRegisterPage,
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
