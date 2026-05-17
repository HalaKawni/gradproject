import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_dashboard_page.dart';

class ParentSignupPage extends StatefulWidget {
  const ParentSignupPage({super.key});

  @override
  State<ParentSignupPage> createState() => _ParentSignupPageState();
}

class _ParentSignupPageState extends State<ParentSignupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final _ageController = TextEditingController();
  String? _selectedExperience;

  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  bool _showUsernameError = false;
  bool _showNameError = false;
  bool _showPasswordError = false;
  bool _showRePasswordError = false;
  bool _showPasswordMismatch = false;

  final List<String> _experienceOptions = [
    'No experience',
    'A little experience',
    'Some experience',
    'A lot of experience',
  ];

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
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onDone() {
    setState(() {
      _showUsernameError = _usernameController.text.isEmpty;
      _showNameError = _displayNameController.text.isEmpty;
      _showPasswordError = _passwordController.text.isEmpty;
      _showRePasswordError = _rePasswordController.text.isEmpty;
      _showPasswordMismatch = !_showPasswordError &&
          !_showRePasswordError &&
          _passwordController.text != _rePasswordController.text;
    });

    final hasError = _usernameController.text.isEmpty ||
        _displayNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _rePasswordController.text.isEmpty ||
        _passwordController.text != _rePasswordController.text;

    if (!hasError) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ParentDashboardPage(
            childName: _displayNameController.text,
            childEmail: '${_usernameController.text}@example.com',
          ),
        ),
      );
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
                // BACKGROUND
                Positioned.fill(
                  child: Container(
                    color: const Color.fromRGBO(216, 233, 241, 1),
                  ),
                ),

                // CLOUDS
                _animatedCloud(0.0, 30, 180, 65),
                _animatedCloud(0.5, 80, 140, 48),
                _animatedCloud(0.25, 10, 120, 42),
                _animatedCloud(0.1, 200, 160, 55),
                _animatedCloud(0.7, 260, 100, 35),
                _animatedCloud(0.4, 380, 150, 52),
                _animatedCloud(0.85, 460, 130, 44),
                _animatedCloud(0.6, 540, 110, 38),

                // CONTENT
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // BACK
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

                      // TITLE
                      Text(
                        'PARENT SIGNUP',
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

                      // SUBTITLE
                      Text(
                        'Create a user for your child',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card centered, Important box floats to its right
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          const cardWidth = 520.0;
                          const importantWidth = 240.0;
                          const gap = 20.0;
                          final leftPad =
                              ((constraints.maxWidth - cardWidth) / 2 - 200)
                                  .clamp(0.0, constraints.maxWidth);
                          return Padding(
                            padding: EdgeInsets.only(left: leftPad),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // WHITE CARD
                                Container(
                                  width: cardWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Child account details',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      _buildLabel('Username (Must be unique)'),
                                      _buildTextField(
                                        controller: _usernameController,
                                        hasError: _showUsernameError,
                                        onChanged: (_) => setState(() =>
                                            _showUsernameError = false),
                                      ),
                                      if (_showUsernameError)
                                        _buildError('This field is required'),
                                      _buildHint(
                                          'To protect your privacy, do not use your full name'),
                                      const SizedBox(height: 14),

                                      _buildLabel('Display name'),
                                      _buildTextField(
                                        controller: _displayNameController,
                                        hasError: _showNameError,
                                        onChanged: (_) => setState(
                                            () => _showNameError = false),
                                      ),
                                      if (_showNameError)
                                        _buildError('This field is required'),
                                      _buildHint(
                                          "To protect your child's privacy, please do not use any personal information, such as your child's full name"),
                                      const SizedBox(height: 14),

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
                                      const SizedBox(height: 14),

                                      _buildLabel('Age (Optional)'),
                                      _buildTextField(
                                        controller: _ageController,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 14),

                                      _buildLabel('Experience (Optional)'),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFFDDDDDD)),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedExperience,
                                            isExpanded: true,
                                            hint: const SizedBox(),
                                            icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Color(0xFF888888)),
                                            items: _experienceOptions
                                                .map((opt) => DropdownMenuItem(
                                                      value: opt,
                                                      child: Text(opt,
                                                          style: GoogleFonts
                                                              .nunito(
                                                            fontSize: 13,
                                                            color: const Color(
                                                                0xFF333333),
                                                          )),
                                                    ))
                                                .toList(),
                                            onChanged: (val) => setState(() =>
                                                _selectedExperience = val),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4A017),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _onDone,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFEFBE1C),
                                                foregroundColor:
                                                    const Color(0xFF3A2A00),
                                                elevation: 0,
                                                padding: const EdgeInsets
                                                    .symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: Text(
                                                'DONE',
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

                                const SizedBox(width: gap),

                                // IMPORTANT BOX (floats on background)
                                SizedBox(
                                  width: importantWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber_rounded,
                                              color: Color(0xFFEFBE1C),
                                              size: 22,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Important',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "To protect your child's privacy, please do not use any personal information, such as your child's full name. Also, we keep this username private and never share it with others.",
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            color: Colors.white,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Already a member
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

  Widget _buildHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: const Color(0xFF888888),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    bool hasError = false,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                hasError ? const Color(0xFFE53935) : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color:
                hasError ? const Color(0xFFE53935) : const Color(0xFF6DB33F),
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

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
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
    final isActive = widget.filled || _hovered;
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
            color: isActive
                ? const Color.fromARGB(255, 220, 202, 233)
                : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: isActive ? const Color(0xFF3A2A00) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
