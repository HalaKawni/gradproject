import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/game_api_service.dart';
import 'world_map_page.dart';

// ══════════════════════════════════════════════════════════════
//  PAGE WRAPPER
// ══════════════════════════════════════════════════════════════
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
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.5), blurRadius: 20)],
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
          child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF2E7D32), width: 2)),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFF8B6914),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFFFD700), width: 1)),
          child: Text(
            'CODEMONKEY JR. – SEQUENCING: CHALLENGE #$_currentLevel',
            style: GoogleFonts.montserrat(
                color: const Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const Spacer(),
        Row(children: List.generate(3, (i) => Container(
          width: 14, height: 14, margin: const EdgeInsets.only(left: 6),
          decoration: BoxDecoration(
            color: i < _currentLevel ? const Color(0xFFFFD700) : const Color(0xFF555555),
            shape: BoxShape.circle,
            border: Border.all(
                color: i < _currentLevel ? const Color(0xFFFF8F00) : const Color(0xFF333333),
                width: 2)),
        ))),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  COMMAND PANEL
// ══════════════════════════════════════════════════════════════
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
      decoration: const BoxDecoration(color: Color(0xFF3D1F0D),
        border: Border(top: BorderSide(color: Color(0xFF8B6914), width: 2))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          GestureDetector(
            onTap: onRemoveLast,
            child: SizedBox(width: 52, height: 52,
              child: Stack(alignment: Alignment.center, children: [
                ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/tiny_swords/UI/Buttons/Button_Red.png',
                    width: 52, height: 52, fit: BoxFit.fill)),
                const Icon(Icons.replay, color: Colors.white, size: 22),
              ])),
          ),
          const SizedBox(width: 8),
          Expanded(child: SizedBox(height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal, itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, i) => i < sequence.length
                  ? _CmdBlock(cmd: sequence[i])
                  : const _CmdBlock(cmd: '')))),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onRun,
            child: SizedBox(width: 56, height: 56,
              child: Stack(alignment: Alignment.center, children: [
                ClipOval(child: Image.asset(
                    'assets/images/tiny_swords/UI/Buttons/Button_Blue.png',
                    width: 56, height: 56, fit: BoxFit.fill)),
                const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ])),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const SizedBox(width: 52), const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('right'), child: const _CmdBlock(cmd: 'right')),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('left'), child: const _CmdBlock(cmd: 'left')),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('up'), child: const _CmdBlock(cmd: 'up')),
          const SizedBox(width: 8),
          GestureDetector(onTap: () => onAddCommand('down'), child: const _CmdBlock(cmd: 'down')),
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
      return Container(width: 52, height: 52,
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF444444), width: 2)));
    }
    IconData icon = Icons.arrow_forward;
    if (cmd == 'left') icon = Icons.arrow_back;
    if (cmd == 'up') icon = Icons.arrow_upward;
    if (cmd == 'down') icon = Icons.arrow_downward;
    return SizedBox(width: 52, height: 52,
      child: Stack(alignment: Alignment.center, children: [
        ClipRRect(borderRadius: BorderRadius.circular(6),
          child: Image.asset(
              'assets/images/tiny_swords/UI/Buttons/Button_Blue.png',
              width: 52, height: 52, fit: BoxFit.fill)),
        Icon(icon, color: Colors.white, size: 26),
      ]));
  }
}

// ══════════════════════════════════════════════════════════════
//  RESULT OVERLAY
// ══════════════════════════════════════════════════════════════
class _ResultOverlay extends StatelessWidget {
  final bool isSuccess; final int level; final VoidCallback onAction;
  const _ResultOverlay({required this.isSuccess, required this.level, required this.onAction});
  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withOpacity(0.75),
      child: Center(child: Container(width: 360,
        decoration: BoxDecoration(color: const Color(0xFF2C1810),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B6914), width: 3)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFF8B6914) : const Color(0xFF7F0000),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9))),
            child: Text(isSuccess ? '⚔️  Victory!' : '💀  Defeated!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 28, fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700)))),
          Padding(padding: const EdgeInsets.all(24), child: Column(children: [
            Text(
              isSuccess ? 'The warrior reached the castle!' : 'The warrior missed. Try again!',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 15, color: Colors.white70)),
            if (isSuccess) ...[
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(i < level ? Icons.star : Icons.star_border,
                      color: const Color(0xFFFFD700), size: 36)))),
            ],
            const SizedBox(height: 24),
            GestureDetector(onTap: onAction,
              child: SizedBox(width: 200, height: 56,
                child: Stack(alignment: Alignment.center, children: [
                  Image.asset(
                    'assets/images/tiny_swords/UI/Buttons/Button_Blue_9Slides.png',
                    width: 200, height: 56, fit: BoxFit.fill),
                  Text(isSuccess ? 'NEXT LEVEL →' : 'TRY AGAIN',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w800,
                        fontSize: 14, letterSpacing: 1.2, color: Colors.white)),
                ]))),
          ])),
        ]))));
  }
}

