import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'lesson_slide_texts.dart';

// ===========================================================================
//  DATA
// ===========================================================================
class _Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  const _Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
final List<_Question> _kFallbackQuestions = [
  _Question(
    question: 'What are the building blocks that make up the internet?',
    options: [
      'Lasers and satellites.',
      'Many, many software applications.',
      'Computers connected by cables and other hardware.',
      'Radio waves and the clouds.',
    ],
    correctIndex: 2,
  ),
  _Question(
    question: 'What is an example of software?',
    options: [
      'A mouse.',
      'A browser application.',
      'A desk chair cushion.',
      'A keyboard.',
    ],
    correctIndex: 1,
  ),
  _Question(
    question: 'Websites are located by a user-friendly address like app.codemonkey.com. What is this address called?',
    options: ['URL', 'PAM', 'ABC', 'MAT'],
    correctIndex: 0,
  ),
  _Question(
    question: 'If you want to send an email to a lot of recipients, and you don\'t want them to see each others\' email addresses, where should you put the email addresses?',
    options: [
      'In the To:.',
      'In the Cc:.',
      'In the Bcc:.',
      'This isn\'t possible.',
    ],
    correctIndex: 2,
  ),
  _Question(
    question: 'What is the internet?',
    options: [
      'A huge network of connected computers.',
      'A type of software program.',
      'A device for storing files.',
      'A social media platform.',
    ],
    correctIndex: 0,
  ),
];
// ===========================================================================
//  PAGE
// ===========================================================================
class DigitalQuizPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback? onChainFinished;
  const DigitalQuizPage({super.key, required this.lesson, this.onChainFinished});

  @override
  State<DigitalQuizPage> createState() => _DigitalQuizPageState();
}

class _DigitalQuizPageState extends State<DigitalQuizPage> {
  int _currentQ = 0;
  int? _selectedIdx;
  int? _hoveredIdx;
  bool _submitted = false;
  int _score = 0;
  bool _isLoading = false;

  List<_Question> _questions = List.of(_kFallbackQuestions);

  static const _labels = ['A', 'B', 'C', 'D'];

