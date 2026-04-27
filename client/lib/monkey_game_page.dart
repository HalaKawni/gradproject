import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/game_api_service.dart';
import 'world_map_page.dart';

class MonkeyGamePage extends StatefulWidget {
  const MonkeyGamePage({super.key});
  @override
  State<MonkeyGamePage> createState() => _MonkeyGamePageState();
}

class _MonkeyGamePageState extends State<MonkeyGamePage> {
  late TinySwordsGame _game;
  int _currentLevel = 1;
  bool _showSuccess = false;
  bool _showFailure = false;
  final List<String> _userSequence = [];

  @override
  void initState() { super.initState(); _initGame(); }
  void _initGame() => _game = TinySwordsGame(level: _currentLevel);

  Future<void> _runSequence() async {
    if (_userSequence.isEmpty) return;
    final result = await _game.runSequence(List.from(_userSequence));
    if (!mounted) return;
    if (result) await _handleSuccess();
    else setState(() => _showFailure = true);
  }

  Future<void> _handleSuccess() async {
    try {
      await GameApiService.saveLevelResult(
          gameId: 'codemonkey-jr', level: _currentLevel, stars: 3, score: 100);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _showSuccess = true);
  }

  void _nextLevel() => setState(() {
        _currentLevel = (_currentLevel % 3) + 1;
        _showSuccess = false;
        _userSequence.clear();
        _initGame();
      });

  void _retry() => setState(() {
        _showFailure = false;
        _userSequence.clear();
        _initGame();
      });

  void _addCommand(String cmd) {
    if (_userSequence.length < 8) setState(() => _userSequence.add(cmd));
  }

  void _removeLastCommand() {
    if (_userSequence.isNotEmpty) setState(() => _userSequence.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1810),
      body: Column(children: [
        _buildTopBar(context),
        Expanded(child: Stack(children: [
          Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B6914), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GameWidget(game: _game),
                ),
              ),
            ),
            _CommandPanel(
              sequence: _userSequence,
              onAddCommand: _addCommand,
              onRemoveLast: _removeLastCommand,
              onRun: _runSequence,
            ),
          ]),
          if (_showSuccess)
            _ResultOverlay(isSuccess: true, level: _currentLevel, onAction: _nextLevel),
          if (_showFailure)
            _ResultOverlay(isSuccess: false, level: _currentLevel, onAction: _retry),
        ])),
      ]),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF3D1F0D),
        border: Border(bottom: BorderSide(color: Color(0xFF8B6914), width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E7D32), width: 2),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF8B6914),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFD700), width: 1),
          ),
          child: Text(
            'CODEMONKEY JR. – SEQUENCING: CHALLENGE #$_currentLevel',
            style: GoogleFonts.montserrat(
                color: const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Row(children: List.generate(3, (i) => Container(
          width: 14, height: 14,
          margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: i < _currentLevel ? const Color(0xFFFFD700) : const Color(0xFF555555),
            shape: BoxShape.circle,
            border: Border.all(
                color: i < _currentLevel ? const Color(0xFFFF8F00) : const Color(0xFF333333),
                width: 2),
          ),
        ))),
      ]),
    );
  }
}

// ── COMMAND PANEL ──────────────────────────────────────────────
class _CommandPanel extends StatelessWidget {
  final List<String> sequence;
  final ValueChanged<String> onAddCommand;
  final VoidCallback onRemoveLast, onRun;