// ══════════════════════════════════════════════════════════════
//  FLAME GAME
// ══════════════════════════════════════════════════════════════
class TinySwordsGame extends FlameGame {
  final int level;
  late int _steps;
  late _WarriorComponent warrior;
  late _CastleComponent castle;
  bool _animating = false;
  static const double stepSize = 60.0;

  TinySwordsGame({required this.level}) { _steps = level + 1; }

  @override
  Color backgroundColor() => const Color(0xFF3BBFCC);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final W = size.x;
    final H = size.y;

    // ── WATER BACKGROUND ──
    add(_WaterBg(gameSize: size));

    // Render tile size = 32px for finer detail
    const ts = 32.0;

    // Main island dimensions — leaves water visible on all sides
    final islandX = W * 0.06;
    final islandY = H * 0.04;
    final islandW = W * 0.88;
    final islandH = H * 0.46;
    const sandRing = 20.0;

    // ── SAND BASE (beach ring) ──
    add(_SandTileRect(
      x: islandX - sandRing, y: islandY - sandRing * 0.5,
      w: islandW + sandRing * 2, h: islandH + sandRing * 1.4, ts: ts,
    ));

    // ── GRASS ISLAND ──
    add(_GrassTileRect(x: islandX, y: islandY, w: islandW, h: islandH, ts: ts));

    // ── STONE WALL bottom of grass ──
    add(_StoneWallRow(x: islandX, y: islandY + islandH - ts * 0.5, w: islandW, ts: ts));

    // Peninsula base Y
    final penY = islandY + islandH + ts * 0.8;
    final penH = H * 0.28;

    // ── LEFT PENINSULA ──
    final leftPenX = islandX - sandRing;
    final leftPenW = islandW * 0.30 + sandRing;
    add(_SandTileRect(x: leftPenX, y: penY, w: leftPenW, h: penH, ts: ts));
    

    // ── RIGHT PENINSULA ──
    final rightPenX = islandX + islandW * 0.70;
    final rightPenW = (islandX + islandW + sandRing) - rightPenX;
    add(_SandTileRect(x: rightPenX, y: penY, w: rightPenW, h: penH, ts: ts));
    

    // ── CENTER SAND PATCH ──
    add(_SandTileRect(
      x: islandX + islandW * 0.30, y: penY + penH * 0.18,
      w: islandW * 0.38, h: penH * 0.62, ts: ts,
    ));

    // ── CASTLE ──
    final castleX = W * 0.43;
    final castleY = islandY + 8;
    castle = _CastleComponent(position: Vector2(castleX, castleY));
    await castle.onLoadSprites();
    add(castle);

    // ── BANNER ──
    add(await _spr('tiny_swords/UI/Banners/Banner_Vertical.png',
        sp: Vector2(0, 0), ss: Vector2(192, 192),
        sz: Vector2(40, 40), pos: Vector2(castleX + 130, castleY - 6)));

    // ── HOUSES ──
    final houseData = [
      ('tiny_swords/Factions/Knights/Buildings/House/House_Blue.png',   W*0.07, islandY+12.0),
      ('tiny_swords/Factions/Knights/Buildings/House/House_Yellow.png', W*0.15, islandY+32.0),
      ('tiny_swords/Factions/Knights/Buildings/House/House_Blue.png',   W*0.27, islandY+44.0),
      ('tiny_swords/Factions/Knights/Buildings/House/House_Yellow.png', W*0.73, islandY+14.0),
      ('tiny_swords/Factions/Knights/Buildings/House/House_Blue.png',   W*0.81, islandY+34.0),
      ('tiny_swords/Factions/Knights/Buildings/House/House_Yellow.png', W*0.65, islandY+50.0),
    ];
    for (final h in houseData) {
      add(await _spr(h.$1,
          sp: Vector2(0, 0), ss: Vector2(128, 192),
          sz: Vector2(56, 84), pos: Vector2(h.$2, h.$3)));
    }

