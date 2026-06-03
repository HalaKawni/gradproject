import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digitalplaypagelesson2wordmatch.dart';
import '../services/api_service.dart';
import 'lesson_slide_texts.dart';

// ── COLORS ──────────────────────────────────────────────────────────────────
class _C {
  static const ink      = Color(0xFF0B0820);
  static const ink2     = Color(0xFF1A1340);
  static const paper    = Color(0xFFFFF6D8);
  static const gold     = Color(0xFFFFD23A);
  static const safe     = Color(0xFF56E07A);
  static const safeD    = Color(0xFF1D8A3A);
  static const risk     = Color(0xFFFF5470);
  static const riskD    = Color(0xFFA82045);
  static const cyan     = Color(0xFF56D3FF);
  static const cyanD    = Color(0xFF1A78B8);
  static const purple   = Color(0xFFB266FF);
  static const orange   = Color(0xFFFF8A3A);
  static const deepBlue = Color(0xFF3A2680);
  static const sender   = Color(0xFF9A4CD8);
}

// ── PIXEL PALETTE ────────────────────────────────────────────────────────────
Color? _px(String ch) {
  switch (ch) {
    case 'K': return const Color(0xFF0B0820);
    case 'W': return const Color(0xFFFFFFFF);
    case 'C': return const Color(0xFF56D3FF);
    case 'G': return const Color(0xFF56E07A);
    case 'R': return const Color(0xFFFF5470);
    case 'Y': return const Color(0xFFFFD23A);
    case 'P': return const Color(0xFFB266FF);
    case 'O': return const Color(0xFFFF8A3A);
    case 'B': return const Color(0xFF3A2680);
    case 'S': return const Color(0xFF9A4CD8);
    case 'T': return const Color(0xFFC4A04A);
    default:  return null;
  }
}

// ── CONCEPTS ─────────────────────────────────────────────────────────────────
class _Concept {
  final String text;
  final bool positive;
  final String sender;
  final String preview;
  final List<String> icon;
  const _Concept({
    required this.text, required this.positive,
    required this.sender, required this.preview, required this.icon,
  });
}

const _kFallbackConcepts = [
  _Concept(
    text: "STRONG\nPASSWORD", positive: true,
    sender: "PASSGUARD",
    preview: "Your password is 16 chars with symbols. Logged in safely.",
    icon: [
      "................","................",".....KKKKKK.....",
      "....K......K....","....K.WWWW.K....","....K.W..W.K....",
      "...KKKKKKKKKK...","...KYYYYYYYYK...","...KYYKWWKYYK...",
      "...KYYWKKWYYK...","...KYYWKKWYYK...","...KYYKWWKYYK...",
      "...KYYYYYYYYK...","...KKKKKKKKKK...","................","................"
    ],
  ),
  _Concept(
    text: "FRIENDLY\nFRIENDS", positive: true,
    sender: "MIA + JAY",
    preview: "Hey wanna study together this weekend?",
    icon: [
      "................","....KKKK....KKKK","...KGGGGK..KCCCC",
      "..KGWGGWGK.KCWWC","..KGGGGGGK.KCWWC","..KGWWWWGK.KCWWC",
      "..KGGGGGGK.KCCCC","...KGGGGK..KCCCC","....KKKK....KKKK",
      "..KGGGGGGGGGGGK.",".KGGYGGYGGYGGYK.",".KGGGGGGGGGGGGK.",
      "..KGGGGGGGGGGK..","...KKKKKKKKKK...","................","................"
    ],
  ),
  _Concept(
    text: "LIMIT\nDIGITAL USE", positive: true,
    sender: "WELLBEING",
    preview: "You've used 1 hr today. Time for a break!",
    icon: [
      "................","....KKKKKKKK....","...KCCCCCCCCK...",
      "..KCWWWCWWWWCK..","..KCWWWCWWWWCK..",".KCWWWWCWWWWWCK.",
      ".KCWWWWCKKWWWCK.",".KCWWWWCKWWWWCK.",".KCWWWWCWWWWWCK.",
      ".KCWWWWWWWWWWCK.","..KCWWWWWWWWCK..","..KCWWWCWWWWCK...",
      "...KCCCCCCCCK....","....KKKKKKKK....","................","................"
    ],
  ),
  _Concept(
    text: "FAKE\nNEWS", positive: false,
    sender: "BREAKING!!!",
    preview: "YOU WON A FREE iPHONE! CLICK HERE TO CLAIM NOW",
    icon: [
      "................",".KKKKKKKKKKKKKK.",".KWWWWWWWWWWWWK.",
      ".KWKKKKWKKKKKWK.",".KWKWWWWWWWKWWK.",".KWKKKKKKKKKWWK.",
      ".KWKWWWWWWWKWWK.",".KWKKKKKKKKKWWK.",".KWWWWWWWWWWWWK.",
      ".KWWWWWWWWWWWWK.",".KKKKKKKKKKKKKK.","....RKR....RKR..",
      ".....KR....RK...","....RKR....RKR...","...RK.K....K.KR.","................"
    ],
  ),
  _Concept(
    text: "PHISHING", positive: false,
    sender: "BANK-SUPPORT",
    preview: "Verify your account NOW or it will be locked. Click link.",
    icon: [
      "................","..KK............","..KK....KK......",
      "..KK....KK......","..KKKKKKKKK.....","......KK.......",
      "......KK........",".....KK.........","....KK..........",
      "....KK..........","....KK..........","....KK..........",
      ".....KKK.......W",".KK...KKK.....WW",".KKK...KKKKKKKK.","..KKKKK........."
    ],
  ),
  _Concept(
    text: "SHARE WITH\nSTRANGERS", positive: false,
    sender: "UNKNOWN_USER",
    preview: "Hey kid, what's your address? Want a free gift?",
    icon: [
      "................","................",".....KKKKKKKK...",
      "....K........K..","....K.WW..WW.K..","....K..WW.WW.K..",
      "....K.WW..WW.K..","....K..WW.WW.K..",".....KKKKKKKK...",
      "....KKKKKKKKKK..","...KKBBBBBBBBKK.","..KKBBBBBBBBBBKK",
      "..KBBBBBBBBBBBBK","..KBBBBBBBBBBBBK","..KKKKKKKKKKKKKK","................"
    ],
  ),
  _Concept(
    text: "CYBER-\nBULLYING", positive: false,
    sender: "MEAN-MSG",
    preview: "Ur such a loser nobody likes u",
    icon: [
      "................","..KKKKKKKKKKK...",".KRRRRRRRRRRRK..",
      ".KRRKKRKKRRRRK..",".KRRKKRKKRRRRK..",".KRRRRRRRRRRRK..",
      ".KRRRKKKKKRRRK..",".KRRRRRRRRRRRK..",".KKKKKKKKKKKKK..",
      "...KK...........","....KK..........",".....KK.........",
      "......KKKKKK....","................","................","................"
    ],
  ),
];

