import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  PROPORTIONS (matching screenshot exactly)
//  Left panel  : 306px  (≈ 8.1cm)
//  Center panel: flex   (≈ 10.9cm)
//  Right panel : 393px  (≈ 10.4cm)
// ─────────────────────────────────────────────
const double _kLeftWidth  = 390.0;
const double _kRightWidth = 550.0;

// ─────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────
class AiHootGamePage extends StatefulWidget {
  const AiHootGamePage({super.key});
  @override
  State<AiHootGamePage> createState() => _AiHootGamePageState();
}

// ─────────────────────────────────────────────
//  BLOCK TYPES
// ─────────────────────────────────────────────
enum BlockCategory {
  movement, events, display, widgets, gameAndSounds,
  control, logicAndData, variables, objectsFunctions,
  otherObjectsFunctions, ai,
}

class BlockDef {
  final String label;
  final Color color;
  final BlockCategory category;
  final String? param;
  const BlockDef(this.label, this.color, this.category, {this.param});
}

// ─────────────────────────────────────────────
//  OBSTACLE
// ─────────────────────────────────────────────
class _Obstacle {
  double x;
  final double y, w, h;
  _Obstacle({required this.x, required this.y, required this.w, required this.h});
}

// ─────────────────────────────────────────────
//  PAGE STATE
// ─────────────────────────────────────────────
class _AiHootGamePageState extends State<AiHootGamePage>
    with TickerProviderStateMixin {

  // ── Exercise ──
  int _exerciseIndex = 0;
  static const int _totalExercises = 9;

  // ── Blocks ──
  BlockCategory _selectedCategory = BlockCategory.movement;
  final List<BlockDef> _workspace = [];
  static const BlockDef _triggerBlock =
      BlockDef('On Run', Color(0xFF5BA65B), BlockCategory.events);

  // ── Right panel tab: 0=Sprites,1=Widgets,2=Sounds,3=Game ──
  int _rightTab = 0;

  // ── Sprite properties checkboxes ──
  bool _allowGravity        = true;
  bool _collideWorldBounds  = true;
  bool _immovable           = false;
  bool _show                = true;
  bool _collideOtherSprites = true;
  bool _draggable           = false;

  // ── Game engine ──
  bool _gameRunning = false;
  bool _gameOver    = false;
  bool _gameWon     = false;

  // Owl
  double _owlY     = 0.65;
  double _owlVelY  = 0.0;
  double _owlScale = 1.0;
  int    _owlFrame = 0; // 0-4, cycles through sprite sheet

  // Obstacles
  final List<_Obstacle> _obstacles = [];
  final Random _rng = Random();
  Timer?  _gameTimer;
  Timer?  _animTimer;
  double  _score         = 0;
  int     _stepSize      = 1;
  int     _jumpSize      = 1;
  double  _obstacleSpeed = 0.004;

  // ─── Block palette ───
  static final Map<BlockCategory, List<BlockDef>> _palette = {
    BlockCategory.movement: [
      BlockDef('Step',  const Color(0xFF6DB84A), BlockCategory.movement, param: '1'),
      BlockDef('Jump',  const Color(0xFF6DB84A), BlockCategory.movement, param: '1'),
      BlockDef('Get X', const Color(0xFF6DB84A), BlockCategory.movement),
      BlockDef('Get Y', const Color(0xFF6DB84A), BlockCategory.movement),
      BlockDef('Set X', const Color(0xFF6DB84A), BlockCategory.movement, param: '300'),
    ],
    BlockCategory.events: [
      BlockDef('On Run',       const Color(0xFF5BA65B), BlockCategory.events),
      BlockDef('On Key Press', const Color(0xFF5BA65B), BlockCategory.events),
    ],
    BlockCategory.control: [
      BlockDef('Loop', const Color(0xFFE6A020), BlockCategory.control),
      BlockDef('If',   const Color(0xFFE6A020), BlockCategory.control),
      BlockDef('Wait', const Color(0xFFE6A020), BlockCategory.control, param: '1'),
    ],
    BlockCategory.ai: [
      BlockDef('AI Pose: Big',   const Color(0xFF9B59B6), BlockCategory.ai),
      BlockDef('AI Pose: Small', const Color(0xFF9B59B6), BlockCategory.ai),
      BlockDef('AI Detect',      const Color(0xFF9B59B6), BlockCategory.ai),
    ],
    BlockCategory.gameAndSounds: [
      BlockDef('Play Sound', const Color(0xFFE74C3C), BlockCategory.gameAndSounds),
      BlockDef('Game Over',  const Color(0xFFE74C3C), BlockCategory.gameAndSounds),
    ],
    BlockCategory.logicAndData: [
      BlockDef('And', const Color(0xFF3498DB), BlockCategory.logicAndData),
      BlockDef('Or',  const Color(0xFF3498DB), BlockCategory.logicAndData),
      BlockDef('Not', const Color(0xFF3498DB), BlockCategory.logicAndData),
    ],
    BlockCategory.variables: [
      BlockDef('Set Var', const Color(0xFFE67E22), BlockCategory.variables, param: 'x'),
      BlockDef('Get Var', const Color(0xFFE67E22), BlockCategory.variables, param: 'x'),
    ],
    BlockCategory.display: [
      BlockDef('Show', const Color(0xFF1ABC9C), BlockCategory.display),
      BlockDef('Hide', const Color(0xFF1ABC9C), BlockCategory.display),
    ],
    BlockCategory.objectsFunctions: [
      BlockDef('Move To', const Color(0xFF2980B9), BlockCategory.objectsFunctions),
      BlockDef('Resize',  const Color(0xFF2980B9), BlockCategory.objectsFunctions, param: '1'),
    ],
    BlockCategory.otherObjectsFunctions: [
      BlockDef('Collide', const Color(0xFF95A5A6), BlockCategory.otherObjectsFunctions),
    ],
    BlockCategory.widgets: [
      BlockDef('Button', const Color(0xFF16A085), BlockCategory.widgets),
      BlockDef('Slider', const Color(0xFF16A085), BlockCategory.widgets),
    ],
  };

  static const Map<BlockCategory, String> _catLabels = {
    BlockCategory.movement:              'Movement',
    BlockCategory.events:                'Events',
    BlockCategory.display:               'Display',
    BlockCategory.widgets:               'Widgets',
    BlockCategory.gameAndSounds:         'Game and Sounds',
    BlockCategory.control:               'Control',
    BlockCategory.logicAndData:          'Logic and Data',
    BlockCategory.variables:             'Variables',
    BlockCategory.objectsFunctions:      "Object's Functions",
    BlockCategory.otherObjectsFunctions: "Other objects' Functions",
    BlockCategory.ai:                    'AI',
  };

  static const List<Map<String, String>> _exercises = [
    {
      'title': 'Nice to Meet You, Oliver.',
      'body':
        "It's going to be an exciting night! We are going to learn how to build an AI-based game to move Oliver, the owl, between obstacles and get to the end of the route.\n\n"
        "The player will use different postures to change the size of the owl so it can go below or over tiles.\n"
        "This is the game you will create at the end of the course:",
      'hint':
        'A [Loop] block repeats the blocks inside it over and over for as long as the game runs.\n\n'
        'The [Step] block makes the Owl move.',
    },
    {
      'title': 'Make Oliver Step!',
      'body': 'Drag a Step block into the workspace and connect it below the On Run trigger. Press RUN to see Oliver walk forward.',
      'hint': 'The [Step] block takes a number — try changing it from 1 to 3!',
    },
    {
      'title': 'Add a Loop',
      'body': 'Wrap your Step block in a Loop so Oliver keeps moving forever.',
      'hint': 'Drag the [Loop] block from Control, then drag [Step] inside the loop.',
    },
    {
      'title': 'Jumping Over Obstacles',
      'body': 'Add a Jump block after the Step block. Oliver will now step forward AND jump each tick.',
      'hint': 'Adjust the [Jump] value to control how high Oliver jumps.',
    },
    {
      'title': 'Intro to AI Poses',
      'body': 'Use the AI Pose blocks to make Oliver grow BIG or shrink SMALL.',
      'hint': 'Try placing [AI Pose: Big] and [AI Pose: Small] in sequence.',
    },
    {
      'title': 'Combine Movement + AI',
      'body': 'Now combine Step, Jump, and AI Pose blocks to guide Oliver through a tricky obstacle course.',
      'hint': 'Order matters — think about when to grow vs shrink.',
    },
    {
      'title': 'Score Points',
      'body': "Oliver earns points every time he passes an obstacle. How high can you get his score?",
      'hint': 'Keep your program looping — more steps = more points!',
    },
    {
      'title': 'Game Over Logic',
      'body': 'Add a Game Over block inside an If condition so the game ends when Oliver collides with a tile.',
      'hint': "Use the [Collide] block from Other objects' Functions.",
    },
    {
      'title': 'Final Challenge!',
      'body': 'Build the complete game: Loop → Step → AI Detect → resize Oliver → avoid all obstacles!',
      'hint': 'You got this! Combine everything you have learned.',
    },
  ];

  // ─────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────
  @override
  void dispose() {
    _gameTimer?.cancel();
    _animTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  GAME ENGINE
  // ─────────────────────────────────────────────
  void _runGame() {
    _gameTimer?.cancel();
    _animTimer?.cancel();
    setState(() {
      _gameRunning = true;
      _gameOver    = false;
      _gameWon     = false;
      _owlY        = 0.65;
      _owlVelY     = 0.0;
      _owlScale    = 1.0;
      _owlFrame    = 0;
      _score       = 0;
      _obstacles.clear();
      _parseBlocks();
    });
    for (int i = 0; i < 4; i++) _spawnObstacle(baseX: 0.55 + i * 0.3);
    _animTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (_gameRunning) setState(() => _owlFrame = (_owlFrame + 1) % 5);
    });
    _gameTimer = Timer.periodic(const Duration(milliseconds: 30), _tick);
  }

  void _parseBlocks() {
    _stepSize      = 1;
    _jumpSize      = 1;
    _obstacleSpeed = 0.004;
    for (final b in _workspace) {
      if (b.label == 'Step' && b.param != null) {
        _stepSize      = int.tryParse(b.param!) ?? 1;
        _obstacleSpeed = 0.003 + _stepSize * 0.001;
      }
      if (b.label == 'Jump'          && b.param != null) _jumpSize  = int.tryParse(b.param!) ?? 1;
      if (b.label == 'AI Pose: Big')   _owlScale = 1.6;
      if (b.label == 'AI Pose: Small') _owlScale = 0.6;
    }
  }

  void _spawnObstacle({double? baseX}) {
    final x    = baseX ?? 1.1;
    final tall = _rng.nextBool();
    final h    = tall ? 0.38 : 0.18;
    final y    = tall ? _rng.nextDouble() * 0.25 : 0.55 + _rng.nextDouble() * 0.25;
    _obstacles.add(_Obstacle(x: x, y: y, w: 0.06, h: h));
  }

  void _tick(Timer t) {
    if (!_gameRunning) return;
    setState(() {
      for (final o in _obstacles) o.x -= _obstacleSpeed * _stepSize;
      _obstacles.removeWhere((o) => o.x < -0.1);
      if (_obstacles.isEmpty || _obstacles.last.x < 0.72) _spawnObstacle();

      final hasJump = _workspace.any((b) => b.label == 'Jump');
      if (hasJump) {
        _owlVelY += 0.0018 * _jumpSize;
        _owlY    += _owlVelY;
        if (_owlY > 0.78) { _owlY = 0.78; _owlVelY = -0.024 * _jumpSize; }
        if (_owlY < 0.08) { _owlY = 0.08; _owlVelY = 0; }
      }

      _score += _obstacleSpeed * 10;

      const double owlNormW = 0.055;
      final  double owlNormH = 0.12 * _owlScale;
      const  double owlNormX = 0.12;
      for (final o in _obstacles) {
        if (owlNormX + owlNormW > o.x &&
            owlNormX            < o.x + o.w &&
            _owlY  + owlNormH   > o.y &&
            _owlY               < o.y + o.h) {
          _gameRunning = false;
          _gameOver    = true;
          _animTimer?.cancel();
          t.cancel();
          return;
        }
      }
      if (_score >= 200) {
        _gameRunning = false;
        _gameWon     = true;
        _animTimer?.cancel();
        t.cancel();
      }
    });
  }

  void _stopGame() {
    _gameTimer?.cancel();
    _animTimer?.cancel();
    setState(() { _gameRunning = false; });
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF0),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: _kLeftWidth,  child: _buildLeftPanel()),
                Expanded(child: _buildCenterPanel()),
                SizedBox(width: _kRightWidth, child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() {
    return Container(
      height: 48,
      color: const Color(0xFF2B1D0E),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.code, color: Color(0xFFE8A020), size: 22),
          const SizedBox(width: 8),
          Text('AI IS A HOOT: EXERCISE #${_exerciseIndex + 1}',
              style: GoogleFonts.montserrat(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const Spacer(),
          const Icon(Icons.chat_bubble_outline, color: Colors.white54, size: 20),
          const SizedBox(width: 16),
          const Icon(Icons.account_circle, color: Colors.white54, size: 24),
          const SizedBox(width: 16),
          const Icon(Icons.menu, color: Colors.white54, size: 22),
        ],
      ),
    );
  }

  // ── LEFT PANEL (306px) ──
  Widget _buildLeftPanel() {
    final ex = _exercises[_exerciseIndex];
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise nav
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _NavArrow(
                  icon: Icons.arrow_back_ios,
                  onTap: _exerciseIndex > 0 ? () => setState(() => _exerciseIndex--) : null,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFCCCCCC)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Exercise ${_exerciseIndex + 1} of $_totalExercises',
                          style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _NavArrow(
                  icon: Icons.arrow_forward_ios,
                  onTap: _exerciseIndex < _totalExercises - 1
                      ? () => setState(() => _exerciseIndex++) : null,
                ),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.replay,  color: const Color(0xFFF5A623), onTap: _stopGame),
                const SizedBox(width: 5),
                _IconBtn(icon: Icons.refresh, color: const Color(0xFFF5A623),
                    onTap: () => setState(() => _workspace.clear())),
              ],
            ),
          ),

          // Show solution bar
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F5E9),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 15),
                const SizedBox(width: 6),
                Text('Show my previous solution',
                    style: GoogleFonts.nunito(
                        fontSize: 11.5, fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50))),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Color(0xFF4CAF50), size: 15),
                      const SizedBox(width: 5),
                      Text('OVERVIEW',
                          style: GoogleFonts.montserrat(
                              fontSize: 11.5, fontWeight: FontWeight.w800,
                              color: const Color(0xFF4CAF50))),
                    ],
                  ),
                  const Divider(color: Color(0xFF4CAF50), thickness: 1),
                  const SizedBox(height: 4),
                  Text(ex['title']!,
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.article_outlined, size: 12, color: Color(0xFF4CAF50)),
                        label: Text('Listen',
                            style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF4CAF50))),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(ex['body']!,
                      style: GoogleFonts.nunito(
                          fontSize: 12, color: const Color(0xFF333333), height: 1.55)),
                  const SizedBox(height: 12),
                  // Preview thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: double.infinity,
                      height: 128,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/images/starry_night.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  CustomPaint(painter: _StarryPainter())),
                          const Positioned(
                            top: 5, left: 5,
                            child: _TimerBadge(label: '00:32'),
                          ),
                          const Positioned(
                            top: 5, right: 5,
                            child: _ResetBadge(),
                          ),
                          Positioned(
                            left: 70, bottom: 18,
                            child: Container(width: 16, height: 56,
                                color: const Color(0xFFB94040)),
                          ),
                          Positioned(
                            right: 24, bottom: 8,
                            child: Image.asset('assets/images/owl.png',
                                width: 32,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.flutter_dash, size: 32, color: Colors.brown)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ex['hint']!.split('\n\n').map((line) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: RichText(text: _parseHint(line)),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _parseHint(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\[([^\]]+)\]');
    int last = 0;
    for (final m in regex.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, m.start),
          style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF555555), height: 1.5),
        ));
      }
      final word = m.group(1)!;
      final isControl = word == 'Loop' || word == 'If';
      spans.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: isControl ? const Color(0xFFE6A020) : const Color(0xFF6DB84A),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(word,
              style: GoogleFonts.nunito(
                  fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: GoogleFonts.nunito(fontSize: 11.5, color: const Color(0xFF555555), height: 1.5),
      ));
    }
    return TextSpan(children: spans);
  }

  // ── CENTER PANEL (flex) ──
  Widget _buildCenterPanel() {
    return Container(
      color: const Color(0xFFF0F0ED),
      child: Column(
        children: [
          // Oliver header + RUN
          Container(
            height: 52,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Image.asset('assets/images/owl.png', width: 26,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.flutter_dash, size: 26, color: Colors.brown)),
                const SizedBox(width: 8),
                Text('Oliver',
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _gameRunning ? _stopGame : _runGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gameRunning
                        ? const Color(0xFFE74C3C) : const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  icon: Icon(_gameRunning ? Icons.stop : Icons.play_arrow, size: 19),
                  label: Text(_gameRunning ? 'STOP' : 'RUN!',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),

          // Workspace area
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                    child: _BlockWidget(block: _triggerBlock),
                  ),
                  Expanded(
                    child: ReorderableListView(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          if (newIdx > oldIdx) newIdx--;
                          final item = _workspace.removeAt(oldIdx);
                          _workspace.insert(newIdx, item);
                        });
                      },
                      children: _workspace.asMap().entries.map((e) =>
                        Padding(
                          key: ValueKey(e.key),
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              _BlockWidget(block: e.value),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _workspace.removeAt(e.key)),
                                child: const Icon(Icons.close, size: 14, color: Colors.black38),
                              ),
                            ],
                          ),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pinned movement blocks row
          Container(
            height: 52,
            color: const Color(0xFFF0F0ED),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: (_palette[BlockCategory.movement] ?? []).map((b) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () => setState(() => _workspace.add(b)),
                      child: _BlockWidget(block: b),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),

          // Category tabs
          Container(
            height: 38,
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Row(
                children: BlockCategory.values.map((cat) {
                  final selected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: selected ? _catColor(cat) : Colors.white,
                          border: Border.all(
                              color: selected ? _catColor(cat) : const Color(0xFFCCCCCC)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_catLabels[cat]!,
                            style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF555555))),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Palette blocks
          Container(
            height: 62,
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: (_palette[_selectedCategory] ?? []).map((b) =>
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: GestureDetector(
                      onTap: () => setState(() => _workspace.add(b)),
                      child: _BlockWidget(block: b),
                    ),
                  ),
                ).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _catColor(BlockCategory cat) {
    switch (cat) {
      case BlockCategory.movement:              return const Color(0xFF6DB84A);
      case BlockCategory.events:                return const Color(0xFF5BA65B);
      case BlockCategory.display:               return const Color(0xFF1ABC9C);
      case BlockCategory.widgets:               return const Color(0xFF16A085);
      case BlockCategory.gameAndSounds:         return const Color(0xFFE74C3C);
      case BlockCategory.control:               return const Color(0xFFE6A020);
      case BlockCategory.logicAndData:          return const Color(0xFF3498DB);
      case BlockCategory.variables:             return const Color(0xFFE67E22);
      case BlockCategory.objectsFunctions:      return const Color(0xFF2980B9);
      case BlockCategory.otherObjectsFunctions: return const Color(0xFF95A5A6);
      case BlockCategory.ai:                    return const Color(0xFF9B59B6);
    }
  }

  // ── RIGHT PANEL (393px) ──
  Widget _buildRightPanel() {
    return Container(
      color: const Color(0xFFEEEEEE),
      child: Column(
        children: [
          // Tool icons bar (top-right of canvas)
          Container(
            height: 38,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.near_me,      size: 17, color: Colors.black54),
                SizedBox(width: 10),
                Icon(Icons.open_with,    size: 17, color: Colors.black54),
                SizedBox(width: 10),
                Icon(Icons.format_paint, size: 17, color: Colors.black54),
                SizedBox(width: 10),
                Icon(Icons.content_cut,  size: 17, color: Colors.black54),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/images/starry_night.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          CustomPaint(painter: _StarryPainter(), size: Size.infinite)),
                ),

                // Obstacles
                if (_gameRunning || _gameOver || _gameWon)
                  ..._obstacles.map((o) => LayoutBuilder(
                    builder: (ctx, c) => Stack(children: [
                      Positioned(
                        left:   o.x * c.maxWidth,
                        top:    o.y * c.maxHeight,
                        width:  o.w * c.maxWidth,
                        height: o.h * c.maxHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFB94040),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                      ),
                    ]),
                  )),

                // Owl (animated sprite sheet)
                Positioned.fill(
                  child: LayoutBuilder(builder: (ctx, c) {
                    final owlSize = 52.0 * _owlScale;
                    return Stack(children: [
                      Positioned(
                        left: 0.12 * c.maxWidth - owlSize / 2,
                        top:  _owlY * c.maxHeight - owlSize / 2,
                        width: owlSize, height: owlSize,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment(-1.0 + (_owlFrame * 0.5), 0),
                            widthFactor: 0.2,
                            child: Image.asset(
                              'assets/images/owl.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  Icon(Icons.flutter_dash, size: owlSize, color: Colors.brown),
                            ),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),

                // Score
                if (_gameRunning)
                  Positioned(
                    top: 7, left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                      child: Text('Score: ${_score.toInt()}',
                          style: GoogleFonts.nunito(
                              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),

                // Overlay
                if (_gameOver || _gameWon)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_gameWon ? '🎉 You Win!' : '💥 Game Over',
                                style: GoogleFonts.nunito(
                                    fontSize: 24, fontWeight: FontWeight.w900,
                                    color: _gameWon
                                        ? const Color(0xFFFFD700) : Colors.redAccent)),
                            const SizedBox(height: 6),
                            Text('Score: ${_score.toInt()}',
                                style: GoogleFonts.nunito(fontSize: 15, color: Colors.white)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _runGame,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50)),
                              child: Text('Try Again',
                                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Sprites / Widgets / Sounds / Game tabs
          Container(
            height: 32,
            color: Colors.white,
            child: Row(
              children: [
                _buildRightTabBtn('Sprites', 0),
                _buildRightTabBtn('Widgets', 1),
                _buildRightTabBtn('Sounds',  2),
                _buildRightTabBtn('Game',    3),
              ],
            ),
          ),

          // Properties / sprite sheet panel
          _rightTab == 0 ? _buildSpriteProperties() : _buildGenericTab(_rightTab),
        ],
      ),
    );
  }

  Widget _buildRightTabBtn(String label, int idx) {
    final selected = _rightTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rightTab = idx),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: selected ? const Color(0xFF4CAF50) : Colors.transparent,
                  width: 2),
            ),
          ),
          child: Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 11.5, fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF333333) : const Color(0xFF999999))),
        ),
      ),
    );
  }

  // Sprite properties panel — exact match to screenshot
  Widget _buildSpriteProperties() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Checkboxes grid (2 columns)
          Row(
            children: [
              Expanded(child: _buildProp('Allow Gravity',       _allowGravity,
                  (v) => setState(() => _allowGravity = v!))),
              Expanded(child: _buildProp('Collide world bounds', _collideWorldBounds,
                  (v) => setState(() => _collideWorldBounds = v!))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildProp('Immovable', _immovable,
                  (v) => setState(() => _immovable = v!))),
              Expanded(child: _buildProp('Show', _show,
                  (v) => setState(() => _show = v!))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildProp('Collide other sprites', _collideOtherSprites,
                  (v) => setState(() => _collideOtherSprites = v!))),
              Expanded(child: _buildProp('Draggable', _draggable,
                  (v) => setState(() => _draggable = v!))),
            ],
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {},
            child: Text('Hide preview',
                style: GoogleFonts.nunito(
                    fontSize: 11.5, color: const Color(0xFF1A73E8),
                    decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 8),
          // 5 owl sprite frames
          SizedBox(
            height: 60,
            child: Row(
              children: List.generate(5, (i) =>
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: (i == _owlFrame && _gameRunning)
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(4),
                      color: const Color(0xFFF5F5F5),
                    ),
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment(-1.0 + (i * 0.5), 0),
                        widthFactor: 0.2,
                        child: Image.asset('assets/images/owl.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.flutter_dash, size: 34, color: Colors.brown)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // DELETE / DUPLICATE
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF888888),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text('DELETE',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text('DUPLICATE',
                      style: GoogleFonts.montserrat(
                          fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProp(String label, bool value, ValueChanged<bool?> onChange) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18, height: 18,
          child: Checkbox(
            value: value, onChanged: onChange,
            activeColor: const Color(0xFF4CAF50),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF333333))),
        ),
      ],
    );
  }

  Widget _buildGenericTab(int tab) {
    final labels = ['', 'Widgets', 'Sounds', 'Game'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(14),
      child: Text('${labels[tab]} panel',
          style: GoogleFonts.nunito(fontSize: 12, color: Colors.grey)),
    );
  }
}

