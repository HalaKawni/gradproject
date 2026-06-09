import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_play_page_lesson2.dart';

// ===========================================================================
//  DATA MODELS
// ===========================================================================
class _CornerQuestion {
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String? imageAsset;
  const _CornerQuestion({
    required this.questionText,
    required this.options,
    required this.correctIndex,
    this.imageAsset,
  });
}

class _LSlide {
  final String? imagePath;
  final _CornerQuestion? question;
  const _LSlide({this.imagePath, this.question});
  bool get isQuestion => question != null;
}

// ===========================================================================
//  SLIDES  (positions 7, 10, 12, 14 = CORNER QUESTIONS — no datalesson image)
// ===========================================================================
const List<_LSlide> _kSlides = [
  _LSlide(imagePath: 'assets/images/datalesson1.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson2.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson3.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson4.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson5.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson6.jpeg'),
  // position 7 — CORNER QUESTION 1
  _LSlide(question: _CornerQuestion(
    questionText:
        'When you studied the table on the last slide, did you notice a potential pattern? What was the pattern?',
    options: [
      'The raccoons like different kinds of fruit.',
      'Raccoons do not like bananas.',
      'The raccoons who collected the most apples also chose apples as their favorite fruit.',
      'Raccoons named Buster tend to like apples.',
    ],
    correctIndex: 2,
  )),
  _LSlide(imagePath: 'assets/images/datalesson8.jpeg'),
  _LSlide(imagePath: 'assets/images/datalesson9.jpeg'),
  // position 10 — CORNER QUESTION 2
  _LSlide(question: _CornerQuestion(
    questionText:
        'In this graph, blue had how many more votes than red as the favorite color?',
    options: [
      'Five more students picked blue compared to red.',
      'Two more students picked blue compared to red.',
      'Three more students picked blue compared to red.',
      'One more student picked blue compared to red.',
    ],
    correctIndex: 3,
    imageAsset: 'assets/images/lesson2-c2.png',
  )),
  _LSlide(imagePath: 'assets/images/datalesson11.jpeg'),
  // position 12 — CORNER QUESTION 3
  _LSlide(question: _CornerQuestion(
    questionText:
        'Which fruit was picked by the most students, and how many students picked that fruit as presented in this graph',
    options: [
      'Ten students picked apples, which was the fruit most picked.',
      'Twenty students picked apples, which was the fruit most picked.',
      'Twenty-two students picked bananas, which was the fruit most picked.',
      'Sixteen students picked bananas, which was the fruit most picked.',
    ],
    correctIndex: 1,
    imageAsset: 'assets/images/lesson2-c3v2.png',
  )),
  _LSlide(imagePath: 'assets/images/datalesson13.jpeg'),
  // position 14 — CORNER QUESTION 4
  _LSlide(question: _CornerQuestion(
    questionText:
        'How many students in the class have a first name less than six letters long as presented in this graph',
    options: [
      'Eleven students have names less than six letters long.',
      'Thirteen students have names less than six letters long.',
      'Twelve students have names less than six letters long.',
      'Six students have names less than six letters long.',
    ],
    correctIndex: 0,
    imageAsset: 'assets/images/lesson2-c4.png',
  )),
  _LSlide(imagePath: 'assets/images/datalesson15.jpeg'),
];

// ===========================================================================
//  PAGE
// ===========================================================================
class DataLearnPageLesson2 extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DataLearnPageLesson2({super.key, required this.lesson});

  @override
  State<DataLearnPageLesson2> createState() => _DataLearnPageLesson2State();
}

class _DataLearnPageLesson2State extends State<DataLearnPageLesson2> {
  int _current = 0;
  int? _selected;
  bool _answered = false;
  bool _imageExpanded = false;

  _LSlide get _slide => _kSlides[_current];
  bool get _isLast => _current == _kSlides.length - 1;
  bool get _canNext => !_slide.isQuestion || _answered;