    // ── TOWERS ──
// ── GRASS PATCHES under towers ──
// ── GRASS PATCHES under towers ──
    final leftGrassX = leftPenX - 4;
    final leftGrassY = penY + 30;
    final leftGrassW = leftPenW * 0.55;
    final leftGrassH = penH * 0.50;

    final rightGrassX = rightPenX + rightPenW * 0.45;
    final rightGrassY = penY + 30.0;
    final rightGrassW = rightPenW * 0.58;
    final rightGrassH = penH * 0.50;

    add(_GrassTileRect(x: leftGrassX,  y: leftGrassY,  w: leftGrassW,  h: leftGrassH,  ts: 32));
    add(_GrassTileRect(x: rightGrassX, y: rightGrassY, w: rightGrassW, h: rightGrassH, ts: 32));

    // ── STONE WALL on BOTTOM edge of each grass patch ──
   // ── STONE WALL on BOTTOM edge of each grass patch ──
    add(_StoneWallRow(x: leftGrassX,  y: leftGrassY  + leftGrassH  + 16, w: leftGrassW,  ts: 32));
    add(_StoneWallRow(x: rightGrassX, y: rightGrassY + rightGrassH + 16, w: rightGrassW, ts: 32));

    // ── TOWERS (rendered on top of grass patches) ──
    add(await _spr('tiny_swords/Factions/Knights/Buildings/Tower/Tower_Blue.png',
        sp: Vector2(0, 0), ss: Vector2(128, 256),
        sz: Vector2(52, 104), pos: Vector2(leftPenX + 4, penY + 6)));
    add(await _spr('tiny_swords/Factions/Knights/Buildings/Tower/Tower_Blue.png',
        sp: Vector2(0, 0), ss: Vector2(128, 256),
        sz: Vector2(52, 104), pos: Vector2(rightPenX + rightPenW - 58, penY + 6)));

    // ── TREES ──
    final treeData = <(double, double, int, int, double)>[
      (W*0.05, islandY+islandH*0.04, 0, 0, 60.0),
      (W*0.11, islandY+islandH*0.30, 0, 1, 56.0),
      (W*0.24, islandY+islandH*0.10, 0, 2, 62.0),
      (W*0.31, islandY+islandH*0.40, 1, 0, 54.0),
      (W*0.36, islandY+islandH*0.06, 0, 3, 58.0),
      (W*0.52, islandY+islandH*0.32, 0, 1, 56.0),
      (W*0.59, islandY+islandH*0.06, 1, 2, 54.0),
      (W*0.70, islandY+islandH*0.34, 0, 0, 52.0),
      (W*0.76, islandY+islandH*0.08, 0, 3, 58.0),
      (W*0.86, islandY+islandH*0.28, 1, 1, 52.0),
      (W*0.92, islandY+islandH*0.05, 0, 2, 50.0),
    ];
    for (final t in treeData) {
      add(await _spr('tiny_swords/Resources/Trees/Tree.png',
          sp: Vector2(t.$4 * 192.0, t.$3 * 192.0),
          ss: Vector2(192, 192), sz: Vector2(t.$5, t.$5),
          pos: Vector2(t.$1, t.$2)));
    }

    // ── SOLDIERS ──
    add(await _soldier('tiny_swords/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png',
        pos: Vector2(castleX - 58, castleY + 64), sz: 40));
    add(await _soldier('tiny_swords/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png',
        pos: Vector2(castleX + 128, castleY + 56), sz: 40));
    add(await _soldier('tiny_swords/Factions/Knights/Troops/Archer/Blue/Archer_Blue.png',
        pos: Vector2(castleX + 44, castleY + 100), sz: 38));

    // ── SHEEP ──
    for (int i = 0; i < 4; i++) {
      add(await _spr('tiny_swords/Resources/Sheep/HappySheep_Idle.png',
          sp: Vector2(i * 128.0, 0), ss: Vector2(128, 128),
          sz: Vector2(28, 28),
          pos: Vector2(W * (0.28 + i * 0.11), islandY + islandH * 0.56)));
    }