  const _CommandPanel({
    required this.sequence,
    required this.onAddCommand,
    required this.onRemoveLast,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3D1F0D),
        border: Border(top: BorderSide(color: Color(0xFF8B6914), width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          GestureDetector(
            onTap: onRemoveLast,
            child: SizedBox(
              width: 52, height: 52,
              child: Stack(alignment: Alignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/tiny_swords/UI/Buttons/Button_Red.png',
                      width: 52, height: 52, fit: BoxFit.fill),
                ),
                const Icon(Icons.replay, color: Colors.white, size: 22),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (_, i) => i < sequence.length
                    ? _CmdBlock(cmd: sequence[i])
                    : const _CmdBlock(cmd: ''),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRun,
            child: SizedBox(
              width: 56, height: 56,
              child: Stack(alignment: Alignment.center, children: [
                ClipOval(
                  child: Image.asset('assets/images/tiny_swords/UI/Buttons/Button_Blue.png',
                      width: 56, height: 56, fit: BoxFit.fill),
                ),
                const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const SizedBox(width: 52), const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('right'), child: const _CmdBlock(cmd: 'right')),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('left'), child: const _CmdBlock(cmd: 'left')),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('jump'), child: const _CmdBlock(cmd: 'jump')),
        ]),
      ]),
    );
  }
}

class _CmdBlock extends StatelessWidget {
  final String cmd;
  const _CmdBlock({required this.cmd});

  @override
  Widget build(BuildContext context) {
    if (cmd.isEmpty) {
      return Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF444444), width: 2),
        ),
      );
    }
    IconData icon = Icons.arrow_forward;
    if (cmd == 'left') icon = Icons.arrow_back;
    if (cmd == 'jump') icon = Icons.arrow_upward;
    return SizedBox(
      width: 52, height: 52,
      child: Stack(alignment: Alignment.center, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset('assets/images/tiny_swords/UI/Buttons/Button_Blue.png',
              width: 52, height: 52, fit: BoxFit.fill),
        ),
        Icon(icon, color: Colors.white, size: 26),
      ]),
    );
  }
}

