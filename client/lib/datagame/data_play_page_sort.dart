import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_review_page.dart';
import '../services/api_service.dart';

// ── COLORS ───────────────────────────────────────────────────────────────────
class _C {
  static const ink      = Color(0xFF0B0820);
  static const ink2     = Color(0xFF1A1340);
  static const paper    = Color(0xFFFFF6D8);
  static const gold     = Color(0xFFFFD23A);
  static const numC     = Color(0xFF56E07A);   // numerical = green
  static const numD     = Color(0xFF1D8A3A);
  static const nonNum   = Color(0xFFFF8A3A);   // non-numerical = orange
  static const nonNumD  = Color(0xFFA84A10);
  static const cyan     = Color(0xFF56D3FF);
  static const orange   = Color(0xFFFF8A3A);
  static const deepBlue = Color(0xFF3A2680);
  static const sender   = Color(0xFF56D3FF);
}

// ── PIXEL PALETTE ─────────────────────────────────────────────────────────────
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

// ── DATA CONCEPTS ─────────────────────────────────────────────────────────────
class _Concept {
  final String text;
  final bool isNumerical;
  final String source;
  final String preview;
  final List<String> icon;
  const _Concept({
    required this.text,
    required this.isNumerical,
    required this.source,
    required this.preview,
    required this.icon,
  });
}

const _concepts = [
  _Concept(
    text: "STUDENTS'\nHEIGHT",
    isNumerical: true,
    source: "MEASUREMENT",
    preview: "Each student's height in cm was recorded at the start of the school year.",
    icon: [
      "................",
      "......K.........",
      "......Y.........",
      "....K.Y.K.......",
      "....G.Y.G.......",
      "....G.Y.G.......",
      "....G.Y.G.......",
      "....G.Y.GG......",
      "....G.Y.GG......",
      "....GYYYYY......",
      "KKKKKKKKKK......",
      "................",
      "................",
      "................",
      "................",
      "................",
    ],
  ),
  _Concept(
    text: "STEPS\nWALKED",
    isNumerical: true,
    source: "PEDOMETER",
    preview: "A fitness tracker counts the number of steps each person takes every day.",
    icon: [
      "................",
      "..KKKK..........",
      "..KGGK..........",
      "..KGGKK.........",
      "..KGGGK.........",
      "...KKKK.........",
      "................",
      "........KKKKK...",
      "........KGGGK...",
      "........KKGGK...",
      "........KKGKK...",
      "........KKKKK...",
      "................",
      "................",
      "................",
      "................",
    ],
  ),
  _Concept(
    text: "DAILY\nTEMPERATURE",
    isNumerical: true,
    source: "WEATHER SENSOR",
    preview: "A weather station records the temperature in degrees Celsius every day.",
    icon: [
      "....KKKK........",
      "....K..K........",
      "....K.RK........",
      "....K.RK........",
      "....K.RK........",
      "....K.RK........",
      "...KK.RKK.......",
      "...K..RRK.......",
      "...K..RRK.......",
      "...K..RRK.......",
      "....KKKKK.......",
      "................",
      "................",
      "................",
      "................",
      "................",
    ],
  ),
  _Concept(
    text: "SEARCHED\nWORDS",
    isNumerical: false,
    source: "SEARCH ENGINE",
    preview: "The words people type into a search engine are collected as text data.",
    icon: [
      "................",
      "....KKKK........",
      "...K....K.......",
      "...K.CC.K.......",
      "...K.CC.K.......",
      "...K....K.......",
      "....KKKK........",
      ".......KK.......",
      "........KK......",
      ".........KK.....",
      "..........K.....",
      "................",
      "................",
      "................",
      "................",
      "................",
    ],
  ),
  _Concept(
    text: "FAVOURITE\nCOLORS",
    isNumerical: false,
    source: "CLASS SURVEY",
    preview: "Students chose their favourite color from a list. Colors are not numbers!",
    icon: [
      "................",
      "..RRRRGGGG......",
      "..RRRRGGGG......",
      "..RRRRGGGG......",
      "..RRRRGGGG......",
      "................",
      "..YYYYPPPP......",
      "..YYYYPPPP......",
      "..YYYYPPPP......",
      "..YYYYPPPP......",
      "................",
      "..CCCCOOOO......",
      "..CCCCOOOO......",
      "..CCCCOOOO......",
      "..CCCCOOOO......",
      "................",
    ],
  ),
  _Concept(
    text: "PET\nNAMES",
    isNumerical: false,
    source: "CLASS LIST",
    preview: "Students wrote down the names of their pets. Names are words, not numbers.",
    icon: [
      "................",
      ".K.....K........",
      "KCK...KCK.......",
      "KCCK.KCCK.......",
      "KCCCCCCCK.......",
      "KC.C.C.CK.......",
      "KC.....CK.......",
      "KCW...WCK.......",
      ".K.KKK.K........",
      "..KKKKK.........",
      "................",
      "................",
      "................",
      "................",
      "................",
      "................",
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
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PixelIconPainter old) => false;
}

// ── STAR DATA ─────────────────────────────────────────────────────────────────
class _StarData {
  final double x, y, size;
  final Color color;
  final double delay;
  _StarData(this.x, this.y, this.size, this.color, this.delay);
}

// ── GRID FLOOR PAINTER ────────────────────────────────────────────────────────
class _GridFloorPainter extends CustomPainter {
  final double scrollOffset;
  _GridFloorPainter(this.scrollOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final gradPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0x0056E07A), Color(0x2956E07A), Color(0x6B56E07A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF56E07A).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    const gridSize = 12.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    final offset = scrollOffset % gridSize;
    for (double y = -gridSize + offset; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_GridFloorPainter old) => old.scrollOffset != scrollOffset;
}

// ── SCANLINE PAINTER ──────────────────────────────────────────────────────────
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
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

// ── PIXEL HEART ──────────────────────────────────────────────────────────────
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
              colors: [Color(0xFF56E07A), Color(0xFF1D8A3A)],
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
        width: 2, height: e.value,
        margin: const EdgeInsets.only(right: 1),
        color: e.key == 3 ? const Color(0xFF1D8A3A) : const Color(0xFF56E07A),
      )).toList(),
    );
  }
}

