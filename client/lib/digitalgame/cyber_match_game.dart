import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'digital_review_page.dart';

// ── COLORS ───────────────────────────────────────────────────────────────────
class _K {
  static const bg1       = Color(0xFFFFE3CF);
  static const bg2       = Color(0xFFFFD1B3);
  static const mint      = Color(0xFFB6EAD2);
  static const mintDeep  = Color(0xFF6FCF9B);
  static const cheese    = Color(0xFFF7D96A);
  static const cheeseD   = Color(0xFFE3BF3A);
  static const cheeseSh  = Color(0xFFBD9520);
  static const lavender  = Color(0xFFC9B6F0);
  static const lavenderD = Color(0xFF8C6FD6);
  static const peach     = Color(0xFFFF9B71);
  static const berry     = Color(0xFFFF5C8A);
  static const ink       = Color(0xFF2D2150);
  static const softInk   = Color(0xFF5B4B85);
  static const paper     = Color(0xFFFFF7EC);
  static const pink      = Color(0xFFFFD6E3);
  static const blue      = Color(0xFF79B9FF);
  static const red       = Color(0xFFFF7A8A);
}

// ── PAIR DATA ─────────────────────────────────────────────────────────────────
class _PairData {
  final String id;
  final String label;
  _PairData(this.id, this.label);
}

final _pairs = [
  _PairData('strong',   'Strong\nPassword'),
  _PairData('weak',     'Weak\nPassword'),
  _PairData('phishing', 'Phishing'),
  _PairData('fake',     'Fake\nNews'),
  _PairData('bully',    'Cyber-\nBullying'),
  _PairData('threats',  'Digital\nThreats'),
  _PairData('balance',  'Digital\nBalance'),
  _PairData('citizen',  'Digital\nCitizen'),
];

// ── CARD MODEL ────────────────────────────────────────────────────────────────
class _Card {
  final String pairId;
  final bool isText; // true=label card, false=illustration card
  bool flipped = false;
  bool matched = false;
  bool wrong   = false;
  _Card({required this.pairId, required this.isText});
}

// ── ENCOURAGE MESSAGES ────────────────────────────────────────────────────────
const _matchMsgs = [
  "Yes! Great match!",
  "You're crushing it!",
  "Amazing memory!",
  "Two cheese pieces — together!",
  "Cyber smart!",
  "Wow, nice find!",
];
const _missMsgs = [
  "Oops, try again!",
  "Almost! Keep going.",
  "Don't worry, you got this.",
  "Remember where they are!",
  "Try another pair!",
];

// ── PAGE ─────────────────────────────────────────────────────────────────────
class CyberMatchGame extends StatefulWidget {
  final Map<String, dynamic> lesson;
  const CyberMatchGame({super.key, required this.lesson});

  @override
  State<CyberMatchGame> createState() => _CyberMatchGameState();
}