// ── RESULT OVERLAY ─────────────────────────────────────────────
class _ResultOverlay extends StatelessWidget {
  final bool isSuccess;
  final int level;
  final VoidCallback onAction;
  const _ResultOverlay({required this.isSuccess, required this.level, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: const Color(0xFF2C1810),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8B6914), width: 3),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSuccess ? const Color(0xFF8B6914) : const Color(0xFF7F0000),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
              ),
              child: Text(
                isSuccess ? '⚔️  Victory!' : '💀  Defeated!',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD700)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text(
                  isSuccess ? 'The warrior reached the castle!' : 'The warrior missed. Try again!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70),
                ),
                if (isSuccess) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(i < level ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFD700), size: 36),
                    )),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onAction,
                  child: SizedBox(
                    width: 200, height: 56,
                    child: Stack(alignment: Alignment.center, children: [
                      Image.asset('assets/images/tiny_swords/UI/Buttons/Button_Blue_9Slides.png',
                          width: 200, height: 56, fit: BoxFit.fill),
                      Text(isSuccess ? 'NEXT LEVEL →' : 'TRY AGAIN',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800, fontSize: 14,
                              letterSpacing: 1.2, color: Colors.white)),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  FLAME GAME
// ══════════════════════════════════════════════════════════════
class TinySwordsGame extends FlameGame {
  final int level;
  static const double stepSize = 96.0;
  late int _stepsToTarget;
  late _WarriorComponent warrior;
  late _CastleComponent castle;
  bool _animating = false;

  TinySwordsGame({required this.level}) {
    _stepsToTarget = level + 1;
  }

  @override
  Color backgroundColor() => const Color(0xFF3AAEC8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    const tileSize = 64.0;
    // Ground at 52% — half sky, half ground
    final gY = size.y * 0.52;

    // ── SKY ──
    add(_SkyComponent(gameSize: size));

    // ── FULL GRASS GROUND ──
    add(_TiledGround(groundY: gY, totalWidth: size.x, tileSize: tileSize));

    // ── WATER POOLS (tiled water tiles) ──
    // Left water pool around x=35%
    add(_WaterPool(x: size.x * 0.33, y: gY + 8, width: 130, height: 40));
    // Right water pool around x=72%
    add(_WaterPool(x: size.x * 0.70, y: gY + 8, width: 100, height: 36));

    // ── BACKGROUND TREES (far back, smaller) ──
    final bgTrees = [
      (0.06, 0, 0, 78.0),
      (0.15, 0, 1, 72.0),
      (0.30, 1, 2, 80.0), // autumn near left water
      (0.45, 0, 3, 75.0),
      (0.58, 1, 0, 82.0), // autumn near right water
      (0.68, 0, 2, 70.0),
      (0.80, 1, 1, 76.0),
      (0.90, 0, 0, 68.0),
      (0.96, 1, 3, 72.0),
    ];
    for (final t in bgTrees) {
      final tree = SpriteComponent()
        ..sprite = await Sprite.load('tiny_swords/Resources/Trees/Tree.png',
            srcPosition: Vector2(t.$3 * 192.0, t.$2 * 192.0),
            srcSize: Vector2(192, 192))
        ..size = Vector2(t.$4, t.$4)
        ..position = Vector2(size.x * t.$1 - t.$4 / 2, gY - t.$4 + 10);
      add(tree);
    }

    // ── LEFT HOUSE (blue) with pawn soldier ──
    final house1X = size.x * 0.18;
    add(await _makeSprite(
      'tiny_swords/Factions/Knights/Buildings/House/House_Blue.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 192),
      size: Vector2(90, 135), pos: Vector2(house1X - 45, gY - 131),
    ));
    // Pawn guard left of house
    add(await _makeAnimatedSoldier(
      'tiny_swords/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png',
      pos: Vector2(house1X - 100, gY - 68), size: 56,
      row: 0, cols: 4, stepTime: 0.18,
    ));
    // Sheep near house
    add(await _makeSprite(
      'tiny_swords/Resources/Sheep/HappySheep_Idle.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 128),
      size: Vector2(48, 48), pos: Vector2(house1X + 60, gY - 40),
    ));
    add(await _makeSprite(
      'tiny_swords/Resources/Sheep/HappySheep_Idle.png',
      srcPos: Vector2(128, 0), srcSize: Vector2(128, 128),
      size: Vector2(44, 44), pos: Vector2(house1X + 110, gY - 36),
    ));

    // ── YELLOW HOUSE with archer ──
    final house2X = size.x * 0.52;
    add(await _makeSprite(
      'tiny_swords/Factions/Knights/Buildings/House/House_Yellow.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 192),
      size: Vector2(88, 132), pos: Vector2(house2X - 44, gY - 128),
    ));
    // Archer guard
    add(await _makeAnimatedSoldier(
      'tiny_swords/Factions/Knights/Troops/Archer/Blue/Archer_Blue.png',
      pos: Vector2(house2X + 55, gY - 68), size: 56,
      row: 0, cols: 4, stepTime: 0.18,
    ));
    // Sheep near yellow house
    add(await _makeSprite(
      'tiny_swords/Resources/Sheep/HappySheep_Idle.png',
      srcPos: Vector2(256, 0), srcSize: Vector2(128, 128),
      size: Vector2(46, 46), pos: Vector2(house2X - 100, gY - 38),
    ));

    // ── TOWER with pawn ──
    final towerX = size.x * 0.80;
    add(await _makeSprite(
      'tiny_swords/Factions/Knights/Buildings/Tower/Tower_Blue.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 256),
      size: Vector2(72, 144), pos: Vector2(towerX - 36, gY - 140),
    ));
    // Pawn guard
    add(await _makeAnimatedSoldier(
      'tiny_swords/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png',
      pos: Vector2(towerX + 45, gY - 64), size: 52,
      row: 0, cols: 4, stepTime: 0.2,
    ));

    // ── ROCKS in water pools ──
    add(await _makeSprite(
      'tiny_swords/Terrain/Water/Rocks/Rocks_01.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 128),
      size: Vector2(44, 44), pos: Vector2(size.x * 0.35, gY + 2),
    ));
    add(await _makeSprite(
      'tiny_swords/Terrain/Water/Rocks/Rocks_02.png',
      srcPos: Vector2(0, 0), srcSize: Vector2(128, 128),
      size: Vector2(38, 38), pos: Vector2(size.x * 0.72, gY + 4),
    ));

    // ── DECO scattered on ground ──
    // deco_01=red mushroom, 07=green bush, 09=flower, 11=log,
    // 16=tall grass, 18=big bush
    final decos = [
      (0.08,  '01.png', 36.0, 0.0),   // mushroom
      (0.25,  '07.png', 48.0, 0.0),   // bush
      (0.40,  '09.png', 36.0, 0.0),   // flower
      (0.48,  '01.png', 32.0, 0.0),   // mushroom
      (0.62,  '11.png', 44.0, 0.0),   // log
      (0.76,  '07.png', 44.0, 0.0),   // bush
      (0.84,  '09.png', 34.0, 0.0),   // flower
      (0.92,  '05.png', 32.0, 0.0),   // rock
    ];

    for (final d in decos) {
      add(await _makeSprite(
        'tiny_swords/Deco/${d.$2}',
        srcPos: Vector2(0, 0), srcSize: Vector2(64, 64),
        size: Vector2(d.$3, d.$3),
        pos: Vector2(size.x * d.$1 - d.$3 / 2, gY - d.$3 + 10),
      ));
    }

    // ── WARRIOR ──
    final startX = size.x * 0.05;
    warrior = _WarriorComponent(startX: startX, groundY: gY);
    await warrior.onLoadSprites();
    add(warrior);

    // ── CASTLE as goal ──
    final castleX = startX + _stepsToTarget * stepSize;
    castle = _CastleComponent(position: Vector2(castleX - 90, gY - 165));
    await castle.onLoadSprites();
    add(castle);

    // ── STEP MARKERS ──
    for (int i = 1; i <= _stepsToTarget; i++) {
      add(CircleComponent(
        radius: 5,
        position: Vector2(startX + i * stepSize - 5, gY + 8),
        paint: Paint()..color = const Color(0xFFFFD700).withOpacity(0.9),
      ));
    }
  }

  // Helper: make a static sprite component
  Future<SpriteComponent> _makeSprite(
    String path, {
    required Vector2 srcPos,
    required Vector2 srcSize,
    required Vector2 size,
    required Vector2 pos,
  }) async {
    return SpriteComponent()
      ..sprite = await Sprite.load(path, srcPosition: srcPos, srcSize: srcSize)
      ..size = size
      ..position = pos;
  }

  // Helper: make an animated soldier
  Future<SpriteAnimationComponent> _makeAnimatedSoldier(
    String path, {
    required Vector2 pos,
    required double size,
    required int row,
    required int cols,
    required double stepTime,
  }) async {
    final sprites = <Sprite>[];
    for (int i = 0; i < cols; i++) {
      sprites.add(await Sprite.load(path,
          srcPosition: Vector2(i * 192.0, row * 192.0),
          srcSize: Vector2(192, 192)));
    }
    return SpriteAnimationComponent(
      animation: SpriteAnimation.spriteList(sprites, stepTime: stepTime),
      size: Vector2(size, size),
      position: pos,
    );
  }

  Future<bool> runSequence(List<String> cmds) async {
    if (_animating) return false;
    _animating = true;
    for (final cmd in cmds) {
      if (cmd == 'right') await _move(stepSize, false);
      else if (cmd == 'left') await _move(-stepSize, true);
      else if (cmd == 'jump') await _jump();
    }
    _animating = false;
    final dx = (warrior.x - castle.x).abs();
    final success = dx < 100;
    if (success) { warrior.setAttack(); castle.celebrate(); }
    else warrior.setDead();
    return success;
  }

  Future<void> _move(double dx, bool left) async {
    warrior.setWalking(left);
    final c = Completer<void>();
    warrior.add(MoveEffect.by(Vector2(dx, 0),
        EffectController(duration: 0.4, curve: Curves.easeInOut),
        onComplete: () { warrior.setIdle(); c.complete(); }));
    warrior.add(MoveEffect.by(Vector2(0, -8),
        EffectController(duration: 0.2, reverseDuration: 0.2, curve: Curves.easeOut)));
    await c.future;
  }

  Future<void> _jump() async {
    warrior.setWalking(warrior.flipped);
    final c = Completer<void>();
    warrior.add(MoveEffect.by(Vector2(0, -55),
        EffectController(duration: 0.26, reverseDuration: 0.26, curve: Curves.easeOut),
        onComplete: () { warrior.setIdle(); c.complete(); }));
    await c.future;
  }
}

// ══════════════════════════════════════════════════════════════
//  WARRIOR COMPONENT
// ══════════════════════════════════════════════════════════════
class _WarriorComponent extends PositionComponent {
  bool flipped = false;
  late SpriteAnimationComponent _anim;
  late SpriteAnimation _idleAnim, _walkAnim, _attackAnim;
  late SpriteComponent _deadSprite;
  bool _isDead = false;

  _WarriorComponent({required double startX, required double groundY})
      : super(position: Vector2(startX - 40, groundY - 80), size: Vector2(80, 80));

  Future<void> onLoadSprites() async {
    const path = 'tiny_swords/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png';
    const fw = 192.0, fh = 192.0;

    final idleSprites = <Sprite>[];
    for (int i = 0; i < 4; i++) {
      idleSprites.add(await Sprite.load(path,
          srcPosition: Vector2(i * fw, 0), srcSize: Vector2(fw, fh)));
    }

    final walkSprites = <Sprite>[];
    for (int i = 0; i < 6; i++) {
      walkSprites.add(await Sprite.load(path,
          srcPosition: Vector2(i * fw, fh), srcSize: Vector2(fw, fh)));
    }

    final attackSprites = <Sprite>[];
    for (int i = 0; i < 6; i++) {
      attackSprites.add(await Sprite.load(path,
          srcPosition: Vector2(i * fw, fh * 3), srcSize: Vector2(fw, fh)));
    }

    _idleAnim = SpriteAnimation.spriteList(idleSprites, stepTime: 0.15);
    _walkAnim = SpriteAnimation.spriteList(walkSprites, stepTime: 0.1);
    _attackAnim = SpriteAnimation.spriteList(attackSprites, stepTime: 0.1, loop: false);

    _anim = SpriteAnimationComponent(animation: _idleAnim, size: Vector2(80, 80));
    add(_anim);

    final deadSpr = await Sprite.load(
      'tiny_swords/Factions/Knights/Troops/Dead/Dead.png',
      srcPosition: Vector2(0, 0), srcSize: Vector2(128, 128),
    );
    _deadSprite = SpriteComponent(sprite: deadSpr, size: Vector2(72, 72))
      ..position = Vector2(4, 4)
      ..opacity = 0;
    add(_deadSprite);
  }

  void setIdle() {
    if (_isDead) return;
    _anim.animation = _idleAnim;
    _anim.scale = Vector2(flipped ? -1 : 1, 1);
    _anim.position = Vector2(flipped ? 80 : 0, 0);
  }

  void setWalking(bool left) {
    if (_isDead) return;
    flipped = left;
    _anim.animation = _walkAnim;
    _anim.scale = Vector2(left ? -1 : 1, 1);
    _anim.position = Vector2(left ? 80 : 0, 0);
  }

  void setAttack() { _anim.animation = _attackAnim; }

  void setDead() {
    _isDead = true;
    _anim.opacity = 0;
    _deadSprite.opacity = 1;
  }
}

// ══════════════════════════════════════════════════════════════
//  CASTLE COMPONENT
// ══════════════════════════════════════════════════════════════
class _CastleComponent extends PositionComponent {
  late SpriteComponent _sprite;

  _CastleComponent({required Vector2 position})
      : super(position: position, size: Vector2(180, 165));

  Future<void> onLoadSprites() async {
    final spr = await Sprite.load(
      'tiny_swords/Factions/Knights/Buildings/Castle/Castle_Blue.png',
      srcPosition: Vector2(0, 0),
      srcSize: Vector2(320, 256),
    );
    _sprite = SpriteComponent(sprite: spr, size: Vector2(180, 165));
    add(_sprite);
  }

  void celebrate() {
    add(ScaleEffect.by(Vector2(1.1, 1.1),
        EffectController(duration: 0.2, reverseDuration: 0.2)));
  }
}

// ══════════════════════════════════════════════════════════════
//  WATER POOL — tiled water tiles
// ══════════════════════════════════════════════════════════════
class _WaterPool extends Component with HasGameRef<TinySwordsGame> {
  final double x, y, width, height;
  late Sprite _waterTile;
  bool _loaded = false;

  _WaterPool({required this.x, required this.y, required this.width, required this.height});

  @override
  Future<void> onLoad() async {
    // Water.png: 64x64 single tile
    _waterTile = await Sprite.load('tiny_swords/Terrain/Water/Water.png');
    _loaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_loaded) return;
    // Rounded rect clip for water pool shape
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(8),
    ));
    const tileSize = 40.0;
    final cols = (width / tileSize).ceil() + 1;
    final rows = (height / tileSize).ceil() + 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _waterTile.render(canvas,
            position: Vector2(x + c * tileSize, y + r * tileSize),
            size: Vector2(tileSize, tileSize));
      }
    }
    canvas.restore();
  }
}