// ── PIXEL BATTERY ────────────────────────────────────────────────────────────
class _PixelBattery extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 14, height: 6,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFF56E07A), width: 1)),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Container(color: const Color(0xFF56E07A), width: 8),
        ),
      ),
      Container(width: 2, height: 2, color: const Color(0xFF56E07A)),
    ]);
  }
}

// ── BELL BLINKER ─────────────────────────────────────────────────────────────
class _BellBlinker extends StatefulWidget {
  @override
  State<_BellBlinker> createState() => _BellBlinkerState();
}

class _BellBlinkerState extends State<_BellBlinker> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _anim = Tween<double>(begin: 1, end: 0.4).animate(_c);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Opacity(
        opacity: _anim.value,
        child: const Text('!', style: TextStyle(fontFamily: 'Press Start 2P', fontSize: 6, color: Color(0xFFFFD23A))),
      ),
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
        color: const Color(0xFF56E07A),
        border: Border.all(color: const Color(0xFF0B0820), width: 2),
      ),
      child: Center(child: Container(width: 4, height: 8, color: Colors.white)),
    );
  }
}

// ── MAIN PAGE ────────────────────────────────────────────────────────────────
class DataPlayPageSort extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const DataPlayPageSort({super.key, required this.lesson});

  @override
  State<DataPlayPageSort> createState() => _DataPlayPageSortState();
}

class _DataPlayPageSortState extends State<DataPlayPageSort> with TickerProviderStateMixin {

  late List<int> _order;
  int _idx = 0;
  int _score = 0;
  int _lives = 3;
  int _combo = 0;
  int _maxCombo = 0;
  int _correct = 0;
  bool _running = false;
  bool _locked = false;

  double _timer = 8.0;
  bool _timerActive = false;
  Timer? _gameTimer;

  bool _showTitle = true;
  bool _showEnd = false;

  int _cardAnim = 0;
  bool _cardVisible = false;

  Color? _flashColor;
  bool _flashVisible = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  bool _showCombo = false;
  String _comboText = '';
  late AnimationController _comboCtrl;
  late Animation<double> _comboAnim;

