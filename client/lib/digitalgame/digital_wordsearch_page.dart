import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digital_quiz_page.dart';
import '../services/api_service.dart';
import 'digital_review_page.dart';
import 'lesson_slide_texts.dart';

// ===========================================================================
//  COLORS
// ===========================================================================
class _WSColors {
  static const cream     = Color(0xFFF4E9D0);
  static const cream2    = Color(0xFFFFEFD1);
  static const paper     = Color(0xFFFFFDF6);
  static const ink       = Color(0xFF28204A);
  static const inkSoft   = Color(0xFF5B5380);
  static const grassLight= Color(0xFFB8E07A);
  static const grass     = Color(0xFF9BD96B);
  static const grassDeep = Color(0xFF6BB347);
  static const fairway   = Color(0xFFC9E589);
  static const sand      = Color(0xFFF2D58E);
  static const sandEdge  = Color(0xFFD9B863);
  static const sun       = Color(0xFFFFC83D);
  static const sunLight  = Color(0xFFFFE48A);
  static const sunDeep   = Color(0xFFE0A300);
  static const coral     = Color(0xFFFF8A77);
  static const coralDeep = Color(0xFFE25A45);
  static const purple    = Color(0xFF7B5DC2);
  static const purpleDeep= Color(0xFF5E45A0);
  static const tealBg    = Color(0xFF5FB5A8);
  static const tealBg2   = Color(0xFF4A9A8E);
  static const headerBg  = Color(0xFF2B2342);
}

const _kSize = 10;
const _kPathColors = <Color>[
  Color(0xFF6BC5FF),
  Color(0xFFFF8A77),
  Color(0xFFB07BD6),
  Color(0xFFFFC83D),
  Color(0xFF7BD8B5),
  Color(0xFFF079A8),
];

// ===========================================================================
//  GRID GENERATION
// ===========================================================================
class _Cell {
  final int r, c;
  const _Cell(this.r, this.c);
  @override
  bool operator ==(Object o) => o is _Cell && o.r == r && o.c == c;
  @override
  int get hashCode => r * 1000 + c;
}

class _PlacedWord {
  final String word;
  final List<_Cell> cells;
  _PlacedWord(this.word, this.cells);
}

class _GameData {
  final List<List<String>> grid;
  final List<_PlacedWord> placed;
  _GameData(this.grid, this.placed);
}

_GameData _generateGrid(List<String> words, int size) {
  final rng = math.Random();
  final grid = List.generate(size, (_) => List<String>.filled(size, '', growable: false));
  final placed = <_PlacedWord>[];
  const dirs = [
    [0, 1], [1, 0], [1, 1], [-1, 1],
    [0, -1], [-1, 0], [1, -1], [-1, -1],
  ];
  final ordered = [...words]..sort((a, b) => b.length.compareTo(a.length));
  for (final word in ordered) {
    var didPlace = false;
    for (var attempt = 0; attempt < 400 && !didPlace; attempt++) {
      final d = dirs[rng.nextInt(dirs.length)];
      final sr = rng.nextInt(size);
      final sc = rng.nextInt(size);
      final er = sr + d[0] * (word.length - 1);
      final ec = sc + d[1] * (word.length - 1);
      if (er < 0 || er >= size || ec < 0 || ec >= size) continue;
      var ok = true;
      final cells = <_Cell>[];
      for (var i = 0; i < word.length; i++) {
        final r = sr + d[0] * i;
        final c = sc + d[1] * i;
        final existing = grid[r][c];
        if (existing.isNotEmpty && existing != word[i]) { ok = false; break; }
        cells.add(_Cell(r, c));
      }
      if (!ok) continue;
      for (var i = 0; i < word.length; i++) {
        grid[cells[i].r][cells[i].c] = word[i];
      }
      placed.add(_PlacedWord(word, cells));
      didPlace = true;
    }
  }
  const abc = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (var r = 0; r < size; r++) {
    for (var c = 0; c < size; c++) {
      if (grid[r][c].isEmpty) grid[r][c] = abc[rng.nextInt(abc.length)];
    }
  }
  return _GameData(grid, placed);
}

