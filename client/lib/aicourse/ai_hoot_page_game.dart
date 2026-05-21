import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';


// Put these uploaded images in your Flutter project at:
// client/assets/images/
class CodeMonkeyScratchAssets {
  static const String owl = 'assets/images/owl.png';
  static const String starryNight = 'assets/images/starry_night.png';
  static const String toolDefault = 'assets/images/default.png';
  static const String toolDrag = 'assets/images/drag.png';
  static const String toolErase = 'assets/images/erase.png';
  static const String toolPaint = 'assets/images/paint.png';
}

/// Drop this file in: client/lib/codemonkey_scratch_page.dart
/// Then open it with:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeMonkeyScratchPage()));
///
/// This is a CodeMonkey/Scratch-style builder page that matches the layout in
/// your screenshot: left lesson panel, middle block workspace, right game stage,
/// and sprite settings panel. It uses your uploaded PNG assets.
class CodeMonkeyScratchPage extends StatefulWidget {
  const CodeMonkeyScratchPage({super.key});

  @override
  State<CodeMonkeyScratchPage> createState() => _CodeMonkeyScratchPageState();
}

class _CodeMonkeyScratchPageState extends State<CodeMonkeyScratchPage> {
  static const List<String> _categories = [
    'Movement',
    'Events',
    'Display',
    'Widgets',
    'Game and Sounds',
    'Control',
    'Logic and Data',
    'Variables',
    "Object's Functions",
    "Other objects' Functions",
    'AI',
  ];

  String _selectedCategory = 'Movement';
  bool _isRunning = false;

  // Stage logical coordinates. These are mapped to pixels in the stage widget.
  double _owlX = 36;
  double _owlY = 315;

  // owl.png is a horizontal spritesheet with 5 walking frames.
  // This index chooses which frame is shown on the stage.
  int _owlFrame = 0;

  final List<_ScratchBlockData> _workspaceBlocks = [
    _ScratchBlockData.event('On Run'),
  ];

  final List<_SpriteAssetData> _projectSprites = <_SpriteAssetData>[];

  List<_ScratchBlockData> get _paletteBlocks {
    switch (_selectedCategory) {
      case 'Events':
        return [_ScratchBlockData.event('On Run'), _ScratchBlockData.event('When Clicked')];
      case 'Control':
        return [_ScratchBlockData.control('Loop'), _ScratchBlockData.control('Wait', value: '1')];
      case 'Variables':
        return [_ScratchBlockData.variable('Get X'), _ScratchBlockData.variable('Get Y'), _ScratchBlockData.variable('Set X', value: '300')];
      case 'Display':
        return [_ScratchBlockData.display('Say', value: 'Hello'), _ScratchBlockData.display('Hide'), _ScratchBlockData.display('Show')];
      case 'AI':
        return [_ScratchBlockData.ai('Think'), _ScratchBlockData.ai('Detect')];
      default:
        return [
          _ScratchBlockData.movement('Step', value: '1'),
          _ScratchBlockData.movement('Jump', value: '1'),
          _ScratchBlockData.variable('Get X'),
          _ScratchBlockData.variable('Get Y'),
          _ScratchBlockData.movement('Set X', value: '300'),
        ];
    }
  }

