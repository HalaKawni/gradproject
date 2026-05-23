import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'blocks_flutter_page.dart';


// Put these uploaded images in your Flutter project at:
// client/assets/images/
class CodeMonkeyScratchAssets {
  static const String owl = 'assets/images/owl.png';
  static const String starryNight = 'assets/images/starry_night.png';
  static const String toolDefault = 'assets/images/default.png';
  static const String toolDrag = 'assets/images/drag.png';
  static const String toolErase = 'assets/images/erase.png';
  static const String toolPaint = 'assets/images/paint.png';
  static const String uploadMonkey = 'assets/images/upload_monkey.png';
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
  double _owlScale = 1.0;
  double _owlRotation = 0.0;
  double _owlOpacity = 1.0;

  // owl.png is a horizontal spritesheet with 5 walking frames.
  // This index chooses which frame is shown on the stage.
  int _owlFrame = 0;

  String _selectedObjectId = 'oliver';
  final Map<String, List<_ScratchBlockData>> _objectWorkspaces = {
    'oliver': [_ScratchBlockData.event('On Run')],
  };
  List<_ScratchBlockData> get _workspaceBlocks => _objectWorkspaces[_selectedObjectId]!;

  final List<_SpriteAssetData> _projectSprites = <_SpriteAssetData>[];
  final List<_AddedGameWidget> _stageWidgets = [];

  void _onWidgetAdded(_AddedGameWidget w) {
    setState(() {
      _stageWidgets.add(w);
      if (w.type == _GameWidgetType.timer) {
        _objectWorkspaces[w.id] = [
          _ScratchBlockData.event('On Run'),
          _ScratchBlockData.widgetBlock('Set ${w.type.name}: ${w.name} To', value: '1'),
          _ScratchBlockData.endEvent('On End'),
        ];
      } else if (w.type == _GameWidgetType.button) {
        _objectWorkspaces[w.id] = [
          _ScratchBlockData.event('On Run'),
          _ScratchBlockData.endEvent('On Click'),
          _ScratchBlockData.endEvent('On Down'),
        ];
      } else if (w.type == _GameWidgetType.dialog) {
        _objectWorkspaces[w.id] = [
          _ScratchBlockData.event('On Run'),
          _ScratchBlockData.endEvent('On Confirm'),
        ];
      } else if (w.type == _GameWidgetType.webcam) {
        _objectWorkspaces[w.id] = [
          _ScratchBlockData.event('On Run'),
        ];
      } else {
        _objectWorkspaces[w.id] = [
          _ScratchBlockData.event('On Run'),
          _ScratchBlockData.widgetBlock('Set ${w.type.name}: ${w.name} To', value: '0'),
        ];
      }
    });
  }

  void _onWidgetRemoved(_AddedGameWidget w) {
    setState(() {
      _stageWidgets.remove(w);
      _objectWorkspaces.remove(w.id);
      if (_selectedObjectId == w.id) _selectedObjectId = 'oliver';
    });
  }

  void _onWidgetSelected(_AddedGameWidget w) {
    setState(() => _selectedObjectId = w.id);
  }

  void _onWidgetChanged() => setState(() {});