List<_Cell>? _getLineCells(int sr, int sc, int er, int ec) {
  final dr = er - sr;
  final dc = ec - sc;
  final len = math.max(dr.abs(), dc.abs());
  if (len == 0) return [_Cell(sr, sc)];
  if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return null;
  final stepR = dr == 0 ? 0 : dr.sign;
  final stepC = dc == 0 ? 0 : dc.sign;
  final out = <_Cell>[];
  for (var i = 0; i <= len; i++) {
    out.add(_Cell(sr + stepR * i, sc + stepC * i));
  }
  return out;
}

// ===========================================================================
//  PAGE
// ===========================================================================
class DigitalWordSearchPage extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback? onChainFinished;
  const DigitalWordSearchPage({super.key, required this.lesson, this.onChainFinished});

  @override
  State<DigitalWordSearchPage> createState() => _DigitalWordSearchPageState();
}

class _DigitalWordSearchPageState extends State<DigitalWordSearchPage>
    with TickerProviderStateMixin {

  // Fallback words used while AI words are loading or if the request fails
  static const List<String> _fallbackWords = [
    'SOFTWARE', 'HARDWARE', 'INBOX', 'WEBPAGE', 'BROWSER', 'INTERNET',
  ];

  List<String> _words = List.of(_fallbackWords);
  bool _isLoading = true;

  late _GameData _game;
  final Map<String, _Found> _found = {};
  _Cell? _selStart;
  _Cell? _selEnd;
  _Cell? _hintCell;
  int _stars = 0;
  String _hintMsg = 'Drag across letters to spell a word!';
  bool _done = false;

  final GlobalKey _gridKey = GlobalKey();

  late final AnimationController _confettiCtrl;
  late final AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _game = _generateGrid(_words, _kSize);
    _loadAiWords();
  }

  Future<void> _loadAiWords() async {
    final lessonNumber = widget.lesson['number'] as int;
    final slideTexts = LessonSlideTexts.forLesson(lessonNumber);
    if (slideTexts.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    final aiWords = await ApiService.generateWordSearchWords(
      lessonNumber: lessonNumber,
      slideTexts: slideTexts,
    );
    if (!mounted) return;
    if (aiWords.length >= 4) {
      setState(() {
        _words = aiWords;
        _game = _generateGrid(_words, _kSize);
        _found.clear();
        _stars = 0;
        _done = false;
        _hintMsg = 'New words loaded! Drag to find them!';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ New words generated from lesson!',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: _WSColors.grassDeep,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _hintMsg = 'Could not reach AI — using default words.';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ AI unavailable — is the server running?',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            backgroundColor: _WSColors.coral,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _resetPuzzle() {
    setState(() {
      _game = _generateGrid(_words, _kSize);
      _found.clear();
      _selStart = null;
      _selEnd = null;
      _done = false;
      _stars = 0;
      _hintMsg = 'Drag across letters to spell a word!';
    });
  }

  _Cell? _cellFromGlobal(Offset global) {
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    final size = box.size;
    final cw = size.width / _kSize;
    final ch = size.height / _kSize;
    final c = (local.dx / cw).floor();
    final r = (local.dy / ch).floor();
    if (r < 0 || r >= _kSize || c < 0 || c >= _kSize) return null;
    return _Cell(r, c);
  }

  void _onPanStart(DragStartDetails d) {
    if (_done) return;
    final cell = _cellFromGlobal(d.globalPosition);
    if (cell == null) return;
    setState(() { _selStart = cell; _selEnd = cell; });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_selStart == null) return;
    final cell = _cellFromGlobal(d.globalPosition);
    if (cell == null) return;
    final dr = cell.r - _selStart!.r;
    final dc = cell.c - _selStart!.c;
    if (dr != 0 && dc != 0 && dr.abs() != dc.abs()) return;
    if (cell == _selEnd) return;
    setState(() => _selEnd = cell);
  }

  void _onPanEnd(_) {
    if (_selStart == null || _selEnd == null) return;
    final cells = _getLineCells(_selStart!.r, _selStart!.c, _selEnd!.r, _selEnd!.c);
    setState(() { _selStart = null; _selEnd = null; });
    if (cells == null) return;
    final letters = cells.map((c) => _game.grid[c.r][c.c]).join();
    final reversed = letters.split('').reversed.join();

    String? match;
    List<_Cell> matchedCells = cells;
    if (_words.contains(letters)) {
      match = letters;
    } else if (_words.contains(reversed)) {
      match = reversed;
      matchedCells = cells.reversed.toList();
    }

    if (match != null && !_found.containsKey(match)) {
      final color = _kPathColors[_found.length % _kPathColors.length];
      setState(() {
        _found[match!] = _Found(matchedCells, color);
        _stars++;
        _hintMsg = '✨ $match! ${_encouragement()}';
      });
      if (_found.length == _game.placed.length) {
    _bounceCtrl.forward(from: 0);
    _confettiCtrl.forward(from: 0);
    // Save score to backend
    final lessonNumber = widget.lesson['number'] as int;
    ApiService.saveWordSearchScore(
      gameId: 'digital-literacy',
      lessonNumber: lessonNumber,
      found: _found.length,
      total: _game.placed.length,
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _done = true);
    });
  }
    } else if (match != null && _found.containsKey(match)) {
      setState(() => _hintMsg = 'You already found $match!');
    } else if (cells.length > 1) {
      setState(() => _hintMsg = 'Not on the list — try again!');
    }
  }

  String _encouragement() {
    const msgs = ['Nice!', 'Great spot!', 'Sharp eyes!', 'You got it!', 'Boom!'];
    return msgs[math.Random().nextInt(msgs.length)];
  }

  void _giveHint() {
    final next = _game.placed.firstWhere(
      (p) => !_found.containsKey(p.word),
      orElse: () => _game.placed.first,
    );
    setState(() {
      _hintCell = next.cells.first;
      _hintMsg = 'Look for "${next.word}" 👀';
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _hintCell = null);
    });
  }

  // ==========================================================================
  //  BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle  = widget.lesson['title']  as String;

    return Scaffold(
      backgroundColor: _WSColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(lessonNumber, lessonTitle),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildStage()),
                      _buildSideRail(),
                    ],
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => _confettiCtrl.value > 0
                  ? IgnorePointer(child: _Confetti(controller: _confettiCtrl))
                  : const SizedBox.shrink(),
            ),
            if (_done) _buildWinOverlay(),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  // ── LOADING OVERLAY ──
  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0x88000000),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            decoration: BoxDecoration(
              color: _WSColors.paper,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 30)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(color: _WSColors.purple),
              const SizedBox(height: 16),
              Text('Generating new words…',
                  style: GoogleFonts.nunito(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _WSColors.ink)),
            ]),
          ),
        ),
      ),
    );
  }

  // ── HEADER ──
  Widget _buildHeader(int lessonNumber, String lessonTitle) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _WSColors.headerBg,
        boxShadow: [BoxShadow(color: Color(0x2E000000), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [_WSColors.sun, _WSColors.coral],
              ),
              boxShadow: const [BoxShadow(color: _WSColors.coralDeep, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.pets, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('name of web',
                  style: GoogleFonts.montserrat(
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: _WSColors.sun, letterSpacing: 0.5, height: 1)),
              Text('WORD SEARCH',
                  style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE9B5), letterSpacing: 2)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _WSColors.sun, borderRadius: BorderRadius.circular(6)),
                child: Text('#$lessonNumber',
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800, color: _WSColors.ink, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text(lessonTitle.toUpperCase(),
                  style: GoogleFonts.nunito(
                      fontSize: 13, color: const Color(0xFFFFE9B5),
                      letterSpacing: 1, fontWeight: FontWeight.w700)),
            ]),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star_rounded, color: _WSColors.sun, size: 26),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('FOUND', style: GoogleFonts.nunito(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE9B5), letterSpacing: 1.5)),
                  Text('$_stars / ${_words.length}',
                      style: GoogleFonts.nunito(
                          fontSize: 18, color: _WSColors.cream,
                          height: 1, fontWeight: FontWeight.w700)),
                ],
              ),
            ]),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _WSColors.coral,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: _WSColors.coralDeep, offset: Offset(0, 3))],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── STAGE ──
  Widget _buildStage() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFF4E9D0), Color(0xFFE8D9B5)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _SceneryPainter())),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                child: Row(
                  children: [
                    Expanded(child: Center(child: _buildGridFrame())),
                    const SizedBox(width: 12),
                    _buildFlag(),
                  ],
                ),
              ),
              Positioned(
                left: 18, bottom: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MascotChick(controller: _bounceCtrl, cheer: _done),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: _SpeechBubble(text: _hintMsg),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GRID FRAME ──
  Widget _buildGridFrame() {
    const gridSize = _kSize * 44.0 + 9 * 2.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center, radius: 0.85,
          colors: [_WSColors.fairway, _WSColors.grass, _WSColors.grassDeep],
        ),
        borderRadius: BorderRadius.circular(180),
        border: Border.all(color: _WSColors.sand, width: 8),
        boxShadow: [
          const BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
          BoxShadow(color: _WSColors.sandEdge, spreadRadius: 6),
        ],
      ),
      child: SizedBox(
        width: gridSize, height: gridSize,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(null),
          child: Stack(
            key: _gridKey,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathOverlayPainter(
                    found: _found.values.toList(),
                    selStart: _selStart,
                    selEnd: _selEnd,
                    size: _kSize,
                  ),
                ),
              ),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _kSize,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: _kSize * _kSize,
                itemBuilder: (_, i) {
                  final r = i ~/ _kSize;
                  final c = i % _kSize;
                  final letter = _game.grid[r][c];
                  final isSel = _isInSelection(r, c);
                  final foundColor = _findColorAt(r, c);
                  final isHint = _hintCell != null && _hintCell!.r == r && _hintCell!.c == c;
                  return _Cellette(
                    letter: letter,
                    isSelecting: isSel,
                    foundColor: foundColor,
                    isHint: isHint,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isInSelection(int r, int c) {
    if (_selStart == null || _selEnd == null) return false;
    final cells = _getLineCells(_selStart!.r, _selStart!.c, _selEnd!.r, _selEnd!.c);
    if (cells == null) return false;
    return cells.any((cc) => cc.r == r && cc.c == c);
  }

  Color? _findColorAt(int r, int c) {
    for (final f in _found.values) {
      if (f.cells.any((cc) => cc.r == r && cc.c == c)) return f.color;
    }
    return null;
  }

  // ── FLAG (word list) ──
  Widget _buildFlag() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -8, top: -30, bottom: -120, width: 8,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFFE0D8C5), Color(0xFFB5A88E)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
        Container(
          width: 200,
          padding: const EdgeInsets.fromLTRB(22, 22, 24, 24),
          decoration: BoxDecoration(
            color: _WSColors.purple,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x592D2380), blurRadius: 22, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('FIND THESE WORDS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800, fontSize: 11,
                      letterSpacing: 2, color: const Color(0xFFFFE9B5))),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _words.map((w) => _WordItem(
                    word: w, found: _found.containsKey(w))).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SIDE RAIL ──
  Widget _buildSideRail() {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [_WSColors.tealBg, _WSColors.tealBg2],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(children: [
        _RailButton(icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.of(context).pop()),
        const SizedBox(height: 14),
        _RailButton(icon: Icons.refresh_rounded, onTap: _isLoading ? null : _resetPuzzle),
        const SizedBox(height: 14),
        _RailButton(
          icon: Icons.auto_awesome_rounded,
          onTap: _isLoading ? null : _loadAiWords,
          color: _WSColors.sun,
        ),
        const SizedBox(height: 14),
        _RailButton(icon: Icons.lightbulb_rounded, onTap: _isLoading ? null : _giveHint),
        const Spacer(),
        _NextButton(
          pulsing: _done,
// In _buildSideRail and win overlay:
onTap: _done ? () => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DigitalQuizPage(lesson: widget.lesson, onChainFinished: widget.onChainFinished),
  ),
) : null,        ),
      ]),
    );
  }

  // ── WIN OVERLAY ──
  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xC72B2342),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
            decoration: BoxDecoration(
              color: _WSColors.paper,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x66000000), blurRadius: 60, offset: Offset(0, 20)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('⭐⭐⭐', style: TextStyle(fontSize: 48, letterSpacing: 6)),
              const SizedBox(height: 12),
              Text('You found them all!',
                  style: GoogleFonts.nunito(
                      fontSize: 32, fontWeight: FontWeight.w800, color: _WSColors.ink)),
              const SizedBox(height: 8),
              Text('${_game.placed.length} words spotted. Sharp eyes!',
                  style: GoogleFonts.nunito(fontSize: 18, color: _WSColors.inkSoft)),
              const SizedBox(height: 22),
              GestureDetector(
onTap: _done ? () => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => DigitalQuizPage(lesson: widget.lesson, onChainFinished: widget.onChainFinished),
  ),
) : null,                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: _WSColors.sun,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: _WSColors.sunDeep, offset: Offset(0, 5))],
                  ),
                  child: Text('Continue →',
                      style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700, fontSize: 20, color: _WSColors.ink)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
