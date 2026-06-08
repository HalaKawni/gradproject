import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'data_lesson_slide_texts.dart';

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

const List<_Question> _kLesson2Questions = [
  _Question(
    question:
        'Which of the following is numerical data organized in descending order?',
    options: [
      '34, 16, 10, 3, 12, 9, 1',
      '1, 3, 9, 10, 12, 16, 34',
      '34, 16, 12, 10, 9, 3, 1',
      '1, 34, 3, 16, 9, 12, 10',
    ],
    correctIndex: 2,
  ),
  _Question(
    question:
        'Why is it important to have a heading for each column when organizing data in a table?',
    options: [
      'It helps you understand the meaning of the data in each column.',
      'It makes the table look more complete.',
      'It is a format expected by data analysts.',
      'It will help you find patterns in the data.',
    ],
    correctIndex: 0,
  ),
  _Question(
    question:
        'What is the major difference between a picture graph and a bar chart?',
    options: [
      'Picture graphs are black and white while bar charts use color.',
      'Picture graphs use non-numeric data while bar charts use numeric data.',
      'Picture graphs use symbols of the data while bar charts use the height of a bar.',
      'Picture graphs are used for sports data while bar charts are used for food data.',
    ],
    correctIndex: 2,
  ),
  _Question(
    question:
        'Why do you need to review the key before analyzing a picture graph?',
    options: [
      'The key will help you unlock patterns in the data.',
      'The key will explain how the data was organized.',
      'The key will explain any missing data in the graph.',
      'The key tells you how many items each picture represents.',
    ],
    correctIndex: 3,
  ),
  _Question(
    question: 'What type of data do you usually organize with a line plot?',
    options: [
      'Numerical data',
      'Non-numerical data',
      'Data represented with pictures',
      'Data that involves numbers that cannot be counted',
    ],
    correctIndex: 0,
  ),
];

const List<_Question> _kLesson1Questions = [
  _Question(
    question:
        'The following questions are asked of a large group of people. Which would result in numerical data?',
    options: [
      'What is your favorite color?',
      'What is your favorite sport?',
      'How often do you brush your teeth in a day?',
      'What is your favorite type of music?',
    ],
    correctIndex: 2,
  ),
  _Question(
    question: 'What is non-numerical data?',
    options: [
      'Data that includes measurements and temperatures.',
      'Data that includes colors and pet names.',
      'Data that includes heights and weights.',
      'Data that includes scores and distances.',
    ],
    correctIndex: 1,
  ),
  _Question(
    question:
        'How could you collect data on the favorite fruits of the students in your class?',
    options: [
      'Ask each student and then write down their answer.',
      'Go to the grocery store and count the fruits.',
      'Look at data from another country.',
      'Use a thermometer to measure temperature.',
    ],
    correctIndex: 0,
  ),
  _Question(
    question:
        'Kelly collected data on the number of people in the movie theater wearing a hat by observation. How did she do this?',
    options: [
      'She asked everyone in the theater a question.',
      'She sent out a survey before the movie.',
      'She recorded each person with a hat as she saw them.',
      'She looked at photos from the movie theater.',
    ],
    correctIndex: 2,
  ),
  _Question(
    question: 'Why do people collect data?',
    options: [
      'To make decisions and solve problems.',
      'To understand patterns and trends.',
      'To share information with others.',
      'All of the above.',
    ],
    correctIndex: 3,
  ),
];

// ===========================================================================
//  PAGE
// ===========================================================================
class DataReviewPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DataReviewPage({super.key, required this.lesson});

  @override
  State<DataReviewPage> createState() => _DataReviewPageState();
}

class _DataReviewPageState extends State<DataReviewPage> {
  int _currentQ = 0;
  int? _selectedIdx;
  int? _hoveredIdx;
  bool _submitted = false;
  int _score = 0;
  bool _isLoading = false;