// ── PIXEL ICON PAINTER ────────────────────────────────────────────────────────
class _PixelIconPainter extends CustomPainter {
  final List<String> grid;
  const _PixelIconPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 16;
    final paint = Paint();
    for (int y = 0; y < grid.length; y++) {
      final row = grid[y];
      for (int x = 0; x < row.length; x++) {
        final color = _px(row[x]);
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell, cell),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelIconPainter old) => false;
}

// ── STAR PAINTER ─────────────────────────────────────────────────────────────
class _StarData {
  final double x, y, size;
  final Color color;
  final double delay;
  _StarData(this.x, this.y, this.size, this.color, this.delay);
}

// ── GRID FLOOR PAINTER ───────────────────────────────────────────────────────
class _GridFloorPainter extends CustomPainter {
  final double scrollOffset;
  _GridFloorPainter(this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient fade
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x0056D3FF), Color(0x2956D3FF), Color(0x6B56D3FF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradPaint);

    // Grid lines
    final linePaint = Paint()
      ..color = const Color(0xFF56D3FF).withOpacity(0.55)
      ..strokeWidth = 1;
    const gridSize = 12.0;
    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    // Horizontal lines (scrolling)
    final offset = scrollOffset % gridSize;
    for (double y = -gridSize + offset; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GridFloorPainter old) => old.scrollOffset != scrollOffset;
}

// ── PIXEL BOX DECORATION ─────────────────────────────────────────────────────
// Mimics CSS pixel-shadow borders (like NES style)
BoxDecoration _pixelBox({
  required Color bg,
  required Color border,
  Color? shadow,
  double bw = 2,
}) {
  return BoxDecoration(
    color: bg,
    border: Border.all(color: border, width: bw),
    boxShadow: shadow != null
        ? [BoxShadow(color: shadow, offset: const Offset(0, 4), blurRadius: 0)]
        : null,
  );
}

// ── MAIN PAGE ─────────────────────────────────────────────────────────────────
class DigitalPlayPageLesson2 extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DigitalPlayPageLesson2({super.key, required this.lesson});

  @override
  State<DigitalPlayPageLesson2> createState() => _DigitalPlayPageLesson2State();
}