// ══════════════════════════════════════════════════════════════
//  TILED GROUND
// ══════════════════════════════════════════════════════════════
class _TiledGround extends Component with HasGameRef<TinySwordsGame> {
  final double groundY, totalWidth, tileSize;
  late Sprite _topTile, _fillTile;
  bool _loaded = false;

  _TiledGround({required this.groundY, required this.totalWidth, required this.tileSize});

  @override
  Future<void> onLoad() async {
    _topTile = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(64, 0), srcSize: Vector2(64, 64));
    _fillTile = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(64, 64), srcSize: Vector2(64, 64));
    _loaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_loaded) return;
    final cols = (totalWidth / tileSize).ceil() + 1;
    for (int c = 0; c < cols; c++) {
      _topTile.render(canvas,
          position: Vector2(c * tileSize, groundY),
          size: Vector2(tileSize, tileSize));
    }
    for (int r = 1; r <= 10; r++) {
      for (int c = 0; c < cols; c++) {
        _fillTile.render(canvas,
            position: Vector2(c * tileSize, groundY + r * tileSize),
            size: Vector2(tileSize, tileSize));
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  SKY COMPONENT
// ══════════════════════════════════════════════════════════════
class _SkyComponent extends Component {
  final Vector2 gameSize;
  _SkyComponent({required this.gameSize});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E9EC4), Color(0xFFADE8F5)],
        ).createShader(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y)),
    );
    final p = Paint()..color = Colors.white.withOpacity(0.97);
    _cloud(canvas, p, gameSize.x * 0.08, 20, 115, 46);
    _cloud(canvas, p, gameSize.x * 0.40, 38, 95, 38);
    _cloud(canvas, p, gameSize.x * 0.70, 16, 108, 43);
  }

  void _cloud(Canvas c, Paint p, double x, double y, double w, double h) {
    c.drawCircle(Offset(x, y + h * 0.55), w * 0.20, p);
    c.drawCircle(Offset(x + w * 0.28, y + h * 0.28), w * 0.28, p);
    c.drawCircle(Offset(x + w * 0.56, y + h * 0.55), w * 0.20, p);
    c.drawOval(Rect.fromCenter(
        center: Offset(x + w * 0.28, y + h * 0.68),
        width: w * 0.78, height: h * 0.52), p);
  }
}