class _CyberMatchGameState extends State<CyberMatchGame> {
  late List<_Card> _cards;
  _Card? _firstPick;
  bool _lock = false;
  int _moves = 0;
  int _matched = 0;
  int _secs = 0;
  Timer? _timer;
  bool _won = false;
  String _speech = "Hi friend! Flip two cheese cards to find a matching pair. Ready?";
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    final deck = <_Card>[];
    for (final p in _pairs) {
      deck.add(_Card(pairId: p.id, isText: true));
      deck.add(_Card(pairId: p.id, isText: false));
    }
    deck.shuffle(_rng);
    setState(() {
      _cards   = deck;
      _firstPick = null;
      _lock    = false;
      _moves   = 0;
      _matched = 0;
      _secs    = 0;
      _won     = false;
      _speech  = "Hi friend! Flip two cheese cards to find a matching pair. Ready?";
      _timer   = null;
    });
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secs++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String get _timeStr {
    final m = (_secs ~/ 60).toString().padLeft(2, '0');
    final s = (_secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _pickMsg(List<String> list) => list[_rng.nextInt(list.length)];

  void _onTap(_Card card) {
    if (_lock) return;
    if (card.flipped || card.matched) return;

    _startTimer();
    setState(() => card.flipped = true);

    if (_firstPick == null) {
      _firstPick = card;
      return;
    }

    // second pick
    setState(() {
      _moves++;
      _lock = true;
    });

    if (_firstPick!.pairId == card.pairId && _firstPick != card) {
      // ── MATCH ──
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _firstPick!.matched = true;
          card.matched = true;
          _matched++;
          _speech = _pickMsg(_matchMsgs);
          _firstPick = null;
          _lock = false;
        });
        if (_matched == _pairs.length) {
          _stopTimer();
          setState(() => _won = true);
        }
      });
    } else {
      // ── MISS ──
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        setState(() {
          _firstPick!.wrong = true;
          card.wrong = true;
        });
      });
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _firstPick!.flipped = false;
          _firstPick!.wrong   = false;
          card.flipped = false;
          card.wrong   = false;
          _firstPick  = null;
          _lock        = false;
          _speech      = _pickMsg(_missMsgs);
        });
      });
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lessonNumber = widget.lesson['number'] as int;
    final lessonTitle  = widget.lesson['title']  as String;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_K.bg1, _K.bg2],
                ),
              ),
            ),
          ),
          // ── Dot pattern overlay ──
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DotsPainter()),
            ),
          ),
          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(lessonNumber, lessonTitle),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sidebar
                        SizedBox(width: 270, child: _buildSidebar()),
                        const SizedBox(width: 20),
                        // Board
                        Expanded(child: _buildBoardWrap()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Win overlay ──
          if (_won) _buildWinOverlay(),
        ],
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(int lessonNumber, String lessonTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Brand pill
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 18, 10),
            decoration: BoxDecoration(
              color: _K.paper,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(color: Color(0x1F2D2150), blurRadius: 24, offset: Offset(0, 12)),
                BoxShadow(color: Color(0x1F2D2150), blurRadius: 0, offset: Offset(0, 6)),
              ],
            ),
            child: Row(children: [
              // Bytey star icon
              _ByteyWidget(size: 40),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cyber Match',
                    style: GoogleFonts.fredoka(
                        fontSize: 20, fontWeight: FontWeight.w700,
                        color: _K.ink, height: 1)),
                Text('DIGITAL CITIZENSHIP GAME',
                    style: GoogleFonts.quicksand(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: _K.softInk, letterSpacing: 1)),
              ]),
            ]),
          ),
          const Spacer(),
          // Stats
          _statChip(
            color: _K.mint,
            icon: Icons.check_rounded,
            label: 'Pairs',
            value: '$_matched/8',
          ),
          const SizedBox(width: 10),
          _statChip(
            color: _K.lavender,
            icon: Icons.add_rounded,
            label: 'Moves',
            value: '$_moves',
          ),
          const SizedBox(width: 10),
          _statChip(
            color: _K.pink,
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _timeStr,
          ),
          const SizedBox(width: 14),
          // New Game button
          GestureDetector(
            onTap: _reset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _K.mint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: _K.mintDeep, offset: Offset(0, 6), blurRadius: 0),
                ],
              ),
              child: Row(children: [
                const Icon(Icons.refresh_rounded, color: _K.ink, size: 18),
                const SizedBox(width: 8),
                Text('New Game',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _K.ink)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // NEXT button
          GestureDetector(
            onTap: _won
                ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DigitalReviewPage(lesson: widget.lesson),
                    ))
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: _won ? _K.cheese : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _won ? _K.cheeseSh : Colors.transparent,
                    offset: const Offset(0, 6), blurRadius: 0),
                ],
              ),
              child: Row(children: [
                Text('Next',
                    style: GoogleFonts.fredoka(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: _won ? _K.ink : Colors.white38)),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    color: _won ? _K.ink : Colors.white38, size: 18),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required Color color, required IconData icon,
    required String label, required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _K.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x1F2D2150), offset: Offset(0, 5), blurRadius: 0),
        ],
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _K.ink, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.quicksand(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: _K.softInk, letterSpacing: 1)),
          Text(value,
              style: GoogleFonts.fredoka(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: _K.ink, height: 1)),
        ]),
      ]),
    );
  }

  // ── SIDEBAR ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _K.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x1A2D2150), offset: Offset(0, 10), blurRadius: 0),
          BoxShadow(color: Color(0x1A2D2150), blurRadius: 30, offset: Offset(0, 20)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        // Mascot box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF3DF), Color(0xFFFFE6C8)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFC287), width: 3,
                style: BorderStyle.solid),
          ),
          child: Column(children: [
            _ByteyWidget(size: 50),
            const SizedBox(height: 4),
            Text('Bytey the Star',
                style: GoogleFonts.fredoka(
                    fontSize: 22, fontWeight: FontWeight.w700, color: _K.ink)),
            const SizedBox(height: 10),
            // Speech bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x142D2150), offset: Offset(0, 3)),
                ],
              ),
              child: Text(_speech,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: _K.softInk)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Legend
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF3E7D3), width: 2),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FIND THESE PAIRS',
                style: GoogleFonts.fredoka(
                    fontSize: 17, fontWeight: FontWeight.w700,
                    color: _K.ink, letterSpacing: .5)),
            const SizedBox(height: 12),
            ...['Strong password', 'Weak password', 'Phishing', 'Fake news',
                'Cyberbullying', 'Digital threats', 'Digital balance', 'Digital citizen']
                .map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Text('🧀 ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(t,
                        style: GoogleFonts.quicksand(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: _K.softInk))),
                  ]),
                )),
          ]),
        ),
      ]),
    );
  }

  // ── BOARD ─────────────────────────────────────────────────────────────────
  Widget _buildBoardWrap() {
    return Container(
      decoration: BoxDecoration(
        color: _K.paper,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x1A2D2150), offset: Offset(0, 10), blurRadius: 0),
          BoxShadow(color: Color(0x1A2D2150), blurRadius: 30, offset: Offset(0, 20)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 7,
          mainAxisSpacing: 7,
          childAspectRatio: 1.8,
        ),
        itemCount: _cards.length,
        itemBuilder: (_, i) => _buildCard(_cards[i]),
      ),
    );
  }

  Widget _buildCard(_Card card) {
    return GestureDetector(
      onTap: () => _onTap(card),
      child: _FlipCard(card: card),
    );
  }

  // ── WIN OVERLAY ───────────────────────────────────────────────────────────
  Widget _buildWinOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0x8C2D2150),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: _WinCard(
              moves: _moves,
              time: _timeStr,
              onPlayAgain: _reset,
              onNext: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DigitalReviewPage(lesson: widget.lesson),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

// ── FLIP CARD WIDGET ──────────────────────────────────────────────────────────
class _FlipCard extends StatefulWidget {
  final _Card card;
  const _FlipCard({super.key, required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Cubic(.5, -.2, .4, 1.4)));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(covariant _FlipCard old) {
    super.didUpdateWidget(old);
    if (widget.card.flipped || widget.card.matched) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final angle = _anim.value * pi;
        final isShowingFront = _anim.value > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isShowingFront
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _buildFront(),
                )
              : _buildBack(),
        );
      },
    );
  }

  Widget _buildBack() {
    return Container(
      decoration: BoxDecoration(
        color: _K.cheese,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x73BD9520), offset: Offset(0, 6), blurRadius: 0),
        ],
      ),
      child: Stack(children: [
        // Cheese holes
        Positioned(top: '20%'.asH, left: '18%'.asW,
            child: _CheeseHole(size: 14)),
        Positioned(bottom: '22%'.asH, right: '24%'.asW,
            child: _CheeseHole(size: 10)),
        Positioned(top: '50%'.asH, right: '15%'.asW,
            child: _CheeseHole(size: 8)),
        Center(child: _ByteyWidget(size: 45)),
      ]),
    );
  }

  Widget _buildFront() {
    final card = widget.card;
    final isMatched = card.matched;
    final isWrong   = card.wrong;

    Color borderColor = isMatched ? _K.mintDeep : _K.cheese;
    if (isWrong) borderColor = _K.berry;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isMatched
            ? const Color(0xFFE6FBED)
            : isWrong
                ? const Color(0xFFFFECF0)
                : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 4),
        boxShadow: isMatched
            ? [
                BoxShadow(
                  color: _K.mintDeep.withOpacity(0.3),
                  blurRadius: 0, spreadRadius: 4),
                const BoxShadow(
                  color: _K.mintDeep, offset: Offset(0, 8), blurRadius: 0),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Center(
        child: card.isText
            ? Text(card.pairId == '' ? '' : _labelFor(card.pairId),
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: _K.ink, height: 1.1))
            : _IllusWidget(pairId: card.pairId),
      ),
    );
  }

  String _labelFor(String id) {
    return _pairs.firstWhere((p) => p.id == id).label;
  }
}