//  PIECES
// ===========================================================================
class _Found {
  final List<_Cell> cells;
  final Color color;
  _Found(this.cells, this.color);
}

class _Cellette extends StatelessWidget {
  final String letter;
  final bool isSelecting;
  final Color? foundColor;
  final bool isHint;
  const _Cellette({
    required this.letter, required this.isSelecting,
    required this.foundColor, required this.isHint,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    BoxBorder? border;
    List<BoxShadow>? shadows;

    if (foundColor != null) {
      bg = Colors.transparent;
      fg = Colors.white;
      shadows = const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 1))];
    } else if (isSelecting) {
      bg = _WSColors.sun;
      fg = _WSColors.ink;
      shadows = const [BoxShadow(color: _WSColors.sunDeep, blurRadius: 0, spreadRadius: 3)];
    } else {
      bg = _WSColors.paper;
      fg = _WSColors.ink;
      shadows = const [BoxShadow(color: Color(0x1A28204A), offset: Offset(0, 2))];
    }
    if (isHint) border = Border.all(color: _WSColors.sun, width: 3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: bg, shape: BoxShape.circle,
        border: border, boxShadow: shadows,
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: fg,
              shadows: foundColor != null
                  ? const [Shadow(color: Color(0x4D000000), offset: Offset(0, 1))]
                  : null)),
    );
  }
}

