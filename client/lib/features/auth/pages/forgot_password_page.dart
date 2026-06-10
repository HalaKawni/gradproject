import 'package:client/features/auth/pages/login_page.dart';
import 'package:client/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _sent = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      final result = await AuthService.requestPasswordReset(
        email: _emailController.text.trim().toLowerCase(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sent = true;
        _message =
            result['success']?.toString() ??
            'If an account exists for that email, a reset link has been sent.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sent = false;
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background3.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 24 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF15324A).withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TopBadge(
                          icon: Icons.mark_email_read_outlined,
                          label: 'Secure recovery',
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Forgot your password?',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 28 : 34,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF16324F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter the email linked to your account and we will send a one-time reset link.',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            height: 1.55,
                            color: const Color(0xFF4E6479),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Email address',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF35516A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) =>
                              _isSubmitting ? null : _submit(),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Please enter your email.';
                            }
                            final emailPattern = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            );
                            if (!emailPattern.hasMatch(email)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            hintText: 'name@example.com',
                            icon: Icons.alternate_email_rounded,
                          ),
                        ),
                        if (_message != null) ...[
                          const SizedBox(height: 18),
                          _StatusBanner(message: _message!, success: _sent),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF0C95B),
                              foregroundColor: const Color(0xFF2E2500),
                              padding: const EdgeInsets.symmetric(vertical: 18),
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
                                    'Send reset email',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _backToLogin,
                            child: Text(
                              'Back to login',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2A7AB0),
                              ),
                            ),
                          ),
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

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: const Color(0xFF2A7AB0)),
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

class _TopBadge extends StatelessWidget {
  const _TopBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

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
          Icon(icon, size: 18, color: const Color(0xFF2A7AB0)),
          const SizedBox(width: 8),
          Text(
            label,
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.success});

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
