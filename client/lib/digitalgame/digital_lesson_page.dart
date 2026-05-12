import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DigitalLessonPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DigitalLessonPage({super.key, required this.lesson});

  @override
  State<DigitalLessonPage> createState() => _DigitalLessonPageState();
}

class _DigitalLessonPageState extends State<DigitalLessonPage> {
  int _currentSlide = 0;
  bool _listenMode = false;
  int _playScore = 0;
  int _reviewScore = 0;
  int? _hoveredDot; // tracks which dot is hovered

  List<_SlideData> get _slides {
    final int lessonNumber = widget.lesson['number'] as int;
    switch (lessonNumber) {
      case 1:
        return [
          _SlideData(title: 'Digital Use In A Nutshell',       imagePath: 'assets/images/1.jpeg'),
          _SlideData(title: 'What is a Computer?',             imagePath: 'assets/images/2.jpeg'),
          _SlideData(title: 'Hardware vs. Software',           imagePath: 'assets/images/3.jpeg'),
          _SlideData(title: 'The Internet',                    imagePath: 'assets/images/4.jpeg'),
          _SlideData(title: 'Email Fundamentals',              imagePath: 'assets/images/5.jpeg'),
          _SlideData(title: 'File Organization',               imagePath: 'assets/images/6.jpeg'),
          _SlideData(title: 'Useful Applications',             imagePath: 'assets/images/7.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/8.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/9.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/10.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/11.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/12.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/13.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/14.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/15.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/16.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/17.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/18.jpeg'),
        ];
      case 2:
        return [
          _SlideData(title: 'Digital Citizenship In A Nutshell', imagePath: 'assets/images/1.jpeg'),
          _SlideData(title: 'What is Digital Citizenship?',      imagePath: 'assets/images/2.jpeg'),
          _SlideData(title: 'Online Safety',                     imagePath: 'assets/images/3.jpeg'),
          _SlideData(title: 'Being Respectful Online',           imagePath: 'assets/images/4.jpeg'),
          _SlideData(title: 'Cyberbullying',                     imagePath: 'assets/images/5.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/6.jpeg'),
          _SlideData(title: 'Useful Applications',               imagePath: 'assets/images/7.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/8.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/9.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/10.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/11.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/12.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/13.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/14.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/15.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/16.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/17.jpeg'),
          _SlideData(title: 'Lesson Summary',                    imagePath: 'assets/images/18.jpeg'),
        ];
      case 3:
        return [
          _SlideData(title: 'Digital Collaboration',           imagePath: 'assets/images/1.jpeg'),
          _SlideData(title: 'What is Digital Collaboration?',  imagePath: 'assets/images/2.jpeg'),
          _SlideData(title: 'Collaboration Tools',             imagePath: 'assets/images/3.jpeg'),
          _SlideData(title: 'Effective Communication',         imagePath: 'assets/images/4.jpeg'),
          _SlideData(title: 'Sharing Documents',               imagePath: 'assets/images/5.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/6.jpeg'),
          _SlideData(title: 'Useful Applications',             imagePath: 'assets/images/7.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/8.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/9.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/10.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/11.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/12.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/13.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/14.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/15.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/16.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/17.jpeg'),
          _SlideData(title: 'Lesson Summary',                  imagePath: 'assets/images/18.jpeg'),
        ];
      default:
        return [
          _SlideData(title: 'Lesson', imagePath: 'assets/images/1.jpeg'),
        ];
    }
  }

  void _nextSlide() {
    if (_currentSlide < _slides.length - 1) {
      setState(() => _currentSlide++);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() => _currentSlide--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentSlide];
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;
    final totalSlides = _slides.length;

    return Scaffold(
      backgroundColor: const Color(0xFF7B9FD4),
      body: Column(
        children: [
          _buildTopBar(lessonNumber, lessonTitle, totalSlides),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: _currentSlide > 0 ? _prevSlide : null,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: _buildSlideCard(slide),
                  ),
                ),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: _currentSlide == totalSlides - 1 ? 'FINISH' : 'NEXT',
                  onTap: _nextSlide,
                ),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar(int lessonNumber, String lessonTitle, int totalSlides) {
    return Container(
      color: const Color(0xFFADE8F4),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // ── BACK TO COURSE ──
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8FD4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 14),
                  Text(
                    'BACK TO\nCOURSE',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // ── LESSON NUMBER + TITLE ──
          Text(
            '#$lessonNumber',
            style: GoogleFonts.nunito(
              color: const Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            lessonTitle,
            style: GoogleFonts.nunito(
              color: const Color(0xFF333333),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 500),

          // ── LEARN SECTION ──
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Book icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B8FD4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.menu_book,
                        color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LEARN',
                    style: GoogleFonts.nunito(
                      color: const Color(0xFF555555),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              // ── PROGRESS DOTS ──
              Row(
                children: List.generate(totalSlides, (i) {
                  final bool isCompleted = i < _currentSlide;
                  final bool isCurrent = i == _currentSlide;
                  final bool isLocked = i > _currentSlide;
                  final bool isHovered = _hoveredDot == i;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredDot = i),
                    onExit: (_) => setState(() => _hoveredDot = null),
                    child: GestureDetector(
                      // Only allow clicking completed slides
                      onTap: isCompleted
                          ? () => setState(() => _currentSlide = i)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 3),
                        width: isCurrent ? 24 : 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isHovered && isCompleted
                              ? const Color(0xFFFFD700) // yellow on hover
                              : isCompleted
                                  ? const Color(0xFF4DD0C4) // teal = done
                                  : isCurrent
                                      ? Colors.white // white = current
                                      : const Color(0xFF9BB8D4), // grey = locked
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 4,
                                  )
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(
                                  isHovered ? Icons.star : Icons.star,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF2C8A7A),
                                  size: 11,
                                )
                              : isCurrent
                                  ? Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    )
                                  : Icon(
                                      Icons.lock,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 10,
                                    ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const Spacer(),

          // ── PLAY SCORE ──
          _buildScoreBox('PLAY', _playScore, 3, Icons.sports_esports),
          const SizedBox(width: 8),

          // ── REVIEW SCORE ──
          _buildScoreBox('REVIEW', _reviewScore, 5, Icons.chat_bubble_outline),
        ],
      ),
    );
  }

  Widget _buildScoreBox(String label, int score, int total, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF555555), size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF555555),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.lock, color: Color(0xFF888888), size: 10),
              const SizedBox(width: 2),
              Text(
                '$score/$total',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF555555),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SLIDE CARD ──
  Widget _buildSlideCard(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          slide.imagePath,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8B9FD4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image,
                      color: Colors.white54, size: 80),
                  const SizedBox(height: 16),
                  Text(
                    slide.title,
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SIDE NAVIGATION BUTTON ──
  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: double.infinity,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF6B7FBF)
                    : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM BAR ──
  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFF6B7FBF).withOpacity(0.5),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'LISTEN MODE',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _listenMode = !_listenMode),
                    child: Container(
                      width: 48,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _listenMode
                            ? const Color(0xFF4DD0C4)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: _listenMode
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(2),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                _listenMode ? 'ON' : 'OFF',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${_currentSlide + 1} / ${_slides.length}',
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '© 2022 CodeMonkey Studios Ltd.',
            style: GoogleFonts.nunito(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SLIDE DATA MODEL ──
class _SlideData {
  final String title;
  final String imagePath;

  const _SlideData({
    required this.title,
    required this.imagePath,
  });
}