class _DigitalPlayPageLesson2State extends State<DigitalPlayPageLesson2>
    with TickerProviderStateMixin {

  // ── Game state ──
  late List<int> _order;
  int _idx = 0;
  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _correct = 0;
  bool _running = false;
  bool _locked = false;

  // ── Timer ──
  double _timer = 8.0;
  bool _timerActive = false;
  Timer? _gameTimer;

  // ── Overlays ──
  bool _showTitle = true;
  bool _showEnd = false;

  // ── Card animation ──
  // 0=normal, 1=fly-safe, 2=fly-risk
  int _cardAnim = 0;
  bool _cardVisible = false;

  // ── Flash ──
  Color? _flashColor;
  bool _flashVisible = false;

  // ── Phone shake ──
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // ── Combo banner ──
  bool _showCombo = false;
  String _comboText = '';
  late AnimationController _comboCtrl;
  late Animation<double> _comboAnim;

  // ── Card fly animation ──
  late AnimationController _flyCtrl;
  late Animation<Offset> _flyAnim;
  late Animation<double> _flyRotAnim;
  late Animation<double> _flyOpacity;

  // ── Card enter animation ──
  late AnimationController _enterCtrl;
  late Animation<Offset> _enterAnim;
  late Animation<double> _enterOpacity;

  // ── Grid floor scroll ──
  late AnimationController _gridCtrl;
  double _gridScroll = 0;

  // ── Stars ──
  late List<_StarData> _stars;
  late AnimationController _starCtrl;
  late List<Animation<double>> _starAnims;

  // ── Particles ──
  final List<_Particle> _particles = [];

  // ── Clock ──
  String _clock = '';
  Timer? _clockTimer;

  // ── Button press states ──
  bool _safePressed = false;
  bool _riskPressed = false;

  // ── AI ──
  List<_Concept> _concepts = List.of(_kFallbackConcepts);
  bool _isLoading = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 20),
    ]).animate(_shakeCtrl);

    _comboCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _comboAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_comboCtrl);

    _flyCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _flyAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_flyCtrl);
    _flyRotAnim = Tween<double>(begin: 0, end: 0).animate(_flyCtrl);
    _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _enterAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    _gridCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _gridCtrl.addListener(() {
      setState(() => _gridScroll = _gridCtrl.value * 12);
    });

    // Stars
    _stars = [
      _StarData(24, 14, 2, Colors.white, 0.1),
      _StarData(60, 30, 2, Colors.white, 0.6),
      _StarData(108, 8, 2, const Color(0xFF86D6FF), 1.2),
      _StarData(150, 42, 2, Colors.white, 0.3),
      _StarData(200, 18, 3, const Color(0xFFFFE27A), 0.9),
      _StarData(252, 26, 2, const Color(0xFF86D6FF), 1.5),
      _StarData(300, 10, 2, Colors.white, 0.4),
      _StarData(330, 36, 3, const Color(0xFFFFE27A), 1.0),
      _StarData(18, 74, 2, Colors.white, 1.8),
      _StarData(336, 80, 2, const Color(0xFF86D6FF), 0.5),
    ];
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _starAnims = _stars.map((s) =>
      Tween<double>(begin: 0.95, end: 0.25).animate(
        CurvedAnimation(
          parent: _starCtrl,
          curve: Interval(
            (s.delay / 2.4).clamp(0, 1),
            ((s.delay / 2.4) + 0.5).clamp(0, 1),
          ),
        ),
      ),
    ).toList();

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _comboCtrl.dispose();
    _flyCtrl.dispose();
    _enterCtrl.dispose();
    _gridCtrl.dispose();
    _starCtrl.dispose();
    _gameTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _clock =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  List<int> _shuffled() {
    final list = List.generate(_concepts.length, (i) => i);
    for (int i = list.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = list[i]; list[i] = list[j]; list[j] = tmp;
    }
    return list;
  }

  _Concept get _current => _concepts[_order[_idx]];

  void _startGame() {
    _order = _shuffled();
    setState(() {
      _idx = 0; _score = 0; _lives = 3;
      _combo = 0; _maxCombo = 0; _correct = 0;
      _running = true; _locked = false;
      _showTitle = false; _showEnd = false;
      _cardAnim = 0; _cardVisible = false;
      _particles.clear();
    });
    _nextRound();
  }

  void _nextRound() {
    if (_idx >= _concepts.length || _lives <= 0) {
      _endGame();
      return;
    }
    setState(() {
      _locked = false;
      _timer = 8.0;
      _timerActive = true;
      _cardAnim = 0;
    });
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        if (_running && _timerActive) {
          _timer -= 0.1;
          if (_timer <= 0) {
            _timer = 0;
            _timerActive = false;
            _answer(false);
          }
        }
      });
    });
    _showCardIn();
  }

  void _showCardIn() {
    setState(() => _cardVisible = true);
    _enterCtrl.forward(from: 0);
  }

  void _answer(bool allow) {
    if (!_running || _locked || !_cardVisible) return;
    setState(() { _locked = true; _timerActive = false; });
    _gameTimer?.cancel();

    final correct = (allow && _current.positive) || (!allow && !_current.positive);

    // Fly card off
    final flyEnd = allow
        ? const Offset(1.2, -0.3)
        : const Offset(-1.2, -0.3);
    final flyRot = allow ? 0.6 : -0.6;

    _flyAnim = Tween<Offset>(begin: Offset.zero, end: flyEnd)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
    _flyRotAnim = Tween<double>(begin: 0, end: flyRot)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
    setState(() => _cardAnim = allow ? 1 : 2);
    _flyCtrl.forward(from: 0);

    // Flash
    setState(() {
      _flashColor = correct ? _C.safe.withOpacity(0.55) : _C.risk.withOpacity(0.55);
      _flashVisible = true;
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _flashVisible = false);
    });

    if (correct) {
      _correct++;
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      final gain = 100 + (_combo > 1 ? (_combo - 1) * 50 : 0);
      setState(() => _score += gain);
      if (_combo >= 2) {
        setState(() {
          _comboText = 'x$_combo COMBO! +$gain';
          _showCombo = true;
        });
        _comboCtrl.forward(from: 0).then((_) {
          if (mounted) setState(() => _showCombo = false);
        });
      }
      _spawnParticles(true);
    } else {
      setState(() => _combo = 0);
      setState(() => _lives = (_lives - 1).clamp(0, 3));
      _shakeCtrl.forward(from: 0);
      _spawnParticles(false);
    }

    // Remove card after anim
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _cardVisible = false);
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _idx++);
        _nextRound();
      }
    });
  }

  void _spawnParticles(bool good) {
    final colors = good
        ? [_C.safe, _C.gold, Colors.white, _C.cyan]
        : [_C.risk, _C.orange, Colors.white, _C.riskD];
    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * pi * 2;
      final dist = 40.0 + _rng.nextDouble() * 60;
      _particles.add(_Particle(
        dx: cos(angle) * dist,
        dy: sin(angle) * dist - 20,
        color: colors[i % colors.length],
        birth: DateTime.now(),
      ));
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        final now = DateTime.now();
        setState(() => _particles.removeWhere(
            (p) => now.difference(p.birth).inMilliseconds > 900));
      }
    });
  }

  void _endGame() {
    setState(() { _running = false; _showEnd = true; });
    _saveScore();
  }

  Future<void> _loadAiConcepts() async {
    final lessonNumber = widget.lesson['number'] as int;
    setState(() => _isLoading = true);
    try {
      final rawConcepts = await ApiService.generateSwipeConcepts(
        lessonNumber: lessonNumber,
        slideTexts: LessonSlideTexts.forLesson(lessonNumber),
      );
      if (!mounted) return;
      if (rawConcepts.isNotEmpty) {
        final newConcepts = rawConcepts.asMap().entries.map((e) {
          final c = e.value;
          final icon = _kFallbackConcepts[e.key % _kFallbackConcepts.length].icon;
          return _Concept(
            text: (c['text'] as String).replaceAll(r'\n', '\n'),
            positive: c['positive'] as bool,
            sender: c['sender'] as String,
            preview: c['preview'] as String,
            icon: icon,
          );
        }).toList();
        setState(() => _concepts = newConcepts);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI loaded ${newConcepts.length} concepts!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI failed. Using original concepts.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveScore() async {
    final lessonNumber = widget.lesson['number'] as int;
    await ApiService.saveLevelResult(
      gameId: 'digital-literacy',
      level: 600 + lessonNumber,
      completed: _correct == _concepts.length,
      score: (_correct / _concepts.length * 100).round(),
    );
  }

  String _rank() {
    if (_correct == _concepts.length && _lives == 3) return 'S';
    if (_correct == _concepts.length) return 'A';
    if (_correct >= 5) return 'B';
    if (_correct >= 3) return 'C';
    return 'D';
  }

  String get _endTitle {
    if (_correct == _concepts.length) return 'PERFECT DEFENSE';
    if (_lives <= 0) return 'INBOX HACKED';
    return 'MISSION CLEAR';
  }

  String get _endTitleBlue {
    if (_correct == _concepts.length) return 'DEFENSE';
    if (_lives <= 0) return 'HACKED';
    return 'CLEAR';
  }

  String get _endTitle1 {
    if (_correct == _concepts.length) return 'PERFECT ';
    if (_lives <= 0) return 'INBOX ';
    return 'MISSION ';
  }

  String get _endSub {
    if (_correct == _concepts.length) return '- inbox protected -';
    if (_lives <= 0) return '- watch out for scams -';
    return '- digital safety report -';
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle  = widget.lesson['title']  as String;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.keyL ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _btnPress(true); return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyA ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _btnPress(false); return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        // Game fills entire screen
        child: Stack(
          children: [
            // ── Full-screen game scene ──
            Positioned.fill(
              child: _buildScene(),
            ),

            // ── LEFT PANEL overlay: back + prev + lesson info ──
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: _buildLeftPanel(lessonNumber, lessonTitle),
            ),

            // ── RIGHT PANEL overlay: chips + next ──
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: _buildRightPanel(),
            ),
          ],
        ),
      ),
    );
  }

  // ── LEFT PANEL ────────────────────────────────────────────────────────────
  Widget _buildLeftPanel(int lessonNumber, String lessonTitle) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF7B7FD4).withOpacity(0.92),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.settings.name == 'digital_literacy_hub' || route.isFirst),
            child: Container(
              width: 72, height: 56,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF5B8FD4),
                borderRadius: BorderRadius.circular(8),
              ),
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
          const SizedBox(height: 12),
          // Lesson number
          Text('#$lessonNumber',
              style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          // Lesson title (wrapped)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(lessonTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                    color: Colors.white70,
                    fontSize: 10, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          // AI button — only visible when not actively playing
          if (!_running)
            GestureDetector(
              onTap: _isLoading ? null : _loadAiConcepts,
              child: Container(
                width: 72, height: 44,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.grey.withOpacity(0.5)
                      : const Color(0xFFF5A623),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(height: 2),
                          Text('AI MODE',
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1),
                              textAlign: TextAlign.center),
                        ],
                      ),
              ),
            ),
          const Spacer(),
          // PREVIOUS button
          _buildSideButton(
            icon: Icons.arrow_back_ios,
            label: 'PREVIOUS',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── RIGHT PANEL ───────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF7B7FD4).withOpacity(0.92),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // LEARN chip
          _sideChip(
            icon: Icons.menu_book,
            iconColor: const Color(0xFF5B8FD4),
            label: 'LEARN',
            value: '17/17',
            bg: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 8),
          // PLAY chip
          _sideChipPlay(),
          const SizedBox(height: 8),
          // REVIEW chip
          _sideChip(
            icon: Icons.chat_bubble_outline,
            iconColor: Colors.white54,
            label: 'REVIEW',
            value: '0/5',
            bg: Colors.white.withOpacity(0.08),
            locked: true,
          ),
          const Spacer(),
          // NEXT button
          _buildSideButton(
            icon: Icons.arrow_forward_ios,
            label: 'NEXT',
            onTap: _showEnd
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DigitalPlayPageLesson2WordMatch(
                            lesson: widget.lesson),
                      ),
                    )
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sideChip({
    required IconData icon, required Color iconColor,
    required String label, required String value,
    required Color bg, bool locked = false,
  }) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 14),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.nunito(
                fontSize: 8, fontWeight: FontWeight.w800,
                color: Colors.white70)),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            if (locked) const Icon(Icons.lock, size: 9, color: Colors.white54),
            Text(value, style: GoogleFonts.nunito(
                fontSize: 11, fontWeight: FontWeight.w800,
                color: Colors.white)),
          ]),
        ],
      ),
    );
  }

  Widget _sideChipPlay() {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.sports_esports, color: Color(0xFF4CAF50), size: 14),
            const SizedBox(width: 4),
            Text('PLAY', style: GoogleFonts.nunito(
                fontSize: 8, fontWeight: FontWeight.w800,
                color: Colors.white70)),
          ]),
          const SizedBox(height: 2),
          Text('$_correct/${_concepts.length}',
              style: GoogleFonts.nunito(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // ── SIDE BUTTON ──────────────────────────────────────────────────────────
  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: enabled
                  ? const Color(0xFFF5A623)
                  : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.nunito(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _btnPress(bool allow) {
    if (allow) {
      setState(() => _safePressed = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _safePressed = false);
      });
    } else {
      setState(() => _riskPressed = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _riskPressed = false);
      });
    }
    _answer(allow);
  }

  Widget _buildScene() {
    return Stack(
      children: [
        // ── Dark radial background ──
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.0,
              colors: [Color(0xFF2A164D), Color(0xFF150A32), Color(0xFF07041A)],
              stops: [0, 0.4, 1],
            ),
          ),
        ),
        // ── Stars ──
        ..._buildStars(),
        // ── Grid floor ──
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SizedBox(
            height: 160,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0, 0.3],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: CustomPaint(
                painter: _GridFloorPainter(_gridScroll),
                size: const Size(360, 160),
              ),
            ),
          ),
        ),
        // ── HUD ──
        _buildHUD(),
        // ── Combo banner ──
        if (_showCombo) _buildCombo(),
        // ── Phone ──
        _buildPhone(),
        // ── Action buttons ──
        _buildActions(),
        // ── Scanlines ──
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Color(0x8C000000)],
                  radius: 0.9,
                ),
              ),
            ),
          ),
        ),
        // ── Scanline stripes ──
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _ScanlinePainter()),
          ),
        ),
        // ── Overlays ──
        if (_showTitle) _buildTitleOverlay(),
        if (_showEnd) _buildEndOverlay(),
      ],
    );
  }

  List<Widget> _buildStars() {
    return List.generate(_stars.length, (i) {
      final s = _stars[i];
      return AnimatedBuilder(
        animation: _starAnims[i],
        builder: (_, __) => Positioned(
          left: s.x, top: s.y,
          child: Opacity(
            opacity: _starAnims[i].value,
            child: Container(
              width: s.size, height: s.size,
              color: s.color,
            ),
          ),
        ),
      );
    });
  }

  // ── HUD ────────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    return Positioned(
      top: 14, left: 14, right: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip(
            label: 'LV',
            value: '${min(_idx + 1, _concepts.length)}/${_concepts.length}',
            borderColor: _C.cyan,
            shadowColor: _C.cyanD,
            textColor: _C.cyan,
          ),
          _buildChip(
            label: '★',
            value: _score.toString().padLeft(4, '0'),
            borderColor: _C.gold,
            shadowColor: const Color(0xFFA8821A),
            textColor: _C.gold,
          ),
          _buildHeartsChip(),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label, required String value,
    required Color borderColor, required Color shadowColor, required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEB0B0820),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 4), blurRadius: 0)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: _ps(8, color: textColor)),
        const SizedBox(width: 6),
        Text(value, style: _ps(8, color: Colors.white)),
      ]),
    );
  }

  Widget _buildHeartsChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEB0B0820),
        border: Border.all(color: _C.cyan, width: 2),
        boxShadow: const [BoxShadow(color: _C.cyanD, offset: Offset(0, 4), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final lost = i >= _lives;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: _PixelHeart(lost: lost),
          );
        }),
      ),
    );
  }

  // ── COMBO ─────────────────────────────────────────────────────────────────
  Widget _buildCombo() {
    return Positioned(
      top: 54,
      left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _comboAnim,
        builder: (_, __) => Opacity(
          opacity: _comboAnim.value,
          child: Center(
            child: Text(
              _comboText,
              style: _ps(10, color: _C.gold).copyWith(
                shadows: [const Shadow(color: _C.ink, offset: Offset(2, 2))],
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── PHONE ─────────────────────────────────────────────────────────────────
  Widget _buildPhone() {
    return Positioned(
      left: 0, right: 0, top: 60,
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(_shakeAnim.value, 0),
            child: child,
          ),
          child: SizedBox(
            width: 300, height: 480,
            child: Stack(children: [
              // Shell
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF1A1340),
                  foregroundDecoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF0B0820), width: 4),
                      bottom: BorderSide(color: Color(0xFF0B0820), width: 4),
                      left: BorderSide(color: Color(0xFF0B0820), width: 4),
                      right: BorderSide(color: Color(0xFF0B0820), width: 4),
                    ),
                  ),
                ),
              ),
              // Notch
              Positioned(
                top: 8, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 80, height: 10,
                    color: const Color(0xFF0B0820),
                  ),
                ),
              ),
              // Speaker
              Positioned(
                top: 6, left: 0, right: 0,
                child: Center(
                  child: Container(width: 30, height: 3, color: Colors.black),
                ),
              ),
              // Screen
              Positioned(
                left: 8, right: 8, top: 24, bottom: 38,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF0D1638), Color(0xFF060916)],
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.black, width: 2),
                      bottom: BorderSide(color: Colors.black, width: 2),
                      left: BorderSide(color: Colors.black, width: 2),
                      right: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: ClipRect(child: _buildScreen()),
                ),
              ),
              // Home bar
              Positioned(
                bottom: 10, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 80, height: 10,
                    color: const Color(0xFF0B0820),
                    foregroundDecoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFF2A1F70), width: 2),
                        bottom: BorderSide(color: Color(0xFF2A1F70), width: 2),
                        left: BorderSide(color: Color(0xFF2A1F70), width: 2),
                        right: BorderSide(color: Color(0xFF2A1F70), width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Stack(children: [
      // Status bar
      Positioned(
        left: 0, right: 0, top: 0,
        child: Container(
          height: 16,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text(_clock, style: _ps(6, color: _C.cyan)),
              const Spacer(),
              _PixelSignal(),
              const SizedBox(width: 4),
              _PixelBattery(),
            ],
          ),
        ),
      ),
      // App header
      Positioned(
        left: 0, right: 0, top: 16,
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1F1450), Color(0xFF0D0930)],
            ),
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _AppLogo(),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CYBER INBOX', style: _ps(7, color: Colors.white)),
                Text('1 NEW NOTIFICATION', style: _ps(5, color: _C.cyan)),
              ],
            ),
            const Spacer(),
            _BellBlinker(),
          ]),
        ),
      ),
      // Card area
      Positioned(
        left: 0, right: 0, top: 40, bottom: 18,
        child: _buildCardArea(),
      ),
      // Timer bar
      Positioned(
        left: 8, right: 8, bottom: 6,
        child: _buildTimerBar(),
      ),
      // Flash
      if (_flashVisible)
        Positioned.fill(
          child: IgnorePointer(
            child: Container(color: _flashColor),
          ),
        ),
    ]);
  }

  Widget _buildCardArea() {
    if (!_cardVisible || _showTitle || _showEnd) return const SizedBox.shrink();

    final c = _running && _idx < _concepts.length ? _current : _concepts[0];

    Widget card = Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: _C.paper,
        border: Border.all(color: _C.ink, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x80000020), offset: Offset(0, 6), blurRadius: 0)],
      ),
      child: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon box
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _C.ink2,
                  border: Border.all(color: _C.ink, width: 2),
                ),
                child: CustomPaint(
                  painter: _PixelIconPainter(c.icon),
                  size: const Size(48, 48),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.sender,
                        style: _ps(7, color: _C.sender),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(c.text.replaceAll('\n', '\n'),
                        style: _ps(9, color: _C.ink)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 6),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFC8B27A), width: 2, style: BorderStyle.solid)),
              ),
              child: Text('"${c.preview}"',
                  style: GoogleFonts.vt323(fontSize: 14, color: _C.deepBlue, height: 1.1)),
            ),
          ],
        ),
        Positioned(
          right: 0, bottom: 0,
          child: Text('NEW', style: _ps(6, color: _C.sender)),
        ),
      ]),
    );

    // Enter animation
    if (_cardAnim == 0) {
      card = SlideTransition(
        position: _enterAnim,
        child: FadeTransition(opacity: _enterOpacity, child: card),
      );
    }
    // Fly off animation
    else if (_cardAnim == 1 || _cardAnim == 2) {
      card = AnimatedBuilder(
        animation: _flyCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(
            _flyAnim.value.dx * 280,
            _flyAnim.value.dy * 60,
          ),
          child: Transform.rotate(
            angle: _flyRotAnim.value,
            child: Opacity(opacity: _flyOpacity.value, child: child),
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  Widget _buildTimerBar() {
    final pct = (_timer / 8.0).clamp(0.0, 1.0);
    final warn = _timer <= 2.5;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: _C.ink,
        border: Border.all(color: const Color(0xFF1A1340), width: 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.safe, _C.gold, _C.risk]),
            color: warn ? _C.risk : null,
          ),
        ),
      ),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────
  Widget _buildActions() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Row(
        children: [
          Expanded(child: _buildBtn(label: 'BLOCK', glyph: '✕', isRisk: true, pressed: _riskPressed,
              onTap: () => _btnPress(false))),
          Expanded(child: _buildBtn(label: 'ALLOW', glyph: '✓', isRisk: false, pressed: _safePressed,
              onTap: () => _btnPress(true))),
        ],
      ),
    );
  }

  Widget _buildBtn({
    required String label, required String glyph,
    required bool isRisk, required bool pressed, required VoidCallback onTap,
  }) {
    final bg = isRisk ? _C.risk : _C.safe;
    final shadow = isRisk ? _C.riskD : _C.safeD;
    final yOffset = pressed ? 4.0 : 0.0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, yOffset, 0),
        padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: _C.ink, width: 3),
          boxShadow: [
            BoxShadow(color: shadow, offset: Offset(0, pressed ? 2 : 6), blurRadius: 0),
            BoxShadow(color: _C.ink, offset: Offset(0, pressed ? 4 : 10), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(glyph, style: _ps(18, color: Colors.white).copyWith(
              shadows: [const Shadow(color: _C.ink, offset: Offset(2, 2))],
            )),
            const SizedBox(height: 6),
            Text(label, style: _ps(11, color: Colors.white)),
            const SizedBox(height: 6),
            Text(isRisk ? '[ A ]' : '[ L ]', style: _ps(6, color: _C.ink)),
          ],
        ),
      ),
    );
  }

  // ── TITLE OVERLAY ─────────────────────────────────────────────────────────
  Widget _buildTitleOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xD907041A),
        child: Center(
          child: _buildPanel(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(text: TextSpan(
                style: _ps(18, color: _C.orange).copyWith(
                  shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))],
                  letterSpacing: 1,
                ),
                children: [
                  const TextSpan(text: 'PIXEL '),
                  TextSpan(text: 'GUARD', style: _ps(18, color: _C.cyanD)),
                ],
              )),
              const SizedBox(height: 4),
              Text('- CYBER INBOX -', style: _ps(7, color: _C.ink2)),
              const SizedBox(height: 10),
              Text('An alert pops up on your phone.\nIs it SAFE or RISKY?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.vt323(fontSize: 16, color: const Color(0xFF241A55), height: 1.15)),
              const SizedBox(height: 8),
              // Icon row (4 sample icons)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [0, 3, 4, 1].map((i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: _C.ink2,
                      border: Border.all(color: _C.ink, width: 2),
                    ),
                    child: CustomPaint(
                      painter: _PixelIconPainter(_concepts[i].icon),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 10),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendChip('✓ ALLOW = SAFE', _C.safeD),
                  const SizedBox(width: 6),
                  _legendChip('✕ BLOCK = RISKY', _C.riskD),
                ],
              ),
              const SizedBox(height: 6),
              // Keys
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _kbChip('A = BLOCK'),
                const SizedBox(width: 6),
                _kbChip('L = ALLOW'),
              ]),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _startGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _C.orange,
                    border: Border.all(color: _C.ink, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFFC4561C), offset: Offset(0, 5), blurRadius: 0),
                      BoxShadow(color: _C.ink, offset: Offset(0, 8), blurRadius: 0),
                    ],
                  ),
                  child: Text('▶ START', style: _ps(9, color: Colors.white)),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  // ── END OVERLAY ───────────────────────────────────────────────────────────
  Widget _buildEndOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xD907041A),
        child: Center(
          child: _buildPanel(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(text: TextSpan(
                style: _ps(18, color: _C.orange).copyWith(
                  shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))],
                  letterSpacing: 1,
                ),
                children: [
                  TextSpan(text: _endTitle1),
                  TextSpan(text: _endTitleBlue, style: _ps(18, color: _C.cyanD)),
                ],
              )),
              const SizedBox(height: 4),
              Text(_endSub, style: _ps(7, color: _C.ink2)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                color: _C.ink,
                child: Text(_rank(),
                    style: _ps(36, color: _C.gold).copyWith(
                      shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))],
                      letterSpacing: 2,
                    )),
              ),
              const SizedBox(height: 6),
              Text(
                '${_correct}/${_concepts.length} correct · max combo x$_maxCombo · $_score pts',
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(fontSize: 16, color: const Color(0xFF241A55)),
              ),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _endBtn('↻ AGAIN', isCyan: true, onTap: _startGame),
                const SizedBox(width: 8),
                _endBtn('≡ MENU', isCyan: false, onTap: () {
                  setState(() { _showEnd = false; _showTitle = true; });
                }),
              ]),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: _C.paper,
        border: Border.all(color: _C.ink, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x80000020), offset: Offset(0, 12), blurRadius: 0)],
      ),
      child: child,
    );
  }

  Widget _legendChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _C.ink, width: 2),
      ),
      child: Text(text, style: _ps(6, color: color)),
    );
  }

  Widget _kbChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _C.ink, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFFC8B27A), offset: Offset(0, 3), blurRadius: 0)],
      ),
      child: Text(text, style: _ps(6, color: _C.ink)),
    );
  }

  Widget _endBtn(String label, {required bool isCyan, required VoidCallback onTap}) {
    final bg = isCyan ? _C.cyan : _C.orange;
    final shadow = isCyan ? _C.cyanD : const Color(0xFFC4561C);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: _C.ink, width: 3),
          boxShadow: [
            BoxShadow(color: shadow, offset: const Offset(0, 5), blurRadius: 0),
            const BoxShadow(color: _C.ink, offset: Offset(0, 8), blurRadius: 0),
          ],
        ),
        child: Text(label, style: _ps(9, color: isCyan ? _C.ink : Colors.white)),
      ),
    );
  }

  // ── Text style helper ─────────────────────────────────────────────────────
  TextStyle _ps(double size, {Color color = Colors.white}) {
    return TextStyle(
      fontFamily: 'Press Start 2P',
      fontSize: size,
      color: color,
      letterSpacing: 1,
      height: 1.3,
    );
  }
}