  late AnimationController _flyCtrl;
  late Animation<Offset> _flyAnim;
  late Animation<double> _flyRotAnim;
  late Animation<double> _flyOpacity;

  late AnimationController _enterCtrl;
  late Animation<Offset> _enterAnim;
  late Animation<double> _enterOpacity;

  late AnimationController _gridCtrl;
  double _gridScroll = 0;

  late List<_StarData> _stars;
  late AnimationController _starCtrl;
  late List<Animation<double>> _starAnims;

  final List<_Particle> _particles = [];

  String _clock = '';
  Timer? _clockTimer;

  bool _numPressed = false;
  bool _nonNumPressed = false;

  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 20),
    ]).animate(_shakeCtrl);

    _comboCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _comboAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_comboCtrl);

    _flyCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _flyAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_flyCtrl);
    _flyRotAnim = Tween<double>(begin: 0, end: 0).animate(_flyCtrl);
    _flyOpacity = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));

    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _enterAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));
    _enterOpacity = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut));

    _gridCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _gridCtrl.addListener(() { setState(() => _gridScroll = _gridCtrl.value * 12); });

    _stars = [
      _StarData(24, 14, 2, Colors.white, 0.1),
      _StarData(60, 30, 2, Colors.white, 0.6),
      _StarData(108, 8, 2, const Color(0xFF86FFD6), 1.2),
      _StarData(150, 42, 2, Colors.white, 0.3),
      _StarData(200, 18, 3, const Color(0xFFFFE27A), 0.9),
      _StarData(252, 26, 2, const Color(0xFF86FFD6), 1.5),
      _StarData(300, 10, 2, Colors.white, 0.4),
      _StarData(330, 36, 3, const Color(0xFFFFE27A), 1.0),
      _StarData(18, 74, 2, Colors.white, 1.8),
      _StarData(336, 80, 2, const Color(0xFF86FFD6), 0.5),
    ];
    _starCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat(reverse: true);
    _starAnims = _stars.map((s) => Tween<double>(begin: 0.95, end: 0.25).animate(
      CurvedAnimation(
        parent: _starCtrl,
        curve: Interval((s.delay / 2.4).clamp(0, 1), ((s.delay / 2.4) + 0.5).clamp(0, 1)),
      ),
    )).toList();

    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateClock());
  }

  @override
  void dispose() {
    _shakeCtrl.dispose(); _comboCtrl.dispose();
    _flyCtrl.dispose(); _enterCtrl.dispose();
    _gridCtrl.dispose(); _starCtrl.dispose();
    _gameTimer?.cancel(); _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _clock = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
    if (_idx >= _concepts.length || _lives <= 0) { _endGame(); return; }
    setState(() {
      _locked = false; _timer = 8.0; _timerActive = true; _cardAnim = 0;
    });
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        if (_running && _timerActive) {
          _timer -= 0.1;
          if (_timer <= 0) {
            _timer = 0; _timerActive = false; _answer(false);
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

  // isNumerical: true = tap NUMERICAL button (right), false = tap NON-NUMERICAL (left)
  void _answer(bool isNumerical) {
    if (!_running || _locked || !_cardVisible) return;
    setState(() { _locked = true; _timerActive = false; });
    _gameTimer?.cancel();

    final correct = isNumerical == _current.isNumerical;

    final flyEnd = isNumerical ? const Offset(1.2, -0.3) : const Offset(-1.2, -0.3);
    final flyRot = isNumerical ? 0.6 : -0.6;
    _flyAnim = Tween<Offset>(begin: Offset.zero, end: flyEnd)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
    _flyRotAnim = Tween<double>(begin: 0, end: flyRot)
        .animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeIn));
    setState(() => _cardAnim = isNumerical ? 1 : 2);
    _flyCtrl.forward(from: 0);

    setState(() {
      _flashColor = correct ? _C.numC.withValues(alpha: 0.55) : _C.nonNum.withValues(alpha: 0.55);
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
        setState(() { _comboText = 'x$_combo COMBO! +$gain'; _showCombo = true; });
        _comboCtrl.forward(from: 0).then((_) {
          if (mounted) setState(() => _showCombo = false);
        });
      }
      _spawnParticles(true);
    } else {
      setState(() { _combo = 0; _lives = (_lives - 1).clamp(0, 3); });
      _shakeCtrl.forward(from: 0);
      _spawnParticles(false);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _cardVisible = false);
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) { setState(() => _idx++); _nextRound(); }
    });
  }

  void _spawnParticles(bool good) {
    final colors = good
        ? [_C.numC, _C.gold, Colors.white, _C.cyan]
        : [_C.nonNum, _C.orange, Colors.white, _C.nonNumD];
    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * pi * 2;
      final dist = 40.0 + _rng.nextDouble() * 60;
      _particles.add(_Particle(
        dx: cos(angle) * dist, dy: sin(angle) * dist - 20,
        color: colors[i % colors.length], birth: DateTime.now(),
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

  Future<void> _saveScore() async {
    final lessonNumber = widget.lesson['number'] as int;
    await ApiService.saveLevelResult(
      gameId: 'data-everywhere',
      level: 100 + lessonNumber,
      completed: _correct == _concepts.length,
      score: (_correct / _concepts.length * 100).round(),
    );
  }

  String _rank() {
    if (_correct == _concepts.length && _lives == 3) return 'S';
    if (_correct == _concepts.length) return 'A';
    if (_correct >= 4) return 'B';
    if (_correct >= 2) return 'C';
    return 'D';
  }

  String get _endTitle1 {
    if (_correct == _concepts.length) return 'DATA ';
    if (_lives <= 0) return 'NEED ';
    return 'MISSION ';
  }

  String get _endTitleBlue {
    if (_correct == _concepts.length) return 'EXPERT!';
    if (_lives <= 0) return 'MORE PRACTICE';
    return 'COMPLETE';
  }

  String get _endSub {
    if (_correct == _concepts.length) return '- you sorted all data correctly -';
    if (_lives <= 0) return '- review numerical vs non-numerical -';
    return '- data sorting report -';
  }

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
          if (event.logicalKey == LogicalKeyboardKey.keyL || event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _btnPress(true); return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _btnPress(false); return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(children: [
          Positioned.fill(child: _buildScene()),
          Positioned(left: 0, top: 0, bottom: 0, child: _buildLeftPanel(lessonNumber, lessonTitle)),
          Positioned(right: 0, top: 0, bottom: 0, child: _buildRightPanel()),
        ]),
      ),
    );
  }

  Widget _buildLeftPanel(int lessonNumber, String lessonTitle) {
    return Container(
      width: 110,
      color: const Color(0xFF7B7FD4).withValues(alpha: 0.92),
      child: Column(children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil(
              (route) => route.settings.name == 'data_course_hub' || route.isFirst),
          child: Container(
            width: 72, height: 56,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF5B8FD4), borderRadius: BorderRadius.circular(8)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.arrow_back_ios, color: Colors.white, size: 14),
              Text('BACK TO\nCOURSE',
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, height: 1.1),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('#$lessonNumber', style: GoogleFonts.nunito(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(lessonTitle, textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
        const Spacer(),
        _buildSideButton(icon: Icons.arrow_back_ios, label: 'PREVIOUS', onTap: () => Navigator.of(context).pop()),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 110,
      color: const Color(0xFF7B7FD4).withValues(alpha: 0.92),
      child: Column(children: [
        const SizedBox(height: 16),
        _sideChip(icon: Icons.menu_book, iconColor: const Color(0xFF5B8FD4),
            label: 'LEARN', value: '18/18', bg: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 8),
        _sideChipPlay(),
        const SizedBox(height: 8),
        _sideChip(icon: Icons.chat_bubble_outline, iconColor: Colors.white54,
            label: 'REVIEW', value: '0/5', bg: Colors.white.withValues(alpha: 0.08), locked: true),
        const Spacer(),
        _buildSideButton(
          icon: Icons.arrow_forward_ios,
          label: 'NEXT',
          onTap: _showEnd
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DataReviewPage(lesson: widget.lesson),
                  ))
              : null,
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sideChip({required IconData icon, required Color iconColor,
      required String label, required String value, required Color bg, bool locked = false}) {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white70)),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          if (locked) const Icon(Icons.lock, size: 9, color: Colors.white54),
          Text(value, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ]),
    );
  }

  Widget _sideChipPlay() {
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sports_esports, color: Color(0xFF4CAF50), size: 14),
          const SizedBox(width: 4),
          Text('PLAY', style: GoogleFonts.nunito(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white70)),
        ]),
        const SizedBox(height: 2),
        Text('$_correct/${_concepts.length}',
            style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ]),
    );
  }

  Widget _buildSideButton({required IconData icon, required String label, required VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF5A623) : Colors.grey.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.nunito(color: enabled ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  void _btnPress(bool isNumerical) {
    if (isNumerical) {
      setState(() => _numPressed = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _numPressed = false);
      });
    } else {
      setState(() => _nonNumPressed = true);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _nonNumPressed = false);
      });
    }
    _answer(isNumerical);
  }

  Widget _buildScene() {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6), radius: 1.0,
            colors: [Color(0xFF0A2D1A), Color(0xFF061508), Color(0xFF020A04)],
            stops: [0, 0.4, 1],
          ),
        ),
      ),
      ..._buildStars(),
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: SizedBox(
          height: 160,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black], stops: [0, 0.3],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: CustomPaint(painter: _GridFloorPainter(_gridScroll), size: const Size(360, 160)),
          ),
        ),
      ),
      _buildHUD(),
      if (_showCombo) _buildCombo(),
      _buildPhone(),
      _buildActions(),
      Positioned.fill(child: IgnorePointer(
        child: Container(decoration: const BoxDecoration(
          gradient: RadialGradient(colors: [Colors.transparent, Color(0x8C000000)], radius: 0.9),
        )),
      )),
      Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanlinePainter()))),
      if (_showTitle) _buildTitleOverlay(),
      if (_showEnd) _buildEndOverlay(),
    ]);
  }

  List<Widget> _buildStars() {
    return List.generate(_stars.length, (i) {
      final s = _stars[i];
      return AnimatedBuilder(
        animation: _starAnims[i],
        builder: (context, child) => Positioned(
          left: s.x, top: s.y,
          child: Opacity(opacity: _starAnims[i].value, child: Container(width: s.size, height: s.size, color: s.color)),
        ),
      );
    });
  }

  Widget _buildHUD() {
    return Positioned(
      top: 14, left: 14, right: 14,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildChip(label: 'LV', value: '${min(_idx + 1, _concepts.length)}/${_concepts.length}',
            borderColor: _C.numC, shadowColor: _C.numD, textColor: _C.numC),
        _buildChip(label: '★', value: _score.toString().padLeft(4, '0'),
            borderColor: _C.gold, shadowColor: const Color(0xFFA8821A), textColor: _C.gold),
        _buildHeartsChip(),
      ]),
    );
  }

  Widget _buildChip({required String label, required String value,
      required Color borderColor, required Color shadowColor, required Color textColor}) {
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
        border: Border.all(color: _C.numC, width: 2),
        boxShadow: const [BoxShadow(color: _C.numD, offset: Offset(0, 4), blurRadius: 0)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(right: 3),
        child: _PixelHeart(lost: i >= _lives),
      ))),
    );
  }

  Widget _buildCombo() {
    return Positioned(
      top: 54, left: 0, right: 0,
      child: AnimatedBuilder(
        animation: _comboAnim,
        builder: (context, child) => Opacity(
          opacity: _comboAnim.value,
          child: Center(
            child: Text(_comboText, style: _ps(10, color: _C.gold).copyWith(
              shadows: [const Shadow(color: _C.ink, offset: Offset(2, 2))], letterSpacing: 1,
            )),
          ),
        ),
      ),
    );
  }

  Widget _buildPhone() {
    return Positioned(
      left: 0, right: 0, top: 60,
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(offset: Offset(_shakeAnim.value, 0), child: child),
          child: SizedBox(
            width: 300, height: 480,
            child: Stack(children: [
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF061508),
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
              Positioned(top: 8, left: 0, right: 0,
                  child: Center(child: Container(width: 80, height: 10, color: const Color(0xFF0B0820)))),
              Positioned(top: 6, left: 0, right: 0,
                  child: Center(child: Container(width: 30, height: 3, color: Colors.black))),
              Positioned(
                left: 8, right: 8, top: 24, bottom: 38,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Color(0xFF061508), Color(0xFF020A04)],
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
              Positioned(
                bottom: 10, left: 0, right: 0,
                child: Center(child: Container(
                  width: 80, height: 10,
                  color: const Color(0xFF0B0820),
                  foregroundDecoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFF1D3A20), width: 2),
                      bottom: BorderSide(color: Color(0xFF1D3A20), width: 2),
                      left: BorderSide(color: Color(0xFF1D3A20), width: 2),
                      right: BorderSide(color: Color(0xFF1D3A20), width: 2),
                    ),
                  ),
                )),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen() {
    return Stack(children: [
      Positioned(
        left: 0, right: 0, top: 0,
        child: Container(
          height: 16, color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Text(_clock, style: _ps(6, color: _C.numC)),
            const Spacer(),
            _PixelSignal(),
            const SizedBox(width: 4),
            _PixelBattery(),
          ]),
        ),
      ),
      Positioned(
        left: 0, right: 0, top: 16,
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0A2D1A), Color(0xFF061508)],
            ),
            border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            _AppLogo(),
            const SizedBox(width: 6),
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('DATA SORTER', style: _ps(7, color: Colors.white)),
              Text('CLASSIFY THE DATA', style: _ps(5, color: _C.numC)),
            ]),
            const Spacer(),
            _BellBlinker(),
          ]),
        ),
      ),
      Positioned(left: 0, right: 0, top: 40, bottom: 18, child: _buildCardArea()),
      Positioned(left: 8, right: 8, bottom: 6, child: _buildTimerBar()),
      if (_flashVisible)
        Positioned.fill(child: IgnorePointer(child: Container(color: _flashColor))),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: _C.ink2, border: Border.all(color: _C.ink, width: 2)),
              child: CustomPaint(painter: _PixelIconPainter(c.icon), size: const Size(48, 48)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.source, style: _ps(7, color: _C.sender), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(c.text, style: _ps(9, color: _C.ink)),
            ])),
          ]),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFC8B27A), width: 2))),
            child: Text('"${c.preview}"',
                style: GoogleFonts.vt323(fontSize: 14, color: _C.deepBlue, height: 1.1)),
          ),
        ]),
        Positioned(right: 0, bottom: 0, child: Text('DATA', style: _ps(6, color: _C.sender))),
      ]),
    );

    if (_cardAnim == 0) {
      card = SlideTransition(position: _enterAnim, child: FadeTransition(opacity: _enterOpacity, child: card));
    } else if (_cardAnim == 1 || _cardAnim == 2) {
      card = AnimatedBuilder(
        animation: _flyCtrl,
        builder: (_, child) => Transform.translate(
          offset: Offset(_flyAnim.value.dx * 280, _flyAnim.value.dy * 60),
          child: Transform.rotate(angle: _flyRotAnim.value,
              child: Opacity(opacity: _flyOpacity.value, child: child)),
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
      decoration: BoxDecoration(color: _C.ink, border: Border.all(color: const Color(0xFF0A2D1A), width: 2)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft, widthFactor: pct,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_C.numC, _C.gold, _C.nonNum]),
            color: warn ? _C.nonNum : null,
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Row(children: [
        Expanded(child: _buildBtn(label: 'NON-NUM', glyph: '←', isNonNum: true, pressed: _nonNumPressed, onTap: () => _btnPress(false))),
        Expanded(child: _buildBtn(label: 'NUMERICAL', glyph: '→', isNonNum: false, pressed: _numPressed, onTap: () => _btnPress(true))),
      ]),
    );
  }

  Widget _buildBtn({required String label, required String glyph,
      required bool isNonNum, required bool pressed, required VoidCallback onTap}) {
    final bg = isNonNum ? _C.nonNum : _C.numC;
    final shadow = isNonNum ? _C.nonNumD : _C.numD;
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(glyph, style: _ps(18, color: Colors.white).copyWith(shadows: [const Shadow(color: _C.ink, offset: Offset(2, 2))])),
          const SizedBox(height: 6),
          Text(label, style: _ps(9, color: Colors.white)),
          const SizedBox(height: 6),
          Text(isNonNum ? '[ A ]' : '[ L ]', style: _ps(6, color: _C.ink)),
        ]),
      ),
    );
  }

  Widget _buildTitleOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xD9020A04),
        child: Center(
          child: _buildPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [
            RichText(text: TextSpan(
              style: _ps(18, color: _C.gold).copyWith(shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))], letterSpacing: 1),
              children: [
                const TextSpan(text: 'DATA '),
                TextSpan(text: 'SORTER', style: _ps(18, color: _C.numC)),
              ],
            )),
            const SizedBox(height: 4),
            Text('- classify the data -', style: _ps(7, color: _C.ink2)),
            const SizedBox(height: 10),
            Text('A data card appears.\nIs it NUMERICAL or NON-NUMERICAL?',
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(fontSize: 16, color: const Color(0xFF0A2D1A), height: 1.15)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [0, 1, 2, 3].map((i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: _C.ink2, border: Border.all(color: _C.ink, width: 2)),
                child: CustomPaint(painter: _PixelIconPainter(_concepts[i].icon)),
              ),
            )).toList()),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _legendChip('← NON-NUM', _C.nonNumD),
              const SizedBox(width: 6),
              _legendChip('NUMERICAL →', _C.numD),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _kbChip('A = NON-NUM'),
              const SizedBox(width: 6),
              _kbChip('L = NUMERICAL'),
            ]),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.numC,
                  border: Border.all(color: _C.ink, width: 3),
                  boxShadow: const [
                    BoxShadow(color: _C.numD, offset: Offset(0, 5), blurRadius: 0),
                    BoxShadow(color: _C.ink, offset: Offset(0, 8), blurRadius: 0),
                  ],
                ),
                child: Text('▶ START', style: _ps(9, color: _C.ink)),
              ),
            ),
          ])),
        ),
      ),
    );
  }

  Widget _buildEndOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xD9020A04),
        child: Center(
          child: _buildPanel(child: Column(mainAxisSize: MainAxisSize.min, children: [
            RichText(text: TextSpan(
              style: _ps(18, color: _C.gold).copyWith(shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))], letterSpacing: 1),
              children: [
                TextSpan(text: _endTitle1),
                TextSpan(text: _endTitleBlue, style: _ps(14, color: _C.numC)),
              ],
            )),
            const SizedBox(height: 4),
            Text(_endSub, style: _ps(6, color: _C.ink2)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: _C.ink,
              child: Text(_rank(), style: _ps(36, color: _C.gold).copyWith(
                shadows: [const Shadow(color: _C.ink, offset: Offset(3, 3))], letterSpacing: 2,
              )),
            ),
            const SizedBox(height: 6),
            Text('$_correct/${_concepts.length} correct · max combo x$_maxCombo · $_score pts',
                textAlign: TextAlign.center,
                style: GoogleFonts.vt323(fontSize: 16, color: const Color(0xFF0A2D1A))),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _endBtn('↻ AGAIN', isCyan: true, onTap: _startGame),
              const SizedBox(width: 8),
              _endBtn('≡ MENU', isCyan: false, onTap: () {
                setState(() { _showEnd = false; _showTitle = true; });
              }),
            ]),
          ])),
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
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _C.ink, width: 2)),
      child: Text(text, style: _ps(6, color: color)),
    );
  }

  Widget _kbChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white, border: Border.all(color: _C.ink, width: 2),
        boxShadow: const [BoxShadow(color: Color(0xFFC8B27A), offset: Offset(0, 3), blurRadius: 0)],
      ),
      child: Text(text, style: _ps(6, color: _C.ink)),
    );
  }

  Widget _endBtn(String label, {required bool isCyan, required VoidCallback onTap}) {
    final bg = isCyan ? _C.numC : _C.gold;
    final shadow = isCyan ? _C.numD : const Color(0xFFA8821A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: _C.ink, width: 3),
          boxShadow: [
            BoxShadow(color: shadow, offset: const Offset(0, 5), blurRadius: 0),
            const BoxShadow(color: _C.ink, offset: Offset(0, 8), blurRadius: 0),
          ],
        ),
        child: Text(label, style: _ps(9, color: _C.ink)),
      ),
    );
  }

  TextStyle _ps(double size, {Color color = Colors.white}) {
    return TextStyle(fontFamily: 'Press Start 2P', fontSize: size, color: color, letterSpacing: 1, height: 1.3);
  }
}