  Future<void> _runProgram() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);

    // Start from the screenshot-like bottom-left position.
    setState(() {
      _owlX = 36;
      _owlY = 315;
      _owlFrame = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 350));

    for (final block in _workspaceBlocks) {
      if (!_isRunning) break;
      await _executeBlock(block);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    if (mounted) {
      setState(() {
        _isRunning = false;
        _owlFrame = 0;
      });
    }
  }

  Future<void> _walkOneStep({required double distance}) async {
    const frameCount = 5;
    const ticks = 10;
    const tickDuration = Duration(milliseconds: 55);

    final double dx = distance / ticks;

    for (var tick = 0; tick < ticks; tick++) {
      if (!mounted || !_isRunning) return;

      setState(() {
        _owlX += dx;
        _owlFrame = tick % frameCount;
      });

      await Future<void>.delayed(tickDuration);
    }

    if (mounted) {
      setState(() => _owlFrame = 0);
    }
  }

  Future<void> _executeBlock(_ScratchBlockData block) async {
    switch (block.label) {
      case 'Step':
        // CodeMonkey-style walking:
        // one Step block moves the owl a small distance, while owl.png cycles
        // through its 5 walking frames. The position and frame change together.
        await _walkOneStep(distance: 62);
        break;
      case 'Jump':
        setState(() => _owlY -= 70);
        await Future<void>.delayed(const Duration(milliseconds: 260));
        setState(() => _owlY += 70);
        await Future<void>.delayed(const Duration(milliseconds: 260));
        break;
      case 'Set X':
        setState(() => _owlX = double.tryParse(block.value ?? '300') ?? 300);
        await Future<void>.delayed(const Duration(milliseconds: 430));
        break;
      case 'Wait':
        await Future<void>.delayed(Duration(milliseconds: ((double.tryParse(block.value ?? '1') ?? 1) * 1000).round()));
        break;
      default:
        await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  void _addBlock(_ScratchBlockData block) {
    if (block.kind == _ScratchBlockKind.event) {
      setState(() {
        _workspaceBlocks
          ..clear()
          ..add(block);
      });
      return;
    }

    setState(() => _workspaceBlocks.add(block));
  }

  void _removeBlock(int index) {
    if (index == 0) return;
    setState(() => _workspaceBlocks.removeAt(index));
  }

  void _clearProgram() {
    setState(() {
      _workspaceBlocks
        ..clear()
        ..add(_ScratchBlockData.event('On Run'));
      _owlX = 36;
      _owlY = 315;
      _owlFrame = 0;
    });
  }

  Future<void> _showAddSpriteDialog(BuildContext context) async {
    final pickedSprite = await showDialog<_SpriteAssetData>(
      context: context,
      barrierColor: Colors.black.withOpacity(.55),
      builder: (_) => const _AddSpriteDialog(),
    );

    if (!mounted || pickedSprite == null) return;

    setState(() {
      _projectSprites.add(pickedSprite);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF2),
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final needsHorizontalScroll = constraints.maxWidth < 1180;
                final width = needsHorizontalScroll ? 1380.0 : constraints.maxWidth;
                final content = SizedBox(
                  width: width,
                  height: constraints.maxHeight,
                  child: Row(
                    children: [
                      const Expanded(flex: 28, child: _LessonPanel()),
                      Container(width: 2, color: const Color(0xFFD0D0D0)),
                      Expanded(
                        flex: 38,
                        child: _BlocksWorkspace(
                          selectedCategory: _selectedCategory,
                          categories: _categories,
                          paletteBlocks: _paletteBlocks,
                          workspaceBlocks: _workspaceBlocks,
                          isRunning: _isRunning,
                          onRun: _runProgram,
                          onClear: _clearProgram,
                          onSelectCategory: (category) {
                            setState(() => _selectedCategory = category);
                          },
                          onAddBlock: _addBlock,
                          onRemoveBlock: _removeBlock,
                        ),
                      ),
                      Container(width: 2, color: const Color(0xFF9A9A9A)),
                      Expanded(
                        flex: 34,
                        child: _GameAndSpritePanel(
                          owlX: _owlX,
                          owlY: _owlY,
                          owlFrame: _owlFrame,
                          isRunning: _isRunning,
                          projectSprites: _projectSprites,
                          onAddSpritePressed: () => _showAddSpriteDialog(context),
                        ),
                      ),
                    ],
                  ),
                );

                if (!needsHorizontalScroll) return content;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: content,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      color: const Color(0xFF3B2118),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFA36A35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF140B07), width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('🐵', style: TextStyle(fontSize: 27)),
          ),
          const SizedBox(width: 8),
          const Text(
            'CODE',
            style: TextStyle(
              color: Color(0xFFFFC12F),
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: 1.3,
              height: 1,
            ),
          ),
          const Text(
            'MONKEY',
            style: TextStyle(
              color: Color(0xFFC7925E),
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: 1.3,
              height: 1,
            ),
          ),
          const SizedBox(width: 24),
          const Text(
            'AI IS A HOOT: EXERCISE #1',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: .4,
            ),
          ),
          const Spacer(),
          const Icon(Icons.article, color: Colors.white, size: 26),
          const SizedBox(width: 30),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7794),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🐧', style: TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 28),
          const Icon(Icons.menu, color: Color(0xFFFFBC1D), size: 34),
        ],
      ),
    );
  }
}

