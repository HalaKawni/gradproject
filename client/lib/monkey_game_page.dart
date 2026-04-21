import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:google_fonts/google_fonts.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE WRAPPER
// ══════════════════════════════════════════════════════════════
class MonkeyGamePage extends StatefulWidget {
  const MonkeyGamePage({super.key});

  @override
  State<MonkeyGamePage> createState() => _MonkeyGamePageState();
}

class _MonkeyGamePageState extends State<MonkeyGamePage> {
  late MonkeySequenceGame _game;
  int _currentLevel = 1;
  bool _showSuccess = false;
  bool _showFailure = false;
  final List<String> _userSequence = [];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _game = MonkeySequenceGame(level: _currentLevel);
  }

  Future<void> _runSequence() async {
    if (_userSequence.isEmpty) return;
    final result = await _game.runSequence(List.from(_userSequence));
    if (!mounted) return;
    setState(() {
      if (result) {
        _showSuccess = true;
      } else {
        _showFailure = true;
      }
    });
  }

  void _nextLevel() {
    setState(() {
      _currentLevel = (_currentLevel % 3) + 1;
      _showSuccess = false;
      _userSequence.clear();
      _initGame();
    });
  }

  void _retry() {
    setState(() {
      _showFailure = false;
      _userSequence.clear();
      _initGame();
    });
  }

  void _addCommand(String cmd) {
    if (_userSequence.length < 8) {
      setState(() => _userSequence.add(cmd));
    }
  }

  void _removeLastCommand() {
    if (_userSequence.isNotEmpty) {
      setState(() => _userSequence.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B00),
      body: Column(
        children: [
          _TopBar(level: _currentLevel, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ── GAME CANVAS ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF44ACFF), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF44ACFF).withOpacity(0.25),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GameWidget(game: _game),
                        ),
                      ),
                    ),
                    // ── COMMAND PANEL ──
                    _CommandPanel(
                      sequence: _userSequence,
                      onAddCommand: _addCommand,
                      onRemoveLast: _removeLastCommand,
                      onRun: _runSequence,
                    ),
                  ],
                ),
                if (_showSuccess)
                  _ResultOverlay(isSuccess: true, level: _currentLevel, onAction: _nextLevel),
                if (_showFailure)
                  _ResultOverlay(isSuccess: false, level: _currentLevel, onAction: _retry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TOP BAR
// ══════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final int level;
  final VoidCallback onBack;
  const _TopBar({required this.level, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFF3D2200),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF6DB84A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'CODEMONKEY JR. – SEQUENCING: CHALLENGE #$level',
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Row(
            children: List.generate(
              3,
              (i) => Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i < level ? const Color(0xFF6DB84A) : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COMMAND PANEL
// ══════════════════════════════════════════════════════════════
class _CommandPanel extends StatelessWidget {
  final List<String> sequence;
  final ValueChanged<String> onAddCommand;
  final VoidCallback onRemoveLast;
  final VoidCallback onRun;

  const _CommandPanel({
    required this.sequence,
    required this.onAddCommand,
    required this.onRemoveLast,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3D2200),
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── SEQUENCE SLOTS ──
          Row(
            children: [
              GestureDetector(
                onTap: onRemoveLast,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE84393),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.replay, color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 8,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (_, i) {
                      if (i < sequence.length) {
                        return _CommandBlock(cmd: sequence[i], filled: true);
                      }
                      return _CommandBlock(cmd: '', filled: false);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onRun,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2E7D32),
                        blurRadius: 0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── AVAILABLE COMMAND BLOCKS ──
          Row(
            children: [
              const SizedBox(width: 56),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onAddCommand('right'),
                child: const _CommandBlock(cmd: 'right', filled: true),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onAddCommand('left'),
                child: const _CommandBlock(cmd: 'left', filled: true),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onAddCommand('jump'),
                child: const _CommandBlock(cmd: 'jump', filled: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandBlock extends StatelessWidget {
  final String cmd;
  final bool filled;
  const _CommandBlock({required this.cmd, required this.filled});

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.arrow_forward;
    if (cmd == 'left') icon = Icons.arrow_back;
    if (cmd == 'jump') icon = Icons.arrow_upward;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: filled && cmd.isNotEmpty ? const Color(0xFF1565C0) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: filled && cmd.isNotEmpty ? const Color(0xFF42A5F5) : Colors.white24,
          width: 2,
        ),
      ),
      child: filled && cmd.isNotEmpty
          ? Icon(icon, color: Colors.white, size: 28)
          : null,
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RESULT OVERLAY
// ══════════════════════════════════════════════════════════════
class _ResultOverlay extends StatelessWidget {
  final bool isSuccess;
  final int level;
  final VoidCallback onAction;

  const _ResultOverlay({
    required this.isSuccess,
    required this.level,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSuccess ? '🎉 Great Job!' : '😅 Almost!',
                style: GoogleFonts.nunito(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                isSuccess
                    ? 'You guided the monkey to the chest!'
                    : 'The monkey missed the chest. Try again!',
                style: GoogleFonts.nunito(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              if (isSuccess) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      i < level ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFC107),
                      size: 32,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSuccess ? const Color(0xFF6DB84A) : const Color(0xFF44ACFF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  isSuccess ? 'NEXT LEVEL →' : 'TRY AGAIN',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FLAME GAME
// ══════════════════════════════════════════════════════════════
class MonkeySequenceGame extends FlameGame {
  final int level;

  static const double stepSize = 100.0;
  late int _stepsToChest;

  late _MonkeySprite monkey;
  late _ChestSprite chest;

  bool _animating = false;

  MonkeySequenceGame({required this.level}) {
    _stepsToChest = level + 1; // level1→2 steps, level2→3, level3→4
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final groundY = size.y * 0.68;

    add(_SkyBackground(gameSize: size));
    add(_Ground(groundY: groundY, totalWidth: size.x));
    _addDecorations(groundY);

    final monkeyStartX = size.x * 0.12;

    monkey = _MonkeySprite(position: Vector2(monkeyStartX, groundY - 64));
    add(monkey);

    final chestX = monkeyStartX + _stepsToChest * stepSize;
    chest = _ChestSprite(position: Vector2(chestX, groundY - 58));
    add(chest);

    // Step dot markers
    for (int i = 1; i <= _stepsToChest; i++) {
      add(_StepMarker(
        position: Vector2(monkeyStartX + i * stepSize, groundY + 2),
      ));
    }
  }

  void _addDecorations(double groundY) {
    for (final x in [size.x * 0.35, size.x * 0.6, size.x * 0.85]) {
      add(_Bush(position: Vector2(x, groundY - 30)));
    }
    add(_Cloud(position: Vector2(80, 35), speed: 12));
    add(_Cloud(position: Vector2(300, 55), speed: 8));
    add(_Cloud(position: Vector2(580, 28), speed: 15));
    for (final x in [size.x * 0.22, size.x * 0.48, size.x * 0.72]) {
      add(_Flower(position: Vector2(x, groundY - 16)));
    }
  }

  /// Runs the user's command sequence. Returns true if monkey reaches chest.
  Future<bool> runSequence(List<String> cmds) async {
    if (_animating) return false;
    _animating = true;

    for (final cmd in cmds) {
      switch (cmd) {
        case 'right':
          await _moveMonkey(stepSize, 0);
          break;
        case 'left':
          await _moveMonkey(-stepSize, 0);
          break;
        case 'jump':
          await _jumpMonkey();
          break;
      }
    }

    _animating = false;

    final dx = (monkey.position.x - chest.position.x).abs();
    final success = dx < 55;
    if (success) {
      monkey.celebrate();
      chest.open();
    } else {
      monkey.showSad();
    }
    return success;
  }

  Future<void> _moveMonkey(double dx, double dy) async {
    monkey.walking = true;
    if (dx < 0) monkey.facingLeft = true;
    if (dx > 0) monkey.facingLeft = false;

    final completer = Completer<void>();
    monkey.add(
      MoveEffect.by(
        Vector2(dx, dy),
        EffectController(duration: 0.45, curve: Curves.easeInOut),
        onComplete: () {
          monkey.walking = false;
          completer.complete();
        },
      ),
    );
    monkey.add(
      MoveEffect.by(
        Vector2(0, -14),
        EffectController(
            duration: 0.22, reverseDuration: 0.22, curve: Curves.easeOut),
      ),
    );
    await completer.future;
  }

  Future<void> _jumpMonkey() async {
    monkey.walking = true;
    final completer = Completer<void>();
    monkey.add(
      MoveEffect.by(
        Vector2(0, -60),
        EffectController(
          duration: 0.3,
          reverseDuration: 0.3,
          curve: Curves.easeOut,
        ),
        onComplete: () {
          monkey.walking = false;
          completer.complete();
        },
      ),
    );
    await completer.future;
  }
}

// ══════════════════════════════════════════════════════════════
//  FLAME COMPONENTS  (pure canvas drawing — no image assets needed)
// ══════════════════════════════════════════════════════════════

class _SkyBackground extends Component {
  final Vector2 gameSize;
  _SkyBackground({required this.gameSize});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6)],
      ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y), paint);
  }
}

class _Ground extends Component {
  final double groundY;
  final double totalWidth;
  _Ground({required this.groundY, required this.totalWidth});

  @override
  void render(Canvas canvas) {
    final p = Paint();
    p.color = const Color(0xFF5AAF3A);
    canvas.drawRect(Rect.fromLTWH(0, groundY, totalWidth, 18), p);
    p.color = const Color(0xFFC8A462);
    canvas.drawRect(Rect.fromLTWH(0, groundY + 18, totalWidth, 200), p);
    p.color = const Color(0xFFB89050);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1.5;
    for (double x = 0; x < totalWidth; x += 60) {
      canvas.drawLine(
          Offset(x, groundY + 18), Offset(x, groundY + 80), p);
    }
    canvas.drawLine(
        Offset(0, groundY + 48), Offset(totalWidth, groundY + 48), p);
    p.style = PaintingStyle.fill;
  }
}

class _StepMarker extends PositionComponent {
  _StepMarker({required Vector2 position})
      : super(position: position, size: Vector2(8, 8));

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = Colors.white.withOpacity(0.5);
    canvas.drawCircle(Offset.zero, 4, p);
  }
}

class _MonkeySprite extends PositionComponent {
  bool walking = false;
  bool facingLeft = false;
  bool _celebrating = false;
  bool _sad = false;
  double _time = 0;

  _MonkeySprite({required Vector2 position})
      : super(position: position, size: Vector2(54, 64));

  void celebrate() => _celebrating = true;
  void showSad() => _sad = true;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (facingLeft) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }

    final p = Paint();

    // Shadow
    p.color = Colors.black26;
    canvas.drawOval(const Rect.fromLTWH(7, 58, 40, 8), p);

    // Legs
    final legOffset = walking ? (math.sin(_time * 8) * 6) : 0.0;
    p.color = const Color(0xFFB8860B);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(12, 52 - legOffset, 12, 16), const Radius.circular(4)),
        p);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(28, 52 + legOffset, 12, 16), const Radius.circular(4)),
        p);

    // Body
    p.color = _sad ? const Color(0xFF8B6914) : const Color(0xFFD4A017);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 30, 34, 26), const Radius.circular(10)),
        p);

    // Belly
    p.color = const Color(0xFFFFD580);
    canvas.drawOval(const Rect.fromLTWH(18, 34, 18, 18), p);

    // Head
    p.color = const Color(0xFFD4A017);
    canvas.drawCircle(const Offset(27, 18), 18, p);

    // Face patch
    p.color = const Color(0xFFFFD580);
    canvas.drawOval(const Rect.fromLTWH(15, 12, 24, 16), p);

    // Ears
    p.color = const Color(0xFFD4A017);
    canvas.drawCircle(const Offset(9, 16), 7, p);
    canvas.drawCircle(const Offset(45, 16), 7, p);
    p.color = const Color(0xFFFFB6C1);
    canvas.drawCircle(const Offset(9, 16), 4, p);
    canvas.drawCircle(const Offset(45, 16), 4, p);

    // Eyes
    p.color = Colors.white;
    canvas.drawCircle(const Offset(21, 14), 5, p);
    canvas.drawCircle(const Offset(33, 14), 5, p);

    if (_sad) {
      final xp = Paint()
        ..color = Colors.red
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(18, 11), const Offset(24, 17), xp);
      canvas.drawLine(const Offset(24, 11), const Offset(18, 17), xp);
      canvas.drawLine(const Offset(30, 11), const Offset(36, 17), xp);
      canvas.drawLine(const Offset(36, 11), const Offset(30, 17), xp);
    } else {
      p.color = Colors.black87;
      canvas.drawCircle(const Offset(22, 14), 3, p);
      canvas.drawCircle(const Offset(34, 14), 3, p);
      p.color = Colors.white;
      canvas.drawCircle(const Offset(23, 12), 1, p);
      canvas.drawCircle(const Offset(35, 12), 1, p);
    }

    // Mouth
    p
      ..color = const Color(0xFF7B3F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mouthPath = Path();
    if (_celebrating) {
      mouthPath.moveTo(19, 24);
      mouthPath.quadraticBezierTo(27, 30, 35, 24);
    } else if (_sad) {
      mouthPath.moveTo(19, 28);
      mouthPath.quadraticBezierTo(27, 22, 35, 28);
    } else {
      mouthPath.moveTo(20, 25);
      mouthPath.quadraticBezierTo(27, 29, 34, 25);
    }
    canvas.drawPath(mouthPath, p);
    p.style = PaintingStyle.fill;

    // Tail
    p
      ..color = const Color(0xFFD4A017)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(44, 38)
      ..cubicTo(60, 28, 64, 48, 52, 52);
    canvas.drawPath(tailPath, p);
    p.style = PaintingStyle.fill;

    canvas.restore();
  }
}

