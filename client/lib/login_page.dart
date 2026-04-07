import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showError = false;

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
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavbar(context),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/login_bg.jpg'),
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
  'LOGIN',
  style: GoogleFonts.amaticSc(
    color: const Color.fromARGB(255, 255, 255, 255),
    fontSize: 60,
    fontWeight: FontWeight.w600,
    shadows: const [
      Shadow(
        offset: Offset(3, 3),
        color: Color.fromARGB(255,50, 136, 189),
        blurRadius: 0,
      ),
    ],
  ),
),
 Positioned(
        bottom: 0,
        left: 16,
        child: IgnorePointer(
          child: Image.asset(
            'assets/images/elephant.png',
            width: 160,
            height: 160,
            fit: BoxFit.contain,
          ),
        ),
      ),
                    const SizedBox(height: 20),

                    // ── WHITE CARD ──
                    Container(
                      width: 780,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
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
  'Account Details',
  style: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color.fromARGB(255,70, 80, 109),
  ),
),
                                  const SizedBox(height: 20),

                                  // Email
                                  Text(
                                    'Email / Username',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: const Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _emailController,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 14),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE53935)),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE53935),
                                            width: 2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Password
                                  Text(
                                    'Password',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: const Color(0xFF555555),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 14),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE53935)),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Color(0xFFE53935),
                                            width: 2),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: const Color(0xFF888888),
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Remember me
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) =>
                                            setState(() => _rememberMe = v!),
                                        activeColor: const Color(0xFF6DB33F),
                                        side: const BorderSide(
                                            color: Color(0xFF888888)),
                                      ),
                                      Text(
                                        'Remember me',
                                        style: GoogleFonts.nunito(
                                          fontSize: 13,
                                          color: const Color(0xFF555555),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            color: const Color(0xFF1A73E8),
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // LOG IN button
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255,195, 158, 222),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (_emailController
                                                    .text.isEmpty ||
                                                _passwordController
                                                    .text.isEmpty) {
                                              setState(
                                                  () => _showError = true);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(255,220, 202, 233),
                                            foregroundColor:
                                                const Color(0xFF3A2A00),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'LOG IN',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Error message
                                  if (_showError) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'This field is required',
                                      style: GoogleFonts.nunito(
                                        color: const Color(0xFFE53935),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                            margin:
                                const EdgeInsets.symmetric(vertical: 24),
                          ),

                          // ── RIGHT: SOCIAL LOGIN ──
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'or log in with:',
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _socialButton('G', 'Google',
                                      const Color(0xFFDB4437)),
                                  const SizedBox(height: 12),
                                  _socialButton('C', 'Clever',
                                      const Color(0xFF1A5276)),
                                  const SizedBox(height: 12),
                                  _socialButton('O', 'Office 365',
                                      const Color(0xFFD83B01)),
                                  const SizedBox(height: 12),
                                  _socialButton('CL', 'ClassLink',
                                      const Color(0xFF00AEEF)),
                                  const SizedBox(height: 12),
                                  _socialButton(
                                      'QR', 'QR Code', Colors.teal),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'More options',
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF1A73E8),
                                          fontSize: 13,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
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
                          const TextSpan(text: "Don't have an account? "),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Sign up now!',
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    return Container(
      color: const Color.fromARGB(255,50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'nameofweb',
              style: TextStyle(
                color: Color.fromARGB(255,220, 202, 233),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _HoverNavButton(label: 'LOG IN', onPressed: () {}),
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
            color:
                isYellow ? const Color.fromARGB(255,220, 202, 233) : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: isYellow
                  ? const Color(0xFF3A2A00)
                  : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}