    // ── DECO ──
    final decoData = [
      (W*0.10, islandY+islandH*0.58, '01.png', 26.0),
      (W*0.21, islandY+islandH*0.22, '07.png', 30.0),
      (W*0.44, islandY+islandH*0.52, '09.png', 24.0),
      (W*0.56, islandY+islandH*0.24, '03.png', 28.0),
      (W*0.74, islandY+islandH*0.56, '11.png', 28.0),
      (W*0.89, islandY+islandH*0.53, '07.png', 26.0),
    ];
    for (final d in decoData) {
      add(await _spr('tiny_swords/Deco/${d.$3}',
          sp: Vector2(0, 0), ss: Vector2(64, 64),
          sz: Vector2(d.$4, d.$4), pos: Vector2(d.$1, d.$2)));
    }

    // ── ROCKS IN WATER ──
    final rockData = [
      (W*0.02,  islandY + 20.0,              'Rocks_01.png', 28.0),
      (W*0.02,  islandY + 60.0,              'Rocks_02.png', 24.0),
      (W*0.96,  islandY + 30.0,              'Rocks_03.png', 26.0),
      (W*0.96,  islandY + 70.0,              'Rocks_02.png', 22.0),
      (W*0.36,  penY + penH + 12,            'Rocks_04.png', 26.0),
      (W*0.50,  penY + penH + 20,            'Rocks_01.png', 22.0),
      (W*0.63,  penY + penH + 14,            'Rocks_03.png', 24.0),
      (leftPenX - 22,  penY + 40,            'Rocks_02.png', 22.0),
      (rightPenX + rightPenW + 6, penY + 36, 'Rocks_04.png', 24.0),
    ];
    for (final r in rockData) {
      add(await _spr('tiny_swords/Terrain/Water/Rocks/${r.$3}',
          sp: Vector2(0, 0), ss: Vector2(128, 128),
          sz: Vector2(r.$4, r.$4), pos: Vector2(r.$1, r.$2)));
    }

    // ── WARRIOR ──
    final startX = W * 0.09;
    final startY = islandY + islandH * 0.72;
    warrior = _WarriorComponent(startX: startX, startY: startY);
    await warrior.onLoadSprites();
    add(warrior);

    // ── STEP MARKERS ──
    for (int i = 1; i <= _steps; i++) {
      add(CircleComponent(
        radius: 4,
        position: Vector2(startX + i * stepSize - 4, startY + 10),
        paint: Paint()..color = const Color(0xFFFFD700).withOpacity(0.9),
      ));
    }
  }

  Future<SpriteComponent> _spr(String path, {
    required Vector2 sp, required Vector2 ss,
    required Vector2 sz, required Vector2 pos,
  }) async => SpriteComponent()
    ..sprite = await Sprite.load(path, srcPosition: sp, srcSize: ss)
    ..size = sz ..position = pos;

  Future<SpriteAnimationComponent> _soldier(String path, {
    required Vector2 pos, required double sz,
  }) async {
    final sprites = <Sprite>[];
    for (int i = 0; i < 4; i++) {
      sprites.add(await Sprite.load(path,
          srcPosition: Vector2(i * 192.0, 0), srcSize: Vector2(192, 192)));
    }
    return SpriteAnimationComponent(
        animation: SpriteAnimation.spriteList(sprites, stepTime: 0.18),
        size: Vector2(sz, sz), position: pos);
  }

  Future<bool> runSequence(List<String> cmds) async {
    if (_animating) return false;
    _animating = true;
    for (final cmd in cmds) {
      if (cmd == 'right') await _move(stepSize, 0, false);
      else if (cmd == 'left') await _move(-stepSize, 0, true);
      else if (cmd == 'up') await _move(0, -stepSize, false);
      else if (cmd == 'down') await _move(0, stepSize, false);
    }
    _animating = false;
    final dx = (warrior.position.x - castle.position.x).abs();
    final dy = (warrior.position.y - castle.position.y).abs();
    final success = dx < 120 && dy < 120;
    if (success) { warrior.setAttack(); castle.celebrate(); }
    else warrior.setDead();
    return success;
  }

  Future<void> _move(double dx, double dy, bool left) async {
    warrior.setWalking(left || (dx == 0 && dy != 0));
    final c = Completer<void>();
    warrior.add(MoveEffect.by(
      Vector2(dx, dy),
      EffectController(duration: 0.4, curve: Curves.easeInOut),
      onComplete: () { warrior.setIdle(); c.complete(); },
    ));
    await c.future;
  }
}