// ─────────────────────────────────────────────
//  BLOCK WIDGET
// ─────────────────────────────────────────────
class _BlockWidget extends StatelessWidget {
  final BlockDef block;
  const _BlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: block.color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 3, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(block.label,
              style: GoogleFonts.nunito(
                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          if (block.param != null) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(block.param!,
                  style: GoogleFonts.nunito(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Icon(icon, size: 13,
        color: onTap != null ? const Color(0xFF555555) : const Color(0xFFBBBBBB)),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
      child: Icon(icon, color: Colors.white, size: 17),
    ),
  );
}

class _TimerBadge extends StatelessWidget {
  final String label;
  const _TimerBadge({required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    color: Colors.black54,
    child: Text(label,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

class _ResetBadge extends StatelessWidget {
  const _ResetBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    color: Colors.black45,
    child: const Text('RESET',
        style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800)),
  );
}

// ─────────────────────────────────────────────
//  STARRY PAINTER (fallback)
// ─────────────────────────────────────────────
class _StarryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF2E3F4F));
    final p   = Paint()..color = Colors.white;
    final rng = Random(42);
    for (int i = 0; i < 55; i++) {
      _drawStar(canvas, Offset(rng.nextDouble() * size.width,
          rng.nextDouble() * size.height), 2.5 + rng.nextDouble() * 5, p);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a  = i * pi / 4;
      final d  = i.isEven ? r : r * 0.42;
      final pt = Offset(c.dx + d * cos(a), c.dy + d * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_StarryPainter old) => false;
}