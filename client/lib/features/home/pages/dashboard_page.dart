import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'game_webview.dart';
// import 'monkey_game_page.dart';
import 'world_map_page.dart';
import '../widgets/unlock_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:client/features/home/services/game_api_service.dart';
import 'package:client/digitalgame/digital_literacy_page.dart';
import 'package:client/datagame/data_course_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, this.username = 'Student'});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _showFilterExpanded = false;
  bool _showLevelError = false;
  bool _showCategoryError = false;
  bool _showTopicError = false;
  String _activeTab = 'Filter'; // internal key, not displayed directly
  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (_) => const UnlockDialog(),
    );
  });
}

  final Set<String> _selectedLevels = {'Novice', 'Beginner', 'Intermediate', 'Advanced'};
  final Set<String> _selectedCategories = {'Main Courses', 'Mini Courses'};
  final Set<String> _selectedTopics = {'Coding', 'Digital Literacy', 'CS Topics'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0ED),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopNavbar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildHeroBanner(),
                        _buildFilterSection(),
                        const SizedBox(height: 24),
                        _buildCoursesSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ──
  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: const Color.fromARGB(255, 158, 211, 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _SidebarItem(
  label: 'dashboard.courses_section'.tr(),
  isActive: true,
  onTap: () => showDialog(
    context: context,
    builder: (_) => const UnlockDialog(),
  ),
),
          _SidebarItem(label: 'dashboard.my_creations'.tr(), isActive: false, onTap: () {}),
          _SidebarItem(label: 'dashboard.discover'.tr(), isActive: false, onTap: () {}),
          const Spacer(),
          _SidebarItem(
            label: 'dashboard.help_center'.tr(),
            isActive: false,
            icon: Icons.help_outline,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── TOP NAVBAR ──
  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'nameofweb',
            style: GoogleFonts.montserrat(
              color: const Color.fromARGB(255, 202, 97, 128),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7DBF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.menu, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }
Widget _buildHeroBanner() {
    return Container(
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: SizedBox(
    height:224,
    child: Stack(
        fit: StackFit.expand,
        children: [
          // ── FULL IMAGE — show RIGHT half ──
          Image.asset(
            'assets/images/hot_air_baloon.png',
            fit: BoxFit.cover,
            width: double.infinity,
            alignment: Alignment.bottomLeft, // ← shows right half
          ),

          // ── DARK OVERLAY on image ──
          Container(color: Colors.black.withOpacity(0.25)),

          // ── YELLOW LEFT with angled cut ──
          ClipPath(
            clipper: _AngledClipper(),
            child: Container(
              color: const Color.fromARGB(255, 254, 253, 153),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A7DBF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.welcome'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A2A00),
                        ),
                      ),
                      Text(
                        '${widget.username}!',
                        style: GoogleFonts.nunito(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A2A00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── RIGHT CONTENT sits on top of image ──
          Positioned(
            left: MediaQuery.of(context).size.width * 0.40,
            right: 24,
            top: 0,
            bottom: 0,
            child: Row(
              children: [
                // Progress circle
               
  FutureBuilder<Map<String, dynamic>>(
  future: GameApiService.getProgress('codemonkey-jr'),
  builder: (context, snapshot) {
    final data = snapshot.data;
    final completed = data != null
        ? (data['highestLevelReached'] ?? 0) as int
        : 0;
    final total = 15; // total levels
    final percent = (completed / total).clamp(0.0, 1.0);
    final percentText = '${(percent * 100).round()}%';

    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4DD0E1),
              ),
            ),
          ),
          Text(
            percentText,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  },
),
                const SizedBox(width: 20),

                // Course info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.current_course'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'dashboard.codemonkey_jr'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'dashboard.sequencing_loops'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Color(0xFFFFD700), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'dashboard.achievements'.tr(),
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Continue coding button
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WorldMapPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255,254, 253, 153),
                    foregroundColor: const Color(0xFF3A2A00),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.play_circle_fill, size: 22),
                  label: Text(
                    'dashboard.continue_coding'.tr(),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
  ),
    );
  }
  // ── FILTER SECTION ──
  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── FILTER / SEARCH TABS ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _activeTab = 'Filter';
                    _showFilterExpanded = !_showFilterExpanded;
                  }),
                  child: Text(
                    'dashboard.filter'.tr(),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _activeTab == 'Filter'
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : const Color(0xFF888888),
                      decoration: _activeTab == 'Filter'
                          ? TextDecoration.underline
                          : null,
                      decorationColor:
                          const Color.fromARGB(255, 68, 172, 255),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => setState(() => _activeTab = 'Search'),
                  child: Text(
                    'dashboard.search'.tr(),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _activeTab == 'Search'
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : const Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FILTER PILLS ROW ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                _buildFilterGroup('dashboard.level'.tr(), [
                  _FilterPill(
                    label: 'common.all'.tr(),
                    isSelected: true,
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('dashboard.category'.tr(), [
                  _FilterPill(
                    label: 'dashboard.main_courses'.tr(),
                    isSelected: _selectedCategories.contains('Main Courses'),
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'dashboard.mini_courses'.tr(),
                    isSelected: _selectedCategories.contains('Mini Courses'),
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('dashboard.topic'.tr(), [
                  _FilterPill(
                    label: 'common.all'.tr(),
                    isSelected: true,
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                ]),
                const Spacer(),
                if (_showFilterExpanded)
                  GestureDetector(
                    onTap: () => setState(() => _showFilterExpanded = false),
                    child: const Icon(Icons.keyboard_arrow_up,
                        color: Color(0xFF888888)),
                  ),
              ],
            ),
          ),

          // ── EXPANDED FILTER ──
          if (_showFilterExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCheckboxColumn(
                    title: 'dashboard.level'.tr(),
                    items: ['Novice', 'Beginner', 'Intermediate', 'Advanced'],
                    displayLabels: [
                      'dashboard.novice'.tr(),
                      'dashboard.beginner'.tr(),
                      'dashboard.intermediate'.tr(),
                      'dashboard.advanced'.tr(),
                    ],
                    selected: _selectedLevels,
                    showError: _showLevelError,
                    onToggle: (val) => setState(() {
                      if (_selectedLevels.contains(val)) {
                        _selectedLevels.remove(val);
                      } else {
                        _selectedLevels.add(val);
                      }
                    }),
                  ),
                  const SizedBox(width: 60),
                  _buildCheckboxColumn(
                    title: 'dashboard.category'.tr(),
                    items: [
                      'Main Courses',
                      'Mini Courses',
                      'Seasonal Activities'
                    ],
                    displayLabels: [
                      'dashboard.main_courses'.tr(),
                      'dashboard.mini_courses'.tr(),
                      'dashboard.seasonal'.tr(),
                    ],
                    selected: _selectedCategories,
                    showError: _showCategoryError,
                    onToggle: (val) => setState(() {
                      if (_selectedCategories.contains(val)) {
                        _selectedCategories.remove(val);
                      } else {
                        _selectedCategories.add(val);
                      }
                    }),
                  ),
                  const SizedBox(width: 60),
                  _buildCheckboxColumn(
                    title: 'dashboard.topic'.tr(),
                    items: ['Coding', 'Digital Literacy', 'CS Topics'],
                    displayLabels: [
                      'dashboard.coding'.tr(),
                      'dashboard.digital_literacy'.tr(),
                      'dashboard.cs_topics'.tr(),
                    ],
                    selected: _selectedTopics,
                    showError: _showTopicError,
                    onToggle: (val) => setState(() {
                      if (_selectedTopics.contains(val)) {
                        _selectedTopics.remove(val);
                      } else {
                        _selectedTopics.add(val);
                      }
                    }),
                  ),
                  const Spacer(),
                  // ── APPLY BUTTON ──
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLevelError = _selectedLevels.isEmpty;
                        _showCategoryError = _selectedCategories.isEmpty;
                        _showTopicError = _selectedTopics.isEmpty;
                        if (!_showLevelError &&
                            !_showCategoryError &&
                            !_showTopicError) {
                          _showFilterExpanded = false;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(255, 252, 183, 199),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'common.apply'.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterGroup(String title, List<Widget> pills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF555555),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: pills),
      ],
    );
  }

  Widget _buildCheckboxColumn({
    required String title,
    required List<String> items,
    List<String>? displayLabels,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    bool showError = false,
  }) {
    final allSelected = items.every((i) => selected.contains(i));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
            if (showError) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back,
                        size: 12, color: Color(0xFFE53935)),
                    const SizedBox(width: 6),
                    Text(
                      'error.selection_required'.tr(),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            if (allSelected) {
              selected.clear();
            } else {
              selected.addAll(items);
            }
          }),
          child: Text(
            allSelected ? 'common.unselect_all'.tr() : 'common.select_all'.tr(),
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF1A73E8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final displayLabel = (displayLabels != null && idx < displayLabels.length)
              ? displayLabels[idx]
              : item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                onToggle(item);
                setState(() {
                  _showLevelError = false;
                  _showCategoryError = false;
                  _showTopicError = false;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: selected.contains(item)
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : Colors.white,
                      border: Border.all(
                        color: selected.contains(item)
                            ? const Color.fromARGB(255, 68, 172, 255)
                            : const Color(0xFFBBBBBB),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: selected.contains(item)
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── COURSES SECTION ──
  Widget _buildCoursesSection() {
    final courses = [
      _CourseData(
        topic: 'Coding',
        level: 'Novice',
        title: 'Linus the Lemur',
        subtitle: 'Computers',
        color: const Color(0xFF5B9EA0),
        imagePath: 'assets/images/course2.jpg',
        description: 'Linus is having fun using computers! Help him collect items he needs such as a screen and mouse. The Chameleon will raise and lower the trees making Linus reach different heights or just clearing the path.',

      ),
    _CourseData(
  topic: 'Coding',
  level: 'Novice',
  title: 'CodeMonkey Jr.',
  subtitle: 'Sequencing & Loops',
  color: const Color(0xFF7BC67E),
  imagePath: 'assets/images/course1.jpg',
  description: 'Learn sequencing and loops by guiding the monkey through fun challenges and puzzles!',
),
      _CourseData(
        topic: 'CS Topics',
        level: 'Beginner',
        title: 'Data is Everywhere',
        subtitle: 'Functions & Variables',
        color: const Color(0xFF4A90C4),
        imagePath: 'assets/images/datacourse.png',
          description: 'Get a glimpse into the world of data. Learn what data is and how to collect it. You will also learn how to organize your data using different graphing visualizations.',

      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Beginner',
        title: 'Banana Tales',
        subtitle: 'Loops & Conditions',
        color: const Color(0xFFE8A838),
        imagePath: 'assets/images/elephant.png',
      ),
      _CourseData(
        topic: 'Digital Literacy',
        level: 'Beginner',
        title: 'Digital Literacy',
        subtitle: 'Internet Safety',
        color: const Color(0xFF9B7BCB),
        imagePath: 'assets/images/digitalcourse.png',
        description: 'A short introduction to some important topics in the digital world: How to use computers, what are software and hardware, possible threats online and protecting your privacy.',


      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Intermediate',
        title: 'Game Builder',
        subtitle: 'Game Design',
        color: const Color(0xFFE57373),
        imagePath: 'assets/images/monkey_yes.png',
      ),
      _CourseData(
        topic: 'Coding',
        level: 'Intermediate',
        title: 'Coding Chatbots',
        subtitle: 'AI & Logic',
        color: const Color(0xFF4DB6AC),
        imagePath: 'assets/images/monkey_no.png',
      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Advanced',
        title: 'Data Science',
        subtitle: 'Python & Data',
        color: const Color(0xFF7986CB),
        imagePath: 'assets/images/elephant.png',
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard.courses_section'.tr(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 68, 172, 255),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: const Color.fromARGB(255, 68, 172, 255),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Wrap(
              spacing: 16,
  runSpacing: 16,
  children: courses.where((course) {
    return _selectedLevels.contains(course.level) &&
           _selectedTopics.contains(course.topic);
  }).map((course) => _CourseCard(course: course)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// // ── COURSE DATA MODEL ──
// class _CourseData {
//   final String topic;
//   final String level;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final String imagePath;

//   const _CourseData({
//     required this.topic,
//     required this.level,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.imagePath,
//   });
// }
class _CourseData {
  final String topic;
  final String level;
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;
  final String description;

  const _CourseData({
    required this.topic,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    this.description = 'Start this course to learn exciting coding concepts!',
  });
}

class _CourseCard extends StatefulWidget {
  final _CourseData course;
  const _CourseCard({required this.course});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  void _showCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CourseDialog(course: widget.course),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _showCourseDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))]
                : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP TAG BAR ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.course.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.widgets, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(widget.course.topic,
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(widget.course.level,
                            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── IMAGE WITH HOVER OVERLAY ──
              Stack(
                children: [
                  ClipRRect(
                    child: Image.asset(
                      widget.course.imagePath,
                      width: 220,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (_hovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
                      ),
                    ),
                ],
              ),

              // ── TITLE & SUBTITLE ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.course.title,
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Text(widget.course.subtitle,
                        style: GoogleFonts.nunito(fontSize: 12, color: const Color(0xFF888888))),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SIDEBAR ITEM ──
class _SidebarItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: widget.isActive
              ? const Color.fromARGB(255, 68, 172, 255)
              : _hovered
                  ? Colors.white.withOpacity(0.08)
                  : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white60, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        widget.isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FILTER PILL ──
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF888888)
                : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

// ── UNDERWATER PAINTER ──
class _UnderwaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (double x in [80, 160, 240]) {
      final path = Path();
      path.moveTo(x, size.height);
      path.cubicTo(x - 20, size.height * 0.7, x + 20, size.height * 0.4,
          x, size.height * 0.1);
      path.cubicTo(x + 20, size.height * 0.4, x - 20, size.height * 0.7,
          x, size.height);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF2D6B4A).withOpacity(0.7)
            ..style = PaintingStyle.fill);
    }

    paint.color = Colors.white.withOpacity(0.3);
    for (final pos in [
      const Offset(50, 30),
      const Offset(120, 60),
      const Offset(200, 20),
    ]) {
      canvas.drawCircle(pos, 8, paint);
    }

    paint.color = const Color(0xFFE8834A).withOpacity(0.9);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(350, 50), width: 40, height: 20),
        paint);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(420, 80), width: 30, height: 15),
        paint);
  }

  @override
  bool shouldRepaint(_UnderwaterPainter old) => false;
  
}


class _CourseDialog extends StatefulWidget {
  final _CourseData course;
  const _CourseDialog({required this.course});

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  int _imageIndex = 0;
  // Add more screenshot paths per course if you have them
  List<String> get _screenshots => [widget.course.imagePath];
Widget? _getGamePage(String title) {
  switch (title) {
    case 'CodeMonkey Jr.':
      return const  WorldMapPage();
    case 'Linus the Lemur':
      return null; // replace with LinusGamePage() when ready
    case 'Coding Adventure':
      return null; // replace with CodingAdventurePage() when ready
    case 'Digital Literacy':
      return const DigitalLiteracyPage();
    case 'Data is Everywhere':
      return const DataCoursePage();
    default:
      return null;
  }
}
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.course.title}: ',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: widget.course.subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: screenshot + arrows ──
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _screenshots[_imageIndex],
                          width: 260,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ArrowBtn(
                            icon: Icons.chevron_left,
                            onTap: () => setState(() {
                              _imageIndex = (_imageIndex - 1 + _screenshots.length) % _screenshots.length;
                            }),
                          ),
                          const SizedBox(width: 12),
                          _ArrowBtn(
                            icon: Icons.chevron_right,
                            onTap: () => setState(() {
                              _imageIndex = (_imageIndex + 1) % _screenshots.length;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // ── RIGHT: status + description ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_border, color: Color(0xFFFFB300), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'dashboard.not_started'.tr(),
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A6000),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          widget.course.description,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF444444),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
  final page = _getGamePage(widget.course.title);
  if (page != null) {
    final routeName = widget.course.title == 'Data is Everywhere'
        ? 'data_course_hub'
        : 'digital_literacy_hub';
    Navigator.push(context, MaterialPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (_) => page,
    ));
  }
  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DB84A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'dashboard.start_coding'.tr(),
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ARROW BUTTON ──
class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6DB84A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
class _AngledClipper extends CustomClipper<Path> {
  @override
 @override
Path getClip(Size size) {
  final path = Path();
  path.moveTo(0, 0);
  path.lineTo(size.width * 0.40, 0);
path.lineTo(size.width * 0.42, size.height);
  path.lineTo(0, size.height);
  path.close();
  return path;
}

  @override
  bool shouldReclip(_AngledClipper old) => false;
}
