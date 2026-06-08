import 'dart:async';

import 'package:client/features/auth/pages/login_page.dart';
import 'package:client/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({
    super.key,
    this.token,
    this.email,
    this.pending = false,
  });

  final String? token;
  final String? email;
  final bool pending;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _loading = false;
  bool _resending = false;
  bool _verified = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    final token = widget.token;
    if (token != null && token.isNotEmpty) {
      unawaited(_verifyEmail(token));
    } else if (widget.pending) {
      _message = widget.email == null || widget.email!.isEmpty
          ? 'Please check your email to verify your account.'
          : 'Please check ${widget.email} to verify your account.';
    } else {
      _message = 'This verification link is missing a token.';
    }
  }

  Future<void> _verifyEmail(String token) async {
    setState(() {
      _loading = true;
      _message = 'Verifying your email...';
    });

    try {
      final result = await AuthService.verifyEmail(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _verified = true;
        _message =
            '${result['success']?.toString() ?? 'Email verified successfully.'} '
            'You can close this page now and log in.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _verified = false;
        _message = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = widget.email;
    if (email == null || email.isEmpty) {
      setState(() {
        _message = 'Enter your email again from signup to resend verification.';
      });
      return;
    }

    setState(() {
      _resending = true;
      _message = 'Sending a new verification email...';
    });

    try {
      final result = await AuthService.resendVerificationEmail(email: email);

      if (!mounted) {
        return;
      }

      setState(() {
        _message = result['success']?.toString() ?? 'Verification email sent.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  void _goToLogin() {
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.pending
        ? 'Check your email'
        : _verified
        ? 'Email verified'
        : 'Email verification';
    final icon = widget.pending
        ? Icons.mark_email_unread_outlined
        : _verified
        ? Icons.verified_outlined
        : Icons.error_outline;
    final iconColor = widget.pending
        ? const Color(0xFF3288BD)
        : _verified
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(216, 233, 241, 1),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                else
                  Icon(icon, size: 52, color: iconColor),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _message ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    height: 1.45,
                    color: const Color(0xFF555555),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.pending && !_verified) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading || _resending
                          ? null
                          : _resendVerificationEmail,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _resending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'RESEND EMAIL',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!_verified)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _goToLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          220,
                          202,
                          233,
                        ),
                        foregroundColor: const Color(0xFF3A2A00),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'BACK TO LOGIN',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
