import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'dashboard_page.dart';
class StudentAccountPage extends StatefulWidget {
  const StudentAccountPage({super.key});

  @override
  State<StudentAccountPage> createState() => _StudentAccountPageState();
}

class _StudentAccountPageState extends State<StudentAccountPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _showEmailError = false;
  bool _showNameError = false;
  bool _showPasswordError = false;
  bool _showRePasswordError = false;
  bool _showPasswordMismatch = false;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudAnimation =
        Tween<double>(begin: 0, end: 1).animate(_cloudController);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

String? _apiError;
bool _loading = false;

Future<void> _onSignUp() async {
  setState(() {
    _showEmailError = _emailController.text.isEmpty;
    _showNameError = _displayNameController.text.isEmpty;
    _showPasswordError = _passwordController.text.isEmpty;
    _showRePasswordError = _rePasswordController.text.isEmpty;
    _showPasswordMismatch = !_showPasswordError &&
        !_showRePasswordError &&
        _passwordController.text != _rePasswordController.text;
    _apiError = null;
  });

  if (_showEmailError ||
      _showNameError ||
      _showPasswordError ||
      _showRePasswordError ||
      _showPasswordMismatch) return;

  setState(() => _loading = true);

  try {
    final result = await AuthService.register(
      name: _displayNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: 'child',
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: result['user']['name'] ?? 'Student',
        ),
      ),
      (route) => false,
    );
 } catch (e) {
  print('REGISTER ERROR: $e');
  setState(() {
    _apiError = e.toString().replaceAll('Exception: ', '');
    _loading = false;
  });
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavbar(context),
          Expanded(
            child: Stack(
              children: [
                // ── BACKGROUND ──
                Positioned.fill(
                  child: Container(
                    color: const Color.fromRGBO(216, 233, 241, 1),
                  ),
                ),

                // ── CLOUDS ──
                _animatedCloud(0.0, 30, 180, 65),
                _animatedCloud(0.5, 80, 140, 48),
                _animatedCloud(0.25, 10, 120, 42),
                _animatedCloud(0.1, 200, 160, 55),
                _animatedCloud(0.7, 260, 100, 35),
                _animatedCloud(0.4, 380, 150, 52),
                _animatedCloud(0.85, 460, 130, 44),
                _animatedCloud(0.6, 540, 110, 38),

                // ── CONTENT ──
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // ── BACK ──
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_left,
                                    color: Colors.white, size: 20),
                                Text(
                                  'BACK',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── TITLE ──
                      Text(
                        'STUDENT SIGNUP',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amaticSc(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(
                              offset: Offset(3, 3),
                              color: Color(0x33000000),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── WHITE CARD ──
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Main white card// ADD this above the SIGN UP button Container:

                          Container(
                            width: 780,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── LEFT: FORM ──
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Enter account details',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // Email
                                        _buildLabel('Email'),
                                        _buildTextField(
                                          controller: _emailController,
                                          hasError: _showEmailError,
                                          onChanged: (_) => setState(() =>
                                              _showEmailError = false),
                                        ),
                                        if (_showEmailError)
                                          _buildError('This field is required'),
                                        const SizedBox(height: 14),

                                        // Display name
                                        _buildLabel('Display name'),
                                        _buildTextField(
                                          controller: _displayNameController,
                                          hasError: _showNameError,
                                          onChanged: (_) => setState(
                                              () => _showNameError = false),
                                        ),
                                        if (_showNameError)
                                          _buildError('This field is required'),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 6),
                                          child: Text(
                                            'To protect your privacy, do not use your full name',
                                            style: GoogleFonts.nunito(
                                              fontSize: 12,
                                              color: const Color(0xFF888888),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // Password
                                        _buildLabel('Password'),
                                        _buildTextField(
                                          controller: _passwordController,
                                          hasError: _showPasswordError,
                                          obscure: _obscurePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: const Color(0xFF888888),
                                              size: 20,
                                            ),
                                            onPressed: () => setState(() =>
                                                _obscurePassword =
                                                    !_obscurePassword),
                                          ),
                                          onChanged: (_) => setState(() {
                                            _showPasswordError = false;
                                            _showPasswordMismatch = false;
                                          }),
                                        ),
                                        if (_showPasswordError)
                                          _buildError('This field is required'),
                                        const SizedBox(height: 14),

                                        // Re-enter password
                                        _buildLabel('Re-enter password'),
                                        _buildTextField(
                                          controller: _rePasswordController,
                                          hasError: _showRePasswordError ||
                                              _showPasswordMismatch,
                                          obscure: _obscureRePassword,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureRePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: const Color(0xFF888888),
                                              size: 20,
                                            ),
                                            onPressed: () => setState(() =>
                                                _obscureRePassword =
                                                    !_obscureRePassword),
                                          ),
                                          onChanged: (_) => setState(() {
                                            _showRePasswordError = false;
                                            _showPasswordMismatch = false;
                                          }),
                                        ),
                                        if (_showRePasswordError)
                                          _buildError('This field is required'),
                                       if (_showPasswordMismatch)
  _buildError('Passwords do not match'),
if (_apiError != null)
  _buildError(_apiError!),
const SizedBox(height: 28),

                                        // SIGN UP button
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255,195, 158, 222),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: _loading ? null : _onSignUp,
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromARGB(255,220, 202, 233),
                                                  foregroundColor:
                                                      const Color(0xFF3A2A00),
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 16),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                ),
                                               child: _loading
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Color(0xFF3A2A00),
          strokeWidth: 2,
        ),
      )
    : Text(
        'SIGN UP',
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── DIVIDER ──
                                Container(
                                  width: 1,
                                  height: 520,
                                  color: const Color(0xFFE0E0E0),
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 24),
                                ),

                                // ── RIGHT: SOCIAL LOGIN ──
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Or sign up with:',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'In the future, continue to log in using the same service',
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: const Color(0xFF888888),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _socialButton(
                                                'G',
                                                'Google',
                                                const Color(0xFFDB4437),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _socialButton(
                                                'C',
                                                'Clever',
                                                const Color(0xFF1A5276),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _socialButton(
                                                'O',
                                                'Office 365',
                                                const Color(0xFFD83B01),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _socialButton(
                                                'CL',
                                                'ClassLink',
                                                const Color(0xFF00AEEF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── MONKEY peeking from left ──
                          Positioned(
                            left: -139,
                            top: -60,
                            child: Image.asset(
                              'assets/images/sign.png',
                              width: 250,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Already a member ──
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          children: [
                            const TextSpan(text: 'Already a member? '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Log in to your account',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 13,
          color: const Color(0xFF555555),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool hasError = false,
    bool obscure = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFE53935)
                : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError
                ? const Color(0xFFE53935)
                : const Color(0xFF6DB33F),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildError(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        msg,
        style: GoogleFonts.nunito(
          color: const Color(0xFFE53935),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _socialButton(String icon, String label, Color color) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFDDDDDD)),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              icon,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedCloud(
      double offset, double top, double width, double height) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        final sw = MediaQuery.of(context).size.width;
        final x =
            -200 + (((_cloudAnimation.value + offset) % 1.0) * (sw + 400));
        return Positioned(left: x, top: top, child: child!);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _CloudPainter()),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'nameofweb',
            style: TextStyle(
              color: Color.fromARGB(255, 220, 202, 233),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              _HoverNavButton(
                label: 'LOG IN',
                onPressed: () => Navigator.pop(context),
              ),
              _HoverNavButton(
                label: 'SIGN UP',
                onPressed: () {},
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── CLOUD PAINTER ──
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    canvas.drawCircle(Offset(w * 0.18, h * 0.85), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.92), w * 0.17, paint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.83, h * 0.85), w * 0.14, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.62),
        width: w * 0.90,
        height: h * 0.55,
      ),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.30), w * 0.22, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.18, h * 0.58), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.58), w * 0.14, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => false;
}

// ── HOVER NAV BUTTON ──
class _HoverNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const _HoverNavButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isYellow
                ? const Color.fromARGB(255, 220, 202, 233)
                : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: isYellow ? const Color(0xFF3A2A00) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}