// ── PIXEL HEART ───────────────────────────────────────────────────────────────
class _PixelHeart extends StatelessWidget {
  final bool lost;
  const _PixelHeart({required this.lost});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: lost
          ? const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.4, 0,
            ])
          : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
      child: ClipPath(
        clipper: _HeartClipper(),
        child: Container(
          width: 10, height: 10,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFF5470), Color(0xFFA82045)],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    // Pixel heart: polygon(50% 100%,0 50%,0 25%,25% 0,50% 25%,75% 0,100% 25%,100% 50%)
    p.moveTo(s.width * 0.5, s.height);
    p.lineTo(0, s.height * 0.5);
    p.lineTo(0, s.height * 0.25);
    p.lineTo(s.width * 0.25, 0);
    p.lineTo(s.width * 0.5, s.height * 0.25);
    p.lineTo(s.width * 0.75, 0);
    p.lineTo(s.width, s.height * 0.25);
    p.lineTo(s.width, s.height * 0.5);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(_) => false;
}

// ── PIXEL SIGNAL ─────────────────────────────────────────────────────────────
class _PixelSignal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const heights = [2.0, 4.0, 6.0, 8.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights.asMap().entries.map((e) => Container(
        width: 2,
        height: e.value,
        margin: const EdgeInsets.only(right: 1),
        color: e.key == 3 ? const Color(0xFF1A78B8) : const Color(0xFF56D3FF),
      )).toList(),
    );
  }
}

