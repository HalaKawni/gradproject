import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digital_review_page.dart';
 import '../services/api_service.dart';
 

class DigitalPlayPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DigitalPlayPage({super.key, required this.lesson});

  @override
  State<DigitalPlayPage> createState() => _DigitalPlayPageState();
}

class _DigitalPlayPageState extends State<DigitalPlayPage> {

  // ── GAME AREA KEY ──
  final GlobalKey _gameAreaKey = GlobalKey();

  // ── LINE PROGRESS ──
  final Map<String, double> _lineProgress = {};

  // ── PAIRS ──
  final List<_Pair> _pairs = [
    _Pair(
      word: 'Hardware',
      definition:
          'The physical parts of the computer, like the mouse, keyboard, and the monitor.',
    ),
    _Pair(
      word: 'Search Engines',
      definition:
          'Applications that help you find webpages for specified criteria.',
    ),
    _Pair(
      word: 'URL',
      definition: 'Unique address of a website.',
    ),
    _Pair(
      word: 'Internet',
      definition: 'Huge network of connected computers.',
    ),
  ];

  // ── STATE ──
  String? _selectedWord;
  String? _selectedDef;
  final Map<String, String> _matched = {};
  final Set<String> _wrongWords = {};
  final Set<String> _wrongDefs = {};

  // ── LINES ──
  final List<_MatchLine> _lines = [];

  // ── KEYS for line drawing ──
  final Map<String, GlobalKey> _wordKeys = {};
  final Map<String, GlobalKey> _defKeys = {};

  // ── SCORES ──
  int _playScore = 0;
  final int _playTotal = 3;
  final int _reviewScore = 0;
  final int _reviewTotal = 5;

  // ── SHUFFLED DISPLAY ORDER ──
  late List<_Pair> _shuffledWords;
  late List<_Pair> _shuffledDefs;
  
  Future<void> _saveScore() async {
    final lessonNumber = widget.lesson['number'] as int;
    await ApiService.saveWordMatchScore(
      gameId: 'digital-literacy',
      lessonNumber: lessonNumber,
      matched: _matched.length,
      total: _pairs.length,
    );
  }

  @override
  void initState() {
    super.initState();
    for (final p in _pairs) {
      _wordKeys[p.word] = GlobalKey();
      _defKeys[p.definition] = GlobalKey();
    }
    _shuffledWords = List.from(_pairs)..shuffle(Random());
    _shuffledDefs = List.from(_pairs)..shuffle(Random());
  }

  void _onWordTap(String word) {
    if (_matched.containsKey(word)) return;
    setState(() {
      if (_selectedWord == word) {
        _selectedWord = null;
      } else {
        _selectedWord = word;
        _wrongWords.remove(word);
      }
    });
    if (_selectedWord != null && _selectedDef != null) {
      _checkMatch(_selectedWord!, _selectedDef!);
    }
  }

  void _onDefTap(String def) {
    if (_matched.values.contains(def)) return;
    setState(() {
      if (_selectedDef == def) {
        _selectedDef = null;
      } else {
        _selectedDef = def;
        _wrongDefs.remove(def);
      }
    });
    if (_selectedWord != null && _selectedDef != null) {
      _checkMatch(_selectedWord!, _selectedDef!);
    }
  }

  void _checkMatch(String word, String def) {
    final correct =
        _pairs.firstWhere((p) => p.word == word).definition == def;

    if (correct) {
      setState(() {
        _matched[word] = def;
        _lines.add(_MatchLine(word: word, def: def));
        _lineProgress[word] = 0.0;
        _selectedWord = null;
        _selectedDef = null;
        _playScore = min(_playScore + 1, _playTotal);
      });

      // ── ANIMATE LINE DRAWING ──
      const steps = 30;
      int step = 0;
      Timer.periodic(const Duration(milliseconds: 16), (timer) {
        step++;
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          _lineProgress[word] = (step / steps).clamp(0.0, 1.0);
        });
        if (step >= steps) timer.cancel();
      });