// ══════════════════════════════════════════════════════════════
//  WATER BACKGROUND
// ══════════════════════════════════════════════════════════════
class _WaterBg extends Component with HasGameRef<TinySwordsGame> {
  final Vector2 gameSize;
  late Sprite _tile;
  bool _loaded = false;
  _WaterBg({required this.gameSize});

  @override
  Future<void> onLoad() async {
    _tile = await Sprite.load('tiny_swords/Terrain/Water/Water.png');
    _loaded = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_loaded) return;
    const ts = 64.0;
    final cols = (gameSize.x / ts).ceil() + 1;
    final rows = (gameSize.y / ts).ceil() + 1;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        _tile.render(canvas,
            position: Vector2(c * ts, r * ts), size: Vector2(ts, ts));
      }
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, gameSize.x, gameSize.y),
        Paint()..color = const Color(0xFF2DB8CC).withOpacity(0.35));
  }
}

// ══════════════════════════════════════════════════════════════
//  SAND TILE RECT — yellow sand, no border/shadow
// ══════════════════════════════════════════════════════════════
class _SandTileRect extends Component with HasGameRef<TinySwordsGame> {
  final double x, y, w, h, ts;
  late Sprite _top, _fill;
  bool _ready = false;

  _SandTileRect({required this.x, required this.y,
      required this.w, required this.h, required this.ts});

  @override
  Future<void> onLoad() async {
    // Yellow sand: col 5 srcX=320 in Tilemap_Flat
   _top = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(384, 0), srcSize: Vector2(64, 64));
    _fill = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(384, 64), srcSize: Vector2(64, 64));
    _ready = true;
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    final cols = (w / ts).ceil() + 1;
    final rows = (h / ts).ceil() + 1;
    for (int c = 0; c < cols; c++) {
      final tx = x + c * ts;
      if (tx >= x + w) break;
      _top.render(canvas, position: Vector2(tx, y), size: Vector2(ts, ts));
    }
    for (int r = 1; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tx = x + c * ts;
        if (tx >= x + w) break;
        _fill.render(canvas,
            position: Vector2(tx, y + r * ts), size: Vector2(ts, ts));
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  GRASS TILE RECT — green grass + foam on all 4 edges
// ══════════════════════════════════════════════════════════════
class _GrassTileRect extends Component with HasGameRef<TinySwordsGame> {
  final double x, y, w, h, ts;
  late Sprite _top, _fill;
  bool _ready = false;
  

  _GrassTileRect({required this.x, required this.y,
      required this.w, required this.h, required this.ts});

  @override
  Future<void> onLoad() async {
    _top = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(64, 0), srcSize: Vector2(64, 64));
    _fill = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Flat.png',
        srcPosition: Vector2(64, 64), srcSize: Vector2(64, 64));
    _ready = true;
  }


  @override
  void render(Canvas canvas) {
    if (!_ready) return;

    // Grass tiles
    final cols = (w / ts).ceil() + 1;
    final rows = (h / ts).ceil() + 1;
    for (int c = 0; c < cols; c++) {
      final tx = x + c * ts;
      if (tx >= x + w) break;
      _top.render(canvas, position: Vector2(tx, y), size: Vector2(ts, ts));
    }
    for (int r = 1; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final tx = x + c * ts;
        if (tx >= x + w) break;
        _fill.render(canvas,
            position: Vector2(tx, y + r * ts), size: Vector2(ts, ts));
      }
    }

    // Foam on all 4 edges
  }
}

// ══════════════════════════════════════════════════════════════
//  STONE WALL ROW — elevation tiles + Shadows.png underneath
// ══════════════════════════════════════════════════════════════
class _StoneWallRow extends Component with HasGameRef<TinySwordsGame> {
  final double x, y, w, ts;
  late Sprite _tile, _shadow;
  bool _ready = false;

  _StoneWallRow({required this.x, required this.y,
      required this.w, required this.ts});