// ── ILLUSTRATION WIDGET ───────────────────────────────────────────────────────
class _IllusWidget extends StatelessWidget {
  final String pairId;
  const _IllusWidget({required this.pairId});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IllusPainter(pairId),
      size: const Size(80, 60),
    );
  }
}

class _IllusPainter extends CustomPainter {
  final String id;
  _IllusPainter(this.id);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    final h = size.height / 90;

    switch (id) {
      case 'strong':   _drawStrong(canvas, s, h);   break;
      case 'weak':     _drawWeak(canvas, s, h);     break;
      case 'phishing': _drawPhishing(canvas, s, h); break;
      case 'fake':     _drawFake(canvas, s, h);     break;
      case 'bully':    _drawBully(canvas, s, h);    break;
      case 'threats':  _drawThreats(canvas, s, h);  break;
      case 'balance':  _drawBalance(canvas, s, h);  break;
      case 'citizen':  _drawCitizen(canvas, s, h);  break;
    }
  }

  Paint _p(Color c, {bool stroke = false, double w = 3}) => Paint()
    ..color = c
    ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _rect(Canvas c, double x, double y, double w, double h,
      double rx, Color fill, double sx, double sy,
      {Color stroke = const Color(0xFF2D2150), double sw = 3}) {
    final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(x * sx, y * sy, w * sx, h * sy), Radius.circular(rx));
    c.drawRRect(r, _p(fill));
    c.drawRRect(r, _p(stroke, stroke: true, w: sw * (sx + sy) / 2));
  }

  void _drawStrong(Canvas c, double sx, double sy) {
    _rect(c, 10, 32, 70, 36, 8, Colors.white, sx, sy);
    final tp = TextPainter(
      text: TextSpan(
        text: 'P@x7!9#',
        style: TextStyle(fontFamily: 'monospace', fontSize: 14 * sx,
            fontWeight: FontWeight.w700, color: _K.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(22 * sx, 46 * sy));
    // Shield
    final shield = Path()
      ..moveTo(95 * sx, 22 * sy)
      ..lineTo(112 * sx, 28 * sy)
      ..lineTo(112 * sx, 50 * sy)
      ..quadraticBezierTo(112 * sx, 64 * sy, 95 * sx, 72 * sy)
      ..quadraticBezierTo(78 * sx, 64 * sy, 78 * sx, 50 * sy)
      ..lineTo(78 * sx, 28 * sy)
      ..close();
    c.drawPath(shield, _p(_K.mintDeep));
    c.drawPath(shield, _p(_K.ink, stroke: true));
    final check = Path()
      ..moveTo(86 * sx, 47 * sy)
      ..lineTo(93 * sx, 54 * sy)
      ..lineTo(104 * sx, 40 * sy);
    c.drawPath(check, _p(Colors.white, stroke: true, w: 4 * sx));
  }

  void _drawWeak(Canvas c, double sx, double sy) {
    _rect(c, 10, 32, 70, 36, 8, Colors.white, sx, sy);
    final tp = TextPainter(
      text: TextSpan(
        text: '12345',
        style: TextStyle(fontFamily: 'monospace', fontSize: 14 * sx,
            fontWeight: FontWeight.w700, color: _K.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(22 * sx, 46 * sy));
    _rect(c, 82, 40, 28, 26, 4, _K.red, sx, sy);
    final arc = Path()
      ..moveTo(88 * sx, 40 * sy)
      ..lineTo(88 * sx, 32 * sy)
      ..quadraticBezierTo(88 * sx, 24 * sy, 96 * sx, 24 * sy);
    c.drawPath(arc, _p(_K.ink, stroke: true));
    final x1 = Path()
      ..moveTo(90 * sx, 48 * sy)..lineTo(102 * sx, 60 * sy);
    final x2 = Path()
      ..moveTo(102 * sx, 48 * sy)..lineTo(90 * sx, 60 * sy);
    c.drawPath(x1, _p(Colors.white, stroke: true, w: 3.5 * sx));
    c.drawPath(x2, _p(Colors.white, stroke: true, w: 3.5 * sx));
  }

  void _drawPhishing(Canvas c, double sx, double sy) {
    _rect(c, 20, 40, 60, 38, 4, Colors.white, sx, sy);
    final v = Path()
      ..moveTo(20 * sx, 42 * sy)
      ..lineTo(50 * sx, 62 * sy)
      ..lineTo(80 * sx, 42 * sy);
    c.drawPath(v, _p(_K.ink, stroke: true));
    final hook = Path()
      ..moveTo(70 * sx, 8 * sy)
      ..lineTo(70 * sx, 32 * sy)
      ..quadraticBezierTo(70 * sx, 50 * sy, 56 * sx, 50 * sy)
      ..quadraticBezierTo(44 * sx, 50 * sy, 44 * sx, 40 * sy)
      ..quadraticBezierTo(44 * sx, 34 * sy, 50 * sx, 34 * sy)
      ..quadraticBezierTo(56 * sx, 34 * sy, 56 * sx, 38 * sy);
    c.drawPath(hook, _p(_K.ink, stroke: true, w: 3.5 * sx));
    c.drawCircle(Offset(70 * sx, 8 * sy), 3 * sx, _p(_K.ink));
    c.drawCircle(Offset(56 * sx, 38 * sy), 5 * sx, _p(_K.red));
    c.drawCircle(Offset(56 * sx, 38 * sy), 5 * sx, _p(_K.ink, stroke: true, w: 2));
  }

  void _drawFake(Canvas c, double sx, double sy) {
    _rect(c, 14, 14, 92, 62, 4, Colors.white, sx, sy);
    c.drawRect(Rect.fromLTWH(22 * sx, 22 * sy, 34 * sx, 22 * sy),
        _p(_K.lavender));
    for (final y in [22.0, 30.0, 36.0, 50.0, 58.0]) {
      c.drawRect(Rect.fromLTWH(60 * sx, y * sy, 38 * sx, 3 * sy),
          _p(y < 40 ? _K.ink : _K.softInk));
    }
    // FAKE stamp (rotated)
    canvas_save_rotate(c, -15 * pi / 180, Offset(71 * sx, 51 * sy), () {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(46 * sx, 40 * sy, 50 * sx, 22 * sy),
          const Radius.circular(3));
      c.drawRRect(r, _p(_K.berry, stroke: true, w: 3));
      final tp2 = TextPainter(
        text: TextSpan(
          text: 'FAKE',
          style: TextStyle(fontFamily: 'Fredoka', fontSize: 14 * sx,
              fontWeight: FontWeight.w700, color: _K.berry),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 50 * sx);
      tp2.paint(c, Offset(46 * sx, 44 * sy));
    });
  }

  void canvas_save_rotate(Canvas c, double angle, Offset center, VoidCallback draw) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(angle);
    c.translate(-center.dx, -center.dy);
    draw();
    c.restore();
  }

  void _drawBully(Canvas c, double sx, double sy) {
    _rect(c, 46, 22, 28, 50, 6, Colors.white, sx, sy);
    c.drawCircle(Offset(55 * sx, 42 * sy), 2.5 * sx, _p(_K.ink));
    c.drawCircle(Offset(65 * sx, 42 * sy), 2.5 * sx, _p(_K.ink));
    final frown = Path()
      ..moveTo(54 * sx, 58 * sy)
      ..quadraticBezierTo(60 * sx, 52 * sy, 66 * sx, 58 * sy);
    c.drawPath(frown, _p(_K.ink, stroke: true, w: 2.5 * sx));
    c.drawCircle(Offset(50 * sx, 50 * sy), 3 * sx,
        _p(_K.blue.withOpacity(0.8)));
    c.drawCircle(Offset(70 * sx, 52 * sy), 3 * sx,
        _p(_K.blue.withOpacity(0.8)));
    // Left speech bubble
    final bubble1 = Path()
      ..moveTo(10 * sx, 18 * sy)
      ..quadraticBezierTo(4 * sx, 18 * sy, 4 * sx, 24 * sy)
      ..lineTo(4 * sx, 34 * sy)
      ..quadraticBezierTo(4 * sx, 40 * sy, 10 * sx, 40 * sy)
      ..lineTo(22 * sx, 40 * sy)
      ..lineTo(26 * sx, 46 * sy)
      ..lineTo(26 * sx, 40 * sy)
      ..lineTo(32 * sx, 40 * sy)
      ..quadraticBezierTo(38 * sx, 40 * sy, 38 * sx, 34 * sy)
      ..lineTo(38 * sx, 24 * sy)
      ..quadraticBezierTo(38 * sx, 18 * sy, 32 * sx, 18 * sy)
      ..close();
    c.drawPath(bubble1, _p(_K.red));
    c.drawPath(bubble1, _p(_K.ink, stroke: true, w: 2.5 * sx));
  }

  void _drawThreats(Canvas c, double sx, double sy) {
    final tri = Path()
      ..moveTo(60 * sx, 12 * sy)
      ..lineTo(100 * sx, 76 * sy)
      ..lineTo(20 * sx, 76 * sy)
      ..close();
    c.drawPath(tri, _p(_K.cheese));
    c.drawPath(tri, _p(_K.ink, stroke: true, w: 3.5 * sx));
    c.drawRect(Rect.fromLTWH(56 * sx, 32 * sy, 8 * sx, 22 * sy), _p(_K.ink));
    c.drawCircle(Offset(60 * sx, 64 * sy), 4 * sx, _p(_K.ink));
    // Bug
    c.drawCircle(Offset(22 * sx, 22 * sy), 6 * sx, _p(_K.lavenderD));
    c.drawCircle(Offset(22 * sx, 22 * sy), 6 * sx,
        _p(_K.ink, stroke: true, w: 2));
    // Skull
    c.drawCircle(Offset(100 * sx, 22 * sy), 7 * sx, _p(Colors.white));
    c.drawCircle(Offset(100 * sx, 22 * sy), 7 * sx,
        _p(_K.ink, stroke: true, w: 2));
    c.drawCircle(Offset(97 * sx, 21 * sy), 1.5 * sx, _p(_K.ink));
    c.drawCircle(Offset(103 * sx, 21 * sy), 1.5 * sx, _p(_K.ink));
  }

  void _drawBalance(Canvas c, double sx, double sy) {
    // Base
    c.drawRect(Rect.fromLTWH(56 * sx, 60 * sy, 8 * sx, 20 * sy), _p(_K.ink));
    _rect(c, 44, 78, 32, 6, 2, _K.ink, sx, sy);
    // Beam
    _rect(c, 14, 32, 92, 5, 2, _K.ink, sx, sy);
    // Left pan
    c.drawLine(Offset(14 * sx, 35 * sy), Offset(28 * sx, 56 * sy),
        _p(_K.ink, stroke: true, w: 2));
    _rect(c, 14, 56, 20, 8, 2, _K.lavender, sx, sy);
    _rect(c, 18, 46, 12, 14, 2, Colors.white, sx, sy);
    // Right pan
    c.drawLine(Offset(106 * sx, 35 * sy), Offset(92 * sx, 56 * sy),
        _p(_K.ink, stroke: true, w: 2));
    _rect(c, 86, 56, 20, 8, 2, _K.mint, sx, sy);
    c.drawCircle(Offset(96 * sx, 48 * sy), 9 * sx, _p(_K.mintDeep));
    c.drawCircle(Offset(96 * sx, 48 * sy), 9 * sx,
        _p(_K.ink, stroke: true, w: 2));
    // Heart pivot
    final heart = Path()
      ..moveTo(60 * sx, 28 * sy)
      ..cubicTo(56 * sx, 24 * sy, 50 * sx, 26 * sy, 50 * sx, 32 * sy)
      ..cubicTo(50 * sx, 38 * sy, 60 * sx, 44 * sy, 60 * sx, 44 * sy)
      ..cubicTo(60 * sx, 44 * sy, 70 * sx, 38 * sy, 70 * sx, 32 * sy)
      ..cubicTo(70 * sx, 26 * sy, 64 * sx, 24 * sy, 60 * sx, 28 * sy);
    c.drawPath(heart, _p(_K.red));
    c.drawPath(heart, _p(_K.ink, stroke: true, w: 2));
  }

  void _drawCitizen(Canvas c, double sx, double sy) {
    c.drawCircle(Offset(60 * sx, 46 * sy), 30 * sx, _p(_K.blue));
    c.drawCircle(Offset(60 * sx, 46 * sy), 30 * sx,
        _p(_K.ink, stroke: true, w: 3));
    final lines = [
      [30.0, 46.0, 90.0, 46.0],
      [60.0, 16.0, 60.0, 76.0],
    ];
    for (final l in lines) {
      c.drawLine(Offset(l[0] * sx, l[1] * sy), Offset(l[2] * sx, l[3] * sy),
          _p(_K.ink, stroke: true, w: 2));
    }
    // Continent 1
    final cont1 = Path()
      ..moveTo(44 * sx, 36 * sy)
      ..quadraticBezierTo(50 * sx, 32 * sy, 56 * sx, 38 * sy)
      ..quadraticBezierTo(52 * sx, 44 * sy, 44 * sx, 42 * sy)
      ..close();
    c.drawPath(cont1, _p(_K.mintDeep));
    // Thumbs up
    _rect(c, 78, 58, 22, 22, 3, _K.cheese, sx, sy);
  }

  @override
  bool shouldRepaint(_IllusPainter old) => old.id != id;
}

// ── CHEESE HOLE ───────────────────────────────────────────────────────────────
class _CheeseHole extends StatelessWidget {
  final double size;
  const _CheeseHole({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD6B134),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2, offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ── BYTEY STAR MASCOT ─────────────────────────────────────────────────────────
class _ByteyWidget extends StatelessWidget {
  final double size;
  const _ByteyWidget({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ByteyPainter(),
      size: Size(size, size),
    );
  }
}

class _ByteyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    Paint p(Color c, {bool stroke = false, double w = 3.5}) => Paint()
      ..color = c
      ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Star body
    final star = Path()
      ..moveTo(50 * s, 8 * s)
      ..lineTo(60 * s, 36 * s)
      ..lineTo(90 * s, 38 * s)
      ..lineTo(66 * s, 56 * s)
      ..lineTo(74 * s, 86 * s)
      ..lineTo(50 * s, 70 * s)
      ..lineTo(26 * s, 86 * s)
      ..lineTo(34 * s, 56 * s)
      ..lineTo(10 * s, 38 * s)
      ..lineTo(40 * s, 36 * s)
      ..close();
    canvas.drawPath(star, p(const Color(0xFFFFD84A)));
    canvas.drawPath(star, p(_K.ink, stroke: true));
    // Cheeks
    canvas.drawCircle(Offset(34 * s, 56 * s), 5 * s,
        p(const Color(0xFFFF8FB1).withOpacity(0.7)));
    canvas.drawCircle(Offset(66 * s, 56 * s), 5 * s,
        p(const Color(0xFFFF8FB1).withOpacity(0.7)));
    // Eyes
    canvas.drawCircle(Offset(40 * s, 48 * s), 4 * s, p(_K.ink));
    canvas.drawCircle(Offset(60 * s, 48 * s), 4 * s, p(_K.ink));
    canvas.drawCircle(Offset(41.5 * s, 46.5 * s), 1.4 * s, p(Colors.white));
    canvas.drawCircle(Offset(61.5 * s, 46.5 * s), 1.4 * s, p(Colors.white));
    // Smile
    final smile = Path()
      ..moveTo(42 * s, 58 * s)
      ..quadraticBezierTo(50 * s, 65 * s, 58 * s, 58 * s);
    canvas.drawPath(smile, p(_K.ink, stroke: true, w: 3));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── WIN CARD ─────────────────────────────────────────────────────────────────
class _WinCard extends StatefulWidget {
  final int moves;
  final String time;
  final VoidCallback onPlayAgain;
  final VoidCallback onNext;
  const _WinCard({
    required this.moves, required this.time,
    required this.onPlayAgain, required this.onNext,
  });

  @override
  State<_WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<_WinCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rock;
  final _rng = Random();
  final _confettiColors = [
    _K.cheese, _K.mintDeep, _K.red, _K.lavenderD, _K.blue, _K.peach,
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _rock = Tween<double>(begin: -10 * pi / 180, end: 10 * pi / 180)
        .animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti
        ...List.generate(30, (i) => _ConfettiPiece(
          color: _confettiColors[i % _confettiColors.length],
          left: _rng.nextDouble(),
          delay: _rng.nextDouble() * 2,
          duration: 1.8 + _rng.nextDouble() * 1.6,
          angle: _rng.nextDouble() * 2 * pi,
        )),
        // Card
        Container(
          width: 460,
          padding: const EdgeInsets.fromLTRB(40, 36, 40, 36),
          decoration: BoxDecoration(
            color: _K.paper,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: const [
              BoxShadow(color: Color(0x4D000000), blurRadius: 60, offset: Offset(0, 20)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _rock,
              builder: (_, child) => Transform.rotate(angle: _rock.value, child: child),
              child: _ByteyWidget(size: 100),
            ),
            const SizedBox(height: 12),
            Text('You did it!',
                style: GoogleFonts.fredoka(
                    fontSize: 36, fontWeight: FontWeight.w700, color: _K.ink)),
            const SizedBox(height: 6),
            Text(
              "You found all the digital citizenship pairs.\nYou're a true Cyber Hero! 🌟",
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                  fontSize: 15, fontWeight: FontWeight.w600, color: _K.softInk),
            ),
            const SizedBox(height: 8),
            Text('${widget.moves} moves · ${widget.time}',
                style: GoogleFonts.fredoka(
                    fontSize: 18, color: _K.softInk, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                onTap: widget.onPlayAgain,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: _K.cheese,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: _K.cheeseSh, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Text('Play Again',
                      style: GoogleFonts.fredoka(
                          fontSize: 16, fontWeight: FontWeight.w700, color: _K.ink)),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: _K.mintDeep,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: _K.mint, offset: Offset(0, 6)),
                    ],
                  ),
                  child: Row(children: [
                    Text('Continue',
                        style: GoogleFonts.fredoka(
                            fontSize: 16, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}

// ── CONFETTI PIECE ────────────────────────────────────────────────────────────
class _ConfettiPiece extends StatefulWidget {
  final Color color;
  final double left, delay, duration, angle;
  const _ConfettiPiece({
    required this.color, required this.left,
    required this.delay, required this.duration, required this.angle,
  });

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: (widget.duration * 1000).round()))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Positioned(
          left: widget.left * MediaQuery.of(context).size.width,
          top: -20 + t * (MediaQuery.of(context).size.height + 60),
          child: Transform.rotate(
            angle: t * 4 * pi + widget.angle,
            child: Container(
              width: 10, height: 14,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── DOTS PAINTER ──────────────────────────────────────────────────────────────
class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withOpacity(0.55);
    final p2 = Paint()..color = const Color(0xFFFF9C6D).withOpacity(0.35);
    final p3 = Paint()..color = const Color(0xFF8C6FD6).withOpacity(0.30);
    const spacing1 = 90.0, spacing2 = 140.0, spacing3 = 180.0;
    for (double x = 0; x < size.width; x += spacing1) {
      for (double y = 0; y < size.height; y += spacing1) {
        canvas.drawCircle(Offset(x, y), 2, p1);
      }
    }
    for (double x = 30; x < size.width; x += spacing2) {
      for (double y = 50; y < size.height; y += spacing2) {
        canvas.drawCircle(Offset(x, y), 2, p2);
      }
    }
    for (double x = 70; x < size.width; x += spacing3) {
      for (double y = 20; y < size.height; y += spacing3) {
        canvas.drawCircle(Offset(x, y), 2, p3);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}



// ── EXTENSION HACK for percentage-based positioning in painters ───────────────
extension _PctExt on String {
  double get asH => double.parse(replaceAll('%', '')) / 100;
  double get asW => double.parse(replaceAll('%', '')) / 100;
}