class _ChestSprite extends PositionComponent {
  bool _opened = false;

  _ChestSprite({required Vector2 position})
      : super(position: position, size: Vector2(50, 50));

  void open() {
    _opened = true;
    add(ScaleEffect.by(
      Vector2(1.25, 1.25),
      EffectController(duration: 0.2, reverseDuration: 0.2),
    ));
  }

  @override
  void render(Canvas canvas) {
    final p = Paint();

    // Shadow
    p.color = Colors.black26;
    canvas.drawOval(const Rect.fromLTWH(5, 44, 40, 8), p);

    // Body
    p.color = const Color(0xFF8B4513);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 20, 46, 30), const Radius.circular(4)),
        p);

    // Lid
    if (_opened) {
      canvas.save();
      canvas.translate(25, 20);
      canvas.rotate(-0.6);
      p.color = const Color(0xFF6B3510);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-23, -14, 46, 16), const Radius.circular(4)),
          p);
      canvas.restore();
    } else {
      p.color = const Color(0xFFA0522D);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(2, 6, 46, 16), const Radius.circular(4)),
          p);
    }

    // Gold trim
    p
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(2, 20, 46, 30), const Radius.circular(4)),
        p);
    p.style = PaintingStyle.fill;

    // Lock
    p.color = const Color(0xFFFFD700);
    canvas.drawRect(const Rect.fromLTWH(20, 30, 10, 8), p);
    p.color = const Color(0xFFB8860B);
    canvas.drawCircle(const Offset(25, 29), 4, p);

    // Coins if opened
    if (_opened) {
      p.color = const Color(0xFFFFD700);
      for (final offset in [
        const Offset(10, 18),
        const Offset(25, 12),
        const Offset(38, 18),
      ]) {
        canvas.drawCircle(offset, 5, p);
      }
    }
  }
}