  @override
  Future<void> onLoad() async {
    _tile = await Sprite.load('tiny_swords/Terrain/Ground/Tilemap_Elevation.png',
        srcPosition: Vector2(64, 0), srcSize: Vector2(64, 64));
    _shadow = await Sprite.load('tiny_swords/Terrain/Ground/Shadows.png',
        srcPosition: Vector2(0, 0), srcSize: Vector2(192, 192));
    _ready = true;
  }

@override
  void render(Canvas canvas) {
    if (!_ready) return;
    // Shadow under the whole wall block
    for (int c = -1; c < (w / ts).ceil() + 2; c++) {
      final tx = x + c * ts;
      if (tx >= x + w + ts) break;
      _shadow.render(canvas,
          position: Vector2(tx - ts * 0.3, y + ts * 2.2),
          size: Vector2(ts * 1.8, ts * 0.9));
    }
    // 3 rows of wall tiles to make thick chunky blocks like image
    for (int row = 0; row < 3; row++) {
      for (int c = 0; c < (w / ts).ceil() + 1; c++) {
        if (x + c * ts >= x + w) break;
        _tile.render(canvas,
            position: Vector2(x + c * ts - 1, y + row * ts),
            size: Vector2(ts + 1, ts + 1));
      }
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  WARRIOR
// ══════════════════════════════════════════════════════════════
class _WarriorComponent extends PositionComponent {
  bool flipped = false;
  late SpriteAnimationComponent _anim;
  late SpriteAnimation _idleAnim, _walkAnim, _attackAnim;
  late SpriteComponent _deadSprite;
  bool _isDead = false;

  _WarriorComponent({required double startX, required double startY})
      : super(position: Vector2(startX - 30, startY - 52), size: Vector2(60, 60));

  Future<void> onLoadSprites() async {
    const p = 'tiny_swords/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png';
    const fw = 192.0, fh = 192.0;

    final idle = <Sprite>[];
    for (int i = 0; i < 4; i++) {
      idle.add(await Sprite.load(p,
          srcPosition: Vector2(i * fw, 0), srcSize: Vector2(fw, fh)));
    }
    final walk = <Sprite>[];
    for (int i = 0; i < 6; i++) {
      walk.add(await Sprite.load(p,
          srcPosition: Vector2(i * fw, fh), srcSize: Vector2(fw, fh)));
    }
    final atk = <Sprite>[];
    for (int i = 0; i < 6; i++) {
      atk.add(await Sprite.load(p,
          srcPosition: Vector2(i * fw, fh * 3), srcSize: Vector2(fw, fh)));
    }

    _idleAnim   = SpriteAnimation.spriteList(idle, stepTime: 0.15);
    _walkAnim   = SpriteAnimation.spriteList(walk, stepTime: 0.1);
    _attackAnim = SpriteAnimation.spriteList(atk,  stepTime: 0.1, loop: false);

    _anim = SpriteAnimationComponent(animation: _idleAnim, size: Vector2(60, 60));
    add(_anim);

    final ds = await Sprite.load(
        'tiny_swords/Factions/Knights/Troops/Dead/Dead.png',
        srcPosition: Vector2(0, 0), srcSize: Vector2(128, 128));
    _deadSprite = SpriteComponent(sprite: ds, size: Vector2(54, 54))
      ..position = Vector2(3, 3)
      ..opacity = 0;
    add(_deadSprite);
  }

  void setIdle() {
    if (_isDead) return;
    _anim.animation = _idleAnim;
    _anim.scale = Vector2(flipped ? -1 : 1, 1);
    _anim.position = Vector2(flipped ? 60 : 0, 0);
  }

  void setWalking(bool left) {
    if (_isDead) return;
    flipped = left;
    _anim.animation = _walkAnim;
    _anim.scale = Vector2(left ? -1 : 1, 1);
    _anim.position = Vector2(left ? 60 : 0, 0);
  }

  void setAttack() { _anim.animation = _attackAnim; }

  void setDead() {
    _isDead = true;
    _anim.opacity = 0;
    _deadSprite.opacity = 1;
  }
}

// ══════════════════════════════════════════════════════════════
//  CASTLE
// ══════════════════════════════════════════════════════════════
class _CastleComponent extends PositionComponent {
  late SpriteComponent _sprite;

  _CastleComponent({required Vector2 position})
      : super(position: position, size: Vector2(140, 128));

  Future<void> onLoadSprites() async {
    final spr = await Sprite.load(
        'tiny_swords/Factions/Knights/Buildings/Castle/Castle_Blue.png',
        srcPosition: Vector2(0, 0), srcSize: Vector2(320, 256));
    _sprite = SpriteComponent(sprite: spr, size: Vector2(140, 128));
    add(_sprite);
  }

  void celebrate() {
    add(ScaleEffect.by(Vector2(1.1, 1.1),
        EffectController(duration: 0.2, reverseDuration: 0.2)));
  }
}