class _WordItem extends StatelessWidget {
  final String word;
  final bool found;
  const _WordItem({required this.word, required this.found});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Text(word,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(found ? 0.45 : 1),
                  letterSpacing: 1)),
          if (found)
            Positioned(
              left: -2, right: -2,
              child: Transform.rotate(
                angle: -0.03,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                      color: _WSColors.sun,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathOverlayPainter extends CustomPainter {
  final List<_Found> found;
  final _Cell? selStart;
  final _Cell? selEnd;
  final int size;
  _PathOverlayPainter({
    required this.found, required this.selStart,
    required this.selEnd, required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cw = canvasSize.width / size;
    final ch = canvasSize.height / size;
    final stroke = cw * 0.85;
    for (final f in found) {
      final first = f.cells.first;
      final last = f.cells.last;
      canvas.drawLine(
        Offset((first.c + 0.5) * cw, (first.r + 0.5) * ch),
        Offset((last.c + 0.5) * cw, (last.r + 0.5) * ch),
        Paint()..color = f.color.withOpacity(0.55)
               ..strokeWidth = stroke ..strokeCap = StrokeCap.round,
      );
    }
    if (selStart != null && selEnd != null) {
      canvas.drawLine(
        Offset((selStart!.c + 0.5) * cw, (selStart!.r + 0.5) * ch),
        Offset((selEnd!.c + 0.5) * cw, (selEnd!.r + 0.5) * ch),
        Paint()..color = _WSColors.sun.withOpacity(0.45)
               ..strokeWidth = stroke ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PathOverlayPainter old) =>
      old.found != found || old.selStart != selStart || old.selEnd != selEnd;
}

class _SceneryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(const Offset(80, 80), 38,
        Paint()..color = _WSColors.sunLight.withOpacity(0.85));
    canvas.drawCircle(const Offset(80, 80), 26, Paint()..color = _WSColors.sun);
    final cloud = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(const Offset(220, 70), 14, cloud);
    canvas.drawCircle(const Offset(240, 60), 18, cloud);
    canvas.drawCircle(const Offset(270, 72), 14, cloud);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height + 80),
        width: size.width + 200, height: 220,
      ),
      Paint()..color = _WSColors.grass.withOpacity(0.45),
    );
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class _MascotChick extends StatelessWidget {
  final AnimationController controller;
  final bool cheer;
  const _MascotChick({required this.controller, required this.cheer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Transform.translate(
          offset: Offset(0, math.sin(t * math.pi) * -14),
          child: Transform.rotate(
            angle: math.sin(t * math.pi * 2) * 0.12,
            child: SizedBox(width: 64, height: 64,
                child: CustomPaint(painter: _ChickPainter(cheer: cheer))),
          ),
        );
      },
    );
  }
}

class _ChickPainter extends CustomPainter {
  final bool cheer;
  _ChickPainter({required this.cheer});
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 80;
    void ellipse(double cx, double cy, double rx, double ry, Color c) {
      canvas.drawOval(Rect.fromCenter(
          center: Offset(cx*s, cy*s), width: rx*2*s, height: ry*2*s),
          Paint()..color = c);
    }
    void circle(double cx, double cy, double r, Color c) {
      canvas.drawCircle(Offset(cx*s, cy*s), r*s, Paint()..color = c);
    }
    ellipse(30, 72, 6, 3, _WSColors.sunDeep);
    ellipse(50, 72, 6, 3, _WSColors.sunDeep);
    ellipse(40, 48, 26, 24, _WSColors.sun);
    ellipse(40, 52, 16, 14, _WSColors.sunLight);
    ellipse(18, 48, 6, 10, _WSColors.sunDeep);
    ellipse(62, 48, 6, 10, _WSColors.sunDeep);
    circle(40, 18, 4, _WSColors.sunDeep);
    if (cheer) {
      final p = Paint()..color = _WSColors.ink ..strokeWidth = 3*s
        ..strokeCap = StrokeCap.round ..style = PaintingStyle.stroke;
      canvas.drawPath(Path()..moveTo(27*s,30*s)..quadraticBezierTo(31*s,24*s,36*s,30*s), p);
      canvas.drawPath(Path()..moveTo(44*s,30*s)..quadraticBezierTo(48*s,24*s,53*s,30*s), p);
    } else {
      circle(32,30,5,Colors.white); circle(48,30,5,Colors.white);
      circle(33,31,2.4,_WSColors.ink); circle(49,31,2.4,_WSColors.ink);
    }
    final beak = Path()..moveTo(36*s,38*s)..lineTo(44*s,38*s)..lineTo(40*s,44*s)..close();
    canvas.drawPath(beak, Paint()..color = _WSColors.coral);
    canvas.drawCircle(Offset(24*s,42*s), 3*s, Paint()..color = _WSColors.coral.withOpacity(0.55));
    canvas.drawCircle(Offset(56*s,42*s), 3*s, Paint()..color = _WSColors.coral.withOpacity(0.55));
  }
  @override bool shouldRepaint(_ChickPainter o) => o.cheer != cheer;
}

