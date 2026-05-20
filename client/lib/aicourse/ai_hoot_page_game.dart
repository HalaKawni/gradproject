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
  });

  final double owlX;
  final double owlY;
  final int owlFrame;
  final bool isRunning;

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
            child: _SpriteInspector(isRunning: isRunning),
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
  const _SpriteInspector({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 53,
          child: Row(
            children: [
              _InspectorTab(label: 'Sprites', selected: true),
              _InspectorTab(label: 'Widgets'),
              _InspectorTab(label: 'Sounds'),
              _InspectorTab(label: 'Game'),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(44, 9, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(child: _TinyCheckbox(label: 'Allow Gravity', value: true)),
                    Expanded(child: _TinyCheckbox(label: 'Collide world bounds', value: true)),
                  ],
                ),
                const Row(
                  children: [
                    Expanded(child: _TinyCheckbox(label: 'Immovable', value: false)),
                    Expanded(child: _TinyCheckbox(label: 'Show', value: true)),
                  ],
                ),
                const Row(
                  children: [
                    Expanded(child: _TinyCheckbox(label: 'Collide other sprites', value: true)),
                    Expanded(child: _TinyCheckbox(label: 'Draggable', value: false)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Hide preview', style: TextStyle(color: Color(0xFF2B74B7), fontSize: 16)),
                const SizedBox(height: 14),
                SizedBox(
                  height: 78,
                  child: Row(
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Transform.rotate(
                          angle: index.isEven ? -.12 : .05,
                          child: _OwlSpriteFrame(frame: index, height: 62),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(label: 'DELETE', icon: Icons.cancel, color: const Color(0xFF858585)),
                    const SizedBox(width: 16),
                    _ActionButton(label: 'DUPLICATE', icon: Icons.copy_all, color: const Color(0xFF45C681)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
