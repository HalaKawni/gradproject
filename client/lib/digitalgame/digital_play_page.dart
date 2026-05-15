import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DigitalPlayPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DigitalPlayPage({super.key, required this.lesson});

  @override
  State<DigitalPlayPage> createState() => _DigitalPlayPageState();
}

class _DigitalPlayPageState extends State<DigitalPlayPage> {
  // ── SPIDER SWING ──
bool _showSwing = false;
Offset _swingStart = Offset.zero;
Offset _swingEnd = Offset.zero;
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
        if (_selectedDef != null) {
          _checkMatch(word, _selectedDef!);
        }
      }
    });
  }

  void _onDefTap(String def) {
    if (_matched.values.contains(def)) return;
    setState(() {
      if (_selectedDef == def) {
        _selectedDef = null;
      } else {
        _selectedDef = def;
        _wrongDefs.remove(def);
        if (_selectedWord != null) {
          _checkMatch(_selectedWord!, def);
        }
      }
    });
  }

  void _checkMatch(String word, String def) {
    final correct =
        _pairs.firstWhere((p) => p.word == word).definition == def;
 if (correct) {
  // get positions for swing animation
  final wordBox = _wordKeys[word]?.currentContext
      ?.findRenderObject() as RenderBox?;
  final defBox = _defKeys[def]?.currentContext
      ?.findRenderObject() as RenderBox?;

  if (wordBox != null && defBox != null) {
    final wordPos = wordBox.localToGlobal(Offset(
      wordBox.size.width,
      wordBox.size.height / 2,
    ));
    final defPos = defBox.localToGlobal(Offset(
      0,
      defBox.size.height / 2,
    ));
    setState(() {
      _swingStart = wordPos;
      _swingEnd = defPos;
      _showSwing = true;
    });
  }

  _matched[word] = def;
  _lines.add(_MatchLine(word: word, def: def));
  _selectedWord = null;
  _selectedDef = null;
  _playScore = min(_playScore + 1, _playTotal);
  if (_matched.length == _pairs.length) {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _showCompletedDialog();
    });
  }
}else {
      _wrongWords.add(word);
      _wrongDefs.add(def);
      _selectedWord = null;
      _selectedDef = null;
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
            color: const Color(0xFF2C1F14),
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
                      'CODEMONKEY',
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
                      ? () => Navigator.of(context).pop()
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

          // LEARN box
          _buildTopBox(
            icon: Icons.menu_book,
            iconColor: const Color(0xFF5B8FD4),
            label: 'LEARN',
            value: '18/18',
            bgColor: const Color(0xFF5B8FD4).withOpacity(0.15),
          ),
          const SizedBox(width: 8),

          // PLAY box
          _buildPlayBox(),
          const SizedBox(width: 8),

          // REVIEW box
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
      final GlobalKey gameAreaKey = GlobalKey();

      return Stack(
        key: gameAreaKey,
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
                gameBox: gameAreaKey.currentContext
                    ?.findRenderObject() as RenderBox?,
              ),
            ),
          ),

          // ── LEFT WORDS ──
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            width: w * 0.18,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _shuffledWords.map((p) {
                final isMatched = _matched.containsKey(p.word);
                final isSelected = _selectedWord == p.word;
                final isWrong = _wrongWords.contains(p.word);

                return GestureDetector(
                  key: _wordKeys[p.word],
                  onTap: () => _onWordTap(p.word),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: w * 0.32,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 22),
                    decoration: BoxDecoration(
                      // ── CARD BACKGROUND ──
                      color: isMatched
                          ? const Color(0xFFB8EEB8)
                          : isWrong
                              ? const Color(0xFFEF9A9A)
                              : isSelected
                                  ? const Color(0xFFD1C4E9)
                                  : const Color(0xFFEAE8F5),
                      // ── ROUNDED CORNERS (pill-like as in pic 2) ──
                      borderRadius: BorderRadius.circular(22),
                      // ── THICK DARK GRAY BORDER ──
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
                      // ── SOFT DIFFUSE SHADOW ──
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
                        // ── WHITE DOT TOP-RIGHT ──
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
  
// ── ANIMAL SLIDE FROM LEFT ──
if (isSelected)
  Positioned(
    left: 140,   // ← more space for bigger image
    top: -60,     // ← extend above card so full animal shows
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
        width: 150,   // ← much bigger
        height: 150,  // ← much bigger
      ),
    ),
  ),
  
  // ── SPIDER SWING OVERLAY ──

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
                  key: _defKeys[p.definition],
                  onTap: () => _onDefTap(p.definition),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: w * 0.29,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 22),
                    decoration: BoxDecoration(
                      // ── CARD BACKGROUND ──
                      color: isMatched
                          ? const Color(0xFFB8EEB8)
                          : isWrong
                              ? const Color(0xFFEF9A9A)
                              : isSelected
                                  ? const Color(0xFFD1C4E9)
                                  : const Color(0xFFEAE8F5),
                      // ── ROUNDED CORNERS (pill-like as in pic 2) ──
                      borderRadius: BorderRadius.circular(22),
                      // ── THICK DARK GRAY BORDER ──
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
                      // ── SOFT DIFFUSE SHADOW ──
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
                        // ── WHITE DOT TOP-RIGHT ──
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
                        // ── ANIMAL SLIDE FROM LEFT ──
if (isSelected)
  Positioned(
    left: -125,   // ← more space for bigger image
    top: -45,     // ← extend above card so full animal shows
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
        'assets/images/spider.png',
        width: 150,   // ← much bigger
        height: 150,  // ← much bigger
      ),
    ),
  ),

  // ── SPIDER SWING OVERLAY ──

                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
                  if (_showSwing)
            Positioned.fill(
              child: _SpiderSwingOverlay(
                start: _swingStart,
                end: _swingEnd,
                animalAsset: 'assets/images/spider2.png',
                onDone: () {
                  if (mounted) setState(() => _showSwing = false);
                },
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
class _SpiderSwingOverlay extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String animalAsset;
  final VoidCallback onDone;

  const _SpiderSwingOverlay({
    required this.start,
    required this.end,
    required this.animalAsset,
    required this.onDone,
  });

  @override
  State<_SpiderSwingOverlay> createState() => _SpiderSwingOverlayState();
}

class _SpiderSwingOverlayState extends State<_SpiderSwingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        // spider position along the line
        final t = _progress.value;
        // arc: mid point dips down like a web swing
        final mid = Offset(
          (widget.start.dx + widget.end.dx) / 2,
          (widget.start.dy + widget.end.dy) / 2 + 80, // arc depth
        );
        // quadratic bezier
        final spiderX = (1 - t) * (1 - t) * widget.start.dx +
            2 * (1 - t) * t * mid.dx +
            t * t * widget.end.dx;
        final spiderY = (1 - t) * (1 - t) * widget.start.dy +
            2 * (1 - t) * t * mid.dy +
            t * t * widget.end.dy;

        return Stack(
          children: [
            // ── WEB LINE ──
            CustomPaint(
              size: Size.infinite,
              painter: _WebLinePainter(
                start: widget.start,
                end: Offset(spiderX, spiderY),
                mid: mid,
                progress: t,
              ),
            ),
            // ── SPIDER ──
            Positioned(
              left: spiderX - 35,
              top: spiderY - 35,
              child: Image.asset(
                widget.animalAsset,
                width: 70,
                height: 70,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WebLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Offset mid;
  final double progress;

  _WebLinePainter({
    required this.start,
    required this.end,
    required this.mid,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    // draw dashed web effect
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WebLinePainter old) => true;
}

// ── LINE PAINTER ──
class _LinePainter extends CustomPainter {
  final List<_MatchLine> lines;
  final Map<String, GlobalKey> wordKeys;
  final Map<String, GlobalKey> defKeys;
  final RenderBox? gameBox;

  _LinePainter({
    required this.lines,
    required this.wordKeys,
    required this.defKeys,
    required this.gameBox,
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

      // ── MAIN WEB LINE ──
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);

      // ── CROSS THREADS ──
      final webPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      for (double t = 0.2; t < 1.0; t += 0.2) {
        final px = (1 - t) * (1 - t) * start.dx +
            2 * (1 - t) * t * mid.dx +
            t * t * end.dx;
        final py = (1 - t) * (1 - t) * start.dy +
            2 * (1 - t) * t * mid.dy +
            t * t * end.dy;
        canvas.drawLine(
          Offset(px - 6, py - 6),
          Offset(px + 6, py + 6),
          webPaint,
        );
        canvas.drawLine(
          Offset(px + 6, py - 6),
          Offset(px - 6, py + 6),
          webPaint,
        );
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