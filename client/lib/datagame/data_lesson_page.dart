import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_play_page.dart';
import 'data_play_page_lesson2.dart';

class DataLessonPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final int initialSlide;
  final bool skipToPlay;
  const DataLessonPage(
      {super.key, required this.lesson, this.initialSlide = 0, this.skipToPlay = false});

  @override
  State<DataLessonPage> createState() => _DataLessonPageState();
}

class _DataLessonPageState extends State<DataLessonPage> {
  late int _currentSlide;
  bool _listenMode = false;
  int _playScore = 0;
  int _reviewScore = 0;
  int? _hoveredDot;

  final FlutterTts _tts = FlutterTts();
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _hoveredAnswers = {};
  int? _surveyAnswer;
  bool _surveySubmitted = false;
  final TextEditingController _openAnswerController = TextEditingController();
  bool _openAnswerSubmitted = false;

  String get _slideKey => 'data_lesson_slide_${widget.lesson['number']}';

  @override
  void initState() {
    super.initState();
    _currentSlide = widget.initialSlide;
    _initTts();
    if (widget.skipToPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _navigateToPlay());
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.50);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.05);
    try {
      final dynamic result = await _tts.getVoices;
      if (result is List && result.isNotEmpty) {
        Map? best;
        for (final v in result) {
          if (v is! Map) continue;
          final name = (v['name'] ?? '').toString().toLowerCase();
          if (name.contains('aria') || name.contains('jenny') ||
              name.contains('guy') || name.contains('natural')) {
            best = v;
            break;
          }
        }
        best ??= result.firstWhere(
          (v) => v is Map && (v['locale'] ?? '').toString().startsWith('en'),
          orElse: () => null,
        ) as Map?;
        if (best != null) {
          await _tts.setVoice({
            'name': best['name'].toString(),
            'locale': (best['locale'] ?? 'en-US').toString(),
          });
        }
      }
    } catch (_) {}
  }

  String _slideText(_SlideData slide) {
    switch (slide.type) {
      case SlideType.image:
        return slide.narration ?? slide.title;
      case SlideType.cornerQuestion:
      case SlideType.survey:
        final buf = StringBuffer('${slide.question} ');
        for (var i = 0; i < slide.answers!.length; i++) {
          buf.write('Option ${i + 1}: ${slide.answers![i]}. ');
        }
        return buf.toString();
      case SlideType.openQuestion:
        return slide.question!;
    }
  }

  Future<void> _speakSlide() async {
    final text = _slideText(_slides[_currentSlide]);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _stopSpeaking() async => await _tts.stop();

  Future<void> _saveSlide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_slideKey, _currentSlide);
  }

  Future<void> _clearSlide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_slideKey, -1);
  }

  void _navigateToPlay() {
    final lessonNumber = widget.lesson['number'] as int;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => lessonNumber == 2
          ? DataPlayPageLesson2(lesson: widget.lesson)
          : DataPlayPage(lesson: widget.lesson),
    ));
  }

  @override
  void dispose() {
    _tts.stop();
    _openAnswerController.dispose();
    super.dispose();
  }

  // ── SLIDE DEFINITIONS ──
  List<_SlideData> get _slides {
    final int lessonNumber = widget.lesson['number'] as int;
    switch (lessonNumber) {
      case 1:
        return [
          _SlideData.image(
            title: 'Collecting Data',
            imagePath: 'assets/images/course21.jpeg',
            narration: 'Today, we will explore the first step in Data Science: Collecting Data. The topic of collecting data involves understanding different forms of data and some methods for collecting it.',
          ),
          _SlideData.survey(
            title: 'Survey Question',
            question: 'Do you know what data is',
            answers: [
              'Yes, of course.',
              "I'm not sure.",
              'I have never heard the term before.',
            ],
            percentages: [60, 27, 13],
          ),
          _SlideData.image(
            title: 'How Do You Pronounce Data?',
            imagePath: 'assets/images/course23.jpeg',
            narration: 'How do you pronounce data? Some say dat-uh, others say day-tuh. Both are correct! Just like how different people have different ways of doing the same thing.',
          ),
          _SlideData.image(
            title: 'There Are Two Types of Data',
            imagePath: 'assets/images/course24.jpeg',
            narration: 'Data represented by numbers is called numerical data. Data that is not represented by numbers is called non-numerical data.',
          ),
          _SlideData.image(
            title: 'Numerical Data',
            imagePath: 'assets/images/course25.jpeg',
            narration: 'You gather numerical data when you count things. How many pets does each person have? How many chocolate chips are in each cookie? How often does the cafeteria serve pizza? You also gather numerical data when you measure things. How tall is each student in the class? What was the daily temperature for the last 30 days? How many miles did we walk each week?',
          ),
          _SlideData.image(
            title: 'Non-numerical Data',
            imagePath: 'assets/images/course26.jpeg',
            narration: 'You gather non-numerical data when you describe things. What kind of pets does each person have? What is your favorite type of cookie? What three words would describe your favorite day? You also gather non-numerical data when you sort things, like sorting your favorite food into categories of veggie, fruit, snack, and dessert.',
          ),
          _SlideData.image(
            title: 'Data Answers Questions',
            imagePath: 'assets/images/course27.jpeg',
            narration: 'Pick which data to collect based on the questions you want to answer. For example, a city building a new park collects data to answer: What playground equipment should be included? Should we include a picnic area? Data to collect from residents: Age of children, top three playground activities, and likelihood of using picnic tables.',
          ),
          _SlideData.image(
            title: 'Why Do We Collect Data?',
            imagePath: 'assets/images/course28.jpeg',
            narration: 'Data helps us make decisions and plan for the future. A weather agency collects the rainfall amount of every city in the world for every day of the year. Why? So they can use the historical data to predict rainfall in the future.',
          ),
          _SlideData.survey(
            title: 'Survey Question',
            question: 'Have you ever collected data yourself?',
            answers: [
              'Yes, I track things all the time!',
              'Yes, but only a little.',
              'No, but I would like to try.',
              'No, I do not think I ever have.',
            ],
            percentages: [35, 30, 22, 13],
          ),
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'You collect the ages of everyone going to your birthday party. What type of data are you collecting?',
            answers: [
              'Non-numerical Data',
              'Numerical Data',
              'Alphanumeric Data',
              'Binary Data',
            ],
            correctIndex: 1,
          ),
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'As you opened your gifts, you created a list of who gave you which gift. What type of data are you collecting?',
            answers: [
              'Non-numerical Data',
              'Numerical Data',
              'Alphanumeric Data',
              'Binary Data',
            ],
            correctIndex: 0,
          ),
          _SlideData.image(
            title: 'We All Collect Data',
            imagePath: 'assets/images/course212.jpeg',
            narration: 'Sonia tracks the amount of books she reads each month. She is trying to meet a yearly goal. Craig collects data on his favorite basketball players. He likes to be able to predict how a player will match up to different opponents. Parents collect the height of their children over the years, sometimes marking a wall when doing so. It is fun and rewarding to see their children grow.',
          ),
          _SlideData.image(
            title: 'Many Reasons to Collect Data',
            imagePath: 'assets/images/course213.jpeg',
            narration: 'It seems like there are many reasons why people collect data. Yes, it is often used to help make decisions or plan for the future. Do you collect any data? I collect data on all the plastic I find in the swamp so I can complain to the next human I meet.',
          ),
          _SlideData.image(
            title: 'How Do We Collect Data?',
            imagePath: 'assets/images/course214.jpeg',
            narration: 'Questionnaire: You can create a list of questions to collect data from a group of people. Observation: You can write down data while observing a situation like a science experiment. Research: You can go to the library or search the internet for data on a topic. Sensors: You can track data by using a device like a phone or pedometer.',
          ),
          _SlideData.image(
            title: 'Data Science is a Career',
            imagePath: 'assets/images/course215.jpeg',
            narration: 'The world is full of data! Data Scientists specialize in methods for collecting, organizing, and applying the data. They assist in predicting the weather, understanding how people use the internet, or even helping doctors find better ways to treat diseases. Data science is like being a detective of information. It is all about collecting clues, finding patterns, and using them to learn new things about the world. Pretty cool, huh?',
          ),
          _SlideData.image(
            title: 'Data Science Around Us',
            imagePath: 'assets/images/course216.jpeg',
            narration: 'Data science is everywhere! From the apps on your phone to the recommendations you see online, data scientists are working behind the scenes to make sense of all the information in the world. Maybe you will be a data scientist one day!',
          ),
          _SlideData.openQuestion(
            title: 'Open Question',
            question: 'What data do you collect in your life, and how do you use it?',
          ),
          _SlideData.image(
            title: 'Great Work!',
            imagePath: 'assets/images/course218.jpeg',
            narration: 'Amazing job completing the Collecting Data lesson! You have learned what data is, the two types of data, why we collect it, and how we collect it. Now you are ready to play and test your knowledge!',
          ),
        ];

      case 2:
        return [
          _SlideData.image(
            title: 'Organizing Data',
            imagePath: 'assets/images/data2.png',
            narration: 'In this lesson, we learn how to organize data. Once we collect data, we need to arrange it so that it is easy to read and understand. Organized data helps us find patterns and make decisions.',
          ),
          _SlideData.image(
            title: 'Why Organize Data?',
            imagePath: 'assets/images/data2.png',
            narration: 'Imagine having a big pile of papers with numbers written on them. It would be very hard to find anything! When we organize data into charts and graphs, we can quickly see patterns, make comparisons, and draw conclusions.',
          ),
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'Why do we organize data into charts and graphs?',
            answers: [
              'To make it look colorful.',
              'To make it easier to understand and find patterns.',
              'To hide information from others.',
              'Because computers cannot store numbers.',
            ],
            correctIndex: 1,
          ),
          _SlideData.image(
            title: 'Bar Graphs',
            imagePath: 'assets/images/data2.png',
            narration: 'A bar graph uses rectangular bars to compare different categories. The taller the bar, the larger the value. For example, we could use a bar graph to compare how many students prefer different subjects.',
          ),
          _SlideData.image(
            title: 'Pie Charts',
            imagePath: 'assets/images/data2.png',
            narration: 'A pie chart is a circle divided into slices. Each slice represents a part of the whole. The bigger the slice, the bigger the share. Pie charts are great for showing how something is divided into parts.',
          ),
          _SlideData.survey(
            title: 'Survey Question',
            question: 'Which type of graph do you find easiest to read?',
            answers: [
              'Bar graph',
              'Pie chart',
              'Line graph',
              'I find them all confusing!',
            ],
            percentages: [45, 25, 20, 10],
          ),
          _SlideData.image(
            title: 'Line Graphs',
            imagePath: 'assets/images/data2.png',
            narration: 'A line graph shows how data changes over time. Points are plotted and then connected with a line. If the line goes up, the value is increasing. If it goes down, the value is decreasing.',
          ),
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'Which graph would you use to show how the temperature changed every day for a week?',
            answers: [
              'Pie chart',
              'Bar graph',
              'Line graph',
              'Tally chart',
            ],
            correctIndex: 2,
          ),
          _SlideData.image(
            title: 'Frequency Tables',
            imagePath: 'assets/images/data2.png',
            narration: 'A frequency table organizes data into rows and columns. It shows how often each value appears in a data set. Frequency tables make it easy to compare groups and see which value occurs most.',
          ),
          _SlideData.openQuestion(
            title: 'Open Question',
            question: 'If you wanted to show your classmates\' favorite colors, which type of graph would you choose and why?',
          ),
        ];

      default:
        return [_SlideData.image(title: 'Lesson', imagePath: 'assets/images/data1.png')];
    }
  }

  bool _canGoNext() {
    final slide = _slides[_currentSlide];
    if (slide.type == SlideType.cornerQuestion) return _selectedAnswers.containsKey(_currentSlide);
    if (slide.type == SlideType.survey) return _surveySubmitted;
    if (slide.type == SlideType.openQuestion) return _openAnswerSubmitted;
    return true;
  }

  void _nextSlide() {
    if (!_canGoNext()) return;
    if (_currentSlide < _slides.length - 1) {
      setState(() {
        _currentSlide++;
        _surveyAnswer = null;
        _surveySubmitted = false;
        _openAnswerSubmitted = false;
        _openAnswerController.clear();
      });
      _saveSlide();
      if (_listenMode) _speakSlide();
    } else {
      _stopSpeaking();
      _clearSlide();
      _navigateToPlay();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
        _surveyAnswer = null;
        _surveySubmitted = false;
        _openAnswerSubmitted = false;
        _openAnswerController.clear();
      });
      _saveSlide();
      if (_listenMode) _speakSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentSlide];
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;
    final totalSlides = _slides.length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255,123, 127, 212),
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
                Expanded(child: _buildSlideContent(slide)),
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

  Widget _buildTopBar(int lessonNumber, String lessonTitle, int totalSlides) {
    return Container(
      color: const Color(0xFFADE8F4),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil(
                (route) => route.settings.name == 'data_course_hub' || route.isFirst),
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
              style: GoogleFonts.nunito(
                  color: const Color(0xFF333333),
                  fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Text(lessonTitle,
              style: GoogleFonts.nunito(
                  color: const Color(0xFF333333),
                  fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(width: 500),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFF5B8FD4),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 4),
                Text('LEARN',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF555555),
                        fontSize: 10, fontWeight: FontWeight.w800)),
              ]),
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
                      onTap: isCompleted
                          ? () { setState(() => _currentSlide = i); _saveSlide(); }
                          : null,
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
                              ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.star,
                                  color: isHovered ? Colors.white : const Color(0xFF2C8A7A),
                                  size: 11)
                              : isCurrent
                                  ? Text('${i + 1}',
                                      style: const TextStyle(fontSize: 9,
                                          fontWeight: FontWeight.bold, color: Color(0xFF333333)))
                                  : Icon(Icons.lock,
                                      color: Colors.white.withValues(alpha: 0.6), size: 10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const Spacer(),
          _buildScoreBox('PLAY', _playScore, lessonNumber == 1 ? 2 : 3, Icons.sports_esports),
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
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
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
                    fontSize: 10, fontWeight: FontWeight.w800)),
          ]),
          Row(children: [
            const Icon(Icons.lock, color: Color(0xFF888888), size: 10),
            const SizedBox(width: 2),
            Text('$score/$total',
                style: GoogleFonts.nunito(
                    color: const Color(0xFF555555),
                    fontSize: 11, fontWeight: FontWeight.w800)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSlideContent(_SlideData slide) {
    switch (slide.type) {
      case SlideType.image:
        return _buildImageSlide(slide);
      case SlideType.cornerQuestion:
        return _buildCornerQuestion(slide);
      case SlideType.survey:
        return _buildSurveyQuestion(slide);
      case SlideType.openQuestion:
        return _buildOpenQuestion(slide);
    }
  }

  Widget _buildImageSlide(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(slide.imagePath!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                  color: const Color(0xFF8B9FD4),
                  borderRadius: BorderRadius.circular(16)),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white54, size: 80),
                    const SizedBox(height: 16),
                    Text(slide.title,
                        style: GoogleFonts.nunito(
                            color: Colors.white70,
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    if (slide.narration != null) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Text(slide.narration!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                                color: Colors.white60,
                                fontSize: 15, fontWeight: FontWeight.w500, height: 1.6)),
                      ),
                    ],
                  ],
                ),
              ),
            )),
      ),
    );
  }

  Widget _buildCornerQuestion(_SlideData slide) {
    final selectedIdx = _selectedAnswers[_currentSlide];
    final answered = selectedIdx != null;

    return Container(
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 200, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0A0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8D080)),
                ),
                child: Text('CORNER QUESTION',
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: const Color(0xFF888844), letterSpacing: 1)),
              ),
              const SizedBox(height: 28),
              Text(slide.question!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.black87, height: 1.4)),
              const SizedBox(height: 8),
              if (!answered)
                Text('Select the correct answer',
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              ...List.generate(slide.answers!.length, (i) {
                final isSelected = selectedIdx == i;
                final isCorrect = i == slide.correctIndex;
                final showCorrect = answered && isCorrect;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: answered
                            ? (showCorrect
                                ? Container(
                                    width: 36, height: 36,
                                    decoration: const BoxDecoration(
                                        color: Color(0xFF4DD0C4), shape: BoxShape.circle),
                                    child: const Icon(Icons.star, color: Colors.white, size: 22))
                                : const SizedBox())
                            : const SizedBox(),
                      ),
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredAnswers.add(i)),
                          onExit: (_) => setState(() => _hoveredAnswers.remove(i)),
                          child: GestureDetector(
                            onTap: answered
                                ? null
                                : () => setState(() => _selectedAnswers[_currentSlide] = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              decoration: BoxDecoration(
                                color: answered && isSelected && isCorrect
                                    ? const Color(0xFF26A69A)
                                    : _hoveredAnswers.contains(i) && !answered
                                        ? const Color(0xFF80D8E8)
                                        : const Color(0xFFADE8F4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(slide.answers![i],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                        fontSize: 17, fontWeight: FontWeight.w600,
                                        color: answered && isSelected && isCorrect
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildSurveyQuestion(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0A0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8D080)),
                ),
                child: Text('SURVEY QUESTION',
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: const Color(0xFF888844), letterSpacing: 1)),
              ),
              const SizedBox(height: 28),
              Text(slide.question!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
              const SizedBox(height: 24),
              if (!_surveySubmitted) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: _buildSurveyOptionGrid(slide),
                ),
                const SizedBox(height: 32),
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
                    child: const Text('Submit Your Answer',
                        style: TextStyle(
                            fontFamily: 'Chennai', fontSize: 18, color: Color(0xFF666600))),
                  ),
                ),
              ] else ...[
                Text(
                  'You answered "${slide.answers![_surveyAnswer!]}", see how other users answered',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                _buildSurveyResultGrid(slide),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyOptionGrid(_SlideData slide) {
    final answers = slide.answers!;
    final rows = <Widget>[];
    for (int i = 0; i < answers.length; i += 2) {
      final isLast = i + 1 >= answers.length;
      Widget row;
      if (isLast) {
        row = Center(
          child: FractionallySizedBox(
            widthFactor: 0.5,
            child: _buildSurveyOptionButton(i, answers[i]),
          ),
        );
      } else {
        row = Row(children: [
          Expanded(child: _buildSurveyOptionButton(i, answers[i])),
          const SizedBox(width: 12),
          Expanded(child: _buildSurveyOptionButton(i + 1, answers[i + 1])),
        ]);
      }
      rows.add(row);
      if (i + 2 < answers.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildSurveyOptionButton(int index, String text) {
    final isSelected = _surveyAnswer == index;
    return GestureDetector(
      onTap: () => setState(() => _surveyAnswer = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF26A69A) : const Color(0xFF80CBC4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Chennai', fontSize: 20, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildSurveyResultGrid(_SlideData slide) {
    final answers = slide.answers!;
    final List<Color> barColors = [
      const Color(0xFFFFD54F),
      const Color(0xFF29B6F6),
      const Color(0xFF29B6F6),
      const Color(0xFF29B6F6),
    ];
    final List<Color> bgColors = [
      const Color(0xFFFFF9C4),
      const Color(0xFFB3E5FC),
      const Color(0xFFB3E5FC),
      const Color(0xFFB3E5FC),
    ];

    Widget resultItem(int i) {
      final pct = slide.percentages![i];
      return Container(
        height: 64,
        decoration: BoxDecoration(
            color: bgColors[i % bgColors.length],
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Container(
            width: 55,
            height: double.infinity,
            decoration: BoxDecoration(
              color: barColors[i % barColors.length],
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(answers[i],
                  style: const TextStyle(
                      fontFamily: 'Chennai', fontSize: 20, color: Colors.black87)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text('$pct%',
                style: const TextStyle(
                    fontFamily: 'Chennai',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87)),
          ),
        ]),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < answers.length; i += 2) {
      final isLast = i + 1 >= answers.length;
      Widget row;
      if (isLast) {
        row = Center(
          child: FractionallySizedBox(widthFactor: 0.5, child: resultItem(i)),
        );
      } else {
        row = Row(children: [
          Expanded(child: resultItem(i)),
          const SizedBox(width: 12),
          Expanded(child: resultItem(i + 1)),
        ]);
      }
      rows.add(row);
      if (i + 2 < answers.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }

  Widget _buildOpenQuestion(_SlideData slide) {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0A0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8D080)),
                  ),
                  child: const Text('OPEN QUESTION',
                      style: TextStyle(fontFamily: 'Chennai', fontSize: 13,
                          color: Color(0xFF888844), letterSpacing: 1)),
                ),
                const SizedBox(height: 32),
                Text(slide.question!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.black87, height: 1.4)),
                const SizedBox(height: 24),
                Text('Enter your answer below:',
                    style: GoogleFonts.nunito(fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF4A90C4), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _openAnswerController,
                    maxLines: 5,
                    enabled: !_openAnswerSubmitted,
                    style: GoogleFonts.nunito(fontSize: 16),
                    decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _openAnswerController,
                  builder: (context, _) {
                    final canSubmit = _openAnswerController.text.trim().isNotEmpty &&
                        !_openAnswerSubmitted;
                    return GestureDetector(
                      onTap: canSubmit
                          ? () => setState(() => _openAnswerSubmitted = true)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        decoration: BoxDecoration(
                          color: _openAnswerSubmitted
                              ? Colors.grey.withValues(alpha: 0.3)
                              : canSubmit
                                  ? const Color(0xFFFFC83D)
                                  : const Color(0xFFEEEECC),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: canSubmit && !_openAnswerSubmitted
                              ? [const BoxShadow(color: Color(0xFFE0A300), offset: Offset(0, 4))]
                              : [],
                        ),
                        child: Text('Submit Your Answer',
                            style: GoogleFonts.nunito(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: canSubmit && !_openAnswerSubmitted
                                    ? const Color(0xFF28204A)
                                    : Colors.grey)),
                      ),
                    );
                  },
                ),
              ],
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
        width: 100, height: double.infinity,
        color: const Color(0xFF7B7FD4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFF5A623) : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 32),
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

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFF6B7FBF).withValues(alpha: 0.5),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('LISTEN MODE',
                    style: GoogleFonts.nunito(
                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    setState(() => _listenMode = !_listenMode);
                    if (_listenMode) _speakSlide(); else _stopSpeaking();
                  },
                  child: Container(
                    width: 48, height: 24,
                    decoration: BoxDecoration(
                      color: _listenMode ? const Color(0xFF4DD0C4) : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: _listenMode ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(2),
                          width: 20, height: 20,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          Text('${_currentSlide + 1} / ${_slides.length}',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          const SizedBox(),
        ],
      ),
    );
  }
}

// ── SLIDE TYPES ──
enum SlideType { image, cornerQuestion, survey, openQuestion }

// ── SLIDE DATA MODEL ──
class _SlideData {
  final String title;
  final SlideType type;
  final String? imagePath;
  final String? narration;
  final String? question;
  final List<String>? answers;
  final int? correctIndex;
  final List<int>? percentages;

  _SlideData._({
    required this.title, required this.type,
    this.imagePath, this.narration, this.question,
    this.answers, this.correctIndex, this.percentages,
  });

  factory _SlideData.image({required String title, required String imagePath, String? narration}) =>
      _SlideData._(title: title, type: SlideType.image, imagePath: imagePath, narration: narration);

  factory _SlideData.cornerQuestion({
    required String title, required String question,
    required List<String> answers, required int correctIndex,
  }) => _SlideData._(title: title, type: SlideType.cornerQuestion,
      question: question, answers: answers, correctIndex: correctIndex);

  factory _SlideData.survey({
    required String title, required String question,
    required List<String> answers, required List<int> percentages,
  }) => _SlideData._(title: title, type: SlideType.survey,
      question: question, answers: answers, percentages: percentages);

  factory _SlideData.openQuestion({required String title, required String question}) =>
      _SlideData._(title: title, type: SlideType.openQuestion, question: question);
}
