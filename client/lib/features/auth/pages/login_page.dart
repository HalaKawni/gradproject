import 'dart:async';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_service.dart';
import '../widgets/google_sign_in_button_stub.dart'
    if (dart.library.js_util) '../widgets/google_sign_in_button_web.dart'
    as google_button;
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool _isOpeningGoogleSession = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  ScaffoldMessengerState? _scaffoldMessenger;
  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _googleSignInSubscription;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    unawaited(_setUpGoogleSignIn());
  }

  @override
  void dispose() {
    unawaited(_googleSignInSubscription?.cancel());
    _cloudController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
  }

  Future<void> _setUpGoogleSignIn() async {
    try {
      await GoogleAuthService.initialize();

      if (!mounted) {
        return;
      }

      _googleSignInSubscription = GoogleAuthService.authenticationEvents.listen(
        _handleGoogleAuthenticationEvent,
      )..onError(_handleGoogleSignInError);
    } catch (e) {
      _handleGoogleSignInError(e);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final account = await GoogleAuthService.signIn();
      await _loginWithGoogleAccount(account);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _handleGoogleSignInError(e);
      }
    } catch (e) {
      _handleGoogleSignInError(e);
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
        if (!isGoogleLoading) {
          await _loginWithGoogleAccount(account);
        }
      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  Future<void> _loginWithGoogleAccount(GoogleSignInAccount account) async {
    if (_isOpeningGoogleSession) {
      return;
    }

    if (!mounted) {
      return;
    }

    _isOpeningGoogleSession = true;
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final result = await ApiService.loginWithGoogle(
        idToken: GoogleAuthService.idTokenFor(account),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        await _openAuthenticatedSession(result['data']);
      } else {
        _showErrorMessage(
          result['message']?.toString() ?? 'Google login failed',
        );
      }
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

  Future<void> _openAuthenticatedSession(dynamic rawData) async {
    final session = AuthSession.fromJson(
      rawData is Map ? Map<String, dynamic>.from(rawData) : {},
    );

    if (!session.isValid) {
      throw Exception('Login succeeded but no valid session was returned.');
    }

    await AuthService.saveToken(session.token);
    await AuthService.saveUser({
      'id': session.user.id,
      'name': session.user.name,
      'email': session.user.email,
      'role': session.user.role,
      'ageGroup': session.user.ageGroup,
      'gender': session.user.gender,
      'emailVerified': session.user.emailVerified,
      'authProvider': session.user.authProvider,
      'authProviders': session.user.authProviders,
      'lastSignInProvider': session.user.lastSignInProvider,
      'photoUrl': session.user.photoUrl,
      'profileAvatarType': session.user.profileAvatarType,
      'profileAvatarAssetPath': session.user.profileAvatarAssetPath,
      'profilePhotoBase64': session.user.profilePhotoBase64,
      'profilePhotoFrameScale': session.user.profilePhotoFrameScale,
      'profilePhotoFrameOffsetX': session.user.profilePhotoFrameOffsetX,
      'profilePhotoFrameOffsetY': session.user.profilePhotoFrameOffsetY,
    });

    if (!mounted) {
      return;
    }

    final routeName = switch (session.userRole) {
      'admin' => AppRoutes.admin,
      'parent' => AppRoutes.parent,
      _ => AppRoutes.dashboard,
    };
    final routeData = switch (session.userRole) {
      'admin' => AdminRouteData(session: session),
      'parent' => ParentRouteData(session: session),
      _ => DashboardRouteData(session: session),
    };

    _scaffoldMessenger?.removeCurrentSnackBar();
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: routeData,
    );
  }

  void _handleGoogleSignInError(Object error) {
    debugPrint('Google sign in error: $error');
    _showErrorMessage(error.toString().replaceAll('Exception: ', ''));
  }

  void _showErrorMessage(String message) {
    if (!mounted) {
      return;
    }

    final messenger = _scaffoldMessenger ?? ScaffoldMessenger.maybeOf(context);
    messenger
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return Scaffold(
      body: Column(
        children: [
          _buildNavbar(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background3.jpg'),
                  fit: BoxFit.cover,
                  //scale: 2.5,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ── LOGIN TITLE ──
                    Text(
                      'login.title'.tr(),
                      style: GoogleFonts.amaticSc(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        fontSize: 60,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(
                            offset: Offset(3, 3),
                            color: Color.fromARGB(255, 50, 136, 189),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),

                    //  Positioned(
                    //         bottom: 0,
                    //         left: 16,
                    //         child: IgnorePointer(
                    //           child: Image.asset(
                    //             'assets/images/elephant2.png',
                    //             width: 160,
                    //             height: 160,
                    //             fit: BoxFit.contain,
                    //           ),
                    //         ),
                    //       ),
                    const SizedBox(height: 20),

                    // ── WHITE CARD ──
                    Container(
                      width: isMobile ? double.infinity : 780,
                      margin: isMobile ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── FORM (mobile) ──
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'login.account_details'.tr(),
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color.fromARGB(255, 70, 80, 109),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'login.email_label'.tr(),
                                        style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555)),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _emailController,
                                        onChanged: (_) {
                                          if (_errorText != null) setState(() => _errorText = null);
                                        },
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFFBDBDBD)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFF1A73E8), width: 2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'login.password_label'.tr(),
                                        style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555)),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        onChanged: (_) {
                                          if (_errorText != null) setState(() => _errorText = null);
                                        },
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFFBDBDBD)),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFF1A73E8), width: 2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF888888)),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (v) => setState(() => _rememberMe = v!),
                                            activeColor: const Color(0xFF6DB33F),
                                            side: const BorderSide(color: Color(0xFF888888)),
                                          ),
                                          Text('login.remember_me'.tr(), style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555))),
                                          const Spacer(),
                                          GestureDetector(
                                            onTap: () => Navigator.of(
                                              context,
                                            ).pushNamed(AppRoutes.forgotPassword),
                                            child: Text('login.forgot_password'.tr(), style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF1A73E8), decoration: TextDecoration.underline)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      DecoratedBox(
                                        decoration: BoxDecoration(color: const Color.fromARGB(255, 195, 158, 222), borderRadius: BorderRadius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                                                  setState(() => _errorText = 'error.required'.tr());
                                                  return;
                                                }
                                                setState(() => _errorText = null);
                                                try {
                                                  final result = await AuthService.login(email: _emailController.text.trim(), password: _passwordController.text.trim());
                                                  if (!mounted) return;
                                                  await _openAuthenticatedSession(result);
                                                } catch (e) {
                                                  if (mounted) setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color.fromARGB(255, 220, 202, 233),
                                                foregroundColor: const Color(0xFF3A2A00),
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: Text('login.btn'.tr(), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_errorText != null) ...[
                                        const SizedBox(height: 12),
                                        Text(_errorText!, style: GoogleFonts.nunito(color: const Color(0xFFE53935), fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ],
                                  ),
                                ),
                                // ── HORIZONTAL DIVIDER ──
                                Container(height: 1, color: const Color(0xFFE0E0E0)),
                                // ── SOCIAL LOGIN (mobile) ──
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('login.or_login_with'.tr(), style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                                      const SizedBox(height: 20),
                                      google_button.buildGoogleSignInButton(onPressed: isLoading ? null : _signInWithGoogle, isLoading: isGoogleLoading),
                                      const SizedBox(height: 12),
                                      _socialButton('C', 'Clever', const Color(0xFF1A5276)),
                                      const SizedBox(height: 12),
                                      _socialButton('O', 'Office 365', const Color(0xFFD83B01)),
                                      const SizedBox(height: 12),
                                      _socialButton('CL', 'ClassLink', const Color(0xFF00AEEF)),
                                      const SizedBox(height: 12),
                                      _socialButton('QR', 'QR Code', Colors.teal),
                                      const SizedBox(height: 16),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {},
                                          child: Text('login.more_options'.tr(), style: GoogleFonts.nunito(color: const Color(0xFF1A73E8), fontSize: 13, decoration: TextDecoration.underline)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── LEFT: FORM ──
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'login.account_details'.tr(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color.fromARGB(255, 70, 80, 109),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Email
                                        Text(
                                          'login.email_label'.tr(),
                                          style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555)),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _emailController,
                                          onChanged: (_) {
                                            if (_errorText != null) setState(() => _errorText = null);
                                          },
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFFBDBDBD)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFF1A73E8), width: 2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Password
                                        Text(
                                          'login.password_label'.tr(),
                                          style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555)),
                                        ),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          onChanged: (_) {
                                            if (_errorText != null) setState(() => _errorText = null);
                                          },
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFFBDBDBD)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: _errorText != null ? const Color(0xFFE53935) : const Color(0xFF1A73E8), width: 2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF888888)),
                                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Remember me
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: (v) => setState(() => _rememberMe = v!),
                                              activeColor: const Color(0xFF6DB33F),
                                              side: const BorderSide(color: Color(0xFF888888)),
                                            ),
                                            Text('login.remember_me'.tr(), style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555))),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () => Navigator.of(
                                                context,
                                              ).pushNamed(AppRoutes.forgotPassword),
                                              child: Text('login.forgot_password'.tr(), style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF1A73E8), decoration: TextDecoration.underline)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),

                                        // LOG IN button
                                        DecoratedBox(
                                          decoration: BoxDecoration(color: const Color.fromARGB(255, 195, 158, 222), borderRadius: BorderRadius.circular(8)),
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                                                    setState(() => _errorText = 'error.required'.tr());
                                                    return;
                                                  }
                                                  setState(() => _errorText = null);
                                                  try {
                                                    final result = await AuthService.login(email: _emailController.text.trim(), password: _passwordController.text.trim());
                                                    if (!mounted) return;
                                                    await _openAuthenticatedSession(result);
                                                  } catch (e) {
                                                    if (mounted) setState(() => _errorText = e.toString().replaceFirst('Exception: ', ''));
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color.fromARGB(255, 220, 202, 233),
                                                  foregroundColor: const Color(0xFF3A2A00),
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                child: Text('login.btn'.tr(), style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Error message
                                        if (_errorText != null) ...[
                                          const SizedBox(height: 12),
                                          Text(_errorText!, style: GoogleFonts.nunito(color: const Color(0xFFE53935), fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),

                                // ── DIVIDER ──
                                Container(
                                  width: 1,
                                  height: 420,
                                  color: const Color(0xFFE0E0E0),
                                  margin: const EdgeInsets.symmetric(vertical: 24),
                                ),

                                // ── RIGHT: SOCIAL LOGIN ──
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('login.or_login_with'.tr(), style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                                        const SizedBox(height: 20),
                                        google_button.buildGoogleSignInButton(onPressed: isLoading ? null : _signInWithGoogle, isLoading: isGoogleLoading),
                                        const SizedBox(height: 12),
                                        _socialButton('C', 'Clever', const Color(0xFF1A5276)),
                                        const SizedBox(height: 12),
                                        _socialButton('O', 'Office 365', const Color(0xFFD83B01)),
                                        const SizedBox(height: 12),
                                        _socialButton('CL', 'ClassLink', const Color(0xFF00AEEF)),
                                        const SizedBox(height: 12),
                                        _socialButton('QR', 'QR Code', Colors.teal),
                                        const SizedBox(height: 16),
                                        Center(
                                          child: GestureDetector(
                                            onTap: () {},
                                            child: Text('login.more_options'.tr(), style: GoogleFonts.nunito(color: const Color(0xFF1A73E8), fontSize: 13, decoration: TextDecoration.underline)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // ── Don't have an account ──
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF333333),
                        ),
                        children: [
                          TextSpan(text: 'login.no_account'.tr()),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                'login.signup_now'.tr(),
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: const Color(0xFF1A73E8),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(String icon, String label, Color color) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDDDDD)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                icon,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color.fromARGB(255, 50, 136, 189),
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Image.asset(
                'assets/images/sprites/logocodey.png',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            Row(
              children: [
                _HoverNavButton(label: 'nav.login'.tr(), onPressed: () {}, isMobile: isMobile),
                _HoverNavButton(
                  label: 'nav.signup'.tr(),
                  onPressed: () {},
                  filled: true,
                  isMobile: isMobile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── HOVER NAV BUTTON ──
class _HoverNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool isMobile;

  const _HoverNavButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.isMobile = false,
  });

  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isYellow = widget.filled || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 10 : 20),
          decoration: BoxDecoration(
            color: isYellow
                ? const Color.fromARGB(255, 220, 202, 233)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: isYellow ? const Color(0xFF3A2A00) : Colors.white,
              fontSize: widget.isMobile ? 11 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