       if (_matched.length == _pairs.length) {
    _saveScore(); // fire and forget
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _showCompletedDialog();
    });
  }
    } else {
      setState(() {
        _wrongWords.add(word);
        _wrongDefs.add(def);
        _selectedWord = null;
        _selectedDef = null;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _wrongWords.remove(word);
            _wrongDefs.remove(def);
          });
        }
      });
    }
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎉 Great Job!',
            style: TextStyle(fontFamily: 'Chennai', fontSize: 24)),
        content: const Text('You matched all the words correctly!',
            style: TextStyle(fontFamily: 'Chennai', fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623)),
            child: const Text('CONTINUE',
                style: TextStyle(
                    fontFamily: 'Chennai',
                    color: Colors.white,
                    fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle = widget.lesson['title'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFF7B9FD4),
      body: Column(
        children: [
          // ── CODEMONKEY NAVBAR ──
          Container(
            color: const Color.fromARGB(255, 252, 183, 199),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5E3C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pets,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'name of web',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFF5A623),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      'DIGITAL LITERACY: MINI COURSE: #$lessonNumber ${lessonTitle.toUpperCase()}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A7DBF),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.menu,
                        color: Colors.white, size: 24),
                  ],
                ),
              ],
            ),
          ),
          _buildTopBar(lessonNumber, lessonTitle),
          Expanded(
            child: Row(
              children: [
                _buildSideButton(
                  icon: Icons.arrow_back_ios,
                  label: 'PREVIOUS',
                  onTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 1170,
                      height: 700,
                      child: _buildGameArea(),
                    ),
                  ),
                ),
                _buildSideButton(
                  icon: Icons.arrow_forward_ios,
                  label: 'NEXT',
               onTap: _matched.length == _pairs.length
    ? () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DigitalReviewPage(lesson: widget.lesson),
        ),
      )
    : null,
                ),
              ],
            ),
          ),
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
          _buildTopBox(
            icon: Icons.menu_book,
            iconColor: const Color(0xFF5B8FD4),
            label: 'LEARN',
            value: '18/18',
            bgColor: const Color(0xFF5B8FD4).withOpacity(0.15),
          ),
          const SizedBox(width: 8),
          _buildPlayBox(),
          const SizedBox(width: 8),
          _buildTopBox(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFF888888),
            label: 'REVIEW',
            value: '$_reviewScore/$_reviewTotal',
            bgColor: Colors.grey.withOpacity(0.15),
            locked: true,
          ),
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
    bool locked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        children: [
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
                  const Icon(Icons.lock,
                      size: 10, color: Color(0xFF888888)),
                Text(value,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF333333))),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports,
              color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLAY',
                  style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF555555))),
              Row(
                children: List.generate(_playTotal, (i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 3),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: i < _playScore
                          ? const Color(0xFF4CAF50)
                          : i == _playScore
                              ? Colors.white
                              : Colors.grey.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: i <= _playScore
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
                          width: 1),
                    ),
                    child: i == _playScore
                        ? Center(
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333))))
                        : null,
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── GAME AREA ──
  Widget _buildGameArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return Stack(
        key: _gameAreaKey,
        clipBehavior: Clip.none,
        children: [
          // ── BACKGROUND IMAGE ──
          Image.asset(
            'assets/images/digitalbackground.png',
            width: w,
            height: h,
            fit: BoxFit.cover,
          ),

          // ── MATCH LINES ──
          Positioned.fill(
            child: CustomPaint(
              painter: _LinePainter(
                lines: _lines,
                wordKeys: _wordKeys,
                defKeys: _defKeys,
                gameBox: _gameAreaKey.currentContext
                    ?.findRenderObject() as RenderBox?,
                lineProgress: _lineProgress,
              ),
            ),
          ),

          // ── LEFT WORDS ──
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            width: w * 0.28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _shuffledWords.map((p) {
                final isMatched = _matched.containsKey(p.word);
                final isSelected = _selectedWord == p.word;
                final isWrong = _wrongWords.contains(p.word);

                return GestureDetector(
                  onTap: () => _onWordTap(p.word),
                  child: AnimatedContainer(
                    key: _wordKeys[p.word],
                    clipBehavior: Clip.none,
                    duration: const Duration(milliseconds: 200),
                    width: w * 0.28,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? const Color(0xFFB8EEB8)
                          : isWrong
                              ? const Color(0xFFEF9A9A)
                              : isSelected
                                  ? const Color(0xFFD1C4E9)
                                  : const Color(0xFFEAE8F5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7B1FA2)
                            : isMatched
                                ? const Color(0xFF4CAF50)
                                : isWrong
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF777777),
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          p.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Chennai',
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        // ── LEFT DOT ──
             
                        // ── RIGHT DOT ──
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 2,
                                  offset: const Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ── ANIMAL SLIDE IN FROM LEFT ON SELECT ──
                        if (isSelected)
                          Positioned(
                            left: 255,
                            top: -60,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: 0.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(-value * 100, 0),
                                  child: Opacity(
                                    opacity: 1 - value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/images/spider2.png',
                                width: 150,
                                height: 150,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── RIGHT DEFINITIONS ──
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            width: w * 0.32,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _shuffledDefs.map((p) {
                final isMatched =
                    _matched.values.contains(p.definition);
                final isSelected = _selectedDef == p.definition;
                final isWrong = _wrongDefs.contains(p.definition);

                return GestureDetector(
                  onTap: () => _onDefTap(p.definition),
                  child: AnimatedContainer(
                    key: _defKeys[p.definition],
                    clipBehavior: Clip.none,
                    duration: const Duration(milliseconds: 200),
                    width: w * 0.32,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 22),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? const Color(0xFFB8EEB8)
                          : isWrong
                              ? const Color(0xFFEF9A9A)
                              : isSelected
                                  ? const Color(0xFFD1C4E9)
                                  : const Color(0xFFEAE8F5),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7B1FA2)
                            : isMatched
                                ? const Color(0xFF4CAF50)
                                : isWrong
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF777777),
                        width: 4.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Text(
                          p.definition,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Chennai',
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                      
                        // ── RIGHT DOT ──
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // ── ANIMAL SLIDE IN FROM RIGHT ON SELECT ──
                        if (isSelected)
                          Positioned(
                            right: 310,
                            top: -45,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 1.0, end: 0.0),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(value * 100, 0),
                                  child: Opacity(
                                    opacity: 1 - value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Image.asset(
                                'assets/images/spider.png',
                                width: 150,
                                height: 150,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
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
}

// ── LINE PAINTER ──
class _LinePainter extends CustomPainter {
  final List<_MatchLine> lines;
  final Map<String, GlobalKey> wordKeys;
  final Map<String, GlobalKey> defKeys;
  final RenderBox? gameBox;
  final Map<String, double> lineProgress;

  _LinePainter({
    required this.lines,
    required this.wordKeys,
    required this.defKeys,
    required this.gameBox,
    required this.lineProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gameBox == null) return;

    for (final line in lines) {
      final wordCtx = wordKeys[line.word]?.currentContext;
      final defCtx = defKeys[line.def]?.currentContext;
      if (wordCtx == null || defCtx == null) continue;

      final wordBox = wordCtx.findRenderObject() as RenderBox?;
      final defBox = defCtx.findRenderObject() as RenderBox?;
      if (wordBox == null || defBox == null) continue;

      final wordPos = wordBox.localToGlobal(Offset.zero);
      final defPos = defBox.localToGlobal(Offset.zero);
      final gamePos = gameBox!.localToGlobal(Offset.zero);

      final start = Offset(
        wordPos.dx + wordBox.size.width - gamePos.dx,
        wordPos.dy + wordBox.size.height / 2 - gamePos.dy,
      );
      final end = Offset(
        defPos.dx - gamePos.dx,
        defPos.dy + defBox.size.height / 2 - gamePos.dy,
      );

      final mid = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2 + 80,
      );

      final progress = lineProgress[line.word] ?? 1.0;

      // ── MAIN WEB LINE ──
      final mainPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(start.dx, start.dy);

      Offset tip = start;
      const segments = 30;
      for (int i = 1; i <= (segments * progress).round(); i++) {
        final t = i / segments;
        final px = (1 - t) * (1 - t) * start.dx +
            2 * (1 - t) * t * mid.dx +
            t * t * end.dx;
        final py = (1 - t) * (1 - t) * start.dy +
            2 * (1 - t) * t * mid.dy +
            t * t * end.dy;
        path.lineTo(px, py);
        tip = Offset(px, py);
      }
      canvas.drawPath(path, mainPaint);

      // ── GLOWING DOT AT TIP WHILE ANIMATING ──
      if (progress < 1.0) {
        final dotPaint = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(tip, 6, dotPaint);
      }

      // ── CROSS THREADS ONCE COMPLETE ──
      if (progress >= 1.0) {
        final webPaint = Paint()
          ..color = Colors.white.withOpacity(0.45)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

        for (double t = 0.15; t < 1.0; t += 0.18) {
          final px = (1 - t) * (1 - t) * start.dx +
              2 * (1 - t) * t * mid.dx +
              t * t * end.dx;
          final py = (1 - t) * (1 - t) * start.dy +
              2 * (1 - t) * t * mid.dy +
              t * t * end.dy;
          canvas.drawLine(
            Offset(px - 7, py - 7),
            Offset(px + 7, py + 7),
            webPaint,
          );
          canvas.drawLine(
            Offset(px + 7, py - 7),
            Offset(px - 7, py + 7),
            webPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

// ── DATA CLASSES ──
class _Pair {
  final String word;
  final String definition;
  _Pair({required this.word, required this.definition});
}

class _MatchLine {
  final String word;
  final String def;
  _MatchLine({required this.word, required this.def});
}