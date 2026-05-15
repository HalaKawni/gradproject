import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digital_play_page.dart';

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
  int? _hoveredDot;

  // Quiz state — tracks selected answer per slide index
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _hoveredAnswers = {};
  // Survey state
  int? _surveyAnswer;
  bool _surveySubmitted = false;

  // ── SLIDE DEFINITIONS ──
  List<_SlideData> get _slides {
    final int lessonNumber = widget.lesson['number'] as int;
    switch (lessonNumber) {
      case 1:
        return [
          _SlideData.image(title: 'Digital Use In A Nutshell',     imagePath: 'assets/images/1.jpeg'),
          _SlideData.image(title: 'What is a Computer?',           imagePath: 'assets/images/2.jpeg'),
          _SlideData.image(title: 'Hardware vs. Software',         imagePath: 'assets/images/3.jpeg'),

          // ── SLIDE 4: CORNER QUESTION ──
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'How is hardware different than software?',
            answers: [
              'Hardware is silver.',
              'Hardware is a physical object.',
              'Hardware always contains electronics.',
              'Hardware is harder to design.',
            ],
            correctIndex: 1,
          ),

          _SlideData.image(title: 'The Internet',                  imagePath: 'assets/images/5.jpeg'),
          _SlideData.image(title: 'Email Fundamentals',            imagePath: 'assets/images/6.jpeg'),
          _SlideData.image(title: 'File Organization',             imagePath: 'assets/images/7.jpeg'),
          _SlideData.image(title: 'Useful Applications',           imagePath: 'assets/images/8.jpeg'),

          // ── SLIDE 9: CORNER QUESTION ──
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'If you are looking for information on all the animals that live in caves, what should you search for?',
            answers: [
              'bats',
              'dark caves',
              'animals',
              'animals caves',
            ],
            correctIndex: 3,
          ),

          _SlideData.image(title: 'Lesson 10',                     imagePath: 'assets/images/10.jpeg'),

          // ── SLIDE 11: SURVEY QUESTION ──
          _SlideData.survey(
            title: 'Survey Question',
            question: 'Have you sent an email before?',
            answers: [
              'Yes, I email all the time.',
              'Yes, I\'ve emailed a few times.',
              'No, I prefer sending letters through the regular mail. Stamps rock!',
              'No, but I know I will soon.',
            ],
            percentages: [22, 42, 10, 26],
          ),

          _SlideData.image(title: 'Lesson 12',                     imagePath: 'assets/images/12.jpeg'),
          _SlideData.image(title: 'Lesson 13',                     imagePath: 'assets/images/13.jpeg'),
          _SlideData.image(title: 'Lesson 14',                     imagePath: 'assets/images/14.jpeg'),
          _SlideData.image(title: 'Lesson 15',                     imagePath: 'assets/images/15.jpeg'),
          _SlideData.image(title: 'Lesson 16',                     imagePath: 'assets/images/16.jpeg'),
          _SlideData.image(title: 'Lesson 17',                     imagePath: 'assets/images/17.jpeg'),
          _SlideData.image(title: 'Lesson 18',                     imagePath: 'assets/images/18.jpeg'),
        ];
      case 2:
        return [
          _SlideData.image(title: 'Digital Citizenship In A Nutshell', imagePath: 'assets/images/1.jpeg'),
          _SlideData.image(title: 'What is Digital Citizenship?',      imagePath: 'assets/images/2.jpeg'),
          _SlideData.image(title: 'Online Safety',                     imagePath: 'assets/images/3.jpeg'),
          _SlideData.image(title: 'Being Respectful Online',           imagePath: 'assets/images/5.jpeg'),
          _SlideData.image(title: 'Cyberbullying',                     imagePath: 'assets/images/6.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/7.jpeg'),
          _SlideData.image(title: 'Useful Applications',               imagePath: 'assets/images/8.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/10.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/12.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/13.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/14.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/15.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/16.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/17.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/18.jpeg'),
        ];
      case 3:
        return [
          _SlideData.image(title: 'Digital Collaboration',             imagePath: 'assets/images/1.jpeg'),
          _SlideData.image(title: 'What is Digital Collaboration?',    imagePath: 'assets/images/2.jpeg'),
          _SlideData.image(title: 'Collaboration Tools',               imagePath: 'assets/images/3.jpeg'),
          _SlideData.image(title: 'Effective Communication',           imagePath: 'assets/images/5.jpeg'),
          _SlideData.image(title: 'Sharing Documents',                 imagePath: 'assets/images/6.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/7.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/8.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/10.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/12.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/13.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/14.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/15.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/16.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/17.jpeg'),
          _SlideData.image(title: 'Lesson Summary',                    imagePath: 'assets/images/18.jpeg'),
        ];
      default:
        return [_SlideData.image(title: 'Lesson', imagePath: 'assets/images/1.jpeg')];
    }
  }

  bool _canGoNext() {
    final slide = _slides[_currentSlide];
    if (slide.type == SlideType.cornerQuestion) {
      return _selectedAnswers.containsKey(_currentSlide);
    }
    if (slide.type == SlideType.survey) {
      return _surveySubmitted;
    }
    return true;
  }

  void _nextSlide() {
    if (!_canGoNext()) return;
    if (_currentSlide < _slides.length - 1) {
      setState(() {
        _currentSlide++;
        _surveyAnswer = null;
        _surveySubmitted = false;
      });
    } else {
      Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (_) => DigitalPlayPage(lesson: widget.lesson),
  ),
);
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
        _surveyAnswer = null;
        _surveySubmitted = false;
      });
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
  child: _buildSlideContent(slide),
),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: _currentSlide == totalSlides - 1 ? 'FINISH' : 'NEXT',
                  onTap: _canGoNext() ? _nextSlide : null,
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
          // Back button
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
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
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

          // Lesson number + title
          Text('#$lessonNumber',
              style: GoogleFonts.nunito(
                  color: const Color(0xFF333333),
                  fontSize: 16,
                  fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: GoogleFonts.nunito(
                  color: const Color(0xFF333333),
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 500),

          // LEARN + dots
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B8FD4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 4),
                  Text('LEARN',
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF555555),
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: List.generate(totalSlides, (i) {
                  final bool isCompleted = i < _currentSlide;
                  final bool isCurrent = i == _currentSlide;
                  final bool isHovered = _hoveredDot == i;

                  return MouseRegion(
                    onEnter: (_) => setState(() => _hoveredDot = i),
                    onExit: (_) => setState(() => _hoveredDot = null),
                    child: GestureDetector(
                      onTap: isCompleted ? () => setState(() => _currentSlide = i) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 3),
                        width: isCurrent ? 24 : 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isHovered && isCompleted
                              ? const Color(0xFFFFD700)
                              : isCompleted
                                  ? const Color(0xFF4DD0C4)
                                  : isCurrent
                                      ? Colors.white
                                      : const Color(0xFF9BB8D4),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isCurrent
                              ? [BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.star,
                                  color: isHovered ? Colors.white : const Color(0xFF2C8A7A),
                                  size: 11)
                              : isCurrent
                                  ? Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333)))
                                  : Icon(Icons.lock,
                                      color: Colors.white.withOpacity(0.6), size: 10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const Spacer(),

          _buildScoreBox('PLAY', _playScore, 3, Icons.sports_esports),
          const SizedBox(width: 8),
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
          Row(children: [
            Icon(icon, color: const Color(0xFF555555), size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.nunito(
                    color: const Color(0xFF555555),
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
          ]),
          Row(children: [
            const Icon(Icons.lock, color: Color(0xFF888888), size: 10),
            const SizedBox(width: 2),
            Text('$score/$total',
                style: GoogleFonts.nunito(
                    color: const Color(0xFF555555),
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ]),
        ],
      ),
    );
  }

  // ── SLIDE CONTENT ROUTER ──
  Widget _buildSlideContent(_SlideData slide) {
    switch (slide.type) {
      case SlideType.image:
        return _buildImageSlide(slide);
      case SlideType.cornerQuestion:
        return _buildCornerQuestion(slide);
      case SlideType.survey:
        return _buildSurveyQuestion(slide);
    }
  }

  // ── IMAGE SLIDE ──
  Widget _buildImageSlide(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          slide.imagePath!,
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
                  const Icon(Icons.image, color: Colors.white54, size: 80),
                  const SizedBox(height: 16),
                  Text(slide.title,
                      style: GoogleFonts.nunito(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CORNER QUESTION SLIDE ──
  Widget _buildCornerQuestion(_SlideData slide) {
    final selectedIdx = _selectedAnswers[_currentSlide];
    final answered = selectedIdx != null;

    return Container(
  margin: EdgeInsets.zero,
decoration: const BoxDecoration(
  color: Colors.white,
),
      child: SingleChildScrollView(
        child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── CORNER QUESTION badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0A0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8D080)),
                ),
                child: Text(
                  'CORNER QUESTION',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF888844),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Question ──
              Text(
                slide.question!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),

              if (!answered)
                Text(
                  'Select the correct answer',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 24),

              // ── Answer buttons ──
              ...List.generate(slide.answers!.length, (i) {
                final isSelected = selectedIdx == i;
                final isCorrect = i == slide.correctIndex;
                final isWrong = answered && isSelected && !isCorrect;
                final showCorrect = answered && isCorrect;

             Color btnColor = const Color(0xFFADE8F4);
if (answered && isSelected && isCorrect) {
  btnColor = const Color(0xFF26A69A);
}

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // ── Left indicator ──
                SizedBox(
  width: 44,
  child: answered
      ? (showCorrect
          ? Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4DD0C4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star,
                  color: Colors.white, size: 22),
            )
          : const SizedBox())
      : const SizedBox(),
),

                      // ── Answer button ──
Expanded(
  child: MouseRegion(
    onEnter: (_) => setState(() => _hoveredAnswers.add(i)),
    onExit: (_) => setState(() => _hoveredAnswers.remove(i)),
    child: GestureDetector(
      onTap: answered
          ? null
          : () => setState(
              () => _selectedAnswers[_currentSlide] = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: answered && isSelected && isCorrect
              ? const Color(0xFF26A69A)
              : _hoveredAnswers.contains(i) && !answered
                  ? const Color(0xFF80D8E8)
                  : const Color(0xFFADE8F4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            slide.answers![i],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: answered && isSelected && isCorrect
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
      ),
    ),
  ),
),
                      // ── Right star for correct ──
                  const SizedBox(width: 44),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── SURVEY QUESTION SLIDE ──
  Widget _buildSurveyQuestion(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
          child: Column(
            children: [
              // ── SURVEY QUESTION badge ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0A0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8D080)),
                ),
                child: Text(
                  'SURVEY QUESTION',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF888844),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Question ──
              Text(
                slide.question!,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              if (!_surveySubmitted) ...[
  const SizedBox(height: 16),
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 60),
    child: GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 4.5,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(slide.answers!.length, (i) {
        final isSelected = _surveyAnswer == i;
        return GestureDetector(
          onTap: () => setState(() => _surveyAnswer = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF26A69A)
                  : const Color(0xFF80CBC4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  slide.answers![i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Chennai',
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  ),
  const SizedBox(height: 32),

  // Submit button
  GestureDetector(
    onTap: _surveyAnswer != null
        ? () => setState(() => _surveySubmitted = true)
        : null,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
      decoration: BoxDecoration(
        color: _surveyAnswer != null
            ? const Color(0xFFFFF0A0)
            : const Color(0xFFEEEECC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D080)),
      ),
      child: Text(
        'Submit Your Answer',
        style: const TextStyle(
          fontFamily: 'Chennai',
          fontSize: 18,
          color: Color(0xFF666600),
        ),
      ),
    ),
  ),

              ] else ...[
                // ── Results view ──
                Text(
                  'You answered "${slide.answers![_surveyAnswer!]}", see how other CodeMonkey users answered',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 4.5,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(slide.answers!.length, (i) {
                    final pct = slide.percentages![i];
                    final isChosen = _surveyAnswer == i;

                    // Colors matching screenshot
                    final List<Color> barColors = [
                      const Color(0xFF29B6F6),
                      const Color(0xFFFFD54F),
                      const Color(0xFF29B6F6),
                      const Color(0xFF29B6F6),
                    ];
                    final List<Color> bgColors = [
                      const Color(0xFFB3E5FC),
                      const Color(0xFFFFF9C4),
                      const Color(0xFFB3E5FC),
                      const Color(0xFFB3E5FC),
                    ];

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColors[i],
                        borderRadius: BorderRadius.circular(10),
                      ),
                     child: Row(
  children: [
    // Narrow colored bar on left
    Container(
      width: 55,
      height: double.infinity,
      decoration: BoxDecoration(
        color: barColors[i],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
        ),
      ),
    ),
    // Text
    Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          slide.answers![i],
          style: const TextStyle(
            fontFamily: 'Chennai',
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
      ),
    ),
    // Percentage
    Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Text(
        '$pct%',
        style: const TextStyle(
          fontFamily: 'Chennai',
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    ),
  ],
),
                      );
                  }),
                ),
              ],
            ],
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
                  : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
                  Text('LISTEN MODE',
                      style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => setState(() => _listenMode = !_listenMode),
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
                                color: Colors.white, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(_listenMode ? 'ON' : 'OFF',
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Text('${_currentSlide + 1} / ${_slides.length}',
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('',
              style: GoogleFonts.nunito(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── SLIDE TYPES ──
enum SlideType { image, cornerQuestion, survey }

// ── SLIDE DATA MODEL ──
class _SlideData {
  final String title;
  final SlideType type;
  final String? imagePath;
  final String? question;
  final List<String>? answers;
  final int? correctIndex;
  final List<int>? percentages;

  _SlideData._({
    required this.title,
    required this.type,
    this.imagePath,
    this.question,
    this.answers,
    this.correctIndex,
    this.percentages,
  });

  factory _SlideData.image({required String title, required String imagePath}) {
    return _SlideData._(title: title, type: SlideType.image, imagePath: imagePath);
  }

  factory _SlideData.cornerQuestion({
    required String title,
    required String question,
    required List<String> answers,
    required int correctIndex,
  }) {
    return _SlideData._(
      title: title,
      type: SlideType.cornerQuestion,
      question: question,
      answers: answers,
      correctIndex: correctIndex,
    );
  }

  factory _SlideData.survey({
    required String title,
    required String question,
    required List<String> answers,
    required List<int> percentages,
  }) {
    return _SlideData._(
      title: title,
      type: SlideType.survey,
      question: question,
      answers: answers,
      percentages: percentages,
    );
  }
}