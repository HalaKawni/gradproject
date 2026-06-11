import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/services/api_service.dart';
import 'package:client/shared/widgets/help_button.dart';
import 'package:client/shared/widgets/hint_card.dart';
import 'package:client/core/services/onboarding_service.dart';

part 'classroom_page_widgets.dart';

// ── palette ──────────────────────────────────────────────────────────────────
const _kViolet     = Color(0xFF6C5CE7);
const _kVioletD    = Color(0xFF5A48D0);
const _kMint       = Color(0xFF10C8A8);
const _kCoral      = Color(0xFFFF6B6B);
const _kGold       = Color(0xFFFFB938);
const _kInk        = Color(0xFF2C2657);
const _kBg         = Color(0xFFF2F0FB);
const _kMuted      = Color(0xFF8E8AAE);
const _kLine       = Color(0xFFECE9F6);
const _kVioletSoft = Color(0xFFEDEAFD);
const _kMintSoft   = Color(0xFFDCF7F0);
const _kCoralSoft  = Color(0xFFFFE6E4);
const _kGoldSoft   = Color(0xFFFFF1D6);
const _kSkySoft    = Color(0xFFE0F1FE);
const _kBreakpoint = 860.0;

const _gameIds = ['codemonkey-jr', 'digital-literacy', 'data-course', 'ai-course'];
const _gameLabels = {
  'codemonkey-jr':    'CodeMonkey Jr',
  'digital-literacy': 'Digital Literacy',
  'data-course':      'Data Course',
  'ai-course':        'AI Course',
};