class _LessonPanel extends StatelessWidget {
  const _LessonPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: 94,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 51),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 25,
                          child: Icon(Icons.arrow_left, color: Colors.amber.shade200),
                        ),
                        Container(width: 1, color: const Color(0xFFE4E4E4)),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Exercise 1 of 9',
                              style: TextStyle(fontSize: 16, color: Color(0xFF203246)),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF26A766), size: 20),
                        Container(width: 1, color: const Color(0xFFE4E4E4)),
                        SizedBox(
                          width: 25,
                          child: Icon(Icons.arrow_right, color: Colors.amber.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 58),
                const _SquareIconButton(icon: Icons.volume_up),
                const SizedBox(width: 16),
                const _SquareIconButton(icon: Icons.cached),
              ],
            ),
          ),
          Container(
            height: 38,
            color: const Color(0xFFD9EEF8),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF50C47D), size: 23),
                SizedBox(width: 7),
                Text(
                  'Show my previous solution',
                  style: TextStyle(color: Color(0xFF2F75B5), fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(29, 26, 34, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes, size: 38, color: Color(0xFF2E2722)),
                      const SizedBox(width: 12),
                      const Text(
                        'OVERVIEW',
                        style: TextStyle(
                          color: Color(0xFF78AD50),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(height: 1.4, width: 130, color: const Color(0xFF78AD50)),
                    ],
                  ),
                  const SizedBox(height: 27),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nice to Meet You, Oliver.',
                          style: TextStyle(
                            color: Color(0xFF101926),
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Text('Listen', style: TextStyle(color: Color(0xFF34B772), fontSize: 16)),
                      const SizedBox(width: 5),
                      Icon(Icons.speaker_notes_outlined, color: Colors.green.shade400),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "It's going to be an exciting night! We are going to learn\n"
                    'how to build an AI-based game to move Oliver, the owl,\n'
                    'between obstacles and get to the end of the route.\n\n'
                    'The player will use different postures to change the size\n'
                    'of the owl so it can go below or over tiles.\n'
                    'This is the game you will create at the end of course:',
                    style: TextStyle(fontSize: 16, height: 1.42, color: Color(0xFF0D1B2A)),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 285,
                    decoration: BoxDecoration(
                      color: const Color(0xFF24343D),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: const Color(0xFFE1E1E1), width: 4),
                    ),
                    child: Stack(
                      children: [
                        const Positioned.fill(child: _StarryNightBackground(compact: true)),
                        Positioned(
                          left: 118,
                          top: 83,
                          child: Container(
                            width: 90,
                            height: 96,
                            color: const Color(0xFFB24432),
                            child: CustomPaint(painter: _BrickPainter()),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 6,
                          child: const _OwlSpriteFrame(frame: 0, height: 58),
                        ),
                        const Positioned(
                          left: 23,
                          top: 92,
                          child: Text('00:32', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, height: 1.42, color: Color(0xFF0D1B2A)),
                      children: [
                        TextSpan(text: 'A '),
                        WidgetSpan(child: _InlineCodeBlock('Loop')),
                        TextSpan(text: ' block repeats the blocks inside it over and over\nfor as long as the game runs.\n\n'),
                        TextSpan(text: 'The '),
                        WidgetSpan(child: _InlineCodeBlock('Step')),
                        TextSpan(text: ' block makes the Owl move.'),
                      ],
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
}


class _StarryNightBackground extends StatelessWidget {
  const _StarryNightBackground({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      CodeMonkeyScratchAssets.starryNight,
      fit: BoxFit.none,
      repeat: ImageRepeat.repeat,
      alignment: Alignment.topLeft,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(painter: _StarFieldPainter(compact: compact));
      },
    );
  }
}

class _OwlSpriteFrame extends StatelessWidget {
  const _OwlSpriteFrame({required this.frame, required this.height});

  final int frame;
  final double height;

  static const int _frameCount = 5;
  static const double _sheetWidth = 225;
  static const double _sheetHeight = 68;
  static const double _frameWidth = _sheetWidth / _frameCount;

  @override
  Widget build(BuildContext context) {
    final safeFrame = frame.clamp(0, _frameCount - 1);
    final frameWidth = height * (_frameWidth / _sheetHeight);

    return SizedBox(
      width: frameWidth,
      height: height,
      child: ClipRect(
        child: Align(
          alignment: Alignment(-1.0 + (2.0 * safeFrame / (_frameCount - 1)), 0),
          widthFactor: 1 / _frameCount,
          child: Image.asset(
            CodeMonkeyScratchAssets.owl,
            height: height,
            fit: BoxFit.fitHeight,
            errorBuilder: (context, error, stackTrace) {
              return Text('🦉', style: TextStyle(fontSize: height * .78));
            },
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 51,
      height: 51,
      decoration: BoxDecoration(
        color: const Color(0xFFF5B719),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(offset: Offset(0, 3), color: Color(0xFFCF9212))],
      ),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _InlineCodeBlock extends StatelessWidget {
  const _InlineCodeBlock(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF68A84D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _BlocksWorkspace extends StatelessWidget {
  const _BlocksWorkspace({
    required this.selectedCategory,
    required this.categories,
    required this.paletteBlocks,
    required this.workspaceBlocks,
    required this.isRunning,
    required this.onRun,
    required this.onClear,
    required this.onSelectCategory,
    required this.onAddBlock,
    required this.onRemoveBlock,
  });

  final String selectedCategory;
  final List<String> categories;
  final List<_ScratchBlockData> paletteBlocks;
  final List<_ScratchBlockData> workspaceBlocks;
  final bool isRunning;
  final VoidCallback onRun;
  final VoidCallback onClear;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<_ScratchBlockData> onAddBlock;
  final ValueChanged<int> onRemoveBlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0F5),
      child: Column(
        children: [
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 11, 0),
            child: Row(
              children: [
                const _OwlSpriteFrame(frame: 0, height: 42),
                const SizedBox(width: 10),
                const Text('Oliver', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1C2530))),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isRunning ? null : onRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF46C77E),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
                  ),
                  icon: Icon(isRunning ? Icons.hourglass_bottom : Icons.play_circle_fill, size: 31),
                  label: Text(isRunning ? 'RUNNING' : 'RUN!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<_ScratchBlockData>(
              onAccept: onAddBlock,
              builder: (context, candidateData, rejectedData) {
                return Container(
                  width: double.infinity,
                  color: candidateData.isEmpty ? const Color(0xFFEAF2F7) : const Color(0xFFDDEFFF),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 11,
                        left: 15,
                        right: 15,
                        bottom: 12,
                        child: SingleChildScrollView(
                          child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            spacing: 10,
                            runSpacing: 9,
                            children: [
                              for (var i = 0; i < workspaceBlocks.length; i++)
                                GestureDetector(
                                  onDoubleTap: () => onRemoveBlock(i),
                                  child: _ScratchBlock(block: workspaceBlocks[i], large: true),
                                ),
                              if (workspaceBlocks.length == 1)
                                Container(
                                  margin: const EdgeInsets.only(top: 50, left: 15),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.45),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: const Text(
                                    'Drag blocks from the palette here.\nDouble click a block to remove it.',
                                    style: TextStyle(color: Color(0xFF7D8990), fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 58,
                        right: 56,
                        child: IconButton(
                          onPressed: onClear,
                          tooltip: 'Clear blocks',
                          icon: const Icon(Icons.delete, color: Color(0xFFC9CFD2), size: 66),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 104,
            color: const Color(0xFFD9D9D9),
            padding: const EdgeInsets.fromLTRB(8, 7, 7, 7),
            child: Column(
              children: [
                SizedBox(
                  height: 61,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: paletteBlocks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final block = paletteBlocks[index];
                      return Draggable<_ScratchBlockData>(
                        data: block,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Transform.scale(scale: 1.04, child: _ScratchBlock(block: block, large: true)),
                        ),
                        childWhenDragging: Opacity(opacity: .35, child: _ScratchBlock(block: block, large: true)),
                        child: _ScratchBlock(block: block, large: true),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 21,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8C8C8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(width: 132),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 8, 10, 18),
            child: Wrap(
              spacing: 6,
              runSpacing: 9,
              children: [
                for (final category in categories)
                  _CategoryButton(
                    label: category,
                    color: _categoryColor(category),
                    selected: selectedCategory == category,
                    onTap: () => onSelectCategory(category),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF17202A) : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ScratchBlock extends StatelessWidget {
  const _ScratchBlock({required this.block, this.large = false});

  final _ScratchBlockData block;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final height = large ? 48.0 : 35.0;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: height,
            padding: EdgeInsets.fromLTRB(large ? 15 : 10, 0, block.value == null ? 15 : 10, 0),
            decoration: BoxDecoration(
              color: block.color,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.16), offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  block.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: large ? 16 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (block.value != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: large ? 31 : 24,
                    height: large ? 31 : 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE5D8),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.16), offset: const Offset(0, 1))],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      block.value!,
                      style: TextStyle(
                        color: const Color(0xFF392C22),
                        fontSize: large ? 15 : 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (block.kind != _ScratchBlockKind.event)
            Positioned(
              left: -9,
              top: height / 2 - 8,
              child: Container(
                width: 17,
                height: 16,
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          if (block.kind != _ScratchBlockKind.event)
            Positioned(
              right: -6,
              top: height / 2 - 8,
              child: Container(
                width: 15,
                height: 16,
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class _GameAndSpritePanel extends StatelessWidget {
  const _GameAndSpritePanel({
    required this.owlX,
    required this.owlY,
    required this.owlFrame,
    required this.isRunning,
    required this.projectSprites,
    required this.onAddSpritePressed,
  });

  final double owlX;
  final double owlY;
  final int owlFrame;
  final bool isRunning;
  final List<_SpriteAssetData> projectSprites;
  final VoidCallback onAddSpritePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            flex: 52,
            child: _StagePreview(
              owlX: owlX,
              owlY: owlY,
              owlFrame: owlFrame,
              isRunning: isRunning,
            ),
          ),
          Expanded(
            flex: 48,
            child: _SpriteInspector(
              projectSprites: projectSprites,
              onAddSpritePressed: onAddSpritePressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePreview extends StatelessWidget {
  const _StagePreview({
    required this.owlX,
    required this.owlY,
    required this.owlFrame,
    required this.isRunning,
  });

  final double owlX;
  final double owlY;
  final int owlFrame;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spriteSize = 74.0;
        final maxLeft = math.max(0.0, constraints.maxWidth - spriteSize - 8);
        final maxTop = math.max(0.0, constraints.maxHeight - spriteSize - 8);
        final left = owlX.clamp(0.0, maxLeft);
        final top = owlY.clamp(0.0, maxTop);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _StarryNightBackground()),
            Positioned(
              left: constraints.maxWidth * .30,
              bottom: 0,
              child: Container(
                width: 30,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF26323B),
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ),
            AnimatedPositioned(
              left: left,
              top: top,
              duration: const Duration(milliseconds: 70),
              curve: Curves.linear,
              child: Container(
                width: spriteSize,
                height: spriteSize,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF91C75B), width: 4),
                ),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: isRunning ? -.05 : -.16,
                  child: _OwlSpriteFrame(frame: owlFrame, height: 66),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: const [
                  _StageToolAsset(assetPath: CodeMonkeyScratchAssets.toolDefault),
                  _StageToolAsset(assetPath: CodeMonkeyScratchAssets.toolDrag),
                  _StageToolAsset(assetPath: CodeMonkeyScratchAssets.toolErase),
                  _StageToolAsset(assetPath: CodeMonkeyScratchAssets.toolPaint),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StageToolAsset extends StatelessWidget {
  const _StageToolAsset({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 41,
      height: 38,
      color: const Color(0xFFC4C7C8),
      padding: const EdgeInsets.all(5),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.crop_square, color: Colors.black87, size: 22);
        },
      ),
    );
  }
}


class _SpriteInspector extends StatelessWidget {
  const _SpriteInspector({
    required this.projectSprites,
    required this.onAddSpritePressed,
  });

  final List<_SpriteAssetData> projectSprites;
  final VoidCallback onAddSpritePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: const [
              _InspectorTab(label: 'Sprites', selected: true),
              _InspectorTab(label: 'Widgets'),
              _InspectorTab(label: 'Sounds'),
              _InspectorTab(label: 'Game'),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(34, 22, 22, 22),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _AddNewSpriteCard(onTap: onAddSpritePressed),
                    const _OliverSpriteCard(),
                    for (final sprite in projectSprites)
                      _ProjectSpriteCard(sprite: sprite),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddNewSpriteCard extends StatelessWidget {
  const _AddNewSpriteCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 135,
        height: 148,
        decoration: BoxDecoration(
          color: const Color(0xFF2E8057),
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 55, color: Color(0xFFB9C6BE)),
            SizedBox(height: 14),
            Text(
              'ADD NEW',
              style: TextStyle(
                color: Color(0xFFB9C6BE),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OliverSpriteCard extends StatelessWidget {
  const _OliverSpriteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF84B75C), width: 3),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 9,
            right: 9,
            child: Icon(Icons.settings, color: Color(0xFF84B75C), size: 22),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _OwlSpriteFrame(frame: 0, height: 61),
                  SizedBox(height: 11),
                  Text(
                    'Oliver',
                    style: TextStyle(
                      color: Color(0xFF3D3D3D),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
}

class _ProjectSpriteCard extends StatelessWidget {
  const _ProjectSpriteCard({required this.sprite});

  final _SpriteAssetData sprite;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E1E1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 9,
            right: 9,
            child: Icon(Icons.settings, color: Color(0xFF84B75C), size: 20),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 68,
                    width: 92,
                    child: Center(
                      child: _SpriteSheetFrame(sprite: sprite, height: 58),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      sprite.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF3D3D3D),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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
}

class _AddSpriteDialog extends StatefulWidget {
  const _AddSpriteDialog();

  @override
  State<_AddSpriteDialog> createState() => _AddSpriteDialogState();
}

class _AddSpriteDialogState extends State<_AddSpriteDialog> {
  static const List<String> _categories = [
    'ALL CATEGORIES',
    'ANIMALS',
    'NATURE',
    'FOOD',
    'SPORTS',
    'SPACE',
    'FANTASY',
    'OBJECTS',
    'MY SPRITES',
  ];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'ALL CATEGORIES';
  String _searchText = '';
  _SpriteAssetData? _selectedSprite = _spriteLibrary.first;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_SpriteAssetData> get _filteredSprites {
    final q = _searchText.trim().toLowerCase();
    return _spriteLibrary.where((sprite) {
      final matchesCategory = _selectedCategory == 'ALL CATEGORIES' ||
          sprite.categories.contains(_selectedCategory);
      final matchesSearch = q.isEmpty ||
          sprite.displayName.toLowerCase().contains(q) ||
          sprite.assetPath.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1380,
          maxHeight: 815,
          minHeight: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ADD A SPRITE',
                style: TextStyle(
                  color: Color(0xFF7BAE55),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 1, color: const Color(0xFF9DCA76)),
              const SizedBox(height: 36),
              Row(
                children: [
                  SizedBox(
                    width: 435,
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchText = value),
                      decoration: InputDecoration(
                        hintText: 'search...',
                        hintStyle: const TextStyle(fontSize: 19, color: Color(0xFF6A6A6A)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        suffixIcon: const Icon(Icons.search, color: Color(0xFF78AD50), size: 26),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFFC7C7C7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFFC7C7C7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Color(0xFF78AD50), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 51),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _SpriteCategoryChip(
                      label: category,
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(58, 16, 38, 18),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisExtent: 158,
                      crossAxisSpacing: 22,
                      mainAxisSpacing: 30,
                    ),
                    itemCount: _filteredSprites.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const _SpriteDialogActionTile(
                          icon: Icons.upload,
                          label: 'UPLOAD SPRITE\nSHEET',
                        );
                      }
                      if (index == 1) {
                        return const _SpriteDialogActionTile(
                          icon: Icons.add,
                          label: 'CREATE A NEW\nSHEET',
                        );
                      }

                      final sprite = _filteredSprites[index - 2];
                      return _SpriteLibraryTile(
                        sprite: sprite,
                        selected: _selectedSprite == sprite,
                        onTap: () => setState(() => _selectedSprite = sprite),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3F2016),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                    ),
                    child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 64),
                  SizedBox(
                    width: 176,
                    height: 47,
                    child: ElevatedButton(
                      onPressed: _selectedSprite == null
                          ? null
                          : () => Navigator.pop(context, _selectedSprite),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D861D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 7),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpriteCategoryChip extends StatelessWidget {
  const _SpriteCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFFFC82E),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFC82E), width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF596779),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SpriteDialogActionTile extends StatelessWidget {
  const _SpriteDialogActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF51C68C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.20), offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 57, color: Colors.white),
          const SizedBox(height: 14),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1.18,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteLibraryTile extends StatelessWidget {
  const _SpriteLibraryTile({
    required this.sprite,
    required this.selected,
    required this.onTap,
  });

  final _SpriteAssetData sprite;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF9A9A9A) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.16), offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: 96,
                height: 96,
                child: Center(child: _SpriteSheetFrame(sprite: sprite, height: 74)),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF58C88B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 31),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpriteSheetFrame extends StatelessWidget {
  const _SpriteSheetFrame({required this.sprite, required this.height});

  final _SpriteAssetData sprite;
  final double height;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      sprite.assetPath,
      height: height,
      fit: BoxFit.fitHeight,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.image_not_supported_outlined, size: height * .55, color: Colors.grey.shade500);
      },
    );

    final frame = sprite.previewFrame.clamp(0, sprite.frameCount - 1);

    if (sprite.frameCount <= 1) {
      return FittedBox(fit: BoxFit.contain, child: image);
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: ClipRect(
        child: Align(
          alignment: Alignment(-1.0 + (2.0 * frame / (sprite.frameCount - 1)), 0),
          widthFactor: 1 / sprite.frameCount,
          child: image,
        ),
      ),
    );
  }
}

class _SpriteAssetData {
  const _SpriteAssetData({
    required this.displayName,
    required this.assetPath,
    required this.categories,
    this.frameCount = 1,
    this.previewFrame = 0,
  });

  final String displayName;
  final String assetPath;
  final List<String> categories;
  final int frameCount;
  final int previewFrame;
}

const List<_SpriteAssetData> _spriteLibrary = [
  _SpriteAssetData(displayName: 'Monkey', assetPath: 'assets/images/sprites/baseballMonkey.png', categories: ['ANIMALS', 'SPORTS'], frameCount: 4),
  _SpriteAssetData(displayName: 'Cupid Monkey', assetPath: 'assets/images/sprites/cupidMonkey.png', categories: ['ANIMALS', 'FANTASY'], frameCount: 5),
  _SpriteAssetData(displayName: 'Banana', assetPath: 'assets/images/sprites/banana.png', categories: ['FOOD', 'NATURE']),
  _SpriteAssetData(displayName: 'Chocolate', assetPath: 'assets/images/sprites/chocolate.png', categories: ['FOOD']),
  _SpriteAssetData(displayName: 'Powerup', assetPath: 'assets/images/sprites/powerup.png', categories: ['OBJECTS']),
  _SpriteAssetData(displayName: 'Tiger', assetPath: 'assets/images/sprites/tiger.png', categories: ['ANIMALS'], frameCount: 6),
  _SpriteAssetData(displayName: 'Hippo', assetPath: 'assets/images/sprites/hippo.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Elephant', assetPath: 'assets/images/sprites/elephant.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Giraffe', assetPath: 'assets/images/sprites/giraffe.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Zebra', assetPath: 'assets/images/sprites/zebra.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Rover', assetPath: 'assets/images/sprites/rover.png', categories: ['SPACE', 'OBJECTS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Unicorn', assetPath: 'assets/images/sprites/unicorn.png', categories: ['ANIMALS', 'FANTASY'], frameCount: 5),
  _SpriteAssetData(displayName: 'Wizard Monkey', assetPath: 'assets/images/sprites/wizardMonkey.png', categories: ['ANIMALS', 'FANTASY'], frameCount: 5),
  _SpriteAssetData(displayName: 'Monster', assetPath: 'assets/images/sprites/spaceMonster.png', categories: ['SPACE', 'FANTASY'], frameCount: 4),
  _SpriteAssetData(displayName: 'Space Monster', assetPath: 'assets/images/sprites/spaceMonster2.png', categories: ['SPACE', 'FANTASY'], frameCount: 4),
  _SpriteAssetData(displayName: 'Space Zebra', assetPath: 'assets/images/sprites/spaceZebra.png', categories: ['ANIMALS', 'SPACE'], frameCount: 5),
  _SpriteAssetData(displayName: 'Astronaut', assetPath: 'assets/images/sprites/astronaut.png', categories: ['SPACE'], frameCount: 6),
  _SpriteAssetData(displayName: 'Basketball Monkey', assetPath: 'assets/images/sprites/basketballMonkey.png', categories: ['ANIMALS', 'SPORTS'], frameCount: 4),
  _SpriteAssetData(displayName: 'Car', assetPath: 'assets/images/sprites/car.png', categories: ['OBJECTS']),
  _SpriteAssetData(displayName: 'Coin', assetPath: 'assets/images/sprites/coin.png', categories: ['OBJECTS']),
  _SpriteAssetData(displayName: 'Elephant 2', assetPath: 'assets/images/sprites/elephant2.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Frog', assetPath: 'assets/images/sprites/frog.png', categories: ['ANIMALS', 'NATURE'], frameCount: 5),
  _SpriteAssetData(displayName: 'Heart', assetPath: 'assets/images/sprites/heart.png', categories: ['OBJECTS']),
  _SpriteAssetData(displayName: 'Hedgehog', assetPath: 'assets/images/sprites/hedgehog.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'House', assetPath: 'assets/images/sprites/house.png', categories: ['OBJECTS']),
  _SpriteAssetData(displayName: 'Knight Monkey', assetPath: 'assets/images/sprites/knightMonkey.png', categories: ['ANIMALS', 'FANTASY'], frameCount: 5),
  _SpriteAssetData(displayName: 'Ostrich', assetPath: 'assets/images/sprites/ostrich.png', categories: ['ANIMALS'], frameCount: 6),
  _SpriteAssetData(displayName: 'Porcupine', assetPath: 'assets/images/sprites/porcupine.png', categories: ['ANIMALS'], frameCount: 5),
  _SpriteAssetData(displayName: 'Soccer Monkey', assetPath: 'assets/images/sprites/soccerMonkey.png', categories: ['ANIMALS', 'SPORTS'], frameCount: 4),
  _SpriteAssetData(displayName: 'Spaceman', assetPath: 'assets/images/sprites/spaceman.png', categories: ['SPACE'], frameCount: 6),
  _SpriteAssetData(displayName: 'Star', assetPath: 'assets/images/sprites/star.png', categories: ['SPACE', 'OBJECTS']),
  _SpriteAssetData(displayName: 'Truck', assetPath: 'assets/images/sprites/truck.png', categories: ['OBJECTS'], frameCount: 3),
  _SpriteAssetData(displayName: 'Turtle', assetPath: 'assets/images/sprites/turtle.png', categories: ['ANIMALS', 'NATURE'], frameCount: 6),
];

class _InspectorTab extends StatelessWidget {
  const _InspectorTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFD1D6D9),
          borderRadius: selected ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(13)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : const Color(0xFF7A8185),
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}

class _TinyCheckbox extends StatelessWidget {
  const _TinyCheckbox({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: (_) {},
            visualDensity: VisualDensity.compact,
            activeColor: const Color(0xFF667E8E),
          ),
        ),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF414141)))),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.18), offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 9),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: .5)),
        ],
      ),
    );
  }
}

enum _ScratchBlockKind { event, movement, variable, control, display, ai }

class _ScratchBlockData {
  const _ScratchBlockData({
    required this.label,
    required this.color,
    required this.kind,
    this.value,
  });

  final String label;
  final Color color;
  final _ScratchBlockKind kind;
  final String? value;

  factory _ScratchBlockData.event(String label) => _ScratchBlockData(label: label, color: const Color(0xFF5BA658), kind: _ScratchBlockKind.event);

  factory _ScratchBlockData.movement(String label, {String? value}) => _ScratchBlockData(label: label, value: value, color: const Color(0xFF83B455), kind: _ScratchBlockKind.movement);

  factory _ScratchBlockData.variable(String label, {String? value}) => _ScratchBlockData(label: label, value: value, color: const Color(0xFF50AEB1), kind: _ScratchBlockKind.variable);

  factory _ScratchBlockData.control(String label, {String? value}) => _ScratchBlockData(label: label, value: value, color: const Color(0xFF58B082), kind: _ScratchBlockKind.control);

  factory _ScratchBlockData.display(String label, {String? value}) => _ScratchBlockData(label: label, value: value, color: const Color(0xFF7156B6), kind: _ScratchBlockKind.display);

  factory _ScratchBlockData.ai(String label, {String? value}) => _ScratchBlockData(label: label, value: value, color: const Color(0xFFACAC4F), kind: _ScratchBlockKind.ai);
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Movement':
      return const Color(0xFF80B05D);
    case 'Events':
      return const Color(0xFFB24F54);
    case 'Display':
      return const Color(0xFF6B54B5);
    case 'Widgets':
      return const Color(0xFF4D82A7);
    case 'Game and Sounds':
      return const Color(0xFF8C49A2);
    case 'Control':
      return const Color(0xFF50AD80);
    case 'Logic and Data':
      return const Color(0xFFB28B56);
    case 'Variables':
      return const Color(0xFF4EAFB1);
    case "Object's Functions":
      return const Color(0xFFB05282);
    case "Other objects' Functions":
      return const Color(0xFFB05282);
    case 'AI':
      return const Color(0xFFA7A84C);
    default:
      return const Color(0xFF777777);
  }
}

class _StarFieldPainter extends CustomPainter {
  const _StarFieldPainter({this.compact = false});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF26333C);
    canvas.drawRect(Offset.zero & size, background);

    final shadowPaint = Paint()..color = Colors.black.withOpacity(.65);
    final starPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.2 : 1.5;

    final count = compact ? 45 : 84;
    for (var i = 0; i < count; i++) {
      final x = (((i * 73) % 997) / 997) * size.width;
      final y = (((i * 151) % 991) / 991) * size.height;
      final r = compact ? 3.2 + (i % 3) * 1.2 : 4.0 + (i % 4) * 1.6;
      final angle = (i % 9) * .16;
      final path = _starPath(Offset(x, y), r, r * .43, angle);
      canvas.save();
      canvas.translate(1.4, 1.4);
      canvas.drawPath(path, shadowPaint);
      canvas.restore();
      canvas.drawPath(path, starPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _starPath(Offset center, double outerRadius, double innerRadius, double rotation) {
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final radius = point.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + rotation + point * math.pi / 5;
      final p = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      if (point == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => oldDelegate.compact != compact;
}

class _BrickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF743025)
      ..strokeWidth = 2;
    for (double y = 15; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      for (double x = 0; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 15, size.height)), linePaint);
      }
    }
    for (double y = 15; y < size.height; y += 30) {
      for (double x = 20; x < size.width; x += 40) {
        canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 15, size.height)), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
