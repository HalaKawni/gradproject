import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'my_account_page.dart';

// ── palette from dashboard_page.dart ──────────────────────────────────────
const _kSidebarBg  = Color.fromARGB(255, 158, 211, 220);
const _kNavbarBg   = Color.fromARGB(255, 252, 183, 199);
const _kActiveItem = Color.fromARGB(255, 68,  172, 255);
const _kYellow     = Color.fromARGB(255, 254, 253, 153);
const _kYellowShadow = Color.fromARGB(255, 195, 158, 222);
const _kPageBg     = Color(0xFFF0F0ED);
const _kBannerBg   = Color(0xFFD0EAF5);

class ParentDashboardPage extends StatefulWidget {
  final String parentName;
  final String childName;
  final String childEmail;

  const ParentDashboardPage({
    super.key,
    this.parentName = 'Parent',
    this.childName  = 'Child',
    this.childEmail = 'child@example.com',
  });

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  String _activeTab        = 'Summary';
  String _activeSidebar    = 'PARENT_DASHBOARD';
  bool   _showProfileMenu  = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── SIDEBAR (fixed width, full height) ────────────────────────
          SizedBox(
            width: 200,
            child: Container(
              color: _kSidebarBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _sideItem('PARENT_DASHBOARD', label: 'parent_dash.sidebar_dashboard'.tr()),
                  _sideItem('PARENT_RESOURCES', label: 'parent_dash.sidebar_resources'.tr()),
                  _sideItem('DISCOVER', label: 'parent_dash.sidebar_discover'.tr()),
                  // push HELP CENTER to bottom
                  const Expanded(child: SizedBox()),
                  _sideItem('HELP_CENTER', label: 'parent_dash.sidebar_help'.tr(), icon: Icons.help_outline),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── RIGHT SIDE ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Navbar
                    _buildNavbar(),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: _activeSidebar == 'PARENT_RESOURCES'
                            ? _buildParentResourcesPage()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildBanner(),
                                  _buildChildTabs(),
                                  _buildContentTabs(),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      children: [
                                        _buildRow1(),
                                        const SizedBox(height: 12),
                                        _buildRow2(),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                // Dismiss overlay
                if (_showProfileMenu)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _showProfileMenu = false),
                      child: const SizedBox.expand(),
                    ),
                  ),
                // Profile dropdown
                if (_showProfileMenu)
                  Positioned(
                    top: 52,
                    right: 16,
                    child: _buildProfileDropdown(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ITEM ────────────────────────────────────────────────────────
  Widget _sideItem(String key, {String? label, IconData? icon}) {
    final isActive = _activeSidebar == key;
    final displayLabel = label ?? key;
    return GestureDetector(
      onTap: () => setState(() => _activeSidebar = key),
      child: Container(
        width: double.infinity,
        color: isActive ? _kActiveItem : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: isActive ? Colors.white : const Color(0xFF1A3A5C), size: 15),
              const SizedBox(width: 8),
            ],
            Text(
              displayLabel,
              style: GoogleFonts.montserrat(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      isActive ? Colors.white : const Color(0xFF1A3A5C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── NAVBAR ──────────────────────────────────────────────────────────────
  Widget _buildNavbar() {
    return Container(
      color:   _kNavbarBg,
      height:  52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('nameofweb',
              style: GoogleFonts.montserrat(
                color:      const Color.fromARGB(255, 202, 97, 128),
                fontSize:   18,
                fontWeight: FontWeight.bold,
              )),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _showProfileMenu = !_showProfileMenu),
              child: Container(
                width:      36,
                height:     36,
                decoration: const BoxDecoration(color: Color(0xFF4A7DBF), shape: BoxShape.circle),
                child:      const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.menu, color: Colors.white54, size: 24),
          ]),
        ],
      ),
    );
  }

  // ── PROFILE DROPDOWN ────────────────────────────────────────────────────
  Widget _buildProfileDropdown() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5A3A00), width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/avatar2.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => const CircleAvatar(
                      backgroundColor: Color(0xFF6AAFD4),
                      child: Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ),
            // Divider
            Container(width: 1, height: 80, color: const Color(0xFFDDDDDD)),
            const SizedBox(width: 16),
            // Name + links
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.parentName.toUpperCase(),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kActiveItem,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    setState(() => _showProfileMenu = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MyAccountPage(
                          parentName: widget.parentName,
                          childName:  widget.childName,
                          childEmail: widget.childEmail,
                        ),
                      ),
                    );
                  },
                  child: Text('parent_dash.my_account'.tr(),
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: const Color(0xFF1A73E8))),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _showProfileMenu = false),
                  child: Text('parent_dash.my_profile'.tr(),
                      style: GoogleFonts.nunito(
                          fontSize: 14, color: const Color(0xFF1A73E8))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── BANNER ──────────────────────────────────────────────────────────────
  Widget _buildBanner() {
    return Container(
      color:   _kBannerBg,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left: text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('parent_dash.hello'.tr(namedArgs: {'name': widget.parentName}),
                    style: GoogleFonts.nunito(
                      fontSize:   28,
                      fontWeight: FontWeight.w800,
                      color:      const Color(0xFF1A3A5C),
                    )),
                const SizedBox(height: 6),
                Text(
                  'parent_dash.welcome_desc'.tr(),
                  style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF3A5A7C), height: 1.5),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Elephant image beside premium block
          Image.asset(
            'assets/images/elephant2.png',
            height: 120,
            fit: BoxFit.contain,
            errorBuilder: (_, e, s) => const SizedBox(width: 90),
          ),
          const SizedBox(width: 16),
          // Right: premium
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _feat('parent_dash.feat_access'.tr()),
              const SizedBox(height: 4),
              _feat('parent_dash.feat_challenges'.tr()),
              const SizedBox(height: 4),
              _feat('parent_dash.feat_game'.tr()),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: _kYellowShadow, borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavbarBg,
                      foregroundColor: const Color(0xFF3A2A00),
                      elevation:       0,
                      padding:         const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(text: 'parent_dash.go_premium'.tr(),
                            style: GoogleFonts.nunito(color: const Color(0xFF3A2A00), fontSize: 13, fontWeight: FontWeight.w800)),
                        TextSpan(text: 'parent_dash.premium_price'.tr(),
                            style: GoogleFonts.nunito(color: const Color(0xFF5A3A00), fontSize: 12)),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feat(String t) => Row(children: [
        const Icon(Icons.check_circle, color: _kNavbarBg, size: 16),
        const SizedBox(width: 6),
        Text(t, style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF1A3A5C), fontWeight: FontWeight.w600)),
      ]);

  // ── CHILD TABS ──────────────────────────────────────────────────────────
  Widget _buildChildTabs() {
    return Container(
      color:   _kBannerBg,
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Row(children: [
        Container(
          padding:    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          ),
          child: Text(widget.childName,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
        ),
        const SizedBox(width: 8),
        Container(
          padding:    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: _kActiveItem, borderRadius: BorderRadius.circular(6)),
          child: Text('parent_dash.add_child'.tr(),
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ]),
    );
  }

  // ── CONTENT TABS ────────────────────────────────────────────────────────
  Widget _buildContentTabs() {
    return Container(
      color:   Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Row(
        children: [
            ('Summary',   'parent_dash.tab_summary'.tr()),
            ('Courses',   'parent_dash.tab_courses'.tr()),
            ('Creations', 'parent_dash.tab_creations'.tr()),
          ].map((entry) {
          final tab = entry.$1;
          final tabLabel = entry.$2;
          final active = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              margin:  const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(
                  color: active ? const Color(0xFF333333) : Colors.transparent,
                  width: 2.5,
                )),
              ),
              child: Text(tabLabel,
                  style: GoogleFonts.nunito(
                    fontSize:   15,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color:      active ? const Color(0xFF333333) : const Color(0xFF888888),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── ROW 1 ───────────────────────────────────────────────────────────────
  Widget _buildRow1() {
    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 13, child: _dashboardCard()),
          const SizedBox(width: 12),
          Expanded(flex: 6, child: _statsCard()),
        ],
      ),
    );
  }

  Widget _dashboardCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('parent_dash.card_dashboard'.tr()),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: Color(0xFF6AAFD4), shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset('assets/images/avatar.png', fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Icon(Icons.person, color: Colors.white, size: 40)),
                ),
              ),
              const SizedBox(width: 20),
              // Info column
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('parent_dash.child_email'.tr(), style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555))),
                  const SizedBox(height: 2),
                  Text(widget.childEmail,
                      style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF222222))),
                  const SizedBox(height: 6),
                  Text('parent_dash.change_password'.tr(),
                      style: GoogleFonts.nunito(fontSize: 13, color: _kActiveItem, decoration: TextDecoration.underline)),
                ],
              )),
              // Login button
              Container(
                decoration: BoxDecoration(color: _kYellowShadow, borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kYellow,
                      foregroundColor: const Color(0xFF3A2A00),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text('parent_dash.login_child'.tr(),
                        style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.info, color: Color(0xFF333333), size: 18),
            const SizedBox(width: 8),
            Text('parent_dash.start_playing_hint'.tr(),
                style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF444444))),
          ]),
        ],
      ),
    );
  }

  Widget _statsCard() {
    final stats = [
      ('76',    'parent_dash.stat_solutions'.tr()),
      ('6 /96', 'parent_dash.stat_courses'.tr()),
      ('0',     'parent_dash.stat_challenges'.tr()),
      ('0',     'parent_dash.stat_games'.tr()),
    ];
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statItem(stats[0].$1, stats[0].$2)),
              Expanded(child: _statItem(stats[1].$1, stats[1].$2)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statItem(stats[2].$1, stats[2].$2)),
              Expanded(child: _statItem(stats[3].$1, stats[3].$2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.w800, color: _kActiveItem, height: 1)),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF666666), height: 1.4)),
      ],
    );
  }

  // ── ROW 2 ───────────────────────────────────────────────────────────────
  Widget _buildRow2() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _currentCourseCard()),
          const SizedBox(width: 16),
          Expanded(child: _timeSpentCard()),
          const SizedBox(width: 16),
          Expanded(child: _proficiencyCard()),
        ],
      ),
    );
  }

  // ── PARENT RESOURCES PAGE ────────────────────────────────────────────────
  Widget _buildParentResourcesPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('parent_dash.resources_title'.tr(),
              style: GoogleFonts.nunito(
                fontSize: 28, fontWeight: FontWeight.w800, color: _kActiveItem)),
          const SizedBox(height: 4),
          Text('parent_dash.all_resources'.tr(),
              style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF888888))),
          const SizedBox(height: 28),

          // ── Find Resources by Type ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDDDDD)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('parent_dash.find_resources'.tr(),
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _resourceCard(Icons.grid_view_rounded, _kActiveItem, 'parent_dash.res_all_solutions'.tr(),
                        'parent_dash.res_all_solutions_desc'.tr(), 'parent_dash.res_all_solutions_link'.tr())),
                    const SizedBox(width: 16),
                    Expanded(child: _resourceCard(Icons.code_rounded, const Color(0xFFEFBE1C), 'parent_dash.res_coding_concepts'.tr(),
                        'parent_dash.res_coding_concepts_desc'.tr(), 'parent_dash.res_coding_concepts_link'.tr())),
                    const SizedBox(width: 16),
                    Expanded(child: _resourceCard(Icons.play_circle_outline_rounded, _kActiveItem, 'parent_dash.res_videos'.tr(),
                        'parent_dash.res_videos_desc'.tr(), 'parent_dash.res_videos_link'.tr())),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── More Resources ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDDDDD)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('parent_dash.more_resources'.tr(),
                    style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _resourceCard(Icons.color_lens_outlined, _kActiveItem, 'parent_dash.res_coloring'.tr(),
                        'parent_dash.res_coloring_desc'.tr(), 'parent_dash.res_coloring_link'.tr())),
                    const SizedBox(width: 16),
                    Expanded(child: _resourceCard(Icons.help_outline_rounded, _kNavbarBg, 'parent_dash.res_help'.tr(),
                        'parent_dash.res_help_desc'.tr(), 'parent_dash.res_help_link'.tr())),
                    const SizedBox(width: 16),
                    Expanded(child: _resourceCard(Icons.inventory_2_outlined, _kNavbarBg, 'parent_dash.res_media'.tr(),
                        'parent_dash.res_media_desc'.tr(), 'parent_dash.res_media_link'.tr())),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _resourceCard(IconData icon, Color iconColor, String title, String desc, String link) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF222222))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc,
              style: GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF555555), height: 1.5)),
          const SizedBox(height: 14),
          Text(link,
              style: GoogleFonts.nunito(fontSize: 13, color: _kActiveItem, fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline, decorationColor: _kActiveItem)),
        ],
      ),
    );
  }

  Widget _currentCourseCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('parent_dash.card_current_course'.tr()),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border:       Border.all(color: const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(children: [
              Container(
                padding:    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kActiveItem,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('parent_dash.text_coding'.tr(),
                        style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    Container(
                      padding:    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                      child: Text('parent_dash.beginner'.tr(),
                          style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Image.asset('assets/images/elephant2.png',
                  width:  double.infinity,
                  height: 100,
                  fit:    BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    height: 100,
                    color:  _kActiveItem.withValues(alpha: 0.15),
                    child:  const Icon(Icons.image, color: _kActiveItem, size: 40),
                  )),
            ]),
          ),
          const SizedBox(height: 10),
          Center(child: Column(children: [
            Text('parent_dash.coding_adventure'.tr(),
                style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
            Text('parent_dash.part_fundamentals'.tr(),
                style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF888888))),
          ])),
        ],
      ),
    );
  }

  Widget _timeSpentCard() {
    const days   = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const values = [0.0,    0.0,   0.0,   0.0,   0.08,  0.0,   0.0];
    const maxH   = 80.0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('parent_dash.card_time_spent'.tr()),
          const SizedBox(height: 14),
          Text('parent_dash.past_7_days'.tr(),
              style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF555555))),
          const SizedBox(height: 12),
          // Y-axis labels
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Numeric axis
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [30, 25, 20, 15, 10, 5, 0].map((v) => SizedBox(
                  height: maxH / 6,
                  child: Text('$v',
                      style: GoogleFonts.nunito(fontSize: 9, color: const Color(0xFF888888))),
                )).toList(),
              ),
              const SizedBox(width: 4),
              // Bars
              Expanded(
                child: SizedBox(
                  height: maxH,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(days.length, (i) => Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: values[i] * maxH,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color:        _kNavbarBg,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Day labels
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Row(
              children: days.map((d) => Expanded(
                child: Text(d, textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(fontSize: 10, color: const Color(0xFF888888))),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proficiencyCard() {
    final skills = [
      ('Sequencing',            'Novice',       true),
      ('Objects',               'Novice',       true),
      ('Simple loops',          'Novice',       true),
      ('Variables',             'Not Acquired', false),
      ('Indexes/Arrays/Lists',  'Novice',       true),
      ('For loops',             'Not Acquired', false),
      ('Functions',             'Not Acquired', false),
      ('Conditional loops',     'Novice',       true),
      ('Conditionals',          'Novice',       true),
      ('Boolean operators',     'Not Acquired', false),
      ('Events',                'Not Acquired', false),
      ('Classes',               'Not Acquired', false),
      ('AI predictions',        'Not Acquired', false),
      ('Simple Data Types *',   'Not Acquired', false),
      ('Advanced Data Types *', 'Not Acquired', false),
      ('Input/Output *',        'Not Acquired', false),
      ('Sort *',                'Not Acquired', false),
      ('Modules/Import *',      'Not Acquired', false),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _cardTitle('parent_dash.card_proficiency'.tr()),
              Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(color: Color(0xFF3A3A3A), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1.5, color: _kActiveItem),
          const SizedBox(height: 8),
          // Scrollable skill list
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...skills.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(
                        child: Text(s.$1,
                            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                      ),
                      Text(s.$2,
                          style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF666666))),
                      const SizedBox(width: 8),
                      Container(
                        width: 18, height: 18,
                        decoration: BoxDecoration(
                          color:        s.$3 ? _kActiveItem : const Color(0xFFCCCCCC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('parent_dash.max_level_note'.tr(),
                        style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF888888), fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SHARED HELPERS ───────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      padding:     const EdgeInsets.all(14),
      decoration:  BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t,
            style: GoogleFonts.montserrat(
              fontSize:   13,
              fontWeight: FontWeight.w700,
              color:      _kActiveItem,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: 5),
        Container(height: 1.5, color: _kActiveItem),
      ],
    );
  }
}