// ── page ──────────────────────────────────────────────────────────────────────
class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key});
  @override State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String? _classroomCode;
  bool    _loading = true;
  String? _error;

  List<dynamic>         _members     = [];
  List<dynamic>         _leaderboard = [];
  List<dynamic>         _activity    = [];
  List<dynamic>         _challenges  = [];
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _weeklyChallenge;
  Map<String, dynamic>  _reactions   = {};

  bool _membersLoading     = false;
  bool _leaderboardLoading = false;
  bool _activityLoading    = false;
  bool _overviewLoading    = false;
  String _selectedGame     = _gameIds[0];
  int    _desktopSection   = 0;
  int    _hintIndex        = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this)
      ..addListener(() { if (!_tab.indexIsChanging) _onTab(_tab.index); });
    _init();
    _initHintIndex();
  }

  Future<void> _initHintIndex() async {
    final h0 = await OnboardingService.isHintDismissed('classroom_join');
    final h1 = await OnboardingService.isHintDismissed('classroom_tabs');
    if (!mounted) return;
    setState(() => _hintIndex = h0 ? (h1 ? 2 : 1) : 0);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _init() async {
    final code = await ApiService.getMyClassroomCode();
    if (!mounted) return;
    if (code == null) { setState(() { _loading = false; _error = 'none'; }); return; }
    setState(() { _classroomCode = code; _loading = false; });
    _loadOverview();
  }

  void _onTab(int i) {
    if (i == 0 && _stats == null)       _loadOverview();
    if (i == 1 && _members.isEmpty)     _loadMembers();
    if (i == 2 && _leaderboard.isEmpty) _loadLeaderboard();
    if (i == 3 && _activity.isEmpty)    _loadActivity();
  }

  void _onDesktopSection(int i) {
    setState(() => _desktopSection = i);
    if (i == 0 && _stats == null)       _loadOverview();
    if (i == 1 && _members.isEmpty)     _loadMembers();
    if (i == 2 && _leaderboard.isEmpty) _loadLeaderboard();
    if (i == 3 && _activity.isEmpty)    _loadActivity();
  }

  // ── loaders ─────────────────────────────────────────────────────────────

  Future<void> _loadOverview() async {
    setState(() => _overviewLoading = true);
    final results = await Future.wait([
      ApiService.getClassroomStats(),
      ApiService.getWeeklyChallenge(),
      ApiService.getChallenges(),
      ApiService.getClassroomMembers(),
    ]);
    if (!mounted) return;
    final md = results[3] as Map<String, dynamic>?;
    setState(() {
      _stats           = results[0] as Map<String, dynamic>?;
      _weeklyChallenge = results[1] as Map<String, dynamic>?;
      _challenges      = results[2] as List<dynamic>;
      _members         = (md?['members'] as List<dynamic>?) ?? _members;
      _overviewLoading = false;
    });
  }

  Future<void> _loadMembers() async {
    setState(() => _membersLoading = true);
    final data = await ApiService.getClassroomMembers();
    if (!mounted) return;
    setState(() { _members = (data?['members'] as List<dynamic>?) ?? []; _membersLoading = false; });
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _leaderboardLoading = true);
    final data = await ApiService.getClassroomLeaderboard(_selectedGame);
    if (!mounted) return;
    setState(() { _leaderboard = (data?['leaderboard'] as List<dynamic>?) ?? []; _leaderboardLoading = false; });
  }

  Future<void> _loadActivity() async {
    setState(() => _activityLoading = true);
    final data = await ApiService.getClassroomActivity();
    if (!mounted) return;
    final acts = (data?['activity'] as List<dynamic>?) ?? [];
    final keys = acts.map((a) => a['activityKey'] as String).toList();
    final reactions = keys.isNotEmpty ? await ApiService.getReactions(keys) : <String, dynamic>{};
    if (!mounted) return;
    setState(() { _activity = acts; _reactions = reactions; _activityLoading = false; });
  }

  // ── root build ───────────────────────────────────────────────────────────

  static const _classroomTips = [
    HelpTip(
      icon: Icons.key_rounded,
      color: Color(0xFF6C5CE7),
      title: 'Join with Your Classroom Code',
      description:
          "Ask your teacher for the classroom code, then enter it here to instantly join and access all assigned lessons.",
    ),
    HelpTip(
      icon: Icons.assignment_rounded,
      color: Color(0xFF10C8A8),
      title: 'View Assigned Lessons',
      description:
          'Once you join a classroom, your teacher can assign specific lessons and games for you to complete.',
    ),
    HelpTip(
      icon: Icons.games_rounded,
      color: Color(0xFFFF6B6B),
      title: 'Play Assigned Games',
      description:
          'Your classroom gives you access to Digital Literacy, Data Course, AI Course, and CodeMonkey Jr games assigned by your teacher.',
    ),
    HelpTip(
      icon: Icons.leaderboard_rounded,
      color: Color(0xFFFFB938),
      title: 'Track Your Progress',
      description:
          'Complete lessons and games to earn points. Your teacher can see your progress and give you feedback.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: Column(
      children: [
        if (_hintIndex == 0)
          HintCard(
            key: ValueKey('classroom_join_$_hintIndex'),
            hintKey: 'classroom_join',
            icon: Icons.key_rounded,
            color: Color(0xFF6C5CE7),
            title: 'How to join your classroom',
            message: "Ask a friend for a classroom code, then enter it here to join and access shared lessons.",
            onDismissed: () => setState(() => _hintIndex = 1),
          ),
        if (_hintIndex == 1)
          HintCard(
            key: ValueKey('classroom_tabs_$_hintIndex'),
            hintKey: 'classroom_tabs',
            icon: Icons.tab_rounded,
            color: Color(0xFF10C8A8),
            title: 'Explore the classroom tabs',
            message: 'Switch between Overview, Members, Leaderboard, and Activity to see all classroom info.',
            onDismissed: () => setState(() => _hintIndex = 2),
          ),
        Expanded(
          child: LayoutBuilder(builder: (_, c) =>
              c.maxWidth >= _kBreakpoint ? _buildDesktop() : _buildMobile()),
        ),
      ],
    ),
    floatingActionButton: const HelpButton(
      pageTitle: 'Classroom',
      tips: _classroomTips,
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // DESKTOP
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDesktop() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Row(children: [
      _DesktopSidebar(
        onBack: () => Navigator.of(context).maybePop(),
        classroomCode: _classroomCode,
        selectedIndex: _desktopSection,
        onSelect: _onDesktopSection,
        onShare: _classroomCode != null ? _showShareCodeDialog : _showCreateDialog,
      ),
      Expanded(child: _error == 'none'
          ? _buildNotInClassroomDesktop()
          : _buildDesktopContent()),
    ]);
  }

  Widget _buildDesktopContent() {
    const titles = ['Overview', 'Members', 'Ranks', 'Activity'];
    const subs   = ['Your classroom at a glance', 'Everyone in the class',
                    'Who is topping each course',  'Latest wins from the class'];
    final body = [
      _buildOverviewDesktop(),
      _buildMembersDesktop(),
      _buildLeaderboardDesktop(),
      _buildActivityDesktop(),
    ][_desktopSection];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(36, 32, 36, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_desktopSection],
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            Text(
              subs[_desktopSection],
              style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted),
            ),
          ],
        ),
      ),
      Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(36, 20, 36, 48), child: body)),
    ]);
  }

  Widget _buildOverviewDesktop() {
    if (_overviewLoading) return const Center(child: CircularProgressIndicator());
    final s = _stats;
    return Column(children: [
      Row(children: [
        _StatCard(emoji: '⭐', value: '${s?['totalStars'] ?? 0}',   label: 'Total Stars', color: _kGold,   bg: _kGoldSoft),
        const SizedBox(width: 16),
        _StatCard(emoji: '🧩', value: '${s?['totalLevels'] ?? 0}',  label: 'Levels Done', color: _kVioletD, bg: _kVioletSoft),
        const SizedBox(width: 16),
        _StatCard(emoji: '👥', value: '${s?['memberCount'] ?? 0}',  label: 'Members',     color: _kMint,   bg: _kMintSoft),
        const SizedBox(width: 16),
        _StatCard(emoji: '📈', value: '${s?['weeklyLevels'] ?? 0}', label: 'This Week',   color: _kCoral,  bg: _kCoralSoft),
      ]),
      const SizedBox(height: 20),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 7, child: Column(children: [
          _buildWeeklyChallengeCard(),
          const SizedBox(height: 18),
          _buildChallengesCard(),
        ])),
        const SizedBox(width: 18),
        Expanded(flex: 5, child: Column(children: [
          _buildStreakWallCard(),
          if (s?['mostActiveName'] != null) ...[
            const SizedBox(height: 18),
            _BCard(child: _activeRow(s!['mostActiveName'])),
          ],
        ])),
      ]),
    ]);
  }

  Widget _buildMembersDesktop() {
    if (_membersLoading) return const Center(child: CircularProgressIndicator());
    if (_members.isEmpty) return _empty('No classmates yet', Icons.people_outline);
    final badges = _computeBadges(_members);
    return Wrap(spacing: 16, runSpacing: 16,
      children: _members.map((m) => SizedBox(width: 340,
        child: _MemberCard(
          member: m,
          badges: badges[m['id']?.toString() ?? ''] ?? [],
          onChallenge: () => _showChallengeDialog(m),
        ))).toList(),
    );
  }

  Widget _buildLeaderboardDesktop() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildGameSelector(),
    const SizedBox(height: 20),
    if (_leaderboardLoading)
      const Center(child: CircularProgressIndicator())
    else if (_leaderboard.isEmpty)
      _empty('No scores yet for this course', Icons.emoji_events_outlined)
    else
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: _buildPodiumCard()),
        const SizedBox(width: 20),
        Expanded(child: _buildLeaderboardRows()),
      ]),
  ]);

  Widget _buildActivityDesktop() {
    if (_activityLoading) return const Center(child: CircularProgressIndicator());
    if (_activity.isEmpty) return _empty('No activity yet — be the first!', Icons.bolt_outlined);
    return Wrap(spacing: 16, runSpacing: 16,
      children: List.generate(_activity.length, (i) {
        final e = _activity[i]; final key = e['activityKey'] as String? ?? '';
        return SizedBox(width: 340, child: _ActivityCard(
          event: e,
          reactions: (_reactions[key] as List<dynamic>?) ?? [],
          onReact: (emoji) async { await ApiService.toggleReaction(key, emoji); _loadActivity(); },
        ));
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOBILE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMobile() => Column(children: [
    _buildMobileHeader(),
    if (_loading)
      const Expanded(child: Center(child: CircularProgressIndicator()))
    else if (_error == 'none')
      _buildNotInClassroomMobile()
    else
      Expanded(child: Column(children: [
        _buildMobileTabBar(),
        Expanded(child: TabBarView(controller: _tab, children: [
          _buildOverviewMobile(),
          _buildMembersTab(),
          _buildLeaderboardTab(),
          _buildActivityTab(),
        ])),
      ])),
  ]);

  Widget _buildMobileHeader() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF7B68FF), _kViolet, _kVioletD],
    )),
    padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('My Classroom',
            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        if (_classroomCode != null) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔑 ', style: TextStyle(fontSize: 12)),
              Text('Code: ', style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 12)),
              Text(_classroomCode!, style: GoogleFonts.fredoka(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2)),
            ]),
          ),
        ],
      ])),
      const _CodeyMascot(size: 48),
    ]),
  );

  Widget _buildBackButton() => GestureDetector(
    onTap: () => Navigator.of(context).maybePop(),
    child: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kLine),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.arrow_back, color: _kInk, size: 20),
    ),
  );

  Widget _buildMobileTabBar() => Container(
    color: const Color(0xFF5E4ECC),
    child: TabBar(
      controller: _tab,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 12),
      tabs: const [
        Tab(icon: Icon(Icons.bar_chart_rounded, size: 19),    text: 'Overview'),
        Tab(icon: Icon(Icons.people_rounded, size: 19),       text: 'Members'),
        Tab(icon: Icon(Icons.emoji_events_rounded, size: 19), text: 'Ranks'),
        Tab(icon: Icon(Icons.bolt_rounded, size: 19),         text: 'Activity'),
      ],
    ),
  );

  Widget _buildOverviewMobile() {
    if (_overviewLoading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildStatsCard(),
        const SizedBox(height: 14),
        _buildWeeklyChallengeCard(),
        const SizedBox(height: 14),
        _buildStreakWallCard(),
        const SizedBox(height: 14),
        _buildChallengesCard(),
      ]),
    );
  }

  Widget _buildMembersTab() {
    if (_membersLoading) return const Center(child: CircularProgressIndicator());
    if (_members.isEmpty) return _empty('No classmates yet', Icons.people_outline);
    final badges = _computeBadges(_members);
    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (_, i) => _MemberCard(
          member: _members[i],
          badges: badges[_members[i]['id']?.toString() ?? ''] ?? [],
          onChallenge: () => _showChallengeDialog(_members[i]),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() => Column(children: [
    _buildGameSelector(),
    if (_leaderboardLoading)
      const Expanded(child: Center(child: CircularProgressIndicator()))
    else if (_leaderboard.isEmpty)
      Expanded(child: _empty('No scores yet for this course', Icons.emoji_events_outlined))
    else
      Expanded(child: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _buildPodiumCard(),
          const SizedBox(height: 12),
          _buildLeaderboardRows(),
        ]),
      )),
  ]);

  Widget _buildActivityTab() {
    if (_activityLoading) return const Center(child: CircularProgressIndicator());
    if (_activity.isEmpty) return _empty('No activity yet — be the first!', Icons.bolt_outlined);
    return RefreshIndicator(
      onRefresh: _loadActivity,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activity.length,
        itemBuilder: (_, i) {
          final e = _activity[i]; final key = e['activityKey'] as String? ?? '';
          return _ActivityCard(
            event: e,
            reactions: (_reactions[key] as List<dynamic>?) ?? [],
            onReact: (emoji) async { await ApiService.toggleReaction(key, emoji); _loadActivity(); },
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED SECTION CARDS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsCard() {
    final s = _stats;
    return _BCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.bar_chart_rounded, 'Classroom Stats'),
      const SizedBox(height: 14),
      Row(children: [
        _StatChip(emoji: '⭐', value: '${s?['totalStars'] ?? 0}',   label: 'Stars',   color: _kGold,   bg: _kGoldSoft),
        _StatChip(emoji: '🧩', value: '${s?['totalLevels'] ?? 0}',  label: 'Levels',  color: _kVioletD, bg: _kVioletSoft),
        _StatChip(emoji: '👥', value: '${s?['memberCount'] ?? 0}',  label: 'Members', color: _kMint,   bg: _kMintSoft),
        _StatChip(emoji: '📈', value: '${s?['weeklyLevels'] ?? 0}', label: 'Week',    color: _kCoral,  bg: _kCoralSoft),
      ]),
      if (s?['mostActiveName'] != null) ...[
        const SizedBox(height: 12),
        _activeRow(s!['mostActiveName']),
      ],
    ]));
  }

  Widget _activeRow(String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFFFF7EC),
        border: Border.all(color: const Color(0xFFFFE6BE)),
        borderRadius: BorderRadius.circular(13)),
    child: Row(children: [
      const Text('🔥 ', style: TextStyle(fontSize: 16)),
      Text('Most active: ', style: GoogleFonts.fredoka(fontSize: 13.5, color: _kMuted)),
      Text(name, style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.w600, color: _kInk)),
    ]),
  );

  Widget _buildWeeklyChallengeCard() {
    final wc = _weeklyChallenge;
    return _BCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _sectionTitle(Icons.flag_rounded, 'Weekly Challenge'),
        const Spacer(),
        _linkBtn(wc == null ? 'Set Challenge' : 'Change', _showSetChallengeDialog),
      ]),
      const SizedBox(height: 10),
      if (wc == null)
        Text('No challenge set yet. Set one for your classroom!',
            style: GoogleFonts.fredoka(fontSize: 13.5, color: _kMuted))
      else ...[
        Text(wc['title'], style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600, color: _kInk)),
        const SizedBox(height: 3),
        Text('by ${wc['creatorName']}', style: GoogleFonts.fredoka(fontSize: 12.5, color: _kMuted)),
        const SizedBox(height: 12),
        _AnimatedProgressBar(
            current: (wc['completedLevels'] as num).toInt(),
            target: (wc['targetLevels'] as num).toInt(),
            done: wc['done'] == true),
        if (wc['done'] == true) ...[
          const SizedBox(height: 10),
          Row(children: [
            const Text('🎉', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text('Challenge complete! Amazing teamwork!',
                style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.w600, color: _kMint)),
          ]),
        ],
      ],
    ]));
  }

  Widget _buildStreakWallCard() {
    if (_members.isEmpty) return const SizedBox.shrink();
    final sorted = [..._members]
      ..sort((a, b) => ((b['streak'] as int?) ?? 0).compareTo((a['streak'] as int?) ?? 0));
    return _BCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.local_fire_department_rounded, 'Streak Wall'),
      const SizedBox(height: 12),
      ...sorted.map((m) => _StreakRow(member: m)),
    ]));
  }

  Widget _buildChallengesCard() {
    if (_challenges.isEmpty) return const SizedBox.shrink();
    return _BCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle(Icons.sports_kabaddi_rounded, 'Head-to-Head'),
      const SizedBox(height: 10),
      ..._challenges.take(5).map((c) => _ChallengeRow(challenge: c)),
    ]));
  }

  Widget _buildGameSelector() => Container(
    color: _kSkySoft,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Text('Course:', style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 13.5,
          color: const Color(0xFF1C7DC0))),
      const SizedBox(width: 12),
      Expanded(child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGame, isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          style: GoogleFonts.fredoka(fontSize: 13.5, fontWeight: FontWeight.w600, color: _kInk),
          items: _gameIds.map((id) =>
              DropdownMenuItem(value: id, child: Text(_gameLabels[id] ?? id))).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() { _selectedGame = v; _leaderboard = []; });
            _loadLeaderboard();
          },
        ),
      )),
    ]),
  );

  Widget _buildPodiumCard() {
    if (_leaderboard.length < 3) return const SizedBox.shrink();
    final top = _leaderboard.take(3).toList();
    return _BCard(child: Column(children: [
      _sectionTitle(Icons.emoji_events_rounded, 'Podium'),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _PodiumColumn(entry: top[1], rank: 2, standHeight: 80,
            color: const Color(0xFFAEB7C9)),
        const SizedBox(width: 10),
        _PodiumColumn(entry: top[0], rank: 1, standHeight: 100,
            color: const Color(0xFFFFB938)),
        const SizedBox(width: 10),
        _PodiumColumn(entry: top[2], rank: 3, standHeight: 64,
            color: const Color(0xFFCD7F32)),
      ]),
    ]));
  }

  Widget _buildLeaderboardRows() {
    const medals = ['🥇', '🥈', '🥉'];
    return Column(children: List.generate(_leaderboard.length, (i) {
      final e    = _leaderboard[i];
      final rank = e['rank'] as int? ?? (i + 1);
      return _BCard(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          SizedBox(width: 36, child: rank <= 3
              ? Text(medals[rank - 1], style: const TextStyle(fontSize: 22))
              : Text('$rank', style: GoogleFonts.fredoka(fontSize: 14,
                  fontWeight: FontWeight.w700, color: _kMuted))),
          _ColoredAvatar(name: e['name'] as String? ?? '?', size: 38),
          const SizedBox(width: 12),
          Expanded(child: Text(e['name'] as String? ?? 'Unknown',
              style: GoogleFonts.fredoka(fontSize: 14.5, fontWeight: FontWeight.w600))),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${e['totalScore']} pts',
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w700, color: _kVioletD)),
            Text('⭐ ${e['totalStars']}  Lv.${e['highestLevel']}',
                style: GoogleFonts.fredoka(fontSize: 11.5, color: _kMuted)),
          ]),
        ]),
      );
    }));
  }

  // ── not in classroom ─────────────────────────────────────────────────────

  Widget _buildNotInClassroomMobile() => Expanded(child: Center(child:
    Column(mainAxisSize: MainAxisSize.min, children: [
      const _CodeyMascot(size: 90),
      const SizedBox(height: 22),
      Text("You're not in a classroom yet",
          style: GoogleFonts.fredoka(fontSize: 19, fontWeight: FontWeight.w700, color: _kInk),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text("Join a friend's classroom or create your own.",
          style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted), textAlign: TextAlign.center),
      const SizedBox(height: 28),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _bigBtn('Join', Icons.login_rounded, _kViolet, _showJoinDialog),
        const SizedBox(width: 14),
        _bigBtn('Create', Icons.add_circle_outline_rounded, _kMint, _showCreateDialog),
      ]),
    ])));

  Widget _buildNotInClassroomDesktop() => Center(child:
    Column(mainAxisSize: MainAxisSize.min, children: [
      const _CodeyMascot(size: 100),
      const SizedBox(height: 24),
      Text("You're not in a classroom yet",
          style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700, color: _kInk),
          textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text("Join a friend's classroom or create your own.",
          style: GoogleFonts.fredoka(fontSize: 15, color: _kMuted), textAlign: TextAlign.center),
      const SizedBox(height: 32),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _bigBtn('Join', Icons.login_rounded, _kViolet, _showJoinDialog),
        const SizedBox(width: 14),
        _bigBtn('Create', Icons.add_circle_outline_rounded, _kMint, _showCreateDialog),
      ]),
    ]));

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  void _showJoinDialog() {
    final ctrl = TextEditingController();
    bool joining = false; String? err;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => _CodeyDialog(title: 'Join a Classroom', child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter the code your friend shared:',
              style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted)),
          const SizedBox(height: 12),
          TextField(controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 6),
              decoration: _inputDec('ABC123')),
          if (err != null) ...[const SizedBox(height: 8),
            Text(err!, style: GoogleFonts.fredoka(fontSize: 13, color: _kCoral))],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _dialogBtn('Cancel', false, () => Navigator.pop(ctx))),
            const SizedBox(width: 10),
            Expanded(child: _dialogBtn('Join', true, joining ? null : () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.isEmpty) { set(() => err = 'Please enter a code'); return; }
              set(() { joining = true; err = null; });
              final ok = await ApiService.joinClassroom(code);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.pop(ctx);
                setState(() { _classroomCode = code; _error = null; });
                _loadOverview();
              } else {
                set(() { joining = false; err = 'Invalid code. Check with your friend.'; });
              }
            })),
          ]),
        ]),
      ),
    ));
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  void _showCreateDialog() {
    final code = _generateCode();
    bool copied = false, joining = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => _CodeyDialog(title: 'Create a Classroom', child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Share this code so friends can join.',
              style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted)),
          const SizedBox(height: 14),
          Text(code, style: GoogleFonts.fredoka(fontSize: 42, fontWeight: FontWeight.w700,
              color: _kViolet, letterSpacing: 7)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () { Clipboard.setData(ClipboardData(text: code)); set(() => copied = true); },
            icon: Icon(copied ? Icons.check_rounded : Icons.copy_rounded, size: 16),
            label: Text(copied ? 'Copied!' : 'Copy Code',
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(foregroundColor: _kViolet,
                side: const BorderSide(color: _kViolet),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _dialogBtn('Cancel', false, () => Navigator.pop(ctx))),
            const SizedBox(width: 10),
            Expanded(child: _dialogBtn('Start Classroom', true, joining ? null : () async {
              set(() => joining = true);
              final ok = await ApiService.joinClassroom(code);
              if (!ctx.mounted) return;
              if (ok) {
                Navigator.pop(ctx);
                setState(() { _classroomCode = code; _error = null; });
                _loadOverview();
              } else { set(() => joining = false); }
            })),
          ]),
        ]),
      ),
    ));
  }

  void _showShareCodeDialog() {
    if (_classroomCode == null) return;
    bool copied = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => _CodeyDialog(title: 'Share Classroom Code', child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Share this code with friends so they can join.',
              style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted)),
          const SizedBox(height: 14),
          Text(_classroomCode!, style: GoogleFonts.fredoka(fontSize: 42, fontWeight: FontWeight.w700,
              color: _kViolet, letterSpacing: 7)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _classroomCode!));
              set(() => copied = true);
            },
            icon: Icon(copied ? Icons.check_rounded : Icons.copy_rounded, size: 16),
            label: Text(copied ? 'Copied!' : 'Copy Code',
                style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(foregroundColor: _kViolet,
                side: const BorderSide(color: _kViolet),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(height: 20),
          _dialogBtn('Done', true, () => Navigator.pop(ctx)),
        ]),
      ),
    ));
  }

  void _showSetChallengeDialog() {
    final titleCtrl = TextEditingController();
    String? selectedGame; int target = 10; bool saving = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => _CodeyDialog(title: 'Set Weekly Challenge', child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Title', style: GoogleFonts.fredoka(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 7),
          TextField(controller: titleCtrl, decoration: _inputDec('Complete 10 levels together!')),
          const SizedBox(height: 14),
          Text('Course (optional)', style: GoogleFonts.fredoka(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: selectedGame,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
            hint: Text('All courses', style: GoogleFonts.fredoka(fontSize: 13)),
            items: [
              const DropdownMenuItem(value: null, child: Text('All courses')),
              ..._gameIds.map((id) => DropdownMenuItem(value: id, child: Text(_gameLabels[id] ?? id))),
            ],
            onChanged: (v) => set(() => selectedGame = v),
          ),
          const SizedBox(height: 14),
          Text('Target levels (class total)', style: GoogleFonts.fredoka(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _stepBtn(Icons.remove_rounded, () { if (target > 1) set(() => target--); }),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text('$target', style: GoogleFonts.fredoka(fontSize: 32, fontWeight: FontWeight.w700))),
            _stepBtn(Icons.add_rounded, () => set(() => target++)),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _dialogBtn('Cancel', false, () => Navigator.pop(ctx))),
            const SizedBox(width: 10),
            Expanded(child: _dialogBtn('Set Challenge', true, saving ? null : () async {
              if (titleCtrl.text.trim().isEmpty) return;
              set(() => saving = true);
              final ok = await ApiService.setWeeklyChallenge(
                  title: titleCtrl.text.trim(), targetLevels: target, gameId: selectedGame);
              if (!ctx.mounted) return;
              if (ok) { Navigator.pop(ctx); _loadOverview(); }
              else { set(() => saving = false); }
            })),
          ]),
        ]),
      ),
    ));
  }

  void _showChallengeDialog(dynamic member) {
    String? selectedGame; bool sending = false;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => _CodeyDialog(title: 'Challenge ${member['name']}', child:
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pick a course — your best score becomes the target.',
              style: GoogleFonts.fredoka(fontSize: 14, color: _kMuted)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: selectedGame,
            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
            hint: Text('Pick a course', style: GoogleFonts.fredoka(fontSize: 13)),
            items: _gameIds.map((id) => DropdownMenuItem(value: id,
                child: Text(_gameLabels[id] ?? id))).toList(),
            onChanged: (v) => set(() => selectedGame = v),
          ),
          const SizedBox(height: 6),
          Text('Your current best will be used as the target to beat.',
              style: GoogleFonts.fredoka(fontSize: 12, color: _kMuted)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _dialogBtn('Cancel', false, () => Navigator.pop(ctx))),
            const SizedBox(width: 10),
            Expanded(child: _dialogBtn('Send Challenge 🎯', true,
              (sending || selectedGame == null) ? null : () async {
                set(() => sending = true);
                final messenger = ScaffoldMessenger.of(context);
                final myStats = await ApiService.getMyStats();
                final myGameStats = (myStats?['games'] as List<dynamic>? ?? [])
                    .firstWhere((g) => g['gameId'] == selectedGame, orElse: () => null);
                final myScore = myGameStats?['totalScore'] as int? ?? 0;
                final ok = await ApiService.sendChallenge(
                  challengedId: member['id'].toString(),
                  challengedName: member['name'],
                  gameId: selectedGame!,
                  challengerScore: myScore,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(
                  content: Text(ok ? 'Challenge sent to ${member['name']}! 🎯'
                      : 'Could not send challenge. Try again.',
                      style: GoogleFonts.fredoka()),
                  backgroundColor: ok ? _kMint : _kCoral,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
                if (ok) _loadOverview();
              },
            )),
          ]),
        ]),
      ),
    ));
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Widget _sectionTitle(IconData icon, String title) => Row(children: [
    Icon(icon, color: _kViolet, size: 21),
    const SizedBox(width: 9),
    Text(title, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600, color: _kInk)),
  ]);

  Widget _linkBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _kVioletSoft, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.fredoka(fontSize: 12.5, fontWeight: FontWeight.w600, color: _kVioletD)),
    ),
  );

  Widget _bigBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      ElevatedButton.icon(
        onPressed: onTap, icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 15)),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4),
      );

  Widget _empty(String msg, IconData icon) => Center(child:
    Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 52, color: const Color(0xFFBBBBBB)),
      const SizedBox(height: 14),
      Text(msg, style: GoogleFonts.fredoka(fontSize: 15, color: _kMuted)),
    ]));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kViolet, width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );

  Widget _dialogBtn(String label, bool primary, VoidCallback? onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: primary ? _kViolet : const Color(0xFFF2F0FA),
      foregroundColor: primary ? Colors.white : const Color(0xFF6a668c),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 13),
      elevation: primary ? 2 : 0,
    ),
    child: (onTap == null && primary)
        ? const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 14)),
  );

  Widget _stepBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: _kVioletSoft, borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: _kVioletD, size: 22),
    ),
  );

  Map<String, List<String>> _computeBadges(List<dynamic> members) {
    if (members.isEmpty) return {};
    final badges = <String, List<String>>{};
    void add(dynamic m, String b) =>
        badges.putIfAbsent(m['id']?.toString() ?? '', () => []).add(b);

    add(members.first, '👑');
    final byStars = [...members]..sort((a, b) =>
        ((b['totalStars'] as int?) ?? 0).compareTo((a['totalStars'] as int?) ?? 0));
    if (byStars.first['id'] != members.first['id']) add(byStars.first, '⭐');
    final byStreak = [...members]..sort((a, b) =>
        ((b['streak'] as int?) ?? 0).compareTo((a['streak'] as int?) ?? 0));
    if ((byStreak.first['streak'] as int? ?? 0) > 0) add(byStreak.first, '🔥');
    final byGames = [...members]..sort((a, b) =>
        ((b['games'] as List?)?.length ?? 0).compareTo((a['games'] as List?)?.length ?? 0));
    if (((byGames.first['games'] as List?)?.length ?? 0) > 0) add(byGames.first, '🚀');
    return badges;
  }
}