class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechArrowPainter(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14,7,12,7),
        decoration: BoxDecoration(
          color: _WSColors.cream2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _WSColors.sunDeep, width: 2.5),
        ),
        child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
                fontSize: 14, fontWeight: FontWeight.w500,
                color: _WSColors.ink, height: 1.25)),
      ),
    );
  }
}

class _SpeechArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()..moveTo(-2, size.height/2-9)..lineTo(-14, size.height/2)..lineTo(-2, size.height/2+9)..close(),
        Paint()..color = _WSColors.sunDeep);
    canvas.drawPath(
        Path()..moveTo(0, size.height/2-7)..lineTo(-10, size.height/2)..lineTo(0, size.height/2+7)..close(),
        Paint()..color = _WSColors.cream2);
  }
  @override bool shouldRepaint(covariant CustomPainter o) => false;
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  const _RailButton({required this.icon, this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final bg = color ?? _WSColors.purple;
    return Opacity(
      opacity: onTap != null ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: bg.withValues(alpha: 0.6), offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _NextButton extends StatefulWidget {
  final bool pulsing;
  final VoidCallback? onTap;
  const _NextButton({required this.pulsing, required this.onTap});
  @override State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final scale = widget.pulsing ? 1 + (_c.value * 0.08) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: widget.onTap != null ? _WSColors.sun : Colors.grey.withOpacity(0.4),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: _WSColors.sunDeep, offset: Offset(0, 5))],
          ),
          child: Icon(Icons.chevron_right_rounded, size: 36,
              color: widget.onTap != null ? _WSColors.ink : Colors.white38),
        ),
      ),
    );
  }
}

