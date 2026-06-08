import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'digital_play_page.dart';
import 'digitalplaypagelesson2.dart';
import 'digital_play_page_lesson3.dart';

class DigitalLessonPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final int initialSlide;
  final bool skipToPlay;
  const DigitalLessonPage({super.key, required this.lesson, this.initialSlide = 0, this.skipToPlay = false});

  @override
  State<DigitalLessonPage> createState() => _DigitalLessonPageState();
}

class _DigitalLessonPageState extends State<DigitalLessonPage> {
  late int _currentSlide;
  bool _listenMode = false;
  int _playScore = 0;
  int _reviewScore = 0;
  int? _hoveredDot;

  final FlutterTts _tts = FlutterTts();

  // Corner question state
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _hoveredAnswers = {};

  // Survey state
  int? _surveyAnswer;
  bool _surveySubmitted = false;

  // Open question state
  final TextEditingController _openAnswerController = TextEditingController();
  bool _openAnswerSubmitted = false;

  String get _slideKey => 'lesson_slide_${widget.lesson['number']}';

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
    // Prefer Microsoft neural voices (Aria, Jenny, Guy) — much less robotic on Windows 11
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

  Future<void> _stopSpeaking() async {
    await _tts.stop();
  }

  Future<void> _saveSlide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_slideKey, _currentSlide);
  }

  Future<void> _clearSlide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_slideKey, -1); // -1 = slides done, play page is next
  }

  void _navigateToPlay() {
    final lessonNumber = widget.lesson['number'] as int;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => lessonNumber == 2
          ? DigitalPlayPageLesson2(lesson: widget.lesson)
          : lessonNumber == 3
              ? DigitalPlayPageLesson3(lesson: widget.lesson)
              : DigitalPlayPage(lesson: widget.lesson),
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
            title: 'Digital Use In A Nutshell',
            imagePath: 'assets/images/1.jpeg',
            narration: 'In this lesson, we review: What a computer is. Hardware versus software. How the internet and the World Wide Web work. Email fundamentals. File organization. And useful applications for students.',
          ),
          _SlideData.image(
            title: 'What is a Computer?',
            imagePath: 'assets/images/2.jpeg',
            narration: 'What is a computer and what does it do? A computer is an information processing machine. It listens, thinks, and then speaks — well, sort of. A computer takes input from the user, processes that input, and then outputs the results to the user.',
          ),
          _SlideData.image(
            title: 'Hardware vs. Software',
            imagePath: 'assets/images/3.jpeg',
            narration: 'Computers combine hardware and software. Hardware refers to all the physical parts of the computer. Software refers to all the programs you use on your computer.',
          ),
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
          _SlideData.image(
            title: 'The Internet',
            imagePath: 'assets/images/5.jpeg',
            narration: 'The internet is amazing. But how does it work — is it a humongous software application? Actually, the internet is a massive network of computers connected by cables, wires, and other hardware. The World Wide Web and websites are the software that runs on those computers.',
          ),
          _SlideData.image(
            title: 'Email Fundamentals',
            imagePath: 'assets/images/6.jpeg',
            narration: 'You can send an email to many people, called recipients. There are different types of recipients. TO are your main recipients — you might want a reply from them. CC, or Carbon Copy, recipients get a copy of your email, but they are not your main audience. BCC, or Blind Carbon Copy, works like CC, but the TO and CC recipients will not know there are additional people receiving the email. The B in BCC means blind.',
          ),
          _SlideData.image(
            title: 'File Organization',
            imagePath: 'assets/images/7.jpeg',
            narration: 'Your computer and the cloud store lots and lots of documents, called files. It is useful to organize files using folders. These folders are organized using hierarchy, and can be sorted in many ways — such as by title, date created, and date last opened.',
          ),
          _SlideData.image(
            title: 'Useful Applications',
            imagePath: 'assets/images/8.jpeg',
            narration: 'Useful applications for students include: Word Processing — customize text documents in word processing applications. Spreadsheets — enter, organize, sort, calculate, and program your data. And Presentations — create a fantastic slideshow for your next presentation.',
          ),
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
          _SlideData.image(
            title: 'So Many Files',
            imagePath: 'assets/images/10.jpeg',
            narration: 'Wow, that is a lot of files! No wonder we need to organize them. But where do files come from? Every document you create is a file. Also, every application that runs on your computer is made up of several files.',
          ),
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
          _SlideData.image(
            title: 'Emails',
            imagePath: 'assets/images/12.jpeg',
            narration: 'Emails are electronic messages sent over the internet. You need an email address to send and receive emails. Email is one of the most widely used ways to communicate online.',
          ),
          _SlideData.image(
            title: 'Email Organization',
            imagePath: 'assets/images/13.jpeg',
            narration: 'Email applications organize your emails using different storage folders. The Inbox Folder stores your incoming emails — it is important to check it regularly. The Sent Folder stores a copy of the emails you have sent, which comes in handy sometimes. The Drafts Folder stores emails you plan on sending but have not finished writing yet. If you started an email and cannot find it, check your drafts folder.',
          ),
          _SlideData.image(
            title: 'Tips for Students and Everyone Else',
            imagePath: 'assets/images/14.jpeg',
            narration: 'Here are some tips for students and everyone else about using the internet safely and effectively.',
          ),
          _SlideData.image(
            title: 'Search Engines',
            imagePath: 'assets/images/15.jpeg',
            narration: 'Since the World Wide Web is so big, how do you find what you are looking for? We have search engines for that! Search engines are applications that specialize in finding information that matches the keywords you enter. It is important to use descriptive words when looking for information.',
          ),
          _SlideData.image(
            title: 'Websites are Made of Webpages',
            imagePath: 'assets/images/16.jpeg',
            narration: 'Websites are made of webpages. Websites are created with a language called HTML, which stands for HyperText Markup Language. Each website has a unique address called a URL, or Uniform Resource Locator. You view web pages by using a browser application. Browsers like Chrome and Edge have lots of handy features to improve your experience.',
          ),
          _SlideData.image(
            title: 'Using the Internet',
            imagePath: 'assets/images/17.jpeg',
            narration: 'When using the internet, you need a web browser like Chrome, Safari, or Edge. The internet connects millions of computers through a network. You can use search engines like Yahoo, Google, or Bing to find information.',
          ),
          _SlideData.image(title: 'Lesson 18', imagePath: 'assets/images/18.jpeg'),
        ];

      case 2:
        return [
          _SlideData.image(title: 'Digital Citizenship in a Nutshell', imagePath: 'assets/images/lesson21.jpeg'),
          _SlideData.image(title: 'Digital Citizenship',               imagePath: 'assets/images/lesson22.jpeg'),
          _SlideData.image(title: 'Digital Citizenship',               imagePath: 'assets/images/lesson23.jpeg'),
          _SlideData.image(title: 'Digital Citizenship',               imagePath: 'assets/images/lesson24.jpeg'),
          _SlideData.openQuestion(
            title: 'Open Question',
            question: 'What are your favorite activities when you are away from your computer or digital device?',
          ),
          _SlideData.image(title: 'Be Safe on the Internet',           imagePath: 'assets/images/lesson26.jpeg'),
          _SlideData.image(title: 'Be Friendly on the Internet',       imagePath: 'assets/images/lesson27.jpeg'),
          _SlideData.image(title: 'Be Responsible on the Internet',    imagePath: 'assets/images/lesson28.jpeg'),
          _SlideData.survey(
            title: 'Survey Question',
            question: 'Have you heard of the email threat called "phishing"?',
            answers: ['Yes.', 'No.', 'What does that mean?'],
            percentages: [35, 31, 34],
          ),
          _SlideData.image(title: 'Online Threats',                    imagePath: 'assets/images/lesson210.jpeg'),
          _SlideData.image(title: 'Phishing is a Type of Email Scam',  imagePath: 'assets/images/lesson211.jpeg'),
          _SlideData.image(title: 'Is it Real?',                       imagePath: 'assets/images/lesson212.jpeg'),
          _SlideData.image(title: 'Misinformation',                    imagePath: 'assets/images/lesson213.jpeg'),
          _SlideData.cornerQuestion(
            title: 'Corner Question',
            question: 'Why do some websites have passwords?',
            answers: [
              'Some websites store private information, and they only want it accessed by specific people who have registered.',
              'Websites like to snoop on people\'s passwords.',
              'Websites want to appear complicated.',
              'Passwords are for secret clubs.',
            ],
            correctIndex: 0,
          ),
          _SlideData.image(title: 'Passwords',                         imagePath: 'assets/images/lesson215.jpeg'),
          _SlideData.image(title: 'Passwords',                         imagePath: 'assets/images/lesson216.jpeg'),
          _SlideData.image(title: 'Passwords',                         imagePath: 'assets/images/lesson217.jpeg'),
        ];

     case 3:
  return [
    _SlideData.image(title: 'Digital Collaboration',              imagePath: 'assets/images/lesson31.png'),
    _SlideData.image(title: 'What is Collaboration?',             imagePath: 'assets/images/lesson33.jpeg'),
    _SlideData.image(title: 'What is Digital Collaboration?',     imagePath: 'assets/images/lesson312.png'),
    _SlideData.survey(
      title: 'Survey Question',
      question: 'Do you know what "collaboration" means?',
      answers: [
        'I\'m not sure; it\'s a pretty big word.',
        'It\'s when a group of people share ideas and input on a project.',
        'It\'s when you work on a project by yourself.',
        'I have heard the word, but I am not 100% sure of its meaning.',
      ],
      percentages: [20, 60, 4, 16],
    ),
    _SlideData.image(title: 'How?',                               imagePath: 'assets/images/lesson34.jpeg'),
    _SlideData.image(title: 'Applications\' Collaboration Feature', imagePath: 'assets/images/lesson310.png'),
    _SlideData.image(title: 'Video Conferencing Technology',      imagePath: 'assets/images/lesson37.jpeg'),
    _SlideData.image(title: 'Global Trends Influence Technology', imagePath: 'assets/images/lesson38.jpeg'),
    _SlideData.image(title: 'What is a Trend?',                   imagePath: 'assets/images/lesson310.png'),
    _SlideData.image(title: 'Why do Global Trends Influence Technology', imagePath: 'assets/images/lesson36.jpeg'),
    _SlideData.image(title: 'Is Virtual Reality a Trend?',        imagePath: 'assets/images/lesson312.png'),
    _SlideData.image(title: 'Digital Collaboration Etiquette',    imagePath: 'assets/images/lesson39.jpeg'),
    _SlideData.image(title: 'Digital Collaboration Etiquette 2',  imagePath: 'assets/images/lesson311.jpeg'),
  ];

      default:
        return [_SlideData.image(title: 'Lesson', imagePath: 'assets/images/1.jpeg')];
    }
  }

  // ── CAN GO NEXT ──
  bool _canGoNext() {
    final slide = _slides[_currentSlide];
    if (slide.type == SlideType.cornerQuestion) {
      return _selectedAnswers.containsKey(_currentSlide);
    }
    if (slide.type == SlideType.survey) {
      return _surveySubmitted;
    }
    if (slide.type == SlideType.openQuestion) {
      return _openAnswerSubmitted;
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
                  label: 'digital.previous'.tr(),
                  onTap: _currentSlide > 0 ? _prevSlide : null,
                ),
                Expanded(child: _buildSlideContent(slide)),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: _currentSlide == totalSlides - 1 ? 'digital.finish'.tr() : 'digital.next'.tr(),
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
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
            child: Container(
              width: 52, height: 52,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8FD4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
                  Text('digital.back_to_course'.tr(),
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
          Flexible(
            child: Text(lessonTitle,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                    color: const Color(0xFF333333),
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B8FD4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 4),
                  Text('digital.learn'.tr(),
                      style: GoogleFonts.nunito(
                          color: const Color(0xFF555555),
                          fontSize: 10, fontWeight: FontWeight.w800)),
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
                      onTap: isCompleted ? () { setState(() => _currentSlide = i); _saveSlide(); } : null,
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
                              ? [BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4)]
                              : [],
                        ),
                        child: Center(
                          child: isCompleted
                              ? Icon(Icons.star,
                                  color: isHovered
                                      ? Colors.white
                                      : const Color(0xFF2C8A7A),
                                  size: 11)
                              : isCurrent
                                  ? Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333)))
                                  : Icon(Icons.lock,
                                      color: Colors.white.withOpacity(0.6),
                                      size: 10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const Spacer(),
          _buildScoreBox('digital.play'.tr(), _playScore, 3, Icons.sports_esports),
          const SizedBox(width: 8),
          _buildScoreBox('digital.review'.tr(), _reviewScore, 5, Icons.chat_bubble_outline),
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

  // ── SLIDE CONTENT ROUTER ──
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
                          fontSize: 18, fontWeight: FontWeight.w600)),
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
                child: Text('digital.corner_question'.tr(),
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
                Text('digital.select_correct'.tr(),
                    style: GoogleFonts.nunito(
                        fontSize: 14, color: Colors.black54,
                        fontWeight: FontWeight.w500)),
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
                                        color: Color(0xFF4DD0C4),
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.star,
                                        color: Colors.white, size: 22))
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

  // ── SURVEY QUESTION SLIDE ──
  Widget _buildSurveyQuestion(_SlideData slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
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
                child: Text('digital.survey_question'.tr(),
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w800,
                        color: const Color(0xFF888844), letterSpacing: 1)),
              ),
              const SizedBox(height: 28),
              Text(slide.question!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.black87)),
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
                              child: Text(slide.answers![i],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontFamily: 'Chennai',
                                      fontSize: 20, color: Colors.white)),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _surveyAnswer != null
                      ? () => setState(() => _surveySubmitted = true)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 18),
                    decoration: BoxDecoration(
                      color: _surveyAnswer != null
                          ? const Color(0xFFFFF0A0)
                          : const Color(0xFFEEEECC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8D080)),
                    ),
                    child: Text('digital.submit_answer'.tr(),
                        style: const TextStyle(
                            fontFamily: 'Chennai',
                            fontSize: 18, color: Color(0xFF666600))),
                  ),
                ),
              ] else ...[
                Text(
                  'digital.survey_result'.tr(namedArgs: {'answer': slide.answers![_surveyAnswer!]}),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 15, color: Colors.black54,
                      fontWeight: FontWeight.w500),
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
                          color: bgColors[i % bgColors.length],
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Container(
                            width: 55, height: double.infinity,
                            decoration: BoxDecoration(
                              color: barColors[i % barColors.length],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              child: Text(slide.answers![i],
                                  style: const TextStyle(
                                      fontFamily: 'Chennai',
                                      fontSize: 20, color: Colors.black87)),
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

  // ── OPEN QUESTION SLIDE ──
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
                  child: Text('digital.open_question'.tr(),
                      style: const TextStyle(
                          fontFamily: 'Chennai', fontSize: 13,
                          color: Color(0xFF888844), letterSpacing: 1)),
                ),
                const SizedBox(height: 32),
                Text(slide.question!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: Colors.black87, height: 1.4)),
                const SizedBox(height: 24),
                Text('digital.enter_answer'.tr(),
                    style: GoogleFonts.nunito(
                        fontSize: 15, color: Colors.black54)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF7B5DC2), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _openAnswerController,
                    maxLines: 5,
                    enabled: !_openAnswerSubmitted,
                    style: GoogleFonts.nunito(fontSize: 16),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: _openAnswerController,
                  builder: (context, _) {
                    final canSubmit =
                        _openAnswerController.text.trim().isNotEmpty &&
                            !_openAnswerSubmitted;
                    return GestureDetector(
                      onTap: canSubmit
                          ? () => setState(() => _openAnswerSubmitted = true)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        decoration: BoxDecoration(
                          color: _openAnswerSubmitted
                              ? Colors.grey.withOpacity(0.3)
                              : canSubmit
                                  ? const Color(0xFFFFC83D)
                                  : const Color(0xFFEEEECC),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: canSubmit && !_openAnswerSubmitted
                              ? [const BoxShadow(
                                  color: Color(0xFFE0A300),
                                  offset: Offset(0, 4))]
                              : [],
                        ),
                        child: Text('digital.submit_answer'.tr(),
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
        width: 100, height: double.infinity,
        color: const Color(0xFF7B7FD4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFFF5A623)
                    : Colors.grey.withOpacity(0.3),
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
                  Text('digital.listen_mode'.tr(),
                      style: GoogleFonts.nunito(
                          color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      setState(() => _listenMode = !_listenMode);
                      if (_listenMode) {
                        _speakSlide();
                      } else {
                        _stopSpeaking();
                      }
                    },
                    child: Container(
                      width: 48, height: 24,
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
                            width: 20, height: 20,
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
              Text(_listenMode ? 'digital.on'.tr() : 'digital.off'.tr(),
                  style: GoogleFonts.nunito(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Text('${_currentSlide + 1} / ${_slides.length}',
              style: GoogleFonts.nunito(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700)),
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
    required this.title,
    required this.type,
    this.imagePath,
    this.narration,
    this.question,
    this.answers,
    this.correctIndex,
    this.percentages,
  });

  factory _SlideData.image({
    required String title,
    required String imagePath,
    String? narration,
  }) {
    return _SlideData._(title: title, type: SlideType.image, imagePath: imagePath, narration: narration);
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

  factory _SlideData.openQuestion({
    required String title,
    required String question,
  }) {
    return _SlideData._(
      title: title,
      type: SlideType.openQuestion,
      question: question,
    );
  }
}