class _Bush extends PositionComponent {
  _Bush({required Vector2 position})
      : super(position: position, size: Vector2(60, 50));

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = const Color(0xFF2E8B22);
    canvas.drawCircle(const Offset(10, 30), 20, p);
    canvas.drawCircle(const Offset(30, 20), 26, p);
    canvas.drawCircle(const Offset(50, 30), 20, p);
    p.color = const Color(0xFF3DAA2E);
    canvas.drawCircle(const Offset(30, 18), 22, p);
  }
}

class _Flower extends PositionComponent {
  final Color color;
  _Flower({required Vector2 position, this.color = const Color(0xFFFF69B4)})
      : super(position: position, size: Vector2(16, 20));

  @override
  void render(Canvas canvas) {
    final p = Paint()
      ..color = const Color(0xFF228B22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(8, 20), const Offset(8, 6), p);
    p.style = PaintingStyle.fill;
    p.color = color;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5;
      canvas.drawCircle(
          Offset(8 + 5 * math.cos(angle), 6 + 5 * math.sin(angle)), 4, p);
    }
    p.color = Colors.yellow;
    canvas.drawCircle(const Offset(8, 6), 3, p);
  }
}

class _Cloud extends PositionComponent {
  final double speed;
  double _maxX = 900;

  _Cloud({required Vector2 position, required this.speed})
      : super(position: position, size: Vector2(80, 30));

@override
void onMount() {
  super.onMount();
  _maxX = (findGame()! as FlameGame).size.x + 100;
}
  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    if (position.x > _maxX) position.x = -100;
  }

  @override
  void render(Canvas canvas) {
    final p = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawCircle(const Offset(20, 20), 18, p);
    canvas.drawCircle(const Offset(40, 14), 22, p);
    canvas.drawCircle(const Offset(62, 20), 16, p);
  }
}