  late List<_Question> _questions;

  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    final lessonNum = widget.lesson['number'];
    _questions = List.of(
      (lessonNum == 2 || lessonNum.toString() == '2')
          ? _kLesson2Questions
          : _kLesson1Questions,
    );
  }

  _Question get _q => _questions[_currentQ];
  bool get _isLast => _currentQ == _questions.length - 1;
  bool get _canNext => _submitted;

  Future<void> _loadAiQuestions() async {
    setState(() => _isLoading = true);
    final lessonNumber = widget.lesson['number'] as int;
    final slideTexts = DataLessonSlideTexts.forLesson(lessonNumber);
    if (slideTexts.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final aiData = await ApiService.generateQuizQuestions(
      lessonNumber: lessonNumber,
      slideTexts: slideTexts,
    );
    if (!mounted) return;

    if (aiData.length >= 3) {
      final newQuestions = aiData
          .map((q) => _Question(
                question: q['question'] as String,
                options: List<String>.from(q['options']),
                correctIndex: q['correctIndex'] as int,
              ))
          .toList();
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
      gameId: 'data-everywhere',
      lessonNumber: lessonNumber,
      correctAnswers: _score,
      totalQuestions: _questions.length,
    );
    await ApiService.saveLevelResult(
      gameId: 'data-everywhere',
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
          onNext: () => Navigator.of(context).pop(),
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
          _buildNavbar(lessonNumber, lessonTitle),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: _currentQ > 0 ? _prev : null,
                ),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                          color: Color(0xFF1FB5C9)),
                                      const SizedBox(height: 14),
                                      Text('Generating new questions…',
                                          style: GoogleFonts.nunito(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700)),
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

  Widget _buildNavbar(int lessonNumber, String lessonTitle) {
    return Container(
      color: const Color(0xFFFCB7C7),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(children: [
              Image.asset('assets/images/sprites/logocodey.png',
                  height: 40, fit: BoxFit.contain),
              const SizedBox(width: 24),
              Flexible(
                child: Text(
                  'DATA IS EVERYWHERE: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
          Row(children: [
            Image.asset('assets/images/sprites/avatar00.png',
                width: 36, height: 36),
            const SizedBox(width: 16),
            Image.asset('assets/images/sprites/btn_menu.png',
                width: 24, height: 24),
          ]),
        ],
      ),
    );
  }

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
          GestureDetector(
            onTap: _isLoading ? null : _loadAiQuestions,
            child: Opacity(
              opacity: _isLoading ? 0.4 : 1.0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 5),
                  Text('AI',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildTopBox(
              icon: Icons.menu_book,
              iconColor: const Color(0xFF5B8FD4),
              label: 'LEARN',
              value: lessonNumber == 2 ? '15/15' : '10/10',
              bgColor: const Color(0xFF5B8FD4).withValues(alpha: 0.15)),
          const SizedBox(width: 8),
          _buildTopBox(
              icon: Icons.sports_esports,
              iconColor: const Color(0xFF4CAF50),
              label: 'PLAY',
              value: '4/4',
              bgColor: const Color(0xFF4CAF50).withValues(alpha: 0.15)),
          const SizedBox(width: 8),
          _buildReviewBox(),
        ],
      ),
    );
  }

  Widget _buildTopBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
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
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
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
            Text('REVIEW',
                style: GoogleFonts.nunito(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
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
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333)));
                } else {
                  dotColor = Colors.white.withValues(alpha: 0.4);
                  child = null;
                }
                return Container(
                  margin: const EdgeInsets.only(right: 3),
                  width: 16,
                  height: 16,
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFD6F1F8),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0A0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8D080)),
                  ),
                  child: Text(
                    'REVIEW QUESTION #${_currentQ + 1}',
                    style: const TextStyle(
                      fontFamily: 'Chennai',
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
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A237E),
                      height: 1.4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

  Widget _buildAnswerOption(int idx) {
    final label = _labels[idx];
    final text = _q.options[idx];
    final isSelected = _selectedIdx == idx;
    final isHovered = _hoveredIdx == idx && !_submitted;
    final isCorrect = _submitted && idx == _q.correctIndex;
    final isWrong = _submitted && isSelected && idx != _q.correctIndex;
    final isDimmed = _submitted && !isSelected && idx != _q.correctIndex;

    Color circleBg;
    Color circleBorder;
    Color circleText;
    Widget? circleChild;

    if (isCorrect) {
      circleBg = Colors.white;
      circleBorder = const Color(0xFF1FB5C9);
      circleText = const Color(0xFF1FB5C9);
      circleChild = null;
    } else if (isWrong) {
      circleBg = const Color(0xFFE57373);
      circleBorder = const Color(0xFFE53935);
      circleText = Colors.white;
      circleChild = const Icon(Icons.close, color: Colors.white, size: 22);
    } else if (isDimmed) {
      circleBg = const Color(0xFFE0E0E0);
      circleBorder = const Color(0xFFBDBDBD);
      circleText = const Color(0xFFBDBDBD);
      circleChild = null;
    } else if (isSelected) {
      circleBg = const Color(0xFFFFC83D);
      circleBorder = const Color(0xFFE0A300);
      circleText = const Color(0xFF28204A);
      circleChild = null;
    } else {
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
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      );
    } else if (isCorrect) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1FB5C9), width: 2),
        ),
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1FB5C9))),
      );
    } else if (isDimmed) {
      textWidget = Text(text,
          style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFBDBDBD)));
    } else if (isSelected && !_submitted) {
      textWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFC83D), width: 2),
        ),
        child: Text(text,
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF28204A))),
      );
    } else if (isHovered) {
      textWidget = Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC83D).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(text,
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF28204A))),
          ),
        ],
      );
    } else {
      textWidget = Text(text,
          style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF28204A)));
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredIdx = idx),
      onExit: (_) => setState(() => _hoveredIdx = null),
      child: GestureDetector(
        onTap: () => _selectAnswer(idx),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: circleBorder, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: circleBorder.withValues(alpha: 0.3),
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: circleChild ??
                      Text(label,
                          style: TextStyle(
                              fontFamily: 'Chennai',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: circleText)),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(child: textWidget),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _selectedIdx != null && !_submitted;

    return GestureDetector(
      onTap: canSubmit ? _submit : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        height: 160,
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
              ? [
                  BoxShadow(
                      color: const Color(0xFFE0A300).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
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
        color: const Color(0xFF1FB5C9),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF5A623)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: enabled ? Colors.white : Colors.white38, size: 32),
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

// ===========================================================================
//  COMPLETION SCREEN
// ===========================================================================
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
          Container(
            color: const Color(0xFFFCB7C7),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(children: [
                    Image.asset('assets/images/sprites/logocodey.png',
                        height: 40, fit: BoxFit.contain),
                    const SizedBox(width: 24),
                    Flexible(
                      child: Text(
                        'DATA IS EVERYWHERE: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
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
          Container(
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
                _topBox(
                    icon: Icons.menu_book,
                    iconColor: const Color(0xFF5B8FD4),
                    label: 'LEARN',
                    value: lessonNumber == 2 ? '15/15' : '10/10',
                    bgColor:
                        const Color(0xFF5B8FD4).withValues(alpha: 0.15)),
                const SizedBox(width: 8),
                _topBox(
                    icon: Icons.sports_esports,
                    iconColor: const Color(0xFF4CAF50),
                    label: 'PLAY',
                    value: '4/4',
                    bgColor:
                        const Color(0xFF4CAF50).withValues(alpha: 0.15)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
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
                        Text('REVIEW',
                            style: GoogleFonts.nunito(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF555555))),
                        const SizedBox(height: 2),
                        Text('$total/$total',
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF333333))),
                      ],
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 780,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(48, 0, 24, 0),
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
                                      const TextSpan(
                                          text: ' correct answers'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).popUntil(
                            (route) =>
                                route.settings.name == 'data_course_hub' ||
                                route.isFirst),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE48A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE0A300), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0xFFE0A300),
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.arrow_back_ios,
                                size: 16, color: Color(0xFF28204A)),
                            const SizedBox(width: 8),
                            Text('Back to\ncourse',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF28204A))),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => Navigator.of(context).popUntil(
                            (route) =>
                                route.settings.name == 'data_course_hub' ||
                                route.isFirst),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE48A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE0A300), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0xFFE0A300),
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            Text('Next lesson',
                                style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
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

  static Widget _topBox({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color bgColor,
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
            Text(value,
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333))),
          ],
        ),
      ]),
    );
  }
}
