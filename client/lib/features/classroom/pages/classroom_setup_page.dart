import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/features/auth/pages/student_account_page.dart';

class ClassroomSetupPage extends StatefulWidget {
  const ClassroomSetupPage({super.key});

  @override
  State<ClassroomSetupPage> createState() => _ClassroomSetupPageState();
}

class _ClassroomSetupPageState extends State<ClassroomSetupPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  String? _mode; // 'join' or 'create'
  final _codeController = TextEditingController();
  bool _showCodeError = false;
  String? _generatedCode;
  bool _codeCopied = false;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudAnimation = Tween<double>(begin: 0, end: 1).animate(_cloudController);
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _onCreateTap() {
    setState(() {
      _mode = 'create';
      _generatedCode = _generateCode();
      _codeCopied = false;
    });
  }

  void _onJoinTap() {
    setState(() {
      _mode = 'join';
      _generatedCode = null;
      _codeController.clear();
      _showCodeError = false;
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _generatedCode!));
    setState(() => _codeCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _codeCopied = false);
    });
  }

  void _proceed() {
    if (_mode == 'create') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentAccountPage(classroomCode: _generatedCode),
        ),
      );
    } else {
      final code = _codeController.text.trim().toUpperCase();
      if (code.isEmpty) {
        setState(() => _showCodeError = true);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentAccountPage(classroomCode: code),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildNavbar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color.fromRGBO(216, 233, 241, 1)),
                ),
                _animatedCloud(0.0, 30, 180, 65),
                _animatedCloud(0.5, 80, 140, 48),
                _animatedCloud(0.25, 10, 120, 42),
                _animatedCloud(0.7, 260, 100, 35),
                _animatedCloud(0.4, 380, 150, 52),
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                                Text(
                                  'Back',
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
                      const SizedBox(height: 24),
                      Text(
                        'STUDENT SIGN UP',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set Up Your Classroom',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amaticSc(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          shadows: const [
                            Shadow(offset: Offset(3, 3), color: Color(0x33000000), blurRadius: 0),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Join an existing classroom or create a new one.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── CARDS ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OptionCard(
                              label: 'Join',
                              subtitle: 'I have a code from a friend',
                              icon: Icons.login_rounded,
                              isSelected: _mode == 'join',
                              onTap: _onJoinTap,
                            ),
                            const SizedBox(width: 24),
                            _OptionCard(
                              label: 'Create',
                              subtitle: 'Start a new classroom',
                              icon: Icons.add_circle_outline_rounded,
                              isSelected: _mode == 'create',
                              onTap: _onCreateTap,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── JOIN: code input ──
                      if (_mode == 'join') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 340,
                                child: TextField(
                                  controller: _codeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF333333),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Enter classroom code',
                                    hintStyle: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: const Color(0xFF999999),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(
                                          color: Color(0xFF6DB33F), width: 2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              if (_showCodeError) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Please enter a code',
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
                        const SizedBox(height: 20),
                        _buildContinueButton(),
                      ],

                      // ── CREATE: show generated code ──
                      if (_mode == 'create' && _generatedCode != null) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Your Classroom Code',
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF555555),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _generatedCode!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF2B87C8),
                                  letterSpacing: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Share this code with your friends so they can join your classroom.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: const Color(0xFF777777),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _copyCode,
                                    icon: Icon(
                                      _codeCopied ? Icons.check : Icons.copy,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _codeCopied ? 'Copied!' : 'Copy Code',
                                      style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2B87C8),
                                      side: const BorderSide(color: Color(0xFF2B87C8)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: _onCreateTap,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(
                                      'New Code',
                                      style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildContinueButton(),
                      ],

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

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: _proceed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2B87C8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Text(
        'Continue to Sign Up',
        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _animatedCloud(double offset, double top, double width, double height) {
    return AnimatedBuilder(
      animation: _cloudAnimation,
      builder: (context, child) {
        final sw = MediaQuery.of(context).size.width;
        final x = -200 + (((_cloudAnimation.value + offset) % 1.0) * (sw + 400));
        return Positioned(left: x, top: top, child: child!);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(painter: _CloudPainter()),
      ),
    );
  }

  Widget _buildNavbar() {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('assets/images/sprites/logocodey.png',
              height: 40, fit: BoxFit.contain),
          Row(children: [
            _HoverNavButton(label: 'Log In', onPressed: () => Navigator.pop(context)),
            _HoverNavButton(label: 'Sign Up', onPressed: () {}, filled: true),
          ]),
        ],
      ),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF2B87C8)
                  : _hovered
                      ? const Color(0xFF888888)
                      : const Color(0xFFDDDDDD),
              width: widget.isSelected ? 3 : (_hovered ? 2 : 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                    widget.isSelected || _hovered ? 0.15 : 0.07),
                blurRadius: widget.isSelected || _hovered ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 40,
                color: widget.isSelected
                    ? const Color(0xFF2B87C8)
                    : const Color(0xFF999999),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: GoogleFonts.amaticSc(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: const Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.62), width: w * 0.90, height: h * 0.55),
      paint,
    );
    canvas.drawCircle(Offset(w * 0.32, h * 0.42), w * 0.18, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.30), w * 0.22, paint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.42), w * 0.18, paint);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => false;
}

class _HoverNavButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const _HoverNavButton({required this.label, required this.onPressed, this.filled = false});

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