  _Question get _q => _questions[_currentQ];
  bool get _isLast => _currentQ == _questions.length - 1;
  bool get _canNext => _submitted;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAiQuestions() async {
    setState(() => _isLoading = true);
    final lessonNumber = widget.lesson['number'] as int;
    final slideTexts = LessonSlideTexts.forLesson(lessonNumber);
    if (slideTexts.isEmpty) { setState(() => _isLoading = false); return; }

    final aiData = await ApiService.generateQuizQuestions(
      lessonNumber: lessonNumber,
      slideTexts: slideTexts,
    );
    if (!mounted) return;

    if (aiData.length >= 3) {
      final newQuestions = aiData.map((q) => _Question(
        question: q['question'] as String,
        options: List<String>.from(q['options']),
        correctIndex: q['correctIndex'] as int,
      )).toList();
      setState(() {
        _questions = newQuestions;
        _currentQ = 0;
        _selectedIdx = null;
        _hoveredIdx = null;
        _submitted = false;
        _score = 0;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✨ New questions generated from lesson!',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 2),
        ));
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ AI unavailable — using default questions.',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          backgroundColor: const Color(0xFFE53935),
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  void _selectAnswer(int idx) {
    if (_submitted) return;
    setState(() => _selectedIdx = idx);
  }

  void _submit() {
    if (_selectedIdx == null || _submitted) return;
    setState(() {
      _submitted = true;
      if (_selectedIdx == _q.correctIndex) _score++;
    });
  }

  void _next() {
    if (!_canNext) return;
    if (_isLast) {
      _showCompletedDialog();
      return;
    }
    setState(() {
      _currentQ++;
      _selectedIdx = null;
      _hoveredIdx = null;
      _submitted = false;
    });
  }

  void _prev() {
    if (_currentQ == 0) return;
    setState(() {
      _currentQ--;
      _selectedIdx = null;
      _hoveredIdx = null;
      _submitted = false;
    });
  }
  void _showCompletedDialog() async {
    final lessonNumber = widget.lesson['number'] as int;
    await ApiService.saveQuizScore(
      gameId: 'digital-literacy',
      lessonNumber: lessonNumber,
      correctAnswers: _score,
      totalQuestions: _questions.length,
    );
    await ApiService.saveLevelResult(
      gameId: 'digital-literacy',
      level: lessonNumber,
      completed: true,
      score: ((_score / _questions.length) * 100).round(),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _CompletionScreen(
          lessonTitle: widget.lesson['title'] as String,
          lessonNumber: lessonNumber,
          score: _score,
          total: _questions.length,
          onBack: () => Navigator.of(context).pop(),
          onNext: widget.onChainFinished ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF1FB5C9),
      body: Column(
        children: [
          _buildNavBar(lessonNumber, lessonTitle),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: _currentQ > 0 ? _prev : null,
                ),
                // ── narrow white box ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Stack(
                      children: [
                        Container(color: Colors.white, child: _buildContent()),
                        if (_isLoading)
                          Container(
                            color: Colors.black45,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  const CircularProgressIndicator(color: Color(0xFF1FB5C9)),
                                  const SizedBox(height: 14),
                                  Text('Generating new questions…',
                                      style: GoogleFonts.nunito(
                                          fontSize: 16, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: 'NEXT',
                  onTap: _canNext ? _next : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NAV BAR ──
  Widget _buildNavBar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(children: [
              Image.asset('assets/images/sprites/logocodey.png', height: 40, fit: BoxFit.contain),
              const SizedBox(width: 24),
              Flexible(
                child: Text(
                  'DIGITAL LITERACY: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      color: Colors.white70, fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          Row(children: [
            Image.asset('assets/images/sprites/avatar00.png', width: 36, height: 36),
            const SizedBox(width: 16),
            Image.asset('assets/images/sprites/btn_menu.png', width: 24, height: 24),
          ]),
        ],
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
            onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
            child: Container(
              width: 52, height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF5B8FD4),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                  Text('BACK TO\nCOURSE',
                      style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 7,
                          fontWeight: FontWeight.w800, height: 1.1),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('#$lessonNumber',
              style: const TextStyle(
                  fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 22)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: const TextStyle(
                  fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 24)),
          const Spacer(),
          GestureDetector(
            onTap: _isLoading ? null : _loadAiQuestions,
            child: Opacity(
              opacity: _isLoading ? 0.4 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text('AI', style: GoogleFonts.nunito(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildTopBox(icon: Icons.menu_book, iconColor: const Color(0xFF5B8FD4),
              label: 'LEARN', value: '18/18',
              bgColor: const Color(0xFF5B8FD4).withOpacity(0.15)),
          const SizedBox(width: 8),
          _buildTopBox(icon: Icons.sports_esports, iconColor: const Color(0xFF4CAF50),
              label: 'PLAY', value: '3/3',
              bgColor: const Color(0xFF4CAF50).withOpacity(0.15)),
          const SizedBox(width: 8),
          _buildReviewBox(),
        ],
      ),
    );
  }

  Widget _buildTopBox({
    required IconData icon, required Color iconColor,
    required String label, required String value, required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.nunito(
                fontSize: 9, fontWeight: FontWeight.w800,
                color: const Color(0xFF555555))),
            Text(value, style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: const Color(0xFF333333))),
          ],
        ),
      ]),
    );
  }

  Widget _buildReviewBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: const Color(0xFF5B8FD4),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('REVIEW', style: GoogleFonts.nunito(
                fontSize: 9, fontWeight: FontWeight.w800,
                color: const Color(0xFF555555))),
            const SizedBox(height: 2),
            Row(
              children: List.generate(_questions.length, (i) {
                Color dotColor;
                Widget? child;
                if (i < _currentQ) {
                  dotColor = const Color(0xFF4CAF50);
                  child = const Icon(Icons.check, size: 8, color: Colors.white);
                } else if (i == _currentQ) {
                  dotColor = Colors.white;
                  child = Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 7, fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)));
                } else {
                  dotColor = Colors.white.withOpacity(0.4);
                }
                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  child: child != null ? Center(child: child) : null,
                );
              }),
            ),
          ],
        ),
      ]),
    );
  }

  // ── CONTENT ──
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── QUESTION CARD ──
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD6F1F8),
              borderRadius: BorderRadius.circular(28), // more rounded
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── BADGE in Chennai font ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0A0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8D080)),
                  ),
                  child: Text(
                    'REVIEW QUESTION #${_currentQ + 1}',
                    style: const TextStyle(
                      fontFamily: 'Chennai', // ← Chennai font
                      fontSize: 13,
                      color: Color(0xFF888844),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _q.question,
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A237E), height: 1.4),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── ANSWER OPTIONS + SUBMIT ──
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // answers
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 16, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                        _q.options.length, (i) => _buildAnswerOption(i)),
                  ),
                ),
              ),
              // submit button
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 32, 24),
                child: Center(child: _buildSubmitButton()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ANSWER OPTION ──
  Widget _buildAnswerOption(int idx) {
  final label = _labels[idx];
  final text = _q.options[idx];
  final isSelected = _selectedIdx == idx;
  final isHovered = _hoveredIdx == idx && !_submitted;
  final isCorrect = _submitted && idx == _q.correctIndex;
  final isWrong = _submitted && isSelected && idx != _q.correctIndex;
  final isHighlighted = isSelected || isHovered;

  // ── CIRCLE colors ──
 // ── CIRCLE colors ──
Color circleBg;
Color circleBorder;
Color circleText;
Widget? circleChild;

if (isCorrect) {
  circleBg = const Color(0xFF4CAF50);
  circleBorder = const Color(0xFF388E3C);
  circleText = Colors.white;
  circleChild = const Icon(Icons.check, color: Colors.white, size: 22);
} else if (isWrong) {
  circleBg = const Color(0xFFE57373);
  circleBorder = const Color(0xFFE53935);
  circleText = Colors.white;
  circleChild = const Icon(Icons.close, color: Colors.white, size: 22);
} else if (isSelected) {
  // ← only on CLICK, not hover
  circleBg = const Color(0xFFFFC83D);
  circleBorder = const Color(0xFFE0A300);
  circleText = const Color(0xFF28204A);
  circleChild = null;
} else {
  // hover OR unselected — same cream style
  circleBg = const Color(0xFFFFF0C0);
  circleBorder = const Color(0xFFE8D080);
  circleText = const Color(0xFF28204A);
  circleChild = null;
}

 Widget textWidget;
if (isWrong) {
  textWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE57373),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(text, style: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
  );
} else if (isCorrect) {
  textWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Text(text, style: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
  );
} else if (isSelected && !_submitted) {
  // CLICK — yellow border pill
  textWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFFFC83D), width: 2),
    ),
    child: Text(text, style: GoogleFonts.nunito(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: const Color(0xFF28204A))),
  );
} else if (isHovered) {
  // HOVER — yellow pill no border (same as before)
  textWidget = Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFC83D).withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: GoogleFonts.nunito(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: const Color(0xFF28204A))),
      ),
    ],
  );
} else {
  // plain
  textWidget = Text(text, style: GoogleFonts.nunito(
      fontSize: 18, fontWeight: FontWeight.w600,
      color: const Color.fromARGB(255,40, 32, 74)));
}

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _hoveredIdx = idx),
    onExit: (_) => setState(() => _hoveredIdx = null),
    child: GestureDetector(
      onTap: () => _selectAnswer(idx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // circle
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: circleBg,
                shape: BoxShape.circle,
                border: Border.all(color: circleBorder, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: circleBorder.withOpacity(0.3),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: circleChild ?? Text(label,
                    style: TextStyle(
                        fontFamily: 'Chennai', fontSize: 20,
                        fontWeight: FontWeight.w800, color: circleText)),
              ),
            ),
            const SizedBox(width: 16),
            // text pill
            textWidget,
          ],
        ),
      ),
    ),
  );
}
  // ── SUBMIT BUTTON ──
  Widget _buildSubmitButton() {
  final canSubmit = _selectedIdx != null && !_submitted;

  return GestureDetector(
    onTap: canSubmit ? _submit : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 160, height: 160,
      decoration: BoxDecoration(
        color: canSubmit
            ? const Color(0xFFFFE48A)
            : const Color(0xFFE8E8E8),
        shape: BoxShape.circle,
        border: Border.all(
          color: canSubmit
              ? const Color(0xFFE0A300)
              : const Color(0xFFCCCCCC),
          width: 2.5,
        ),
        boxShadow: canSubmit
            ? [BoxShadow(
                color: const Color(0xFFE0A300).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))]
            : [],
      ),
      child: Center(
        child: Text(
          _submitted ? 'SUBMITTED' : 'SUBMIT YOUR\nANSWER',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Chennai',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF28204A),
            height: 1.4,
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
        color: const Color.fromARGB(255,31,181,201),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF5A623)
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: enabled ? Colors.white : Colors.white38, size: 32),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    color: enabled ? Colors.white : Colors.white38,
                    fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
class _CompletionScreen extends StatelessWidget {
  final String lessonTitle;
  final int lessonNumber;
  final int score;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _CompletionScreen({
    required this.lessonTitle,
    required this.lessonNumber,
    required this.score,
    required this.total,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4ABFB8),
      body: Column(
        children: [
          // ── NAVBAR ──
          Container(
            color: const Color(0xFF2C1F14),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(children: [
                    Image.asset('assets/images/sprites/logocodey.png', height: 40, fit: BoxFit.contain),
                    const SizedBox(width: 24),
                    Flexible(
                      child: Text(
                        'DIGITAL LITERACY: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            color: Colors.white70, fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
                Row(children: [
                  Image.asset('assets/images/sprites/avatar00.png', width: 36, height: 36),
                  const SizedBox(width: 16),
                  Image.asset('assets/images/sprites/btn_menu.png', width: 24, height: 24),
                ]),
              ],
            ),
          ),

          // ── TOP BAR ──
          Container(
            color: const Color(0xFFADE8F4),
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
                  child: Container(
                    width: 52, height: 52,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: const Color(0xFF5B8FD4),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                        Text('BACK TO\nCOURSE',
                            style: GoogleFonts.nunito(
                                color: Colors.white, fontSize: 7,
                                fontWeight: FontWeight.w800, height: 1.1),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('#$lessonNumber',
                    style: const TextStyle(
                        fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 22)),
                const SizedBox(width: 8),
                Text(lessonTitle,
                    style: const TextStyle(
                        fontFamily: 'Chennai', color: Color(0xFF333333), fontSize: 24)),
                const Spacer(),
                // LEARN
                _topBox(icon: Icons.menu_book, iconColor: const Color(0xFF5B8FD4),
                    label: 'LEARN', value: '18/18',
                    bgColor: const Color(0xFF5B8FD4).withOpacity(0.15)),
                const SizedBox(width: 8),
                // PLAY
                _topBox(icon: Icons.sports_esports, iconColor: const Color(0xFF4CAF50),
                    label: 'PLAY', value: '3/3',
                    bgColor: const Color(0xFF4CAF50).withOpacity(0.15)),
                const SizedBox(width: 8),
                // REVIEW — all dots green
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                          color: const Color(0xFF5B8FD4),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('REVIEW', style: GoogleFonts.nunito(
                            fontSize: 9, fontWeight: FontWeight.w800,
                            color: const Color(0xFF555555))),
                        const SizedBox(height: 2),
                        Text('$total/$total',
                            style: GoogleFonts.nunito(
                                fontSize: 11, fontWeight: FontWeight.w800,
                                color: const Color(0xFF333333))),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── MAIN CONTENT ──
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── WHITE CARD ──
                  Container(
                    width: 780,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // ── LEFT TEXT ──
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(48, 0, 24, 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('GREAT JOB!',
                                    style: GoogleFonts.nunito(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF3D2B8F),
                                        letterSpacing: 1)),
                                const SizedBox(height: 12),
                                Text('You\'ve completed "$lessonTitle"',
                                    style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        color: const Color(0xFF444444))),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        color: const Color(0xFF555555)),
                                    children: [
                                      const TextSpan(text: 'Review score '),
                                      TextSpan(
                                        text: '$score/$total',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF333333)),
                                      ),
                                      const TextSpan(text: ' correct answers'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── RIGHT IMAGE ──
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.asset(
                            'assets/images/great.png',
                            width: 300,
                            height: 260,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── BUTTONS ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE48A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE0A300), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0xFFE0A300),
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.arrow_back_ios,
                                size: 16, color: Color(0xFF28204A)),
                            const SizedBox(width: 8),
                            Text('Back to\ncourse',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    color: const Color(0xFF28204A))),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE48A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE0A300), width: 2),
                            boxShadow: const [
                              BoxShadow(color: Color(0xFFE0A300),
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Next lesson',
                                style: GoogleFonts.nunito(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    color: const Color(0xFF28204A))),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Color(0xFF28204A)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBox({
    required IconData icon, required Color iconColor,
    required String label, required String value, required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.nunito(
                fontSize: 9, fontWeight: FontWeight.w800,
                color: const Color(0xFF555555))),
            Text(value, style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: const Color(0xFF333333))),
          ],
        ),
      ]),
    );
  }
}