  void _next() {
    if (!_canNext) return;
    if (_isLast) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DataPlayPageLesson2(lesson: widget.lesson),
      ));
      return;
    }
    setState(() {
      _current++;
      _selected = null;
      _answered = false;
      _imageExpanded = false;
    });
  }

  void _prev() {
    if (_current == 0) return;
    setState(() {
      _current--;
      _selected = null;
      _answered = false;
      _imageExpanded = false;
    });
  }

  void _tapOption(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;
    return Scaffold(
      backgroundColor: const Color(0xFF7B7FD4),
      body: Column(
        children: [
          _buildNavbar(lessonNumber, lessonTitle),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: _current > 0 ? _prev : null,
                ),
                Expanded(
                  child: _slide.isQuestion
                      ? _buildQuestionContent(_slide.question!)
                      : _buildImageContent(_slide.imagePath!),
                ),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: _isLast ? 'FINISH' : 'NEXT',
                  onTap: _canNext ? _next : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NAVBAR ──
  Widget _buildNavbar(int lessonNumber, String lessonTitle) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFFCB7C7),
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Image.asset('assets/images/sprites/logocodey.png',
                  height: 40, fit: BoxFit.contain),
              const SizedBox(width: 24),
              Text(
                'DATA IS EVERYWHERE: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
            Row(children: [
              Image.asset('assets/images/sprites/avatar00.png',
                  width: 36, height: 36),
              const SizedBox(width: 16),
              Image.asset('assets/images/sprites/btn_menu.png',
                  width: 24, height: 24),
            ]),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color(0xFFADE8F4),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil(
                (route) =>
                    route.settings.name == 'data_course_hub' ||
                    route.isFirst),
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF5B8FD4),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 14),
                  Text('BACK TO\nCOURSE',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          height: 1.1),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('#$lessonNumber',
              style: const TextStyle(
                  fontFamily: 'Chennai',
                  color: Color(0xFF333333),
                  fontSize: 22)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: const TextStyle(
                  fontFamily: 'Chennai',
                  color: Color(0xFF333333),
                  fontSize: 24)),
          const Spacer(),
          _buildLearnBox(),
          const SizedBox(width: 8),
          _buildTopBox(
            icon: Icons.sports_esports,
            iconColor: Colors.grey,
            label: 'PLAY',
            value: '0/2',
            bgColor: Colors.grey.withValues(alpha: 0.15),
            locked: true,
          ),
          const SizedBox(width: 8),
          _buildTopBox(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.grey,
            label: 'REVIEW',
            value: '0/5',
            bgColor: Colors.grey.withValues(alpha: 0.15),
            locked: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF5B8FD4).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.menu_book, color: Color(0xFF5B8FD4), size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LEARN',
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF555555))),
            const SizedBox(height: 2),
            Row(
              children: List.generate(_kSlides.length, (i) {
                Color dotColor;
                Widget? child;
                if (i < _current) {
                  dotColor = const Color(0xFF4CAF50);
                  child =
                      const Icon(Icons.check, size: 7, color: Colors.white);
                } else if (i == _current) {
                  dotColor = Colors.white;
                  child = Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)));
                } else {
                  dotColor = Colors.white.withValues(alpha: 0.4);
                  child = null;
                }
                return Container(
                  margin: const EdgeInsets.only(right: 2),
                  width: 14,
                  height: 14,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  child: child != null ? Center(child: child) : null,
                );
              }),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildTopBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
    bool locked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF555555))),
            Row(children: [
              if (locked)
                const Icon(Icons.lock, size: 10, color: Color(0xFF888888)),
              Text(value,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF333333))),
            ]),
          ],
        ),
      ]),
    );
  }

  // ── IMAGE SLIDE ──
  Widget _buildImageContent(String path) {
    return Container(
      color: Colors.white,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  // ── CORNER QUESTION SLIDE ──
  Widget _buildQuestionContent(_CornerQuestion q) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0A0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8D080)),
                    ),
                    child: const Text(
                      'CORNER QUESTION',
                      style: TextStyle(
                        fontFamily: 'Chennai',
                        fontSize: 14,
                        color: Color(0xFF888844),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Question row (text + optional thumbnail)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          q.questionText,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A2E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (q.imageAsset != null) ...[
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _imageExpanded = !_imageExpanded),
                          child: Container(
                            width: 110,
                            height: 88,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF5B8FD4), width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6)
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Stack(
                                children: [
                                  Image.asset(q.imageAsset!,
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 88),
                                  Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.zoom_in,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!_answered) ...[
                    const SizedBox(height: 8),
                    Text('Select the correct answer',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  // Options
                  ...List.generate(
                      q.options.length, (i) => _buildOption(q, i)),
                ],
              ),
            ),
          ),
        ),
        // Expanded image overlay
        if (_imageExpanded && q.imageAsset != null)
          _buildImageOverlay(q.imageAsset!),
      ],
    );
  }

  Widget _buildOption(_CornerQuestion q, int idx) {
    final isCorrect = _answered && idx == q.correctIndex;
    final isWrong =
        _answered && _selected == idx && idx != q.correctIndex;

    final Color pillColor =
        isWrong ? const Color(0xFF007B8A) : const Color(0xFFADE8F4);
    final Color textColor =
        isWrong ? Colors.white : const Color(0xFF1A1A2E);

    Widget? leadingIcon;
    if (isCorrect) {
      leadingIcon = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50), width: 2.5),
        ),
        child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
      );
    } else if (isWrong) {
      leadingIcon = Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
            color: Color(0xFFE53935), shape: BoxShape.circle),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      );
    }

    return MouseRegion(
      cursor: _answered
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _tapOption(idx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: pillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  q.options[idx],
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOverlay(String assetPath) {
    return GestureDetector(
      onTap: () => setState(() => _imageExpanded = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 24)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── SIDE BUTTON ──
  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: double.infinity,
        color: const Color(0xFF7B7FD4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF5A623)
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