class _Confetti extends StatefulWidget {
  final AnimationController controller;
  const _Confetti({required this.controller});
  @override State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> {
  final _rand = math.Random();
  late final List<_Piece> _pieces;
  @override
  void initState() {
    super.initState();
    const colors = [_WSColors.sun, _WSColors.coral, _WSColors.grass,
                    Color(0xFF6BC5FF), _WSColors.purple, Color(0xFF7BD8B5)];
    _pieces = List.generate(80, (_) => _Piece(
      x: _rand.nextDouble(), delay: _rand.nextDouble()*0.3,
      dur: 0.6+_rand.nextDouble()*0.45,
      color: colors[_rand.nextInt(colors.length)],
      rotSpeed: 2+_rand.nextDouble()*4,
    ));
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) {
        final t = widget.controller.value;
        final h = MediaQuery.of(context).size.height;
        final w = MediaQuery.of(context).size.width;
        return Stack(children: _pieces.map((p) {
          final lt = ((t-p.delay)/p.dur).clamp(0.0,1.0);
          return Positioned(
            left: p.x * w,
            top: -30 + lt*(h+60),
            child: Opacity(opacity: 1-0.6*lt,
              child: Transform.rotate(angle: lt*p.rotSpeed*math.pi,
                child: Container(width:10, height:14,
                    decoration: BoxDecoration(color:p.color,
                        borderRadius:BorderRadius.circular(3))))),
          );
        }).toList());
      },
    );
  }
}

class _Piece {
  final double x, delay, dur, rotSpeed;
  final Color color;
  _Piece({required this.x, required this.delay, required this.dur,
          required this.color, required this.rotSpeed});
}
