import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';

class MyAccountPage extends StatefulWidget {
  final String parentName;

  const MyAccountPage({
    super.key,
    this.parentName = 'Parent',
  });

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<double>   _cloudAnim;

  bool _hideDiscover  = false;
  bool _turnOffHints  = false;
  List<Map<String, dynamic>> _linkedChildren = [];
  bool _loadingChildren = true;

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _cloudAnim = Tween<double>(begin: 0, end: 1).animate(_cloudController);
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final children = await ApiService.getLinkedChildren();
    if (mounted) setState(() { _linkedChildren = children; _loadingChildren = false; });
  }

  Future<void> _unlink(String childId) async {
    await ApiService.unlinkChild(childId);
    _loadChildren();
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
            child: Stack(
              children: [
                // ── Sky background ──
                Positioned.fill(
                  child: Container(color: const Color.fromRGBO(216, 233, 241, 1)),
                ),
                // ── Clouds ──
                _cloud(0.00,  30, 180, 65),
                _cloud(0.50,  80, 140, 48),
                _cloud(0.25,  10, 120, 42),
                _cloud(0.10, 200, 160, 55),
                _cloud(0.70, 260, 100, 35),
                _cloud(0.40, 380, 150, 52),
                _cloud(0.85, 460, 130, 44),
                _cloud(0.60, 540, 110, 38),

                // ── Scrollable content ──
                SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // Title
                      Text(
                        'account.title'.tr(),
                        style: GoogleFonts.amaticSc(
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(3, 3), color: Color(0x33000000)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // White card
                      Center(child: Container(
                        width: 750,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(36),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSection('account.user_details'.tr(), _buildUserDetails()),
                            const SizedBox(height: 32),
                            _buildSection('account.linked_children'.tr(), _buildChildDetails()),
                            const SizedBox(height: 32),
                            _buildSubscriptionsSection(),
                            const SizedBox(height: 32),
                            _buildSettingsSection(),
                            const SizedBox(height: 32),
                            _buildDeleteSection(),
                          ],
                        ),
                      )),

                      const SizedBox(height: 48),
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

  // ── SECTION WRAPPER ────────────────────────────────────────────────────────
  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3A5A7C),
            )),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFCCCCCC), thickness: 1),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  // ── USER DETAILS ──────────────────────────────────────────────────────────
  Widget _buildUserDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar('assets/images/avatar2.png'),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(widget.parentName,
                      style: GoogleFonts.nunito(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: const Color(0xFF222222))),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 14, color: Color(0xFF1A73E8)),
                  Text(' ${'account.edit'.tr()}',
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: const Color(0xFF1A73E8),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFF1A73E8))),
                ]),
                const SizedBox(height: 4),
                Text('account.parent_role'.tr(),
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: const Color(0xFF888888))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {},
          icon: Image.asset('assets/images/google_logo.png',
              width: 18, height: 18,
              errorBuilder: (_, e, s) =>
                  const Text('G', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
          label: Text('account.signed_google'.tr(),
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF444444))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFCCCCCC)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ── LINKED CHILDREN ───────────────────────────────────────────────────────
  Widget _buildChildDetails() {
    if (_loadingChildren) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_linkedChildren.isEmpty) {
      return Text('account.no_linked_children'.tr(),
          style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF888888)));
    }
    return Column(
      children: _linkedChildren.map((child) {
        final id = child['_id'] as String? ?? child['id'] as String? ?? '';
        final name = child['name'] as String? ?? 'Child';
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _avatar('assets/images/avatar.png'),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800,
                            color: const Color(0xFF222222))),
                    const SizedBox(height: 4),
                    Text('account.child_role'.tr(),
                        style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF888888))),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.lock_outline, size: 13, color: Color(0xFF888888)),
                      const SizedBox(width: 4),
                      Text('account.child_privacy_note'.tr(),
                          style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF888888))),
                    ]),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _unlink(id),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE53935)),
                  foregroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text('account.unlink_child'.tr(),
                    style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── MANAGE SUBSCRIPTIONS ─────────────────────────────────────────────────
  Widget _buildSubscriptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('account.manage_subscriptions'.tr(),
                style: GoogleFonts.nunito(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: const Color(0xFF3A5A7C))),
            Text('account.redemption_code'.tr(),
                style: GoogleFonts.nunito(
                    fontSize: 13, color: const Color(0xFF1A73E8),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF1A73E8))),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFFCCCCCC), thickness: 1),
        const SizedBox(height: 16),

        // Subscription row card
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Red left accent
                Container(
                  width: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        _subCol('account.sub_type'.tr(), 'account.sub_home_trial'.tr()),
                        _subCol('account.sub_billing'.tr(), 'account.sub_non_recurring'.tr()),
                        _subCol('account.sub_valid_from'.tr(), 'April 3 2026'),
                        _subCol('account.sub_valid_until'.tr(), 'April 17 2026'),
                        _subColStatus(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Alert banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFCDD2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555)),
              children: [
                TextSpan(text: 'account.trial_over'.tr()),
                TextSpan(
                  text: 'account.review_pricing'.tr(),
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: const Color(0xFF1A73E8),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF1A73E8)),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _subCol(String header, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header,
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: const Color(0xFF555555), letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF333333))),
        ],
      ),
    );
  }

  Widget _subColStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('account.sub_status'.tr(),
            style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: const Color(0xFF555555), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.circle, color: Color(0xFFE53935), size: 10),
          const SizedBox(width: 4),
          Text('account.sub_expired'.tr(),
              style: GoogleFonts.nunito(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: const Color(0xFFE53935))),
        ]),
      ],
    );
  }

  // ── SETTINGS ─────────────────────────────────────────────────────────────
  Widget _buildSettingsSection() {
    return _buildSection(
      'account.settings'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _hideDiscover,
                onChanged: (v) => setState(() => _hideDiscover = v ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF444444)),
                      children: [
                        TextSpan(text: 'account.hide_discover'.tr()),
                        TextSpan(text: 'account.read_more'.tr(),
                            style: GoogleFonts.nunito(
                                fontSize: 13, color: const Color(0xFF1A73E8),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF1A73E8))),
                        TextSpan(text: 'account.about_discover'.tr()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _turnOffHints,
                onChanged: (v) => setState(() => _turnOffHints = v ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('account.turn_off_hints'.tr(),
                      style: GoogleFonts.nunito(
                          fontSize: 13, color: const Color(0xFF444444))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── DELETE ACCOUNT ────────────────────────────────────────────────────────
  Widget _buildDeleteSection() {
    return _buildSection(
      'account.delete_account'.tr(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account.delete_desc'.tr(),
            style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555), height: 1.6),
          ),
          const SizedBox(height: 12),
          Text(
            'account.delete_linked_note'.tr(),
            style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555), height: 1.6),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF555555), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text('account.delete_btn'.tr(),
                style: GoogleFonts.montserrat(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333), letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  // ── AVATAR HELPER ─────────────────────────────────────────────────────────
  Widget _avatar(String path) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5A3A00), width: 2.5),
        color: const Color(0xFF6AAFD4),
      ),
      child: ClipOval(
        child: Image.asset(path, fit: BoxFit.cover,
            errorBuilder: (_, e, s) =>
                const Icon(Icons.person, color: Colors.white, size: 36)),
      ),
    );
  }

  // ── NAVBAR ────────────────────────────────────────────────────────────────
  Widget _buildNavbar(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 50, 136, 189),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                Text('nav.back'.tr(),
                    style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Text('nameofweb',
              style: TextStyle(
                  color: Color.fromARGB(255, 220, 202, 233),
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  // ── CLOUD ─────────────────────────────────────────────────────────────────
  Widget _cloud(double offset, double top, double w, double h) {
    return AnimatedBuilder(
      animation: _cloudAnim,
      builder: (context, child) {
        final sw = MediaQuery.of(context).size.width;
        final x = -200 + (((_cloudAnim.value + offset) % 1.0) * (sw + 400));
        return Positioned(left: x, top: top, child: child!);
      },
      child: SizedBox(
        width: w, height: h,
        child: CustomPaint(painter: _CloudPainter()),
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
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.62), width: w * 0.90, height: h * 0.55),
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