// ── PIXEL BATTERY ────────────────────────────────────────────────────────────
class _PixelBattery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14, height: 6,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF56D3FF), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: Container(color: const Color(0xFF56E07A), width: 8),
          ),
        ),
        Container(width: 2, height: 2, color: const Color(0xFF56D3FF)),
      ],
    );
  }
}

// ── APP LOGO ─────────────────────────────────────────────────────────────────
class _AppLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14, height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF56D3FF),
        border: Border.all(color: const Color(0xFF0B0820), width: 2),
      ),
      child: Center(
        child: Container(width: 4, height: 8, color: Colors.white),
      ),
    );
  }
}

// ── BELL BLINKER ─────────────────────────────────────────────────────────────
class _BellBlinker extends StatefulWidget {
  @override
  State<_BellBlinker> createState() => _BellBlinkerState();
}

class _BellBlinkerState extends State<_BellBlinker>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1, end: 0.4).animate(_c);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Text('!',
            style: TextStyle(
              fontFamily: 'Press Start 2P',
              fontSize: 6,
              color: const Color(0xFFFFD23A),
            )),
      ),
    );
  }
}

// ── SCANLINE PAINTER ─────────────────────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── PARTICLE ─────────────────────────────────────────────────────────────────
class _Particle {
  final double dx, dy;
  final Color color;
  final DateTime birth;
  _Particle({required this.dx, required this.dy, required this.color, required this.birth});
}