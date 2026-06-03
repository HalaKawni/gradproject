import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';

class LinkChildPage extends StatefulWidget {
  const LinkChildPage({super.key});

  @override
  State<LinkChildPage> createState() => _LinkChildPageState();
}

class _LinkChildPageState extends State<LinkChildPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;

  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _successName;

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

  Future<void> _onLink() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'error.required'.tr());
      return;
    }
    setState(() { _isLoading = true; _error = null; _successName = null; });
    try {
      final child = await ApiService.linkChild(code);
      if (!mounted) return;
      setState(() => _successName = child?['childName'] as String? ?? 'child');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                Positioned.fill(child: Container(color: const Color.fromRGBO(216, 233, 241, 1))),
                _animatedCloud(0.0, 30, 180, 65),
                _animatedCloud(0.5, 80, 140, 48),
                _animatedCloud(0.25, 10, 120, 42),
                _animatedCloud(0.1, 200, 160, 55),
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
                                Text('nav.back'.tr(),
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'parent.link_child_title'.tr(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amaticSc(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          shadows: const [Shadow(offset: Offset(3, 3), color: Color(0x33000000))],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'parent.link_child_subtitle'.tr(),
                        style: GoogleFonts.nunito(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 28),

                      LayoutBuilder(builder: (ctx, constraints) {
                        const cardWidth = 520.0;
                        const infoWidth = 240.0;
                        const gap = 20.0;
                        final leftPad = ((constraints.maxWidth - cardWidth) / 2 - 200).clamp(0.0, constraints.maxWidth);
                        return Padding(
                          padding: EdgeInsets.only(left: leftPad),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── WHITE CARD ──
                              Container(
                                width: cardWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
                                ),
                                padding: const EdgeInsets.all(32),
                                child: _successName != null
                                    ? _buildSuccess()
                                    : _buildForm(),
                              ),

                              const SizedBox(width: gap),

                              // ── HOW IT WORKS ──
                              SizedBox(
                                width: infoWidth,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.info_outline, color: Color(0xFFEFBE1C), size: 22),
                                        const SizedBox(width: 8),
                                        Text('parent.link_instructions_title'.tr(),
                                            style: GoogleFonts.montserrat(
                                                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ]),
                                      const SizedBox(height: 12),
                                      Text(
                                        'parent.link_instructions'.tr(),
                                        style: GoogleFonts.nunito(fontSize: 13, color: Colors.white, height: 1.7),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

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

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('parent.link_code_label'.tr(),
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
        const SizedBox(height: 20),

        Text('parent.link_code_label'.tr(),
            style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _codeController,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(6),
          ],
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.robotoMono(fontSize: 20, letterSpacing: 6, fontWeight: FontWeight.w700),
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            hintText: 'parent.link_code_hint'.tr(),
            hintStyle: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFFAAAAAA), letterSpacing: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _error != null ? const Color(0xFFE53935) : const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(6),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: _error != null ? const Color(0xFFE53935) : const Color(0xFF8A6FBF), width: 2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(_error!, style: GoogleFonts.nunito(color: const Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 28),

        Container(
          decoration: BoxDecoration(color: const Color.fromARGB(255, 195, 158, 222), borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _onLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 220, 202, 233),
                  foregroundColor: const Color(0xFF3A2A00),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3A2A00)))
                    : Text('parent.link_btn'.tr(),
                        style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 64),
        const SizedBox(height: 16),
        Text(
          'parent.link_success'.tr(namedArgs: {'name': _successName!}),
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF333333)),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 220, 202, 233),
              foregroundColor: const Color(0xFF3A2A00),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text('nav.back'.tr(),
                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
        ),
      ],
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
      child: SizedBox(width: width, height: height, child: CustomPaint(painter: _CloudPainter())),
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
          Image.asset('assets/images/sprites/logocodey.png', height: 40, fit: BoxFit.contain),
          Row(children: [
            _HoverNavButton(label: 'nav.login'.tr(), onPressed: () => Navigator.pop(context)),
          ]),
        ],
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85)..style = PaintingStyle.fill;
    final w = size.width; final h = size.height;
    canvas.drawCircle(Offset(w * 0.18, h * 0.85), w * 0.14, paint);
    canvas.drawCircle(Offset(w * 0.35, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.52, h * 0.92), w * 0.17, paint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.90), w * 0.16, paint);
    canvas.drawCircle(Offset(w * 0.83, h * 0.85), w * 0.14, paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.62), width: w * 0.90, height: h * 0.55), paint);
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
  const _HoverNavButton({required this.label, required this.onPressed});
  @override
  State<_HoverNavButton> createState() => _HoverNavButtonState();
}

class _HoverNavButtonState extends State<_HoverNavButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final isActive = _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: isActive ? const Color.fromARGB(255, 220, 202, 233) : Colors.transparent),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: GoogleFonts.montserrat(
                  color: isActive ? const Color(0xFF3A2A00) : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
