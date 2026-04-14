import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _activeTab = 'Filter';

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
          _SidebarItem(label: 'COURSES', isActive: true, onTap: () {}),
          _SidebarItem(label: 'MY CREATIONS', isActive: false, onTap: () {}),
          _SidebarItem(label: 'DISCOVER', isActive: false, onTap: () {}),
          const Spacer(),
          _SidebarItem(
            label: 'HELP CENTER',
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

  // ── HERO BANNER ──
  Widget _buildHeroBanner() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Container(
            width: 460,
            color: const Color.fromARGB(255, 254, 253, 153),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A7DBF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 44),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
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
          Expanded(
            child: Container(
              color: const Color(0xFF5B9EA0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _UnderwaterPainter()),
                  ),
                  const Positioned(
                    right: 280,
                    top: 40,
                    child: Text(
                      'Start playing any of\nthe activities below.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    'Filter',
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
                    'Search',
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
                _buildFilterGroup('LEVEL', [
                  _FilterPill(
                    label: 'All',
                    isSelected: true,
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('CATEGORY', [
                  _FilterPill(
                    label: 'Main Courses',
                    isSelected: _selectedCategories.contains('Main Courses'),
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Mini Courses',
                    isSelected: _selectedCategories.contains('Mini Courses'),
                    onTap: () => setState(
                        () => _showFilterExpanded = !_showFilterExpanded),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('TOPIC', [
                  _FilterPill(
                    label: 'All',
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
                    title: 'LEVEL',
                    items: ['Novice', 'Beginner', 'Intermediate', 'Advanced'],
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
                    title: 'CATEGORY',
                    items: [
                      'Main Courses',
                      'Mini Courses',
                      'Seasonal Activities'
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
                    title: 'TOPIC',
                    items: ['Coding', 'Digital Literacy', 'CS Topics'],
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
                      'APPLY',
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
                      'A Selection Must Be\nMade To Proceed',
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
            allSelected ? 'Unselect all' : 'Select all',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF1A73E8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
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
                      item,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            )),
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
      ),
      _CourseData(
        topic: 'Coding',
        level: 'Novice',
        title: 'CodeMonkey Jr.',
        subtitle: 'Sequencing & Loops',
        color: const Color(0xFF7BC67E),
        imagePath: 'assets/images/course1.jpg',
      ),
      _CourseData(
        topic: 'Coding',
        level: 'Beginner',
        title: 'Coding Adventure',
        subtitle: 'Functions & Variables',
        color: const Color(0xFF4A90C4),
        imagePath: 'assets/images/monkey_no.png',
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
        imagePath: 'assets/images/Jr1.png',
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
                  'COURSES',
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

// ── COURSE DATA MODEL ──
class _CourseData {
  final String topic;
  final String level;
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;

  const _CourseData({
    required this.topic,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
  });
}

// ── COURSE CARD ──
class _CourseCard extends StatefulWidget {
  final _CourseData course;
  const _CourseCard({required this.course});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP TAG BAR ──
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
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
                    Text(
                      widget.course.topic,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bar_chart,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.level,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── IMAGE ──
              ClipRRect(
                child: Image.asset(
                  widget.course.imagePath,
                  width: 220,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),

              // ── TITLE & SUBTITLE ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
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
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isActive ? Colors.white : Colors.white70,
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