  List<_ScratchBlockData> get _paletteBlocks {
    switch (_selectedCategory) {
      case 'Events':
        return [
          _ScratchBlockData.eventC('On Key', value: '→'),
          _ScratchBlockData.eventC('On Collide', value: 'Oliver'),
          _ScratchBlockData.eventC('On Collide With World Bounds', value: 'Left'),
          _ScratchBlockData.eventC('On Swipe', value: 'Left'),
          _ScratchBlockData.eventC('On Click'),
          _ScratchBlockData.eventC('On Update'),
          _ScratchBlockData.eventC('On Game Tap'),
          _ScratchBlockData.eventC('On Drag End'),
          _ScratchBlockData.eventC('On Run'),
        ];
      case 'Display':
        return [
          _ScratchBlockData.display('Show'),
          _ScratchBlockData.display('Hide'),
          _ScratchBlockData.display('Destroy'),
          _ScratchBlockData.display('Disable'),
          _ScratchBlockData.display('Enable'),
          _ScratchBlockData.display('Set Scale', value: '1'),
          _ScratchBlockData.displayReporter('Get Scale'),
          _ScratchBlockData.display('Set Opacity', value: '1'),
          _ScratchBlockData.displayReporter('Get Opacity'),
        ];
      case 'Widgets':
        return [
          _ScratchBlockData.widgetBlock('Set counter:', value: 'To', value2: '1'),
          _ScratchBlockData.widgetBlock('Change counter:', value: 'By', value2: '1'),
          _ScratchBlockData.widgetBlock('Set text:', value: 'To', value2: '“  ”'),
          _ScratchBlockData.widgetBlock('Set timer:', value: 'To', value2: '1'),
          _ScratchBlockData.widgetBlock('Start clock:', value: ''),
          _ScratchBlockData.widgetReporter('Get', value: 'Value'),
          _ScratchBlockData.widgetReporter('Get', value: 'Seconds'),
        ];
      case 'Game and Sounds':
        return [
          _ScratchBlockData.game('Play', value: 'Sound'),
          _ScratchBlockData.game('Reset Game'),
          _ScratchBlockData.game('Pause Game'),
          _ScratchBlockData.game('Unpause Game'),
          _ScratchBlockData.gameReporter('Get Game Time'),
          _ScratchBlockData.game('Set Background', value: 'jungle'),
        ];
      case 'Control':
        return [
          _ScratchBlockData.controlC('Loop'),
          _ScratchBlockData.controlC('Repeat', value: '10', suffix: 'times'),
          _ScratchBlockData.controlC('if', suffix: 'do', settingsIcon: true),
          _ScratchBlockData.controlC('if', suffix: 'do\nelse', settingsIcon: true, tall: true),
          _ScratchBlockData.control('Wait', value: '1'),
        ];
      case 'Logic and Data':
        return [
          _ScratchBlockData.booleanBlock('not'),
          _ScratchBlockData.booleanBlock('', value: 'and'),
          _ScratchBlockData.booleanBlock('', value: '='),
          _ScratchBlockData.logicReporter('0'),
          _ScratchBlockData.logicReporter('“  ”'),
          _ScratchBlockData.logicReporter('', value: '1', operatorSymbolArg: '+', value2: '1'),
          _ScratchBlockData.logicReporter('Random from', value: '0', suffix: 'to', value2: '100'),
          _ScratchBlockData.booleanBlock('', value: '<'),
          _ScratchBlockData.booleanBlock('', value: '>'),
        ];
      case 'Variables':
        return [
          _ScratchBlockData.variable('Set variable:', value: 'To', value2: '0'),
          _ScratchBlockData.variable('Change variable:', value: 'By', value2: '1'),
          _ScratchBlockData.variableReporter('Get variable:'),
          _ScratchBlockData.variable('Set X', value: '300'),
          _ScratchBlockData.variable('Set Y', value: '200'),
          _ScratchBlockData.variableReporter('Get X'),
          _ScratchBlockData.variableReporter('Get Y'),
        ];
      case "Object's Functions":
        return [
          _ScratchBlockData.functionBlock('to', value: 'do something'),
          _ScratchBlockData.functionC('to', value: 'do something', suffix: 'return'),
          _ScratchBlockData.functionBlock('if', suffix: 'return'),
        ];
      case "Other objects' Functions":
        return [
          _ScratchBlockData.functionBlock('Oliver', value: 'do something'),
          _ScratchBlockData.functionReporter('From', value: 'Oliver', suffix: 'get x'),
          _ScratchBlockData.functionReporter('From', value: 'Oliver', suffix: 'get y'),
          _ScratchBlockData.functionReporter('From', value: 'Oliver', suffix: 'get rotation'),
        ];
      case 'AI':
        return [
          _ScratchBlockData.aiReporter('Predict', value: ''),
          _ScratchBlockData.aiC('On Prediction', value: ''),
        ];
      case 'Movement':
      default:
        return [
          _ScratchBlockData.movement('Step', value: '1'),
          _ScratchBlockData.movement('Jump', value: '1'),
          _ScratchBlockData.movementReporter('Get X'),
          _ScratchBlockData.movementReporter('Get Y'),
          _ScratchBlockData.movement('Set X', value: '300'),
          _ScratchBlockData.movement('Set Y', value: '200'),
          _ScratchBlockData.movement('Change X By', value: '0'),
          _ScratchBlockData.movement('Change Y By', value: '0'),
          _ScratchBlockData.movementReporter('Get Rotation'),
          _ScratchBlockData.movement('Set Rotation', value: '0'),
          _ScratchBlockData.movement('Change Rotation By', value: '0'),
          _ScratchBlockData.movement('Set Speed', value: '1'),
          _ScratchBlockData.movement('Set Allow Gravity', value: 'true'),
          _ScratchBlockData.movementReporter('Get Distance From', value: 'Oliver'),
          _ScratchBlockData.movementReporter('From', value: 'Oliver', suffix: 'get x'),
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
    if (block.kind == _ScratchBlockKind.endEvent) {
      setState(() {
        _workspaceBlocks.removeWhere((b) => b.kind == _ScratchBlockKind.endEvent);
        _workspaceBlocks.add(block);
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
      if (_selectedObjectId == 'oliver') {
        _owlX = 36;
        _owlY = 315;
        _owlFrame = 0;
      }
    });
  }

  void _onOliverSettingsChanged(_SpriteSettings s) {
    setState(() {
      _owlX = s.x.toDouble();
      _owlY = s.y.toDouble();
      _owlScale = s.scale;
      _owlRotation = s.rotation;
      _owlOpacity = s.opacity;
    });
  }

  void _onSpriteDeleted(_SpriteAssetData sprite) {
    setState(() => _projectSprites.remove(sprite));
  }

  void _onSpriteDuplicated(_SpriteAssetData sprite) {
    setState(() => _projectSprites.add(_SpriteAssetData(
      displayName: '${sprite.displayName} copy',
      assetPath: sprite.assetPath,
      categories: sprite.categories,
      frameCount: sprite.frameCount,
      imageBytes: sprite.imageBytes,
    )));
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
                          activeObjectName: _selectedObjectId == 'oliver'
                              ? 'Oliver'
                              : _stageWidgets.firstWhere((w) => w.id == _selectedObjectId, orElse: () => _stageWidgets.first).name,
                          activeObjectAsset: _selectedObjectId == 'oliver'
                              ? null
                              : _stageWidgets.firstWhere((w) => w.id == _selectedObjectId, orElse: () => _stageWidgets.first).assetPath,
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
                          owlScale: _owlScale,
                          owlRotation: _owlRotation,
                          owlOpacity: _owlOpacity,
                          owlFrame: _owlFrame,
                          isRunning: _isRunning,
                          projectSprites: _projectSprites,
                          stageWidgets: _stageWidgets,
                          onAddSpritePressed: () => _showAddSpriteDialog(context),
                          onOliverSettingsChanged: _onOliverSettingsChanged,
                          onSpriteDeleted: _onSpriteDeleted,
                          onSpriteDuplicated: _onSpriteDuplicated,
                          onWidgetAdded: _onWidgetAdded,
                          onWidgetRemoved: _onWidgetRemoved,
                          onWidgetSelected: _onWidgetSelected,
                          onWidgetChanged: _onWidgetChanged,
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
    required this.activeObjectName,
    this.activeObjectAsset,
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
  final String activeObjectName;
  final String? activeObjectAsset;
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
                activeObjectAsset != null
                    ? Image.asset(activeObjectAsset!, height: 42, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.widgets, size: 36))
                    : const _OwlSpriteFrame(frame: 0, height: 42),
                const SizedBox(width: 10),
                Text(activeObjectName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1C2530))),
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
            height: 146,
            color: const Color(0xFFD9D9D9),
            padding: const EdgeInsets.fromLTRB(8, 5, 7, 5),
            child: Column(
              children: [
                SizedBox(
                  height: 115,
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
                const SizedBox(height: 5),
                SizedBox(
                  height: 16,
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

// Converts _ScratchBlockData to a BlockDef so we can render with Scratch3Block.
BlockDef _scratchDataToBlockDef(_ScratchBlockData block) {
  BlockShape blockShape;
  bool leftTab = true;
  bool rightNotch = true;
  ElseRowDef? elseRow;

  switch (block.shape) {
    case _ScratchBlockShape.reporter:
      blockShape = BlockShape.reporter;
      break;
    case _ScratchBlockShape.booleanReporter:
      blockShape = BlockShape.boolean;
      break;
    case _ScratchBlockShape.cBlock:
      if (block.kind == _ScratchBlockKind.event || block.kind == _ScratchBlockKind.endEvent) {
        blockShape = BlockShape.hat;
        leftTab = false;
        rightNotch = block.kind != _ScratchBlockKind.endEvent;
      } else {
        blockShape = BlockShape.cBlock;
        if (block.tall) elseRow = const ElseRowDef(label: 'else');
      }
      break;
    case _ScratchBlockShape.command:
      if (block.kind == _ScratchBlockKind.event) {
        blockShape = BlockShape.hat;
        leftTab = false;
      } else if (block.kind == _ScratchBlockKind.endEvent) {
        blockShape = BlockShape.stack;
        leftTab = false;
        rightNotch = false;
      } else {
        blockShape = BlockShape.stack;
      }
  }

  final fields = <BlockFieldDef>[];
  if (block.settingsIcon) fields.add(const BlockFieldDef.gear());
  if (block.helpIcon) fields.add(const BlockFieldDef.question());

  if (block.value != null) {
    if (block.valueDropdown) {
      fields.add(BlockFieldDef.dropdown(block.value!));
    } else {
      final n = num.tryParse(block.value!);
      if (n != null) {
        fields.add(BlockFieldDef.number(n));
      } else {
        fields.add(BlockFieldDef.label(block.value!));
      }
    }
  }

  if (block.operatorSymbol != null) {
    fields.add(BlockFieldDef.op(block.operatorSymbol!));
  }

  if (block.value2 != null) {
    if (block.value2Dropdown) {
      fields.add(BlockFieldDef.dropdown(block.value2!));
    } else {
      final n = num.tryParse(block.value2!);
      if (n != null) {
        fields.add(BlockFieldDef.number(n));
      } else {
        fields.add(BlockFieldDef.label(block.value2!));
      }
    }
  }

  if (block.suffix != null) {
    fields.add(BlockFieldDef.label(block.suffix!.replaceAll('\n', ' / ')));
  }

  return BlockDef(
    shape: blockShape,
    label: block.label,
    fields: fields,
    leftTab: leftTab,
    rightNotch: rightNotch,
    elseRow: elseRow,
    width: block.width,
  );
}

Color _darkenColor(Color c) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * 0.76).clamp(0.0, 1.0)).toColor();
}

class _ScratchBlock extends StatelessWidget {
  const _ScratchBlock({required this.block, this.large = false});

  final _ScratchBlockData block;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Scratch3Block(
      block: _scratchDataToBlockDef(block),
      color: block.color,
      darkColor: _darkenColor(block.color),
      scale: large ? 1.0 : 0.72,
    );
  }
}


class _GameAndSpritePanel extends StatelessWidget {
  const _GameAndSpritePanel({
    required this.owlX,
    required this.owlY,
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.owlFrame,
    required this.isRunning,
    required this.projectSprites,
    required this.stageWidgets,
    required this.onAddSpritePressed,
    required this.onOliverSettingsChanged,
    required this.onSpriteDeleted,
    required this.onSpriteDuplicated,
    required this.onWidgetAdded,
    required this.onWidgetRemoved,
    required this.onWidgetSelected,
    required this.onWidgetChanged,
  });

  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final int owlFrame;
  final bool isRunning;
  final List<_SpriteAssetData> projectSprites;
  final List<_AddedGameWidget> stageWidgets;
  final VoidCallback onAddSpritePressed;
  final ValueChanged<_SpriteSettings> onOliverSettingsChanged;
  final ValueChanged<_SpriteAssetData> onSpriteDeleted;
  final ValueChanged<_SpriteAssetData> onSpriteDuplicated;
  final ValueChanged<_AddedGameWidget> onWidgetAdded;
  final ValueChanged<_AddedGameWidget> onWidgetRemoved;
  final ValueChanged<_AddedGameWidget> onWidgetSelected;
  final VoidCallback onWidgetChanged;

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
              owlScale: owlScale,
              owlRotation: owlRotation,
              owlOpacity: owlOpacity,
              owlFrame: owlFrame,
              isRunning: isRunning,
              stageWidgets: stageWidgets,
            ),
          ),
          Expanded(
            flex: 48,
            child: _SpriteInspector(
              projectSprites: projectSprites,
              stageWidgets: stageWidgets,
              onAddSpritePressed: onAddSpritePressed,
              owlX: owlX,
              owlY: owlY,
              owlScale: owlScale,
              owlRotation: owlRotation,
              owlOpacity: owlOpacity,
              onOliverSettingsChanged: onOliverSettingsChanged,
              onSpriteDeleted: onSpriteDeleted,
              onSpriteDuplicated: onSpriteDuplicated,
              onWidgetAdded: onWidgetAdded,
              onWidgetRemoved: onWidgetRemoved,
              onWidgetSelected: onWidgetSelected,
              onWidgetChanged: onWidgetChanged,
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
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.owlFrame,
    required this.isRunning,
    required this.stageWidgets,
  });

  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final int owlFrame;
  final bool isRunning;
  final List<_AddedGameWidget> stageWidgets;

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
                child: Opacity(
                  opacity: owlOpacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: owlScale,
                    child: Transform.rotate(
                      angle: (owlRotation * math.pi / 180) + (isRunning ? -.05 : -.16),
                      child: _OwlSpriteFrame(frame: owlFrame, height: 66),
                    ),
                  ),
                ),
              ),
            ),
            for (int i = 0; i < stageWidgets.length; i++)
              if (stageWidgets[i].show)
                if (stageWidgets[i].type == _GameWidgetType.dialog)
                  Positioned(
                    top: 18, left: 18, right: 18, bottom: 60,
                    child: Opacity(
                      opacity: stageWidgets[i].opacity.clamp(0.0, 1.0),
                      child: _StageWidgetOverlay(gameWidget: stageWidgets[i]),
                    ),
                  )
                else
                  Positioned(
                    top: 12.0 + i * 52,
                    left: 12,
                    child: Opacity(
                      opacity: stageWidgets[i].opacity.clamp(0.0, 1.0),
                      child: _StageWidgetOverlay(gameWidget: stageWidgets[i]),
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


// ── Stage widget overlay (counter, text, timer, etc shown on stage) ───────────
class _StageWidgetOverlay extends StatelessWidget {
  const _StageWidgetOverlay({required this.gameWidget});
  final _AddedGameWidget gameWidget;

  @override
  Widget build(BuildContext context) {
    if (gameWidget.type == _GameWidgetType.dialog) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFB8CDD8),
          border: Border.all(color: const Color(0xFF91C75B), width: 3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                gameWidget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gameWidget.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  shadows: const [Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 2)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: SizedBox(
                width: 110, height: 64,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.5,
                      child: Image.asset(
                        _AddedGameWidget.buttonImages[0],
                        fit: BoxFit.fill,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF6B8E3A),
                          child: const Icon(Icons.check, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (gameWidget.type == _GameWidgetType.webcam) {
      return Container(
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF3C3C3C),
          border: Border.all(color: const Color(0xFF91C75B), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: Colors.white54, size: 44),
            SizedBox(height: 4),
            Text('webcam', style: TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      );
    }

    if (gameWidget.type == _GameWidgetType.button) {
      return Transform.rotate(
        angle: gameWidget.rotation * 3.14159265 / 180,
        child: Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF91C75B), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 0.5,
                child: Image.asset(
                  _AddedGameWidget.buttonImages[gameWidget.buttonImageIndex],
                  fit: BoxFit.fill,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF6B8E3A),
                    child: const Icon(Icons.touch_app, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final label = switch (gameWidget.type) {
      _GameWidgetType.counter => '0',
      _GameWidgetType.text    => gameWidget.text,
      _GameWidgetType.timer   => '0.0',
      _GameWidgetType.clock   => '00:00',
      _GameWidgetType.button  => '',
      _GameWidgetType.dialog  => '...',
      _GameWidgetType.webcam  => '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .55),
        border: Border.all(color: const Color(0xFF91C75B), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: gameWidget.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Sprite settings data ─────────────────────────────────────────────────────
class _SpriteSettings {
  _SpriteSettings({required this.sprite, required this.isOliver, String? name})
      : name = name ?? sprite.displayName;

  final _SpriteAssetData sprite;
  final bool isOliver;
  String name;
  int x = 50;
  int y = 365;
  double scale = 1.0;
  double rotation = 0.0;
  double opacity = 1.0;
  bool allowGravity = true;
  bool collideWorldBounds = true;
  bool immovable = false;
  bool show = true;
  bool collideOtherSprites = true;
  bool draggable = false;
}

// ── Sprite inspector panel ────────────────────────────────────────────────────
class _SpriteInspector extends StatefulWidget {
  const _SpriteInspector({
    required this.projectSprites,
    required this.stageWidgets,
    required this.onAddSpritePressed,
    required this.owlX,
    required this.owlY,
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.onOliverSettingsChanged,
    required this.onSpriteDeleted,
    required this.onSpriteDuplicated,
    required this.onWidgetAdded,
    required this.onWidgetRemoved,
    required this.onWidgetSelected,
    required this.onWidgetChanged,
  });

  final List<_SpriteAssetData> projectSprites;
  final List<_AddedGameWidget> stageWidgets;
  final VoidCallback onAddSpritePressed;
  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final ValueChanged<_SpriteSettings> onOliverSettingsChanged;
  final ValueChanged<_SpriteAssetData> onSpriteDeleted;
  final ValueChanged<_SpriteAssetData> onSpriteDuplicated;
  final ValueChanged<_AddedGameWidget> onWidgetAdded;
  final ValueChanged<_AddedGameWidget> onWidgetRemoved;
  final ValueChanged<_AddedGameWidget> onWidgetSelected;
  final VoidCallback onWidgetChanged;

  @override
  State<_SpriteInspector> createState() => _SpriteInspectorState();
}

class _SpriteInspectorState extends State<_SpriteInspector> {
  _SpriteSettings? _active;
  bool _showPreview = false;
  int _activeTab = 0;
  _AddedGameWidget? _activeWidget;

  static const _oliverSprite = _SpriteAssetData(
    displayName: 'Oliver',
    assetPath: 'assets/images/owl.png',
    categories: [],
    frameCount: 5,
  );

  void _openSettings(_SpriteSettings s) =>
      setState(() { _active = s; _showPreview = false; });

  void _closeSettings() =>
      setState(() { _active = null; _showPreview = false; });

  void _notifyIfOliver(_SpriteSettings s) {
    if (s.isOliver) widget.onOliverSettingsChanged(s);
  }

  _SpriteSettings _makeOliverSettings() {
    final s = _SpriteSettings(sprite: _oliverSprite, isOliver: true, name: 'Oliver');
    s.x = widget.owlX.round();
    s.y = widget.owlY.round();
    s.scale = widget.owlScale;
    s.rotation = widget.owlRotation;
    s.opacity = widget.owlOpacity;
    return s;
  }

  void _switchTab(int index) => setState(() { _activeTab = index; _active = null; _activeWidget = null; _showPreview = false; });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              _InspectorTab(label: 'Sprites', selected: _activeTab == 0, onTap: () => _switchTab(0)),
              _InspectorTab(label: 'Widgets', selected: _activeTab == 1, onTap: () => _switchTab(1)),
              _InspectorTab(label: 'Sounds',  selected: _activeTab == 2, onTap: () => _switchTab(2)),
              _InspectorTab(label: 'Game',    selected: _activeTab == 3, onTap: () => _switchTab(3)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: switch (_activeTab) {
              1 => _activeWidget != null ? _buildWidgetSettingsPanel(_activeWidget!) : _buildWidgetsTab(),
              _ => _active != null ? _buildSettingsPanel(_active!) : _buildGrid(),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 22, 22, 22),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _AddNewSpriteCard(onTap: widget.onAddSpritePressed),
              _OliverSpriteCard(
                onSettingsTap: () => _openSettings(_makeOliverSettings()),
              ),
              for (final sprite in widget.projectSprites)
                _ProjectSpriteCard(
                  sprite: sprite,
                  onSettingsTap: () => _openSettings(
                    _SpriteSettings(sprite: sprite, isOliver: false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetsTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 22, 22, 22),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _AddNewSpriteCard(onTap: _showAddWidgetDialog),
              for (final w in widget.stageWidgets)
                _WidgetCard(
                  gameWidget: w,
                  onTap: () => widget.onWidgetSelected(w),
                  onSettingsTap: () => setState(() => _activeWidget = w),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddWidgetDialog() async {
    final picked = await showDialog<_GameWidgetType>(
      context: context,
      barrierColor: Colors.black.withOpacity(.45),
      builder: (_) => const _AddWidgetDialog(),
    );
    if (picked != null && mounted) {
      widget.onWidgetAdded(_AddedGameWidget(picked));
    }
  }

  Widget _buildWidgetSettingsPanel(_AddedGameWidget w) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _activeWidget = null),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(color: Color(0xFFF5A623), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Text('Back to Widgets',
                    style: TextStyle(fontSize: 16, color: Color(0xFF3D3D3D), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Center(child: Image.asset(w.assetPath, width: 52, height: 52, fit: BoxFit.contain)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: .5)),
                    const SizedBox(height: 4),
                    _SettingsTextField(value: w.name, onChanged: (v) => setState(() => w.name = v)),
                    if (w.type == _GameWidgetType.text) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Text', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SettingsTextField(
                              value: w.text,
                              onChanged: (v) { setState(() => w.text = v); widget.onWidgetChanged(); },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: w.show,
                activeColor: const Color(0xFF3DB476),
                onChanged: (v) { setState(() => w.show = v ?? true); widget.onWidgetChanged(); },
              ),
              const Text('Show', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          if (w.type == _GameWidgetType.button) ...[
            const SizedBox(height: 14),
            const Text('IMAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: .5)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < _AddedGameWidget.buttonImages.length; i++) ...[
                  GestureDetector(
                    onTap: () { setState(() => w.buttonImageIndex = i); widget.onWidgetChanged(); },
                    child: Container(
                      width: 64, height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: w.buttonImageIndex == i ? const Color(0xFF3DB476) : const Color(0xFFDDDDDD),
                          width: w.buttonImageIndex == i ? 3 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.5,
                            child: Image.asset(
                              _AddedGameWidget.buttonImages[i],
                              fit: BoxFit.fill,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF6B8E3A),
                                child: const Icon(Icons.image, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (i < _AddedGameWidget.buttonImages.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const Text('ROTATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: .5)),
            const SizedBox(height: 6),
            SizedBox(
              width: 110,
              child: _SettingsStepper(
                label: '', value: w.rotation, step: 1, decimals: 0,
                onChanged: (v) { setState(() => w.rotation = v); widget.onWidgetChanged(); },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Opacity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: _SettingsStepper(
                  label: '', value: w.opacity, step: 0.1, decimals: 1,
                  onChanged: (v) { setState(() => w.opacity = v.clamp(0, 1)); widget.onWidgetChanged(); },
                ),
              ),
              if (w.type != _GameWidgetType.button && w.type != _GameWidgetType.webcam) ...[
                const SizedBox(width: 20),
                const Text('Text Color:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDialog<Color>(
                      context: context,
                      builder: (_) => _ColorPickerDialog(initial: w.textColor),
                    );
                    if (picked != null && mounted) { setState(() => w.textColor = picked); widget.onWidgetChanged(); }
                  },
                  child: Container(
                    width: 36, height: 24,
                    decoration: BoxDecoration(
                      color: w.textColor,
                      border: Border.all(color: const Color(0xFFAAAAAA)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onWidgetRemoved(w);
                    setState(() => _activeWidget = null);
                  },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A5A5A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final copy = _AddedGameWidget(w.type);
                    copy.name = '${w.name} copy';
                    copy.show = w.show;
                    copy.opacity = w.opacity;
                    copy.textColor = w.textColor;
                    copy.text = w.text;
                    copy.buttonImageIndex = w.buttonImageIndex;
                    copy.rotation = w.rotation;
                    widget.onWidgetAdded(copy);
                    setState(() => _activeWidget = null);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('DUPLICATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DB476),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel(_SpriteSettings s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to Sprites
          GestureDetector(
            onTap: _closeSettings,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5A623),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Back to Sprites',
                  style: TextStyle(fontSize: 16, color: Color(0xFF3D3D3D), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Sprite thumbnail + Name / X / Y
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail + Change
              Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                    ),
                    child: Center(
                      child: s.isOliver
                          ? const _OwlSpriteFrame(frame: 0, height: 52)
                          : _SpriteSheetFrame(sprite: s.sprite, height: 52),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Change',
                    style: TextStyle(color: Color(0xFF4A90D9), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Name + X + Y
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: .5)),
                    const SizedBox(height: 4),
                    _SettingsTextField(value: s.name, onChanged: (v) { setState(() => s.name = v); _notifyIfOliver(s); }),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _SettingsStepper(label: 'X', value: s.x.toDouble(), step: 1, decimals: 0, onChanged: (v) { setState(() => s.x = v.round()); _notifyIfOliver(s); })),
                        const SizedBox(width: 8),
                        Expanded(child: _SettingsStepper(label: 'Y', value: s.y.toDouble(), step: 1, decimals: 0, onChanged: (v) { setState(() => s.y = v.round()); _notifyIfOliver(s); })),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // SCALE / ROTATION / OPACITY
          Row(
            children: [
              Expanded(child: _SettingsStepper(label: 'SCALE',    value: s.scale,    step: 0.1, decimals: 1, onChanged: (v) { setState(() => s.scale = v); _notifyIfOliver(s); })),
              const SizedBox(width: 8),
              Expanded(child: _SettingsStepper(label: 'ROTATION', value: s.rotation, step: 1,   decimals: 0, onChanged: (v) { setState(() => s.rotation = v); _notifyIfOliver(s); })),
              const SizedBox(width: 8),
              Expanded(child: _SettingsStepper(label: 'OPACITY',  value: s.opacity,  step: 0.1, decimals: 1, onChanged: (v) { setState(() => s.opacity = v.clamp(0, 1)); _notifyIfOliver(s); })),
            ],
          ),
          const SizedBox(height: 14),
          // Checkboxes
          _CheckboxRow(label1: 'Allow Gravity',        val1: s.allowGravity,       onChanged1: (v) => setState(() => s.allowGravity = v),
                       label2: 'Collide world bounds', val2: s.collideWorldBounds, onChanged2: (v) => setState(() => s.collideWorldBounds = v)),
          const SizedBox(height: 4),
          _CheckboxRow(label1: 'Immovable', val1: s.immovable, onChanged1: (v) => setState(() => s.immovable = v),
                       label2: 'Show',     val2: s.show,      onChanged2: (v) => setState(() => s.show = v)),
          const SizedBox(height: 4),
          _CheckboxRow(label1: 'Collide other sprites', val1: s.collideOtherSprites, onChanged1: (v) => setState(() => s.collideOtherSprites = v),
                       label2: 'Draggable',             val2: s.draggable,          onChanged2: (v) => setState(() => s.draggable = v)),
          const SizedBox(height: 14),
          // Show / Hide preview
          GestureDetector(
            onTap: () => setState(() => _showPreview = !_showPreview),
            child: Text(
              _showPreview ? 'Hide preview' : 'Show preview',
              style: const TextStyle(color: Color(0xFF4A90D9), fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          if (_showPreview) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: s.sprite.frameCount.clamp(1, 10),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: s.isOliver
                      ? _OwlSpriteFrame(frame: i % _OwlSpriteFrame._frameCount, height: 72)
                      : _SpriteSheetFrame(
                          sprite: _SpriteAssetData(
                            displayName: s.sprite.displayName,
                            assetPath: s.sprite.assetPath,
                            categories: s.sprite.categories,
                            frameCount: s.sprite.frameCount,
                            previewFrame: i,
                            imageBytes: s.sprite.imageBytes,
                          ),
                          height: 72,
                        ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // DELETE + DUPLICATE
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: s.isOliver
                      ? null
                      : () {
                          widget.onSpriteDeleted(s.sprite);
                          _closeSettings();
                        },
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A5A5A),
                    disabledBackgroundColor: const Color(0xFFAAAAAA),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onSpriteDuplicated(s.sprite);
                    _closeSettings();
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('DUPLICATE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DB476),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widget card shown in the Widgets tab grid ─────────────────────────────────
class _WidgetCard extends StatelessWidget {
  const _WidgetCard({required this.gameWidget, required this.onTap, required this.onSettingsTap});
  final _AddedGameWidget gameWidget;
  final VoidCallback onTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: 135,
      height: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE1E1E1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 9,
            right: 9,
            child: GestureDetector(
              onTap: onSettingsTap,
              child: const Icon(Icons.settings, color: Color(0xFF84B75C), size: 20),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(gameWidget.assetPath, width: 64, height: 64, fit: BoxFit.contain),
                const SizedBox(height: 10),
                Text(
                  gameWidget.label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3D3D3D)),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ── Color picker dialog ───────────────────────────────────────────────────────
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final Color initial;
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _hue;
  late double _sat;
  late double _val;
  late TextEditingController _rCtrl, _gCtrl, _bCtrl;

  Color get _current => HSVColor.fromAHSV(1, _hue, _sat, _val).toColor();

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _hue = hsv.hue;
    _sat = hsv.saturation;
    _val = hsv.value;
    _syncControllers();
  }

  void _syncControllers() {
    final c = _current;
    _rCtrl = TextEditingController(text: c.red.toString());
    _gCtrl = TextEditingController(text: c.green.toString());
    _bCtrl = TextEditingController(text: c.blue.toString());
  }

  void _updateFromRgb() {
    final r = int.tryParse(_rCtrl.text)?.clamp(0, 255) ?? 0;
    final g = int.tryParse(_gCtrl.text)?.clamp(0, 255) ?? 0;
    final b = int.tryParse(_bCtrl.text)?.clamp(0, 255) ?? 0;
    final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
    setState(() { _hue = hsv.hue; _sat = hsv.saturation; _val = hsv.value; });
  }

  void _refreshRgbFields() {
    final c = _current;
    _rCtrl.text = c.red.toString();
    _gCtrl.text = c.green.toString();
    _bCtrl.text = c.blue.toString();
  }

  @override
  void dispose() {
    _rCtrl.dispose(); _gCtrl.dispose(); _bCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double squareSize = 220;
    const double sliderH = 18;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── SV square ──────────────────────────────────────────────────
            GestureDetector(
              onPanUpdate: (d) {
                final box = context.findRenderObject() as RenderBox?;
                if (box == null) return;
                // find the square's local position — use local offset from the gesture
                final local = d.localPosition;
                setState(() {
                  _sat = (local.dx / squareSize).clamp(0.0, 1.0);
                  _val = 1.0 - (local.dy / squareSize).clamp(0.0, 1.0);
                });
                _refreshRgbFields();
              },
              onTapDown: (d) {
                final local = d.localPosition;
                setState(() {
                  _sat = (local.dx / squareSize).clamp(0.0, 1.0);
                  _val = 1.0 - (local.dy / squareSize).clamp(0.0, 1.0);
                });
                _refreshRgbFields();
              },
              child: SizedBox(
                width: squareSize, height: squareSize,
                child: CustomPaint(
                  painter: _SvPickerPainter(hue: _hue, sat: _sat, val: _val),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Hue slider ─────────────────────────────────────────────────
            GestureDetector(
              onPanUpdate: (d) {
                final local = d.localPosition;
                setState(() => _hue = (local.dx / squareSize * 360).clamp(0.0, 360.0));
                _refreshRgbFields();
              },
              onTapDown: (d) {
                final local = d.localPosition;
                setState(() => _hue = (local.dx / squareSize * 360).clamp(0.0, 360.0));
                _refreshRgbFields();
              },
              child: SizedBox(
                width: squareSize, height: sliderH,
                child: CustomPaint(painter: _HueSliderPainter(hue: _hue)),
              ),
            ),
            const SizedBox(height: 14),
            // ── Preview + RGB fields ────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.colorize, color: const Color(0xFF888888), size: 22),
                const SizedBox(width: 10),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _current,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFAAAAAA), width: 1.5),
                  ),
                ),
                const SizedBox(width: 14),
                _RgbField(label: 'R', ctrl: _rCtrl, onSubmit: _updateFromRgb),
                const SizedBox(width: 8),
                _RgbField(label: 'G', ctrl: _gCtrl, onSubmit: _updateFromRgb),
                const SizedBox(width: 8),
                _RgbField(label: 'B', ctrl: _bCtrl, onSubmit: _updateFromRgb),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3DB476),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(_current),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SvPickerPainter extends CustomPainter {
  const _SvPickerPainter({required this.hue, required this.sat, required this.val});
  final double hue, sat, val;

  @override
  void paint(Canvas canvas, Size size) {
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    // White → hue gradient (left-right)
    final satGrad = LinearGradient(colors: [Colors.white, hueColor]);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = satGrad.createShader(Offset.zero & size),
    );
    // Transparent → black gradient (top-bottom)
    final valGrad = const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = valGrad.createShader(Offset.zero & size),
    );
    // Thumb
    final cx = sat * size.width;
    final cy = (1 - val) * size.height;
    canvas.drawCircle(Offset(cx, cy), 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = HSVColor.fromAHSV(1, hue, sat, val).toColor());
  }

  @override
  bool shouldRepaint(_SvPickerPainter old) => old.hue != hue || old.sat != sat || old.val != val;
}

class _HueSliderPainter extends CustomPainter {
  const _HueSliderPainter({required this.hue});
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final grad = LinearGradient(colors: [
      for (int i = 0; i <= 6; i++) HSVColor.fromAHSV(1, i * 60.0, 1, 1).toColor(),
    ]);
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4));
    canvas.drawRRect(rr, Paint()..shader = grad.createShader(Offset.zero & size));
    final tx = hue / 360 * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(tx, size.height / 2), width: 4, height: size.height + 4), const Radius.circular(2)),
      Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HueSliderPainter old) => old.hue != hue;
}

class _RgbField extends StatelessWidget {
  const _RgbField({required this.label, required this.ctrl, required this.onSubmit});
  final String label;
  final TextEditingController ctrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
        const SizedBox(height: 2),
        SizedBox(
          width: 42,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            ),
            onSubmitted: (_) => onSubmit(),
            onEditingComplete: onSubmit,
          ),
        ),
      ],
    );
  }
}

// ── Add Widget dialog ─────────────────────────────────────────────────────────
class _AddWidgetDialog extends StatefulWidget {
  const _AddWidgetDialog();
  @override
  State<_AddWidgetDialog> createState() => _AddWidgetDialogState();
}

class _AddWidgetDialogState extends State<_AddWidgetDialog> {
  _GameWidgetType? _selected = _GameWidgetType.counter;

  static const _types = [
    (type: _GameWidgetType.counter, label: 'Counter'),
    (type: _GameWidgetType.text,    label: 'Text'),
    (type: _GameWidgetType.timer,   label: 'Timer'),
    (type: _GameWidgetType.clock,   label: 'Clock'),
    (type: _GameWidgetType.button,  label: 'Button'),
    (type: _GameWidgetType.dialog,  label: 'Dialog'),
    (type: _GameWidgetType.webcam,  label: 'Webcam'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Add A Widget',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(color: Color(0xFF4A3728), shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final t in _types)
                    GestureDetector(
                      onTap: () => setState(() => _selected = t.type),
                      child: _WidgetTypeCard(
                        label: t.label,
                        assetPath: 'assets/images/sprites/${t.type.name}.png',
                        selected: _selected == t.type,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Footer buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              color: const Color(0xFFF2F2F2),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selected == null ? null : () => Navigator.of(context).pop(_selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3DB476),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('ADD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetTypeCard extends StatelessWidget {
  const _WidgetTypeCard({required this.label, required this.assetPath, required this.selected});
  final String label;
  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF3DB476) : const Color(0xFFDDDDDD),
          width: selected ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(assetPath, width: 56, height: 56, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3D3D3D))),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Color(0xFF3DB476), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
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
  const _OliverSpriteCard({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

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
          Positioned(
            top: 9,
            right: 9,
            child: GestureDetector(
              onTap: onSettingsTap,
              child: const Icon(Icons.settings, color: Color(0xFF84B75C), size: 22),
            ),
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
  const _ProjectSpriteCard({required this.sprite, required this.onSettingsTap});

  final _SpriteAssetData sprite;
  final VoidCallback onSettingsTap;

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
          Positioned(
            top: 9,
            right: 9,
            child: GestureDetector(
              onTap: onSettingsTap,
              child: const Icon(Icons.settings, color: Color(0xFF84B75C), size: 20),
            ),
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

enum _AddSpriteDialogMode { library, uploadSheet, createSheet, paintEditor }
enum _DrawTool { pencil, eraser, line, rect, oval }
enum _GameWidgetType { counter, text, timer, clock, button, dialog, webcam }

class _AddedGameWidget {
  static int _counter = 0;
  _AddedGameWidget(this.type) : id = 'w${++_counter}', name = type.name;
  final String id;
  final _GameWidgetType type;
  String name;
  bool show = true;
  double opacity = 1.0;
  Color textColor = Colors.white;
  String text = 'Your text here';
  // button-specific
  int buttonImageIndex = 0;
  double rotation = 0.0;
  static const List<String> buttonImages = [
    'assets/images/sprites/default.png',
    'assets/images/sprites/arrow.png',
  ];
  String get label => type.name[0].toUpperCase() + type.name.substring(1);
  String get assetPath => 'assets/images/sprites/${type.name}.png';
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
  final ScrollController _uploadScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  _AddSpriteDialogMode _mode = _AddSpriteDialogMode.library;
  String _selectedCategory = 'ALL CATEGORIES';
  String _searchText = '';
  _SpriteAssetData? _selectedSprite = _spriteLibrary.first;
  int _uploadFrameCount = 1;
  Uint8List? _pickedFileBytes;
  String _pickedFileName = '';
  int _createSheetWidth = 200;
  int _createSheetHeight = 200;

  // Paint editor state
  _DrawTool _activeTool = _DrawTool.pencil;
  double _brushSize = 4.0;
  Color _strokeColor = Colors.black;
  Color _fillColor = Colors.white;
  final List<_DrawStroke> _strokes = [];
  _DrawStroke? _currentStroke;
  final List<List<_DrawStroke>> _undoHistory = [];
  final List<List<_DrawStroke>> _redoHistory = [];
  final List<_SpriteAssetData> _customSprites = [];
  final GlobalKey _canvasRepaintKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    _uploadScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _pickedFileBytes = result.files.single.bytes;
        _pickedFileName = result.files.single.name;
      });
    }
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

  List<_SpriteAssetData> get _filteredCustomSprites {
    if (_selectedCategory != 'ALL CATEGORIES' && _selectedCategory != 'MY SPRITES') {
      return [];
    }
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return _customSprites;
    return _customSprites.where((s) => s.displayName.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1020,
          maxHeight: 680,
          minHeight: 460,
        ),
        child: Padding(
          padding: _mode == _AddSpriteDialogMode.paintEditor
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: _mode == _AddSpriteDialogMode.library
              ? _buildSpriteLibrary(context)
              : _mode == _AddSpriteDialogMode.uploadSheet
                  ? _buildUploadSpriteSheet(context)
                  : _mode == _AddSpriteDialogMode.createSheet
                      ? _buildCreateSpriteSheet(context)
                      : _buildPaintEditor(context),
        ),
      ),
    );
  }

  Widget _buildDialogTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7BAE55),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: .3,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: const Color(0xFF9DCA76)),
      ],
    );
  }

  Widget _buildSpriteLibrary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDialogTitle('ADD A SPRITE'),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 340,
              height: 40,
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
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 28),
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
              padding: const EdgeInsets.fromLTRB(28, 12, 18, 14),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 148,
                mainAxisExtent: 128,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
              ),
              itemCount: _filteredCustomSprites.length + _filteredSprites.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SpriteDialogActionTile(
                    icon: Icons.upload,
                    label: 'UPLOAD SPRITE\nSHEET',
                    onTap: () => setState(() => _mode = _AddSpriteDialogMode.uploadSheet),
                  );
                }
                if (index == 1) {
                  return _SpriteDialogActionTile(
                    icon: Icons.add,
                    label: 'CREATE A NEW\nSHEET',
                    onTap: () => setState(() => _mode = _AddSpriteDialogMode.createSheet),
                  );
                }
                final customCount = _filteredCustomSprites.length;
                if (index - 2 < customCount) {
                  final sprite = _filteredCustomSprites[index - 2];
                  return _SpriteLibraryTile(
                    sprite: sprite,
                    selected: _selectedSprite == sprite,
                    onTap: () => setState(() => _selectedSprite = sprite),
                  );
                }
                final sprite = _filteredSprites[index - 2 - customCount];
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
        _buildLibraryFooter(context),
      ],
    );
  }

  Widget _buildLibraryFooter(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildUploadSpriteSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDialogTitle('UPLOAD A SPRITE SHEET'),
        const SizedBox(height: 44),
        Expanded(
          child: Scrollbar(
            controller: _uploadScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _uploadScrollController,
              padding: const EdgeInsets.fromLTRB(34, 0, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReturnToSpritesButton(
                    onTap: () => setState(() => _mode = _AddSpriteDialogMode.library),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SpriteUploadInstructionsCard(),
                      const SizedBox(width: 0),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SpriteUploadDropArea(onBrowse: _pickFile),
                                const SizedBox(width: 24),
                                _SpriteUploadPreview(imageBytes: _pickedFileBytes, fileName: _pickedFileName),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Number of frames',
                                  style: TextStyle(
                                    color: Color(0xFF353535),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _UploadFrameStepper(
                                  value: _uploadFrameCount,
                                  onChanged: (value) => setState(() => _uploadFrameCount = value),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildUploadFooter(context),
      ],
    );
  }

  Widget _buildUploadFooter(BuildContext context) {
    return Row(
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
            onPressed: _pickedFileBytes == null
                ? null
                : () => Navigator.pop(
                      context,
                      _SpriteAssetData(
                        displayName: _pickedFileName.isNotEmpty ? _pickedFileName : 'Custom Sprite',
                        assetPath: '',
                        categories: const ['MY SPRITES'],
                        frameCount: _uploadFrameCount,
                        imageBytes: _pickedFileBytes,
                      ),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4D861D),
              disabledBackgroundColor: const Color(0xFFA8C38D),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 7),
      ],
    );
  }

  Widget _buildCreateSpriteSheet(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDialogTitle('CREATE A SPRITE SHEET'),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReturnToSpritesButton(
                  onTap: () => setState(() => _mode = _AddSpriteDialogMode.library),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Define the sprite frame size',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _DimensionField(
                          key: const ValueKey('dim_width'),
                          label: 'WIDTH:',
                          value: _createSheetWidth,
                          onChanged: (v) => setState(() => _createSheetWidth = v),
                        ),
                        const SizedBox(height: 18),
                        _DimensionField(
                          key: const ValueKey('dim_height'),
                          label: 'HEIGHT:',
                          value: _createSheetHeight,
                          onChanged: (v) => setState(() => _createSheetHeight = v),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 280,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => setState(() {
                              _strokes.clear();
                              _undoHistory.clear();
                              _redoHistory.clear();
                              _currentStroke = null;
                              _mode = _AddSpriteDialogMode.paintEditor;
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4D861D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('OK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 48),
                    _SpriteSizePreview(
                      frameWidth: _createSheetWidth,
                      frameHeight: _createSheetHeight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Paint editor ──────────────────────────────────────────────────────────

  Size get _canvasDisplaySize {
    const maxW = 460.0;
    const maxH = 370.0;
    final scale = math.min(maxW / _createSheetWidth, maxH / _createSheetHeight);
    return Size(
      (_createSheetWidth * scale).clamp(80.0, maxW),
      (_createSheetHeight * scale).clamp(80.0, maxH),
    );
  }

  void _undo() {
    if (_undoHistory.isEmpty) return;
    setState(() {
      _redoHistory.add(List.from(_strokes));
      _strokes
        ..clear()
        ..addAll(_undoHistory.removeLast());
    });
  }

  void _redo() {
    if (_redoHistory.isEmpty) return;
    setState(() {
      _undoHistory.add(List.from(_strokes));
      _strokes
        ..clear()
        ..addAll(_redoHistory.removeLast());
    });
  }

  void _clearCanvas() {
    setState(() {
      _undoHistory.add(List.from(_strokes));
      _redoHistory.clear();
      _strokes.clear();
    });
  }

  Future<void> _saveSprite() async {
    Uint8List? pngBytes;

    // Null-safe canvas capture — JS TypeError from toImage() is not always
    // catchable, so guard every step before awaiting.
    final renderCtx = _canvasRepaintKey.currentContext;
    if (renderCtx != null) {
      final renderObj = renderCtx.findRenderObject();
      if (renderObj is RenderRepaintBoundary && renderObj.hasSize) {
        try {
          final image = await renderObj.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          pngBytes = byteData?.buffer.asUint8List();
        } catch (_) {
          // ignore — save sprite without preview bytes
        }
      }
    }

    if (!mounted) return;

    // Snapshot the count BEFORE the setState so the name is correct even
    // if setState triggers a re-entrant read.
    final spriteIndex = _customSprites.length + 1;
    final newSprite = _SpriteAssetData(
      displayName: 'My Sprite $spriteIndex',
      assetPath: '',
      categories: const ['MY SPRITES'],
      frameCount: 1,
      imageBytes: pngBytes,
    );

    setState(() {
      _customSprites.add(newSprite);
      _mode = _AddSpriteDialogMode.library;
      _selectedCategory = 'MY SPRITES';
    });
  }

  Future<void> _showColorPicker(BuildContext context, {required bool isStroke}) async {
    const palette = <Color>[
      Colors.black, Colors.white, Color(0xFF808080), Color(0xFFC0C0C0),
      Color(0xFFFF0000), Color(0xFFFF6600), Color(0xFFFFCC00), Color(0xFF00CC00),
      Color(0xFF0066FF), Color(0xFF9900CC), Color(0xFF00CCFF), Color(0xFFFF66CC),
      Color(0xFF660000), Color(0xFF003300), Color(0xFF000066), Color(0xFF663300),
      Color(0xFFFFCCCC), Color(0xFFCCFFCC), Color(0xFFCCCCFF), Color(0xFFFFFFCC),
    ];

    final picked = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isStroke ? 'Stroke Color' : 'Fill Color',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: palette.map((c) => GestureDetector(
            onTap: () => Navigator.pop(ctx, c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                border: Border.all(color: Colors.grey.shade400, width: 1.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStroke) { _strokeColor = picked; } else { _fillColor = picked; }
      });
    }
  }

  Widget _buildPaintEditor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              _ReturnToSpritesButton(
                onTap: () => setState(() => _mode = _AddSpriteDialogMode.createSheet),
              ),
              const SizedBox(width: 18),
              Text(
                'SPRITE EDITOR  $_createSheetWidth × $_createSheetHeight px',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3A8A2E),
                  letterSpacing: .4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 140,
                height: 44,
                child: ElevatedButton(
                  onPressed: _saveSprite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D861D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('OK', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPaintToolbar(context),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrushSizeRow(),
                    Expanded(child: _buildPaintCanvas()),
                    _buildFrameStrip(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaintToolbar(BuildContext context) {
    Widget toolBtn(_DrawTool tool, IconData icon, String tooltip) {
      final active = _activeTool == tool;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => setState(() => _activeTool = tool),
          child: Container(
            width: 44,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 1),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: active ? Border.all(color: const Color(0xFFBBBBBB)) : null,
            ),
            child: Icon(icon, size: 20, color: active ? const Color(0xFF2D5A1A) : const Color(0xFF555555)),
          ),
        ),
      );
    }

    Widget colorSwatch(String label, Color color, bool isStroke) {
      return GestureDetector(
        onTap: () => _showColorPicker(context, isStroke: isStroke),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF666666))),
            const SizedBox(height: 2),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade400, width: 1.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      );
    }

    return Container(
      width: 52,
      color: const Color(0xFFE8E8E8),
      child: Column(
        children: [
          const SizedBox(height: 6),
          toolBtn(_DrawTool.pencil, Icons.edit_rounded, 'Pencil'),
          toolBtn(_DrawTool.eraser, Icons.auto_fix_normal, 'Eraser'),
          toolBtn(_DrawTool.line, Icons.horizontal_rule, 'Line'),
          toolBtn(_DrawTool.rect, Icons.crop_square_rounded, 'Rectangle'),
          toolBtn(_DrawTool.oval, Icons.circle_outlined, 'Oval'),
          const Divider(height: 14, indent: 6, endIndent: 6),
          colorSwatch('stroke', _strokeColor, true),
          colorSwatch('fill', _fillColor, false),
          const Divider(height: 14, indent: 6, endIndent: 6),
          Tooltip(
            message: 'Undo',
            child: GestureDetector(
              onTap: _undo,
              child: Icon(Icons.undo, size: 22,
                  color: _undoHistory.isNotEmpty ? const Color(0xFF444444) : const Color(0xFFBBBBBB)),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: 'Redo',
            child: GestureDetector(
              onTap: _redo,
              child: Icon(Icons.redo, size: 22,
                  color: _redoHistory.isNotEmpty ? const Color(0xFF444444) : const Color(0xFFBBBBBB)),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _clearCanvas,
            child: const Text('Clear',
                style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushSizeRow() {
    const sizes = [1.0, 2.0, 4.0, 8.0, 14.0];
    return Container(
      height: 40,
      color: const Color(0xFFE0E0E0),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _strokeColor,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          for (final size in sizes)
            GestureDetector(
              onTap: () => setState(() => _brushSize = size),
              child: Container(
                width: 36,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _brushSize == size
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.transparent,
                ),
                child: Container(
                  width: size.clamp(2.0, 18.0),
                  height: size.clamp(2.0, 18.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaintCanvas() {
    final displaySize = _canvasDisplaySize;
    return Container(
      color: const Color(0xFFAAAAAA),
      child: Center(
        child: Container(
          width: displaySize.width,
          height: displaySize.height,
          color: Colors.white,
          child: GestureDetector(
            onPanStart: (d) {
              _undoHistory.add(List.from(_strokes));
              _redoHistory.clear();
              final stroke = _DrawStroke(
                tool: _activeTool,
                color: _activeTool == _DrawTool.eraser ? Colors.white : _strokeColor,
                strokeWidth: _activeTool == _DrawTool.eraser ? _brushSize * 4 : _brushSize,
                fillColor: (_activeTool == _DrawTool.rect || _activeTool == _DrawTool.oval)
                    ? _fillColor
                    : null,
              );
              stroke.points.add(d.localPosition);
              setState(() => _currentStroke = stroke);
            },
            onPanUpdate: (d) {
              if (_currentStroke == null) return;
              setState(() => _currentStroke!.points.add(d.localPosition));
            },
            onPanEnd: (_) {
              if (_currentStroke != null) {
                setState(() {
                  _strokes.add(_currentStroke!);
                  _currentStroke = null;
                });
              }
            },
            child: RepaintBoundary(
              key: _canvasRepaintKey,
              child: CustomPaint(
                painter: _SpriteCanvasPainter(
                  strokes: _strokes,
                  currentStroke: _currentStroke,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrameStrip() {
    final displaySize = _canvasDisplaySize;
    final thumbW = (displaySize.width * 0.18).clamp(56.0, 80.0);
    final thumbH = (displaySize.height * 0.18).clamp(48.0, 68.0);
    return Container(
      height: 86,
      color: const Color(0xFFD0D0D0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Frame 1 thumbnail
          Container(
            width: thumbW,
            height: thumbH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF55BB80), width: 2),
            ),
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: displaySize.width,
                  height: displaySize.height,
                  child: CustomPaint(
                    painter: _SpriteCanvasPainter(strokes: _strokes),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add frame button
          Container(
            width: thumbH,
            height: thumbH,
            decoration: BoxDecoration(
              color: const Color(0xFF44BB77),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
}

class _ReturnToSpritesButton extends StatelessWidget {
  const _ReturnToSpritesButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 88,
        height: 91,
        decoration: BoxDecoration(
          color: const Color(0xFF51C68C),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.16), offset: const Offset(0, 3)),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_back, color: Colors.white, size: 38),
            SizedBox(height: 9),
            Text(
              'RETURN TO\nSPRITES',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dimension stepper field ─────────────────────────────────────────────────
class _DimensionField extends StatefulWidget {
  const _DimensionField({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_DimensionField> createState() => _DimensionFieldState();
}

class _DimensionFieldState extends State<_DimensionField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DimensionField old) {
    super.didUpdateWidget(old);
    // Only sync when the arrow buttons change the value (not while the user is typing)
    if (!_focusNode.hasFocus && old.value != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) _commit(_controller.text);
    setState(() {});
  }

  void _onTextChanged(String text) {
    final parsed = int.tryParse(text.trim());
    // Update preview live — don't clamp to minimum while typing so "300"
    // doesn't snap to 10 when the user has only typed "3" so far.
    if (parsed != null && parsed > 0) {
      widget.onChanged(math.min(parsed, 9999));
    }
  }

  void _commit(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed != null) {
      final clamped = parsed.clamp(10, 9999);
      widget.onChanged(clamped);
      _controller.text = '$clamped';
    } else {
      _controller.text = '${widget.value}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9B8A6E),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          width: 130,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _focusNode.hasFocus ? const Color(0xFF7BAE55) : const Color(0xFFC9C9C9),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF2D2D2D), fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6),
                    isDense: true,
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: _commit,
                ),
              ),
              Container(width: 1, color: const Color(0xFFE0E0E0)),
              SizedBox(
                width: 26,
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => widget.onChanged(math.min(9999, widget.value + 10)),
                        child: const Icon(Icons.keyboard_arrow_up, size: 20, color: Color(0xFF7BAE55)),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => widget.onChanged(math.max(10, widget.value - 10)),
                        child: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF7BAE55)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Live sprite-size preview with dimension annotations ──────────────────────
class _SpriteSizePreview extends StatelessWidget {
  const _SpriteSizePreview({required this.frameWidth, required this.frameHeight});

  final int frameWidth;
  final int frameHeight;

  @override
  Widget build(BuildContext context) {
    const maxDisplay = 260.0;
    const minDisplay = 60.0;
    final scale = math.min(maxDisplay / frameWidth, maxDisplay / frameHeight);
    final displayW = (frameWidth * scale).clamp(minDisplay, maxDisplay);
    final displayH = (frameHeight * scale).clamp(minDisplay, maxDisplay);

    const leftPad = 44.0;
    const bottomPad = 36.0;

    return SizedBox(
      width: displayW + leftPad + 12,
      height: displayH + bottomPad + 12,
      child: Stack(
        children: [
          // White card
          Positioned(
            left: leftPad,
            top: 0,
            child: Container(
              width: displayW,
              height: displayH,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.14), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: _SpriteSheetFrame(
                  sprite: const _SpriteAssetData(
                    displayName: 'Monkey',
                    assetPath: 'assets/images/sprites/baseballMonkey.png',
                    categories: ['ANIMALS'],
                    frameCount: 4,
                    previewFrame: 0,
                  ),
                  height: math.min(displayH * 0.62, 52),
                ),
              ),
            ),
          ),
          // Height annotation (left side)
          Positioned(
            left: 0,
            top: 0,
            child: CustomPaint(
              size: Size(leftPad, displayH),
              painter: _DimensionLinePainter(value: frameHeight, isVertical: true),
            ),
          ),
          // Width annotation (bottom)
          Positioned(
            left: leftPad,
            top: displayH + 2,
            child: CustomPaint(
              size: Size(displayW, bottomPad),
              painter: _DimensionLinePainter(value: frameWidth, isVertical: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionLinePainter extends CustomPainter {
  const _DimensionLinePainter({required this.value, required this.isVertical});

  final int value;
  final bool isVertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A8FD4)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const bracketLen = 6.0;
    final label = '$value';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Color(0xFF4A8FD4), fontSize: 11, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (isVertical) {
      final x = size.width - 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(x - bracketLen, 0), Offset(x + bracketLen, 0), paint);
      canvas.drawLine(Offset(x - bracketLen, size.height), Offset(x + bracketLen, size.height), paint);
      tp.paint(canvas, Offset(x - tp.width - 5, size.height / 2 - tp.height / 2));
    } else {
      final y = 10.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      canvas.drawLine(Offset(0, y - bracketLen), Offset(0, y + bracketLen), paint);
      canvas.drawLine(Offset(size.width, y - bracketLen), Offset(size.width, y + bracketLen), paint);
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, y + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _DimensionLinePainter old) =>
      old.value != value || old.isVertical != isVertical;
}

// ── Upload instructions card ─────────────────────────────────────────────────
class _SpriteUploadInstructionsCard extends StatelessWidget {
  const _SpriteUploadInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 310,
      height: 370,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFF465BFF),
          radius: 7,
          dash: 2.5,
          gap: 2.5,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 28, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Important Instructions:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2A211F),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Place all states of your sprite in one\n'
                'horizontal row. Your sprite frames\n'
                'should be divided into equal widths.\n'
                'Background should be transparent\n'
                '(using alpha channel).',
                style: TextStyle(
                  color: Color(0xFF3A2A2A),
                  fontSize: 13,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(5, (index) {
                  final frame = index.clamp(0, 3);
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: SizedBox(
                      width: 44,
                      height: 50,
                      child: _SpriteSheetFrame(
                        sprite: _SpriteAssetData(
                          displayName: 'Monkey',
                          assetPath: 'assets/images/sprites/baseballMonkey.png',
                          categories: const ['ANIMALS'],
                          frameCount: 4,
                          previewFrame: frame,
                        ),
                        height: 50,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: Color(0xFF3A2A2A),
                    fontSize: 13,
                    height: 1.38,
                  ),
                  children: [
                    TextSpan(text: 'Your file must be saved as '),
                    TextSpan(text: 'PNG', style: TextStyle(fontWeight: FontWeight.w900)),
                    TextSpan(text: ',\nand cannot exceed '),
                    TextSpan(text: '3MB', style: TextStyle(fontWeight: FontWeight.w900)),
                    TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpriteUploadDropArea extends StatelessWidget {
  const _SpriteUploadDropArea({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 320,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFE2E2E2),
          radius: 3,
          dash: 6,
          gap: 4,
          strokeWidth: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 100,
              child: Image.asset(
                CodeMonkeyScratchAssets.uploadMonkey,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, size: 64, color: Color(0xFF9EDFED)),
                      SizedBox(height: 6),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onBrowse,
              style: OutlinedButton.styleFrom(
                fixedSize: const Size(180, 48),
                side: const BorderSide(color: Color(0xFFFFB533), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                foregroundColor: const Color(0xFF2D1710),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'BROWSE FILES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteUploadPreview extends StatelessWidget {
  const _SpriteUploadPreview({this.imageBytes, this.fileName = ''});

  final Uint8List? imageBytes;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: 200,
        child: Column(
          children: [
            Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.28), offset: const Offset(0, 6)),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => const Center(
                        child: Icon(Icons.broken_image_outlined, size: 72, color: Colors.grey),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 18),
            const Text(
              'Sprite Preview',
              style: TextStyle(
                color: Color(0xFF2C1A17),
                fontSize: 20,
                height: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              imageBytes != null ? fileName : 'No File Uploaded',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2C1A17),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadFrameStepper extends StatelessWidget {
  const _UploadFrameStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFC9C9C9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                '$value',
                style: const TextStyle(fontSize: 15, color: Color(0xFF2D2D2D)),
              ),
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(math.min(99, value + 1)),
                    child: const Icon(Icons.keyboard_arrow_up, size: 17, color: Color(0xFF7BAE55)),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => onChanged(math.max(1, value - 1)),
                    child: const Icon(Icons.keyboard_arrow_down, size: 17, color: Color(0xFF7BAE55)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1,
    this.dash = 4,
    this.gap = 4,
    this.radius = 0,
  });

  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).outerRect.deflate(strokeWidth / 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    _drawDashedLine(canvas, Offset(rect.left + radius, rect.top), Offset(rect.right - radius, rect.top), paint);
    _drawDashedLine(canvas, Offset(rect.right, rect.top + radius), Offset(rect.right, rect.bottom - radius), paint);
    _drawDashedLine(canvas, Offset(rect.right - radius, rect.bottom), Offset(rect.left + radius, rect.bottom), paint);
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom - radius), Offset(rect.left, rect.top + radius), paint);

    if (radius > 0) {
      canvas.drawArc(Rect.fromCircle(center: Offset(rect.left + radius, rect.top + radius), radius: radius), math.pi, math.pi / 2, false, paint);
      canvas.drawArc(Rect.fromCircle(center: Offset(rect.right - radius, rect.top + radius), radius: radius), -math.pi / 2, math.pi / 2, false, paint);
      canvas.drawArc(Rect.fromCircle(center: Offset(rect.right - radius, rect.bottom - radius), radius: radius), 0, math.pi / 2, false, paint);
      canvas.drawArc(Rect.fromCircle(center: Offset(rect.left + radius, rect.bottom - radius), radius: radius), math.pi / 2, math.pi / 2, false, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final total = (end - start).distance;
    if (total <= 0) return;
    final direction = (end - start) / total;
    double drawn = 0;
    while (drawn < total) {
      final next = math.min(drawn + dash, total);
      canvas.drawLine(start + direction * drawn, start + direction * next, paint);
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dash != dash ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SpriteDialogActionTile extends StatelessWidget {
  const _SpriteDialogActionTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Icon(icon, size: 42, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w900,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
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
                width: 78,
                height: 78,
                child: Center(child: _SpriteSheetFrame(sprite: sprite, height: 60)),
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
    final image = sprite.imageBytes != null
        ? Image.memory(
            sprite.imageBytes!,
            height: height,
            fit: BoxFit.fitHeight,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.image_not_supported_outlined, size: height * .55, color: Colors.grey.shade500);
            },
          )
        : Image.asset(
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
    this.imageBytes,
  });

  final String displayName;
  final String assetPath;
  final List<String> categories;
  final int frameCount;
  final int previewFrame;
  final Uint8List? imageBytes;
}

// ── Settings panel helper widgets ─────────────────────────────────────────────

class _SettingsTextField extends StatefulWidget {
  const _SettingsTextField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<_SettingsTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SettingsTextField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFC9C9C9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF7BAE55), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SettingsStepper extends StatelessWidget {
  const _SettingsStepper({
    required this.label,
    required this.value,
    required this.step,
    required this.decimals,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double step;
  final int decimals;
  final ValueChanged<double> onChanged;

  String _fmt(double v) => decimals == 0 ? v.round().toString() : v.toStringAsFixed(decimals).replaceAll(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF888888), letterSpacing: .5)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFC9C9C9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(_fmt(value), style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D))),
                ),
              ),
              Container(width: 1, color: const Color(0xFFE0E0E0), height: 24),
              SizedBox(
                width: 22,
                child: Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(value + step),
                        child: const Icon(Icons.keyboard_arrow_up, size: 17, color: Color(0xFF7BAE55)),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => onChanged(value - step),
                        child: const Icon(Icons.keyboard_arrow_down, size: 17, color: Color(0xFF7BAE55)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  const _CheckboxRow({
    required this.label1, required this.val1, required this.onChanged1,
    required this.label2, required this.val2, required this.onChanged2,
  });

  final String label1;
  final bool val1;
  final ValueChanged<bool> onChanged1;
  final String label2;
  final bool val2;
  final ValueChanged<bool> onChanged2;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, bool val, ValueChanged<bool> onChange) {
      return Expanded(
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: val,
                onChanged: (v) => onChange(v ?? val),
                activeColor: const Color(0xFF4D861D),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF3D3D3D))),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        item(label1, val1, onChanged1),
        item(label2, val2, onChanged2),
      ],
    );
  }
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

// ── Paint editor model ────────────────────────────────────────────────────────
class _DrawStroke {
  _DrawStroke({
    required this.tool,
    required this.color,
    required this.strokeWidth,
    this.fillColor,
  });

  final _DrawTool tool;
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final List<Offset> points = [];
}

// ── Paint editor canvas painter ───────────────────────────────────────────────
class _SpriteCanvasPainter extends CustomPainter {
  const _SpriteCanvasPainter({required this.strokes, this.currentStroke});

  final List<_DrawStroke> strokes;
  final _DrawStroke? currentStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...strokes, if (currentStroke != null) currentStroke!];
    for (final stroke in all) {
      _paintStroke(canvas, stroke, size);
    }
  }

  void _paintStroke(Canvas canvas, _DrawStroke stroke, Size size) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (stroke.tool) {
      case _DrawTool.pencil:
      case _DrawTool.eraser:
        if (stroke.points.length == 1) {
          canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
        } else {
          final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
          for (final pt in stroke.points.skip(1)) {
            path.lineTo(pt.dx, pt.dy);
          }
          canvas.drawPath(path, paint);
        }
      case _DrawTool.line:
        if (stroke.points.length >= 2) {
          canvas.drawLine(stroke.points.first, stroke.points.last, paint);
        }
      case _DrawTool.rect:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
          if (stroke.fillColor != null) {
            canvas.drawRect(rect, Paint()..color = stroke.fillColor!..style = PaintingStyle.fill);
          }
          canvas.drawRect(rect, paint);
        }
      case _DrawTool.oval:
        if (stroke.points.length >= 2) {
          final rect = Rect.fromPoints(stroke.points.first, stroke.points.last);
          if (stroke.fillColor != null) {
            canvas.drawOval(rect, Paint()..color = stroke.fillColor!..style = PaintingStyle.fill);
          }
          canvas.drawOval(rect, paint);
        }
    }
  }

  @override
  bool shouldRepaint(_SpriteCanvasPainter old) =>
      strokes != old.strokes || currentStroke != old.currentStroke;
}

class _InspectorTab extends StatelessWidget {
  const _InspectorTab({required this.label, this.selected = false, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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

enum _ScratchBlockKind { event, endEvent, movement, variable, control, display, ai, widget, game, logic, functionBlock }

enum _ScratchBlockShape { command, cBlock, reporter, booleanReporter }

class _ScratchBlockData {
  const _ScratchBlockData({
    required this.label,
    required this.color,
    required this.kind,
    this.value,
    this.value2,
    this.suffix,
    this.operatorSymbol,
    this.valueDropdown = false,
    this.value2Dropdown = false,
    this.settingsIcon = false,
    this.helpIcon = false,
    this.tall = false,
    this.width,
    this.shape = _ScratchBlockShape.command,
  });

  final String label;
  final Color color;
  final _ScratchBlockKind kind;
  final String? value;
  final String? value2;
  final String? suffix;
  final String? operatorSymbol;
  final bool valueDropdown;
  final bool value2Dropdown;
  final bool settingsIcon;
  final bool helpIcon;
  final bool tall;
  final double? width;
  final _ScratchBlockShape shape;

  factory _ScratchBlockData.event(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: value != null,
        color: const Color(0xFF5BA658),
        kind: _ScratchBlockKind.event,
      );

  factory _ScratchBlockData.eventC(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: value != null,
        color: const Color(0xFFB15A5D),
        kind: _ScratchBlockKind.event,
        shape: _ScratchBlockShape.cBlock,
        width: label.length > 23 ? 320 : null,
      );

  factory _ScratchBlockData.endEvent(String label) => _ScratchBlockData(
        label: label,
        color: const Color(0xFF8B3A3A),
        kind: _ScratchBlockKind.endEvent,
        shape: _ScratchBlockShape.cBlock,
      );

  factory _ScratchBlockData.movement(String label, {String? value, String? value2, String? suffix}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        suffix: suffix,
        valueDropdown: value == 'true' || value == 'Oliver',
        color: const Color(0xFF83B455),
        kind: _ScratchBlockKind.movement,
      );

  factory _ScratchBlockData.movementReporter(String label, {String? value, String? suffix}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        valueDropdown: value != null,
        color: const Color(0xFF83B455),
        kind: _ScratchBlockKind.movement,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.variable(String label, {String? value, String? value2}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        valueDropdown: value == 'To' || value == 'By',
        color: const Color(0xFF50AEB1),
        kind: _ScratchBlockKind.variable,
      );

  factory _ScratchBlockData.variableReporter(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        color: const Color(0xFF50AEB1),
        kind: _ScratchBlockKind.variable,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.control(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        color: const Color(0xFF58B082),
        kind: _ScratchBlockKind.control,
      );

  factory _ScratchBlockData.controlC(String label, {String? value, String? suffix, bool settingsIcon = false, bool tall = false}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        settingsIcon: settingsIcon,
        tall: tall,
        color: const Color(0xFF58B082),
        kind: _ScratchBlockKind.control,
        shape: _ScratchBlockShape.cBlock,
        width: tall ? 144 : null,
      );

  factory _ScratchBlockData.display(String label, {String? value, String? value2}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        color: const Color(0xFF7156B6),
        kind: _ScratchBlockKind.display,
      );

  factory _ScratchBlockData.displayReporter(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        color: const Color(0xFF7156B6),
        kind: _ScratchBlockKind.display,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.ai(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        color: const Color(0xFFACAC4F),
        kind: _ScratchBlockKind.ai,
      );

  factory _ScratchBlockData.aiReporter(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: true,
        color: const Color(0xFFACAC4F),
        kind: _ScratchBlockKind.ai,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.aiC(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: true,
        color: const Color(0xFFACAC4F),
        kind: _ScratchBlockKind.ai,
        shape: _ScratchBlockShape.cBlock,
      );

  factory _ScratchBlockData.widgetBlock(String label, {String? value, String? value2}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        valueDropdown: value != null,
        color: const Color(0xFF5B88B0),
        kind: _ScratchBlockKind.widget,
      );

  factory _ScratchBlockData.widgetReporter(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: value != null,
        color: const Color(0xFF5B88B0),
        kind: _ScratchBlockKind.widget,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.game(String label, {String? value, String? value2}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        valueDropdown: value != null,
        color: const Color(0xFF8C58B5),
        kind: _ScratchBlockKind.game,
      );

  factory _ScratchBlockData.gameReporter(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        color: const Color(0xFF8C58B5),
        kind: _ScratchBlockKind.game,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.logicReporter(String label, {String? value, String? suffix, String? value2, String? operatorSymbolArg}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        value2: value2,
        operatorSymbol: operatorSymbolArg,
        color: const Color(0xFFB28B56),
        kind: _ScratchBlockKind.logic,
        shape: _ScratchBlockShape.reporter,
      );

  factory _ScratchBlockData.booleanBlock(String label, {String? value}) => _ScratchBlockData(
        label: label,
        value: value,
        valueDropdown: value == 'and' || value == '=' || value == '<' || value == '>',
        color: const Color(0xFFB28B56),
        kind: _ScratchBlockKind.logic,
        shape: _ScratchBlockShape.booleanReporter,
      );

  factory _ScratchBlockData.functionBlock(String label, {String? value, String? suffix}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        helpIcon: true,
        valueDropdown: value != null,
        color: const Color(0xFFB05282),
        kind: _ScratchBlockKind.functionBlock,
      );

  factory _ScratchBlockData.functionC(String label, {String? value, String? suffix}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        settingsIcon: true,
        helpIcon: true,
        color: const Color(0xFFB05282),
        kind: _ScratchBlockKind.functionBlock,
        shape: _ScratchBlockShape.cBlock,
        width: 310,
      );

  factory _ScratchBlockData.functionReporter(String label, {String? value, String? suffix}) => _ScratchBlockData(
        label: label,
        value: value,
        suffix: suffix,
        valueDropdown: value != null,
        color: const Color(0xFFB05282),
        kind: _ScratchBlockKind.functionBlock,
        shape: _ScratchBlockShape.reporter,
      );
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
