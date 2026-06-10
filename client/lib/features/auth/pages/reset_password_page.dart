import 'package:client/features/auth/pages/login_page.dart';
import 'package:client/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  bool _completed = false;
  String? _message;

  String get _token => widget.token?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    if (_token.isEmpty) {
      _message =
          'This reset link is missing a token. Please request a new email.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_token.isEmpty) {
      setState(() {
        _completed = false;
        _message = 'This reset link is invalid. Please request a new email.';
      });
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final result = await AuthService.resetPassword(
        token: _token,
        newPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _completed = true;
        _message =
            result['success']?.toString() ??
            'Password reset successfully. You can now log in.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _completed = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  bool _isStrongPassword(String value) {
    return value.length >= 8 &&
        RegExp(r'[A-Za-z]').hasMatch(value) &&
        RegExp(r'\d').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16324F), Color(0xFF2A7AB0), Color(0xFFEEF8FF)],
          ),
        ),
        child: Stack(
          children: [
            const _ResetBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 24 : 34),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _ResetBadge(),
                            const SizedBox(height: 20),
                            Text(
                              _completed
                                  ? 'Password updated'
                                  : 'Create a new password',
                              style: GoogleFonts.montserrat(
                                fontSize: isMobile ? 27 : 34,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16324F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _completed
                                  ? 'Your password has been changed. The reset link cannot be used again.'
                                  : 'Choose a strong password with at least 8 characters, including letters and numbers.',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                height: 1.55,
                                color: const Color(0xFF4E6479),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (!_completed) ...[
                              Text('New password', style: _fieldLabelStyle()),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  final password = value ?? '';
                                  if (password.isEmpty) {
                                    return 'Please enter a new password.';
                                  }
                                  if (!_isStrongPassword(password)) {
                                    return 'Use at least 8 characters with letters and numbers.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hintText: 'Choose a strong password',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  onToggle: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Confirm password',
                                style: _fieldLabelStyle(),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: _obscureConfirm,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    _isSubmitting ? null : _submit(),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Please confirm your new password.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match.';
                                  }
                                  return null;
                                },
                                decoration: _inputDecoration(
                                  hintText: 'Re-enter your password',
                                  icon: Icons.verified_user_outlined,
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF8FF),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFC8E4F8),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      color: Color(0xFF2A7AB0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'For security, reset links expire after one hour and stop working after a successful password change.',
                                        style: GoogleFonts.nunito(
                                          fontSize: 14,
                                          height: 1.45,
                                          color: const Color(0xFF35516A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (_message != null) ...[
                              const SizedBox(height: 18),
                              _ResetStatus(
                                message: _message!,
                                success: _completed,
                              ),
                            ],
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _completed
                                    ? _goToLogin
                                    : (_isSubmitting ? null : _submit),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _completed
                                      ? const Color(0xFF74C17A)
                                      : const Color(0xFFF0C95B),
                                  foregroundColor: const Color(0xFF2E2500),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Color(0xFF2E2500),
                                        ),
                                      )
                                    : Text(
                                        _completed
                                            ? 'Back to login'
                                            : 'Reset password',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),
                            if (!_completed) ...[
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: _goToLogin,
                                  child: Text(
                                    'Return to login',
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2A7AB0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _fieldLabelStyle() {
    return GoogleFonts.montserrat(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF35516A),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF2A7AB0)),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: const Color(0xFF60788E),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FBFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFC9D9E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2A7AB0), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD74E4E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD74E4E), width: 2),
      ),
    );
  }
}

class _ResetBackground extends StatelessWidget {
  const _ResetBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -60,
            top: 70,
            child: _ResetBubble(
              size: 210,
              color: const Color(0xFFFFFFFF).withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            right: -50,
            top: -30,
            child: _ResetBubble(
              size: 250,
              color: const Color(0xFFF0C95B).withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            right: 70,
            bottom: -40,
            child: _ResetBubble(
              size: 170,
              color: const Color(0xFFBCE6FF).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetBubble extends StatelessWidget {
  const _ResetBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ResetBadge extends StatelessWidget {
  const _ResetBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_reset_rounded,
            size: 18,
            color: Color(0xFF2A7AB0),
          ),
          const SizedBox(width: 8),
          Text(
            'One-time secure link',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A577A),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetStatus extends StatelessWidget {
  const _ResetStatus({required this.message, required this.success});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final background = success
        ? const Color(0xFFEAF8EE)
        : const Color(0xFFFFF1F1);
    final border = success ? const Color(0xFFABD7B6) : const Color(0xFFF1B7B7);
    final iconColor = success
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF35516A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
