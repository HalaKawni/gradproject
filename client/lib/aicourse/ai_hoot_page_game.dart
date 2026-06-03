import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:client/aicourse/blocks_flutter_page.dart';
import 'package:client/features/home/services/game_api_service.dart';


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
  static const String arrowRight = 'assets/images/sprites/next_step.png';
}

const String _kGameId = 'ai-hoot';

const List<({String name, String asset})> _kBackgrounds = [
  (name: 'starry_night', asset: 'assets/images/starry_night.png'),
  (name: 'jungle',       asset: 'assets/images/sprites/jungle.png'),
  (name: 'jungle_night', asset: 'assets/images/sprites/jungle_night.png'),
  (name: 'ocean_night',  asset: 'assets/images/sprites/ocean_night.png'),
  (name: 'bricks',       asset: 'assets/images/sprites/bricks.png'),
  (name: 'bricks_2',     asset: 'assets/images/sprites/bricks_2.png'),
  (name: 'grass',        asset: 'assets/images/sprites/grass.png'),
  (name: 'grass_2',      asset: 'assets/images/sprites/grass_2.png'),
  (name: 'road',         asset: 'assets/images/sprites/road.png'),
  (name: 'clouds_bright',asset: 'assets/images/sprites/clouds_bright.png'),
  (name: 'bubbles',      asset: 'assets/images/sprites/bubbles.png'),
  (name: 'winter',       asset: 'assets/images/sprites/winter.png'),
  (name: 'underground',  asset: 'assets/images/sprites/underground.png'),
  (name: 'sunny',        asset: 'assets/images/sprites/sunny.png'),
  (name: 'nature',       asset: 'assets/images/sprites/nature.png'),
  (name: 'soccer',       asset: 'assets/images/sprites/soccer.png'),
  (name: 'beach',        asset: 'assets/images/sprites/beach.png'),
  (name: 'room',         asset: 'assets/images/sprites/room.png'),
  (name: 'ocean',        asset: 'assets/images/sprites/ocean.png'),
  (name: 'bright_stars', asset: 'assets/images/sprites/bright_stars.png'),
];

/// Drop this file in: client/lib/codemonkey_scratch_page.dart
/// Then open it with:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const CodeMonkeyScratchPage()));
///
/// This is a CodeMonkey/Scratch-style builder page that matches the layout in
/// your screenshot: left lesson panel, middle block workspace, right game stage,
/// and sprite settings panel. It uses your uploaded PNG assets.
class _SavedAiModel {
  const _SavedAiModel({required this.name, required this.classNames});
  final String name;
  final List<String> classNames;
}

class CodeMonkeyScratchPage extends StatefulWidget {
  const CodeMonkeyScratchPage({super.key, this.exerciseNumber = 1, this.savedModels = const []});

  final int exerciseNumber;
  final List<_SavedAiModel> savedModels;

  @override
  State<CodeMonkeyScratchPage> createState() => _CodeMonkeyScratchPageState();
}

List<double> _parsePrediction(dynamic raw) {
  if (raw == null) return [];
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((v) => (v as num).toDouble()).toList();
    } catch (_) {}
  }
  if (raw is js.JsArray) {
    try {
      return raw.toList().map<double>((v) {
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      }).toList();
    } catch (_) {}
  }
  if (raw is js.JsObject) {
    try {
      final len = (raw['length'] as num?)?.toInt() ?? 0;
      return List<double>.generate(len, (i) {
        final v = raw[i];
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString()) ?? 0.0;
      });
    } catch (_) {}
  }
  return [];
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
  bool _paletteOpen = true;
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
  bool _owlVisible = true;
  double _owlSpeed = 62.0; // pixels per Step block
  bool _owlIsJumping = false; // true while a Jump block is in flight
  final Map<String, dynamic> _variables = {};

  Timer? _onPredictionTimer;
  bool _predictionBusy = false;
  Timer? _onUpdateTimer;
  bool _updateBusy = false;

  List<String> _aiClassNames = ['Class 1', 'Class 2'];
  List<String> get _textWidgetNames => _stageWidgets
      .where((w) => w.type == _GameWidgetType.text)
      .map((w) => w.name)
      .toList();

  List<String> get _clockWidgetNames => _stageWidgets
      .where((w) => w.type == _GameWidgetType.clock)
      .map((w) => w.name)
      .toList();
  bool _modelSaved = false;
  bool _modelSelected = false;
  _SavedAiModel? _savedModel;

  bool _isFullscreen = false;
  bool _showRefCards = false;

  List<_PlacedTile> _placedTiles = [];

  // Game settings (Game tab)
  int _worldWidth = 600;
  int _worldHeight = 400;
  String _cameraTarget = 'None';
  String _selectedBackground = 'assets/images/starry_night.png';
  double _gravity = 1800;
  String _physics = 'ARCADE';

  String _selectedObjectId = 'oliver';
  late final Map<String, List<_WorkspaceEntry>> _objectWorkspaces;
  List<_WorkspaceEntry> get _workspaceEntries => _objectWorkspaces[_selectedObjectId]!;

  @override
  void dispose() {
    _onPredictionTimer?.cancel();
    _onUpdateTimer?.cancel();
    super.dispose();
  }

  // ── Progress persistence ────────────────────────────────────────────────────

  Future<void> _loadAndResumeProgress() async {
    if (!mounted) return;
    try {
      final progress = await GameApiService.getProgress(_kGameId);
      final resumeLevel = (progress['currentLevel'] as num?)?.toInt() ?? 1;
      if (!mounted) return;
      if (resumeLevel > 1 && resumeLevel <= 9) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CodeMonkeyScratchPage(
              exerciseNumber: resumeLevel,
              savedModels: widget.savedModels,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveCurrentExercise() async {
    try {
      await GameApiService.saveLevelResult(
        gameId: _kGameId,
        level: widget.exerciseNumber,
        stars: 3,
        score: 100,
      );
    } catch (_) {}
  }

  Future<void> _handleReset() async {
    try {
      await GameApiService.resetProgress(_kGameId);
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CodeMonkeyScratchPage(exerciseNumber: 1)),
    );
  }

  void _navigateToExercise(int n) {
    if (n < 1 || n > 9) return;
    final allSaved = [
      ...widget.savedModels,
      if (_savedModel != null) _savedModel!,
    ];
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CodeMonkeyScratchPage(exerciseNumber: n, savedModels: allSaved),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (widget.exerciseNumber == 9) {
      _objectWorkspaces = {
        'oliver': [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.controlC('Loop'), position: const Offset(20, 47)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Step', value: '1'), position: const Offset(42, 80)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: 'squat'), position: const Offset(20, 136)),
          _WorkspaceEntry(block: _ScratchBlockData.display('Set Scale', value: '0.5'), position: const Offset(42, 169)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: 'stand'), position: const Offset(220, 136)),
          _WorkspaceEntry(block: _ScratchBlockData.display('Set Scale', value: '1'), position: const Offset(242, 169)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: 'arms up'), position: const Offset(20, 250)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Jump', value: '1'), position: const Offset(42, 283)),
          _WorkspaceEntry(block: _ScratchBlockData.eventC('On Collide With World Bounds', value: 'Left'), position: const Offset(430, 14)),
        ],
      };
      if (widget.savedModels.isNotEmpty) {
        _aiClassNames = List.from(widget.savedModels.first.classNames);
        _modelSaved = true;
        _modelSelected = true;
        _savedModel = widget.savedModels.first;
      }
      // Pre-populate webcam widget (carried from previous exercises)
      final webcam = _AddedGameWidget(_GameWidgetType.webcam);
      _stageWidgets.add(webcam);
      _objectWorkspaces[webcam.id] = [
        _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
      ];
    } else if (widget.exerciseNumber == 8 || widget.exerciseNumber == 7) {
      _objectWorkspaces = {
        'oliver': [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.controlC('Loop'), position: const Offset(20, 47)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Step', value: '1'), position: const Offset(42, 80)),
          _WorkspaceEntry(block: _ScratchBlockData.aiReporter('Predict', value: ''), position: const Offset(280, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: ''), position: const Offset(280, 57)),
        ],
      };
      if (widget.exerciseNumber == 8 && widget.savedModels.isNotEmpty) {
        _aiClassNames = List.from(widget.savedModels.first.classNames);
        _modelSaved = true;
        _modelSelected = true;
        _savedModel = widget.savedModels.first;
      }
    } else if (widget.exerciseNumber == 6 || widget.exerciseNumber == 5) {
      _objectWorkspaces = {
        'oliver': [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.controlC('Loop'), position: const Offset(20, 47)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Step', value: '1'), position: const Offset(42, 80)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: 'raise hands'), position: const Offset(20, 136)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Jump', value: '1'), position: const Offset(42, 169)),
          _WorkspaceEntry(block: _ScratchBlockData.eventC('On Update'), position: const Offset(240, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.widgetBlock('Set text:', value: 'text', value2: 'raise hands', value2Dropdown: true), position: const Offset(262, 47)),
        ],
      };
      if (widget.savedModels.isNotEmpty) {
        _aiClassNames = List.from(widget.savedModels.first.classNames);
        _modelSaved = true;
        _modelSelected = true;
        _savedModel = widget.savedModels.first;
      }
      if (widget.exerciseNumber == 6) {
        _worldWidth = 3600;
        _cameraTarget = 'None';
      }
    } else if (widget.exerciseNumber == 4) {
      _objectWorkspaces = {
        'oliver': [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.controlC('Loop'), position: const Offset(20, 47)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Step', value: '1'), position: const Offset(42, 80)),
          _WorkspaceEntry(block: _ScratchBlockData.aiC('On Prediction', value: 'raise hands'), position: const Offset(20, 131)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Jump', value: '1'), position: const Offset(42, 164)),
        ],
      };
      if (widget.savedModels.isNotEmpty) {
        _aiClassNames = List.from(widget.savedModels.first.classNames);
        _modelSaved = true;
        _modelSelected = true;
        _savedModel = widget.savedModels.first;
      }
    } else if (widget.exerciseNumber == 3) {
      _objectWorkspaces = {
        'oliver': [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.controlC('Loop'), position: const Offset(20, 47)),
          _WorkspaceEntry(block: _ScratchBlockData.movement('Step', value: '1'), position: const Offset(42, 80)),
        ],
      };
    } else {
      _objectWorkspaces = {
        'oliver': [_WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14))],
      };
    }
    if (widget.exerciseNumber == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndResumeProgress());
    }
  }

  final List<_SpriteAssetData> _projectSprites = <_SpriteAssetData>[];
  final List<_AddedGameWidget> _stageWidgets = [];
  final Map<_SpriteAssetData, Offset> _spriteStagePositions = {};

  void _onWidgetAdded(_AddedGameWidget w) {
    w.stageX = 12.0;
    w.stageY = 12.0 + _stageWidgets.length * 55.0;
    setState(() {
      _stageWidgets.add(w);
      // "On Run" hat canvasHeight=38, bottom connector at dy+(38-5)=47
      const Offset onRunConnector = Offset(20, 47);
      if (w.type == _GameWidgetType.timer) {
        _objectWorkspaces[w.id] = [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.widgetBlock('Set ${w.type.name}: ${w.name} To', value: '1'), position: onRunConnector),
          _WorkspaceEntry(block: _ScratchBlockData.endEvent('On End'), position: const Offset(20, 130)),
        ];
      } else if (w.type == _GameWidgetType.button) {
        _objectWorkspaces[w.id] = [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.endEvent('On Click'), position: const Offset(20, 130)),
          _WorkspaceEntry(block: _ScratchBlockData.endEvent('On Down'), position: const Offset(250, 130)),
        ];
      } else if (w.type == _GameWidgetType.dialog) {
        _objectWorkspaces[w.id] = [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.endEvent('On Confirm'), position: const Offset(20, 130)),
        ];
      } else if (w.type == _GameWidgetType.webcam || w.type == _GameWidgetType.clock) {
        _objectWorkspaces[w.id] = [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
        ];
      } else {
        _objectWorkspaces[w.id] = [
          _WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)),
          _WorkspaceEntry(block: _ScratchBlockData.widgetBlock('Set ${w.type.name}: ${w.name} To', value: '0'), position: onRunConnector),
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
          _ScratchBlockData.widgetBlock('Set text:', value: 'text', value2: 'raise hands', value2Dropdown: true),
          _ScratchBlockData.widgetBlock('Set timer:', value: 'To', value2: '1'),
          _ScratchBlockData.widgetBlock('Start clock:', value: 'clock'),
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

  // ── Execution engine ───────────────────────────────────────────────────────

  void _stopProgram() {
    if (!_isRunning) return;
    _onPredictionTimer?.cancel();
    _onPredictionTimer = null;
    _onUpdateTimer?.cancel();
    _onUpdateTimer = null;
    setState(() { _isRunning = false; _owlFrame = 0; });
  }

  Future<void> _runProgram() async {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _owlX = 36; _owlY = 315; _owlFrame = 0;
      _owlScale = 1.0; _owlRotation = 0.0; _owlOpacity = 1.0;
      _owlVisible = true; _owlSpeed = 62.0; _owlIsJumping = false;
      _variables.clear();
    });
    _startPredictionPolling();
    _startOnUpdateLoop();
    await _execChain(_execOuterChain());
    _onPredictionTimer?.cancel();
    _onPredictionTimer = null;
    _onUpdateTimer?.cancel();
    _onUpdateTimer = null;
    if (mounted) setState(() { _isRunning = false; _owlFrame = 0; });
  }

  void _startPredictionPolling() {
    _onPredictionTimer?.cancel();
    _predictionBusy = false;
    if (!kIsWeb) return;
    final oliverWs = List<_WorkspaceEntry>.from(_objectWorkspaces['oliver'] ?? []);
    if (!oliverWs.any((e) => e.block.label == 'On Prediction')) return;
    // Clear stale keypoints from the training session so prediction only fires
    // when fresh keypoints arrive from the stage webcam camera.
    js.context['_lastKeypoints'] = js.JsArray();
    _onPredictionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) async {
      if (!mounted || !_isRunning || _predictionBusy) return;
      final predRaw = js.context.callMethod('getLastPrediction', []);
      if (predRaw == null) return;
      final confidences = _parsePrediction(predRaw);
      if (confidences.isEmpty) return;
      double maxConf = 0; int maxIdx = 0;
      for (int i = 0; i < confidences.length; i++) {
        if (confidences[i] > maxConf) { maxConf = confidences[i]; maxIdx = i; }
      }
      // Require ≥4 out of 5 KNN votes (0.8) to avoid false-positive triggers.
      if (maxConf < 0.75) return;
      if (maxIdx >= _aiClassNames.length) return;
      final detectedClass = _aiClassNames[maxIdx].toLowerCase().trim();
      final ws = List<_WorkspaceEntry>.from(_objectWorkspaces['oliver'] ?? []);
      for (final entry in ws) {
        if (entry.block.label != 'On Prediction') continue;
        final blockClass = (entry.editedValue ?? entry.block.value ?? '').toLowerCase().trim();
        if (blockClass != detectedClass) continue;
        _predictionBusy = true;
        try {
          await _execChain(_execInnerChain(entry, ws));
        } finally {
          _predictionBusy = false;
        }
        break;
      }
    });
  }

  void _startOnUpdateLoop() {
    _onUpdateTimer?.cancel();
    _updateBusy = false;
    _onUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!mounted || !_isRunning || _updateBusy) return;
      final hasOnUpdate = _objectWorkspaces.values.any(
        (ws) => ws.any((e) => e.block.label == 'On Update'),
      );
      if (!hasOnUpdate) return;
      _updateBusy = true;
      try {
        for (final ws in _objectWorkspaces.values) {
          for (final entry in List<_WorkspaceEntry>.from(ws)) {
            if (!_isRunning || !mounted) return;
            if (entry.block.label != 'On Update') continue;
            await _execChain(_execInnerChain(entry, ws));
          }
        }
      } finally {
        _updateBusy = false;
      }
    });
  }

  // Find a Predict reporter block in the same workspace as [host].
  // Prefers the closest block by Euclidean distance; returns any match if only one exists.
  _WorkspaceEntry? _findInlinePredict(_WorkspaceEntry host) {
    List<_WorkspaceEntry>? hostWs;
    for (final ws in _objectWorkspaces.values) {
      if (ws.contains(host)) { hostWs = ws; break; }
    }
    final entries = hostWs ?? _workspaceEntries;
    _WorkspaceEntry? best;
    double bestDist = double.infinity;
    for (final e in entries) {
      if (e == host) continue;
      if (e.block.label == 'Predict' && e.block.shape == _ScratchBlockShape.reporter) {
        final dist = (e.position - host.position).distance;
        if (dist < bestDist) { bestDist = dist; best = e; }
      }
    }
    return best;
  }

  // Evaluate a Predict reporter: returns formatted percentage string (e.g. "77%").
  String _evalPredict(String className) {
    if (!kIsWeb) return '0%';
    try {
      final raw = js.context.callMethod('getLastPrediction', []);
      if (raw == null) return '0%';
      final confidences = _parsePrediction(raw); // top-level helper
      if (confidences.isEmpty) return '0%';
      for (int i = 0; i < _aiClassNames.length && i < confidences.length; i++) {
        if (_aiClassNames[i].toLowerCase().trim() == className.toLowerCase().trim()) {
          return '${(confidences[i] * 100).round()}%';
        }
      }
      final maxConf = confidences.reduce(math.max);
      return '${(maxConf * 100).round()}%';
    } catch (_) {
      return '0%';
    }
  }

  void _setWidgetText(String widgetName, String text) {
    for (final w in _stageWidgets) {
      if (w.type == _GameWidgetType.text &&
          w.name.toLowerCase().trim() == widgetName.toLowerCase().trim()) {
        setState(() => w.text = text);
        return;
      }
    }
  }

  // Walking animation — cycles through 5 sprite frames while moving horizontally.
  // Oliver's hitbox insets inside the 74×74 sprite frame.
  static const double _hitL = 10, _hitT = 8, _hitW = 54, _hitH = 62;

  // Resolve horizontal position against placed tiles. Stops Oliver flush against
  // a tile wall instead of walking through it. Skipped while airborne so Oliver
  // can walk over the top of a wall after jumping.
  double _resolveWalkX(double oldX, double newX) {
    if (_owlIsJumping) return newX.clamp(0.0, _worldWidth.toDouble() - 74.0);
    const tileSize = 30.0;
    if (newX == oldX) return newX;
    for (final tile in _placedTiles) {
      final tLeft   = tile.gridX * tileSize;
      final tRight  = tLeft + tileSize;
      final tTop    = tile.gridY * tileSize;
      final tBottom = tTop + tileSize;
      // Skip tiles that don't overlap Oliver's vertical band
      final owlTop    = _owlY + _hitT;
      final owlBottom = owlTop + _hitH;
      if (owlBottom <= tTop || owlTop >= tBottom) continue;
      if (newX > oldX) {
        // Moving right: stop right edge at tile's left face
        final oldRight = oldX + _hitL + _hitW;
        final newRight = newX + _hitL + _hitW;
        if (newRight > tLeft && oldRight <= tLeft) {
          newX = math.min(newX, tLeft - _hitL - _hitW);
        }
      } else {
        // Moving left: stop left edge at tile's right face
        final oldLeft = oldX + _hitL;
        final newLeft = newX + _hitL;
        if (newLeft < tRight && oldLeft >= tRight) {
          newX = math.max(newX, tRight - _hitL);
        }
      }
    }
    return newX.clamp(0.0, _worldWidth.toDouble() - 74.0);
  }

  Future<void> _walkOneStep({required double distance}) async {
    // For AI-controlled exercises, require an active model before walking.
    if ((widget.exerciseNumber == 8 || widget.exerciseNumber == 9) && !_modelSaved) {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      return;
    }
    const frameCount = 5;
    const ticks = 10;
    final double dx = distance / ticks;
    for (var tick = 0; tick < ticks; tick++) {
      if (!mounted || !_isRunning) return;
      final double resolved = _resolveWalkX(_owlX, _owlX + dx);
      setState(() {
        _owlX = resolved;
        _owlFrame = tick % frameCount;
      });
      await Future<void>.delayed(const Duration(milliseconds: 55));
    }
    if (mounted) setState(() => _owlFrame = 0);
  }

  // ── Chain builders ─────────────────────────────────────────────────────────

  // Total height of a block as the execution engine sees it (matches workspace snap math).
  double _execBlockHeight(_WorkspaceEntry entry, [List<_WorkspaceEntry>? ws]) {
    final entries = ws ?? _workspaceEntries;
    final isCBlock = entry.block.shape == _ScratchBlockShape.cBlock &&
        entry.block.kind != _ScratchBlockKind.event &&
        entry.block.kind != _ScratchBlockKind.endEvent;
    if (!isCBlock) return 38.0; // stackH(33) + nd(5)
    // C-block: header + inner content + footer
    const stackH = 33.0; const footH = 13.0; const nd = 5.0;
    final innerX = entry.position.dx + 22;
    double innerTotal = 0;
    for (final e in entries) {
      if (e == entry) continue;
      if ((e.position.dx - innerX).abs() < 14) innerTotal += 38.0;
    }
    return stackH + math.max(30.0, innerTotal) + footH + nd;
  }

  // Find the block immediately below `from` in the outer chain.
  _WorkspaceEntry? _execNextEntry(_WorkspaceEntry from) {
    final bottomY = from.position.dy + _execBlockHeight(from) - 5.0;
    final fromX = from.position.dx;
    _WorkspaceEntry? best; double bestDist = 15.0;
    for (final e in _workspaceEntries) {
      if (e == from) continue;
      final dy = (e.position.dy - bottomY).abs();
      if ((e.position.dx - fromX).abs() < 14 && dy < bestDist) {
        bestDist = dy; best = e;
      }
    }
    return best;
  }

  // Ordered list of blocks in the outer chain following "On Run".
  List<_WorkspaceEntry> _execOuterChain() {
    _WorkspaceEntry? root;
    for (final e in _workspaceEntries) {
      if (e.block.kind == _ScratchBlockKind.event) { root = e; break; }
    }
    if (root == null) return [];
    final chain = <_WorkspaceEntry>[];
    final visited = <_WorkspaceEntry>{root};
    _WorkspaceEntry? cur = _execNextEntry(root);
    while (cur != null && !visited.contains(cur)) {
      visited.add(cur); chain.add(cur); cur = _execNextEntry(cur);
    }
    return chain;
  }

  // Ordered list of blocks inside the inner slot of a C-block.
  // Accepts an optional [ws] to use a specific workspace (e.g. Oliver's) instead of the selected one.
  List<_WorkspaceEntry> _execInnerChain(_WorkspaceEntry cBlock, [List<_WorkspaceEntry>? ws]) {
    final entries = ws ?? _workspaceEntries;
    final innerX = cBlock.position.dx + 22;
    final topY = cBlock.position.dy + 33; // stackH
    _WorkspaceEntry? first; double bestDist = 30.0;
    for (final e in entries) {
      if (e == cBlock) continue;
      final dy = (e.position.dy - topY).abs();
      if ((e.position.dx - innerX).abs() < 30 && dy < bestDist) {
        bestDist = dy; first = e;
      }
    }
    if (first == null) return [];
    final chain = <_WorkspaceEntry>[first];
    final visited = <_WorkspaceEntry>{first};
    _WorkspaceEntry? cur = first;
    while (cur != null) {
      final bottomY = cur.position.dy + _execBlockHeight(cur, entries) - 5.0;
      _WorkspaceEntry? next; double nextDist = 30.0;
      for (final e in entries) {
        if (e == cBlock || visited.contains(e)) continue;
        final dy = (e.position.dy - bottomY).abs();
        if ((e.position.dx - innerX).abs() < 30 && dy < nextDist) {
          nextDist = dy; next = e;
        }
      }
      if (next == null) break;
      chain.add(next); visited.add(next); cur = next;
    }
    return chain;
  }

  // Execute an ordered list of block entries sequentially.
  Future<void> _execChain(List<_WorkspaceEntry> chain) async {
    for (final entry in chain) {
      if (!_isRunning || !mounted) return;
      await _execEntry(entry);
    }
  }

  double _n(String? v, [double fallback = 0]) =>
      double.tryParse(v?.trim() ?? '') ?? fallback;

  // ── Block executor ─────────────────────────────────────────────────────────

  Future<void> _execEntry(_WorkspaceEntry entry) async {
    if (!_isRunning || !mounted) return;
    final b = entry.block;
    final n1 = _n(entry.editedValue ?? b.value);
    final n2 = _n(entry.editedValue2 ?? b.value2);

    switch (b.label) {

      // ── Movement ──────────────────────────────────────────────────────────
      case 'Step':
        await _walkOneStep(distance: n1 * _owlSpeed);

      case 'Jump':
        final jh = n1 * 70; final jd = (260 * n1).clamp(80.0, 5000.0).toInt();
        _owlIsJumping = true;
        setState(() => _owlY -= jh);
        await Future.delayed(Duration(milliseconds: jd));
        if (!mounted || !_isRunning) { _owlIsJumping = false; return; }
        setState(() => _owlY += jh);
        await Future.delayed(Duration(milliseconds: jd));
        _owlIsJumping = false;

      case 'Set X':
        setState(() => _owlX = n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Set Y':
        setState(() => _owlY = n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Change X By':
        setState(() => _owlX += n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Change Y By':
        setState(() => _owlY += n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Set Rotation':
        setState(() => _owlRotation = n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Change Rotation By':
        setState(() => _owlRotation += n1);
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Set Speed':
        _owlSpeed = (n1 * 62.0).clamp(1.0, 1000.0);

      case 'Set Allow Gravity':
        // Physics not simulated — stored for future use.
        break;

      // ── Display ───────────────────────────────────────────────────────────
      case 'Show':
        setState(() => _owlVisible = true);

      case 'Hide':
        setState(() => _owlVisible = false);

      case 'Destroy':
        setState(() { _owlVisible = false; _isRunning = false; });

      case 'Disable':
      case 'Enable':
        break; // UI interaction toggle — no runtime effect yet.

      case 'Set Scale':
        setState(() => _owlScale = n1.clamp(0.01, 10.0));
        await Future.delayed(const Duration(milliseconds: 50));

      case 'Set Opacity':
        setState(() => _owlOpacity = n1.clamp(0.0, 1.0));
        await Future.delayed(const Duration(milliseconds: 50));

      // ── Control ───────────────────────────────────────────────────────────
      case 'Wait':
        await Future.delayed(Duration(
            milliseconds: (n1 * 1000).clamp(0.0, 30000.0).toInt()));

      case 'Loop':
        final inner = _execInnerChain(entry);
        while (_isRunning && mounted) {
          await _execChain(inner);
          // Prevent busy-spin when inner is empty.
          if (inner.isEmpty) await Future.delayed(const Duration(milliseconds: 50));
        }

      case 'Repeat':
        final times = n1.toInt().clamp(0, 10000);
        final inner = _execInnerChain(entry);
        for (int i = 0; i < times && _isRunning && mounted; i++) {
          await _execChain(inner);
        }

      case 'if':
        // Boolean reporter evaluation not yet wired — always executes inner chain.
        await _execChain(_execInnerChain(entry));

      // ── Variables ─────────────────────────────────────────────────────────
      case 'Set variable:':
        _variables['variable'] = n2 != 0 ? n2 : b.value2 ?? 0;

      case 'Change variable:':
        _variables['variable'] =
            ((_variables['variable'] ?? 0) as num) + (n2 != 0 ? n2 : 1);

      // ── Game & Sounds ─────────────────────────────────────────────────────
      case 'Reset Game':
        setState(() {
          _owlX = 36; _owlY = 315; _owlFrame = 0;
          _owlScale = 1.0; _owlRotation = 0.0; _owlOpacity = 1.0;
          _owlVisible = true; _owlSpeed = 62.0;
          _variables.clear();
        });

      case 'Pause Game':
        setState(() => _isRunning = false);

      case 'Unpause Game':
        setState(() => _isRunning = true);

      case 'Play':
        break; // Audio playback not implemented.

      case 'Set Background':
        break; // Background asset swap not implemented.

      case 'Get Game Time':
        break; // Reporter — value returned via variable system in future.

      // ── Widgets ───────────────────────────────────────────────────────────
      case 'Set counter:':
      case 'Change counter:':
      case 'Set timer:':
      case 'Start clock:':
        break;

      case 'Set text:': {
        final widgetName = (entry.editedValue ?? b.value ?? '').trim();
        final String textValue;
        if (b.value2Dropdown) {
          final className = (entry.editedValue2 ?? b.value2 ?? '').trim();
          textValue = _evalPredict(className);
        } else {
          final inlinePredict = _findInlinePredict(entry);
          if (inlinePredict != null) {
            final className = (inlinePredict.editedValue ?? inlinePredict.block.value ?? '').trim();
            textValue = _evalPredict(className);
          } else {
            final raw = (entry.editedValue2 ?? b.value2 ?? '').trim();
            textValue = raw.startsWith('"') && raw.endsWith('"')
                ? raw.substring(1, raw.length - 1)
                : raw;
          }
        }
        _setWidgetText(widgetName, textValue);
      }

      // ── AI ────────────────────────────────────────────────────────────────
      case 'Predict':
      case 'On Prediction':
        break;

      default:
        await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void _addBlock(_ScratchBlockData block, {Offset position = const Offset(80, 80)}) {
    if (block.kind == _ScratchBlockKind.event && block.shape != _ScratchBlockShape.cBlock) {
      setState(() {
        _workspaceEntries
          ..clear()
          ..add(_WorkspaceEntry(block: block, position: const Offset(20, 14)));
      });
      return;
    }
    if (block.kind == _ScratchBlockKind.endEvent) {
      setState(() {
        _workspaceEntries.removeWhere((e) => e.block.kind == _ScratchBlockKind.endEvent);
        _workspaceEntries.add(_WorkspaceEntry(block: block, position: position));
      });
      return;
    }
    setState(() => _workspaceEntries.add(_WorkspaceEntry(block: block, position: position)));
  }

  void _removeBlock(int index) {
    if (index == 0) return;
    setState(() => _workspaceEntries.removeAt(index));
  }

  void _clearProgram() {
    setState(() {
      _workspaceEntries
        ..clear()
        ..add(_WorkspaceEntry(block: _ScratchBlockData.event('On Run'), position: const Offset(20, 14)));
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
    setState(() {
      _projectSprites.remove(sprite);
      _spriteStagePositions.remove(sprite);
    });
  }

  void _onSpriteDuplicated(_SpriteAssetData sprite) {
    final copy = _SpriteAssetData(
      displayName: '${sprite.displayName} copy',
      assetPath: sprite.assetPath,
      categories: sprite.categories,
      frameCount: sprite.frameCount,
      imageBytes: sprite.imageBytes,
    );
    setState(() {
      _spriteStagePositions[copy] = Offset(
        (_spriteStagePositions[sprite]?.dx ?? 50.0) + 20,
        (_spriteStagePositions[sprite]?.dy ?? 50.0) + 20,
      );
      _projectSprites.add(copy);
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
      _spriteStagePositions[pickedSprite] =
          Offset(50.0 + _projectSprites.length * 85.0, 50.0);
      _projectSprites.add(pickedSprite);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF2),
      body: Stack(
        children: [
          Column(
        children: [
          _TopBar(
            exerciseNumber: widget.exerciseNumber,
            onReferenceCardsTap: () => setState(() => _showRefCards = true),
          ),
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
                      Expanded(flex: 28, child: _LessonPanel(
                        workspaceEntries: _workspaceEntries,
                        isRunning: _isRunning,
                        exerciseNumber: widget.exerciseNumber,
                        exerciseSteps: _stepsForExercise(widget.exerciseNumber),
                        aiClassNames: _aiClassNames,
                        modelSaved: _modelSaved,
                        modelSelected: _modelSelected,
                        worldWidth: _worldWidth,
                        cameraTarget: _cameraTarget,
                        onNextExercise: () async {
                          await _saveCurrentExercise();
                          if (!mounted) return;
                          _navigateToExercise(widget.exerciseNumber + 1);
                        },
                        onPrevExercise: () => _navigateToExercise(widget.exerciseNumber - 1),
                        onReset: _handleReset,
                        onAllCompleted: () async {
                          await _saveCurrentExercise();
                          if (!mounted) return;
                          if (widget.exerciseNumber == 9) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => _CourseCompletedDialog(
                                onBackToHome: () {
                                  if (mounted) Navigator.of(context).pop();
                                },
                              ),
                            );
                          }
                        },
                        placedTiles: _placedTiles,
                      )),
                      Container(width: 2, color: const Color(0xFFD0D0D0)),
                      Expanded(
                        flex: 38,
                        child: _BlocksWorkspace(
                          selectedCategory: _selectedCategory,
                          categories: _categories,
                          paletteBlocks: _paletteBlocks,
                          workspaceEntries: _workspaceEntries,
                          isRunning: _isRunning,
                          activeObjectName: _selectedObjectId == 'oliver'
                              ? 'Oliver'
                              : _stageWidgets.firstWhere((w) => w.id == _selectedObjectId, orElse: () => _stageWidgets.first).name,
                          activeObjectAsset: _selectedObjectId == 'oliver'
                              ? null
                              : _stageWidgets.firstWhere((w) => w.id == _selectedObjectId, orElse: () => _stageWidgets.first).assetPath,
                          onRun: _runProgram,
                          onStop: _stopProgram,
                          onClear: _clearProgram,
                          onSelectCategory: (category) {
                            setState(() {
                              if (_selectedCategory == category) {
                                _paletteOpen = !_paletteOpen;
                              } else {
                                _selectedCategory = category;
                                _paletteOpen = true;
                              }
                            });
                          },
                          paletteOpen: _paletteOpen,
                          onAddBlock: (block, pos) => _addBlock(block, position: pos),
                          onRemoveBlock: _removeBlock,
                          aiClassNames: _aiClassNames,
                          textWidgetNames: _textWidgetNames,
                          clockWidgetNames: _clockWidgetNames,
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
                          owlVisible: _owlVisible,
                          isRunning: _isRunning,
                          exerciseNumber: widget.exerciseNumber,
                          projectSprites: _projectSprites,
                          stageWidgets: _stageWidgets,
                          selectedObjectId: _selectedObjectId,
                          onAddSpritePressed: () => _showAddSpriteDialog(context),
                          onOliverSettingsChanged: _onOliverSettingsChanged,
                          onOliverSelected: () => setState(() => _selectedObjectId = 'oliver'),
                          onSpriteDeleted: _onSpriteDeleted,
                          onSpriteDuplicated: _onSpriteDuplicated,
                          onWidgetAdded: _onWidgetAdded,
                          onWidgetRemoved: _onWidgetRemoved,
                          onWidgetSelected: _onWidgetSelected,
                          onWidgetChanged: _onWidgetChanged,
                          onAiClassNamesChanged: (names) => setState(() {
                            _aiClassNames = names;
                            if ((widget.exerciseNumber == 3 || widget.exerciseNumber == 7) && names.isNotEmpty) _modelSelected = true;
                          }),
                          onModelSaved: (model) => setState(() {
                            _modelSaved = true;
                            _savedModel = model;
                            if (widget.exerciseNumber == 7) {
                              _modelSelected = true;
                              _aiClassNames = List.from(model.classNames);
                            }
                          }),
                          savedModels: [
                            ...widget.savedModels,
                            if (_savedModel != null) _savedModel!,
                          ],
                          worldWidth: _worldWidth,
                          worldHeight: _worldHeight,
                          cameraTarget: _cameraTarget,
                          gravity: _gravity,
                          physics: _physics,
                          onWorldWidthChanged: (v) => setState(() => _worldWidth = v),
                          onWorldHeightChanged: (v) => setState(() => _worldHeight = v),
                          onCameraTargetChanged: (v) => setState(() => _cameraTarget = v),
                          onGravityChanged: (v) => setState(() => _gravity = v),
                          onPhysicsChanged: (v) => setState(() => _physics = v),
                          onFullscreen: () => setState(() => _isFullscreen = true),
                          placedTiles: _placedTiles,
                          onTilesChanged: (tiles) => setState(() => _placedTiles = tiles),
                          background: _selectedBackground,
                          onBackgroundChanged: (v) => setState(() => _selectedBackground = v),
                          spriteStagePositions: _spriteStagePositions,
                          onSpritePositionChanged: (sprite, pos) =>
                              setState(() => _spriteStagePositions[sprite] = pos),
                          onOliverPositionChanged: (x, y) =>
                              setState(() { _owlX = x; _owlY = y; }),
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
          if (_showRefCards)
            Positioned.fill(
              child: _ReferenceCardsOverlay(
                onClose: () => setState(() => _showRefCards = false),
              ),
            ),
          if (_isFullscreen) Positioned.fill(
            child: _FullscreenStage(
              owlX: _owlX,
              owlY: _owlY,
              owlScale: _owlScale,
              owlRotation: _owlRotation,
              owlOpacity: _owlOpacity,
              owlFrame: _owlFrame,
              owlVisible: _owlVisible,
              isRunning: _isRunning,
              stageWidgets: _stageWidgets,
              worldWidth: _worldWidth,
              worldHeight: _worldHeight,
              cameraTarget: _cameraTarget,
              background: _selectedBackground,
              onExit: () => setState(() => _isFullscreen = false),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fullscreen stage overlay ─────────────────────────────────────────────────

class _FullscreenStage extends StatelessWidget {
  const _FullscreenStage({
    required this.owlX,
    required this.owlY,
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.owlFrame,
    required this.owlVisible,
    required this.isRunning,
    required this.stageWidgets,
    required this.onExit,
    this.worldWidth = 600,
    this.worldHeight = 400,
    this.cameraTarget = 'None',
    this.background = 'assets/images/starry_night.png',
  });

  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final int owlFrame;
  final bool owlVisible;
  final bool isRunning;
  final List<_AddedGameWidget> stageWidgets;
  final VoidCallback onExit;
  final int worldWidth;
  final int worldHeight;
  final String cameraTarget;
  final String background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spriteSize = 96.0;
        final maxTop = math.max(0.0, constraints.maxHeight - spriteSize - 8);
        // Scale owlY from world-height coordinate space to fullscreen height
        final double scaledY = (owlY / worldHeight.toDouble()) * constraints.maxHeight;
        final top = scaledY.clamp(0.0, maxTop);

        final bool followCam = cameraTarget == 'Oliver';
        final double viewCenterX = constraints.maxWidth / 2 - spriteSize / 2;
        final double maxScroll = math.max(0.0, worldWidth - constraints.maxWidth);
        final double cameraOffset = followCam
            ? (owlX - viewCenterX).clamp(0.0, maxScroll)
            : 0.0;
        final double displayLeft = followCam ? viewCenterX : owlX;

        return ClipRect(
          child: Stack(
            children: [
              // Background
              Positioned(
                left: -cameraOffset,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth + worldWidth,
                child: _StarryNightBackground(asset: background),
              ),
              // Oliver — no border in fullscreen
              if (owlVisible)
                AnimatedPositioned(
                  left: displayLeft,
                  top: top,
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.linear,
                  child: Opacity(
                    opacity: owlOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: owlScale,
                      child: Transform.rotate(
                        angle: (owlRotation * math.pi / 180) + (isRunning ? -.05 : -.16),
                        child: _OwlSpriteFrame(frame: owlFrame, height: spriteSize),
                      ),
                    ),
                  ),
                ),
              // Stage widget overlays
              for (int i = 0; i < stageWidgets.length; i++)
                if (stageWidgets[i].show)
                  if (stageWidgets[i].type == _GameWidgetType.dialog)
                    Positioned(
                      top: 18, left: 18, right: 18, bottom: 60,
                      child: Opacity(
                        opacity: stageWidgets[i].opacity.clamp(0.0, 1.0),
                        child: _StageWidgetOverlay(gameWidget: stageWidgets[i], isRunning: isRunning),
                      ),
                    )
                  else
                    Positioned(
                      top: 12.0 + i * 52,
                      left: 12,
                      child: Opacity(
                        opacity: stageWidgets[i].opacity.clamp(0.0, 1.0),
                        child: _StageWidgetOverlay(gameWidget: stageWidgets[i], isRunning: isRunning),
                      ),
                    ),
              // Exit fullscreen button
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onExit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({this.exerciseNumber = 1, this.onReferenceCardsTap});

  final int exerciseNumber;
  final VoidCallback? onReferenceCardsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 59,
      color: const Color.fromARGB(255, 252, 183, 199),
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
            child: const Text('', style: TextStyle(fontSize: 27)),
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
          Text(
            'AI IS A HOOT: EXERCISE #$exerciseNumber',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: .4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onReferenceCardsTap,
            child: Image.asset('assets/images/sprites/reference_cards.png',
                width: 30, height: 30,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.article, color: Colors.white, size: 26)),
          ),
          const SizedBox(width: 30),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7794),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: Image.asset('assets/images/sprites/00.png',
                width: 36, height: 36,
                errorBuilder: (_, __, ___) =>
                    const Text('🦉', style: TextStyle(fontSize: 25))),
          ),
          const SizedBox(width: 28),
          Image.asset('assets/images/sprites/btn_menu.png',
              width: 34, height: 34,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.menu, color: Color(0xFFFFBC1D), size: 34)),
        ],
      ),
    );
  }
}

// ─── Exercise / instruction data ────────────────────────────────────────────

enum _TileType { grass, dirt, brick, stone, sand }

class _PlacedTile {
  const _PlacedTile({required this.gridX, required this.gridY, required this.type});
  final int gridX;
  final int gridY;
  final _TileType type;

  @override
  bool operator ==(Object other) =>
      other is _PlacedTile && other.gridX == gridX && other.gridY == gridY;
  @override
  int get hashCode => Object.hash(gridX, gridY);
}

class _Bullet {
  const _Bullet(this.text, {this.sub = false, this.numbered = 0});
  final String text;
  final bool sub;      // sub-bullet (○)
  final int numbered;  // > 0 means numbered (1, 2, 3...)
}

class _ExerciseStep {
  const _ExerciseStep({
    required this.heading,
    required this.bullets,
    required this.validate,
    this.isRunStep = false,
    this.isStopStep = false,
    this.requiredAiClassName,
    this.aiClassIndex,
    this.autoCheck = false,
    this.validateSettings,
    this.validateTiles,
  });
  final String heading;
  final List<_Bullet> bullets;
  final bool Function(List<_WorkspaceEntry>) validate;
  final bool isRunStep;
  final bool isStopStep;
  final String? requiredAiClassName;
  final int? aiClassIndex;
  final bool autoCheck;
  final bool Function(int worldWidth, String cameraTarget)? validateSettings;
  final bool Function(List<_PlacedTile>)? validateTiles;
}

final List<_ExerciseStep> _exercise1Steps = [
  _ExerciseStep(
    heading: "Let's start with moving Oliver.",
    bullets: const [
      _Bullet('Drag a Step block from the Movement library'),
      _Bullet('Attach it to the On Run block', sub: true),
    ],
    validate: (entries) => entries.any((e) => e.block.label == 'Step'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Oliver barely moved! We will now make Oliver keep on moving.',
    bullets: const [
      _Bullet('Remove the Step block from the On Run block.', numbered: 1),
      _Bullet('Drag a Loop block from the Control library', numbered: 2),
      _Bullet('Attach it to the On Run block', sub: true),
      _Bullet('Drag a Step block from the Movement library', numbered: 3),
      _Bullet('Attach it inside the Loop block', sub: true),
    ],
    validate: (entries) =>
        entries.any((e) => e.block.label == 'Loop') &&
        entries.any((e) => e.block.label == 'Step'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN! and see what happens.',
    bullets: const [_Bullet('Does the owl stop? Why?', sub: true)],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise2Steps = [
  _ExerciseStep(
    heading: 'We will use an AI model.',
    bullets: const [
      _Bullet('Click on Add New Model in the AI - Pose tab'),
      _Bullet('You can name your model, making it simpler to locate it at a later time'),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Name the first class: raise hands.',
    bullets: const [
      _Bullet('Replace Class 1 with raise hands'),
    ],
    validate: (_) => false,
    requiredAiClassName: 'raise hands',
    aiClassIndex: 0,
  ),
  _ExerciseStep(
    heading: 'Record poses for the raise hands class by:',
    bullets: const [
      _Bullet('Click on Record', numbered: 1),
      _Bullet('Click on the timer icon', numbered: 2),
      _Bullet('Click to record', numbered: 3),
      _Bullet('The camera will start taking pictures in 5 seconds', sub: true),
      _Bullet('Raise your hands', numbered: 4),
      _Bullet('Make sure to move a little to take many versions of your pose', numbered: 5),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Name the second class: stand.',
    bullets: const [
      _Bullet('Replace Class 2 with stand'),
    ],
    validate: (_) => false,
    requiredAiClassName: 'stand',
    aiClassIndex: 1,
  ),
  _ExerciseStep(
    heading: 'Record poses for the stand class by:',
    bullets: const [
      _Bullet('Click on Record', numbered: 1),
      _Bullet('Click on the timer icon', numbered: 2),
      _Bullet('Click to record', numbered: 3),
      _Bullet('The camera will start taking pictures in 5 seconds', sub: true),
      _Bullet('Stand straight', numbered: 4),
      _Bullet('Make sure to move a little to take many versions of your pose', numbered: 5),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Now you are ready to train the model.',
    bullets: const [
      _Bullet('Click on Train Model'),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Test and save your model.',
    bullets: const [
      _Bullet('The model can now identify the two poses you recorded.'),
      _Bullet('Test it by posing raising hands and standing', numbered: 1),
      _Bullet('See that the percentage is above 95% for each pose', sub: true),
      _Bullet('Press Save', numbered: 2),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN! to test your AI model.',
    bullets: const [_Bullet('Does the owl respond to your pose?', sub: true)],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise3Steps = [
  _ExerciseStep(
    heading: 'Choose the AI model you created in the previous exercise by clicking on it.',
    bullets: const [],
    validate: (_) => false,
  ),
  _ExerciseStep(
    heading: 'Add the Webcam widget from the Widgets tab on the right.',
    bullets: const [
      _Bullet('Keep the default name webcam', sub: true),
      _Bullet('Drag the webcam to the upper area of the game', sub: true),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Click on the owl sprite to bring up its code.',
    bullets: const [
      _Bullet('Drag an On Prediction block from the AI library', numbered: 1),
      _Bullet('Change the dropdown to raise hands', sub: true),
    ],
    validate: (entries) => entries.any((e) => e.block.label == 'On Prediction'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Drag a Jump block from the Movement library.',
    bullets: const [
      _Bullet('Attach it inside the On Prediction block', sub: true),
    ],
    validate: (entries) => entries.any((e) => e.block.label == 'Jump'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [_Bullet('Make Oliver jump over the tiles', sub: true)],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise4Steps = [
  _ExerciseStep(
    heading: "Let's display the percentage.",
    bullets: const [
      _Bullet('Click on the owl sprite to bring up its code'),
      _Bullet('Drag an On Update block from the Events library', numbered: 1),
      _Bullet('This block runs every game frame (30-60 times/sec)', sub: true),
      _Bullet('Drag a Set text: block from the Widgets library', numbered: 2),
      _Bullet('Place it inside the On Update block', sub: true),
      _Bullet('Drag a Predict block from the AI library', numbered: 3),
      _Bullet('Attach it to the Set text: block', sub: true),
      _Bullet('Change the dropdown to raise hands', sub: true),
    ],
    validate: (entries) =>
        entries.any((e) => e.block.label == 'On Update') &&
        entries.any((e) => e.block.label == 'Set text:') &&
        entries.any((e) => e.block.label == 'Predict'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [
      _Bullet('Strike different poses and see that only when the prediction is 95% or higher Oliver jumps.', sub: true),
      _Bullet('Move Oliver all the way to the right', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise5Steps = [
  _ExerciseStep(
    heading: 'Go to the Game tab on the lower-right side of the screen.',
    bullets: const [
      _Bullet('Change world\'s width to', numbered: 1),
      _Bullet('3600', sub: true),
    ],
    validate: (_) => false,
    validateSettings: (w, _) => w == 3600,
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [
      _Bullet('Notice that Oliver disappears after walking across the screen', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
  _ExerciseStep(
    heading: 'Click on Stop.',
    bullets: const [],
    validate: (_) => false,
    isStopStep: true,
  ),
  _ExerciseStep(
    heading: 'We need to set the camera to follow Oliver:',
    bullets: const [
      _Bullet('Set the Camera target to', numbered: 1),
      _Bullet('Oliver', sub: true),
    ],
    validate: (_) => false,
    validateSettings: (_, t) => t == 'Oliver',
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [
      _Bullet('Check that now we follow Oliver as it moves', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise6Steps = [
  _ExerciseStep(
    heading: 'Add tiles to make the game more challenging:',
    bullets: const [
      _Bullet('Click on the paintbrush 🖌 to add tiles'),
      _Bullet('Click on the eraser 🧹 to delete tiles', sub: true),
    ],
    validate: (_) => false,
    validateTiles: (tiles) => tiles.isNotEmpty,
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Move the game to the right to add more tiles there:',
    bullets: const [
      _Bullet('Click on the drag icon ✛ to scroll and move around the game screen', numbered: 1),
      _Bullet('Click on the arrow icon to switch back', numbered: 2),
    ],
    validate: (_) => false,
    validateTiles: (tiles) => tiles.any((t) => t.gridX > 8),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [
      _Bullet('Make Oliver jump over the tiles you added', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise7Steps = [
  _ExerciseStep(
    heading: 'We will use the AI model again.',
    bullets: const [
      _Bullet('Click on Add New Model in the AI - Pose tab'),
      _Bullet('You can name your model, making it simpler to locate it at a later time'),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Name the first class: squat.',
    bullets: const [
      _Bullet('Replace Class 1 with squat'),
    ],
    validate: (_) => false,
    requiredAiClassName: 'squat',
    aiClassIndex: 0,
  ),
  _ExerciseStep(
    heading: 'Record poses for the squat class by:',
    bullets: const [
      _Bullet('Click on Record', numbered: 1),
      _Bullet('Click on the timer icon', numbered: 2),
      _Bullet('Click to record', numbered: 3),
      _Bullet('The camera will start taking pictures in 5 seconds', sub: true),
      _Bullet('Do the squat pose', numbered: 4),
      _Bullet('Make sure to move a little to take many versions of your pose', numbered: 5),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Name the second class: stand.',
    bullets: const [
      _Bullet('Replace Class 2 with stand'),
    ],
    validate: (_) => false,
    requiredAiClassName: 'stand',
    aiClassIndex: 1,
  ),
  _ExerciseStep(
    heading: 'Record the pose for stand class:',
    bullets: const [
      _Bullet('Click on Record', numbered: 1),
      _Bullet('Click on the timer icon', numbered: 2),
      _Bullet('Click to record', numbered: 3),
      _Bullet('The camera will start taking pictures in 5 seconds', sub: true),
      _Bullet('Stand straight', numbered: 4),
      _Bullet('Make sure to move a little to take many versions of your pose', numbered: 5),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Add a third class by clicking on Add Another Class.',
    bullets: const [
      _Bullet('Name it arms up'),
      _Bullet('Replace Class 3 with arms up', sub: true),
    ],
    validate: (_) => false,
    requiredAiClassName: 'arms up',
    aiClassIndex: 2,
  ),
  _ExerciseStep(
    heading: 'Record poses for the arms up class by:',
    bullets: const [
      _Bullet('Click on Record', numbered: 1),
      _Bullet('Click on the timer icon', numbered: 2),
      _Bullet('Click to record', numbered: 3),
      _Bullet('The camera will start taking pictures in 5 seconds', sub: true),
      _Bullet('Raise your arms up', numbered: 4),
      _Bullet('Make sure to move a little to take many versions of your pose', numbered: 5),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Click on Train Model.',
    bullets: const [],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'After training the model, the model can identify the three poses you have recorded.',
    bullets: const [
      _Bullet('Test your model by posing in the three different positions'),
      _Bullet('Once you are satisfied that the model recognizes the different poses, click on Save'),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Add this model to the game by clicking on it.',
    bullets: const [],
    validate: (_) => false,
  ),
];

final List<_ExerciseStep> _exercise8Steps = [
  _ExerciseStep(
    heading: '',
    bullets: const [
      _Bullet('Drag an On Prediction block', numbered: 1),
      _Bullet('Change the dropdown to arms up', sub: true),
      _Bullet('Drag a Jump block', numbered: 2),
      _Bullet('Place it inside the On Prediction block', sub: true),
    ],
    validate: (entries) {
      final hasArmsUp = entries.any((e) =>
          e.block.label == 'On Prediction' &&
          (e.editedValue?.toLowerCase() == 'arms up' ||
              e.block.value?.toLowerCase() == 'arms up'));
      final hasJump = entries.any((e) => e.block.label == 'Jump');
      return hasArmsUp && hasJump;
    },
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: '',
    bullets: const [
      _Bullet('Drag an On Prediction block', numbered: 1),
      _Bullet('Change the dropdown to squat', sub: true),
      _Bullet('Drag a Set Scale block', numbered: 2),
      _Bullet('Place it inside the On Prediction block', sub: true),
      _Bullet('Change the value from 1 to 0.5', sub: true),
    ],
    validate: (entries) {
      final hasSquat = entries.any((e) =>
          e.block.label == 'On Prediction' &&
          (e.editedValue?.toLowerCase() == 'squat' ||
              e.block.value?.toLowerCase() == 'squat'));
      final hasSetScale05 = entries.any((e) =>
          e.block.label == 'Set Scale' && e.editedValue == '0.5');
      return hasSquat && hasSetScale05;
    },
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: '',
    bullets: const [
      _Bullet('Drag an On Prediction block', numbered: 1),
      _Bullet('Change the dropdown to stand', sub: true),
      _Bullet('Drag a Set Scale block', numbered: 2),
      _Bullet('Place it inside the On Prediction block', sub: true),
    ],
    validate: (entries) {
      final hasStand = entries.any((e) =>
          e.block.label == 'On Prediction' &&
          (e.editedValue?.toLowerCase() == 'stand' ||
              e.block.value?.toLowerCase() == 'stand'));
      final hasSetScale = entries.where((e) => e.block.label == 'Set Scale').length >= 2;
      return hasStand && hasSetScale;
    },
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN!',
    bullets: const [
      _Bullet('Make sure Oliver can jump on or squat below the tile obstacles', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
];

final List<_ExerciseStep> _exercise9Steps = [
  _ExerciseStep(
    heading: 'Add a Clock widget from the Widgets tab.',
    bullets: const [
      _Bullet('Keep the default name clock'),
      _Bullet('Drag it to the upper left corner'),
    ],
    validate: (_) => true,
  ),
  _ExerciseStep(
    heading: 'Drag a Start clock block.',
    bullets: const [
      _Bullet('Connect it to the On Run block'),
    ],
    validate: (entries) => entries.any((e) => e.block.label == 'Start clock:'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Set the collision direction to Right.',
    bullets: const [
      _Bullet('Click on the owl sprite to bring up its code', numbered: 1),
      _Bullet('Find the On Collide With World Bounds block', numbered: 2),
      _Bullet('Change the dropdown value to Right', sub: true),
    ],
    validate: (entries) => entries.any((e) =>
        e.block.label == 'On Collide With World Bounds' &&
        (e.editedValue?.toLowerCase() == 'right' ||
            e.block.value?.toLowerCase() == 'right')),
    autoCheck: false,
  ),
  _ExerciseStep(
    heading: 'Drag a Pause Game block.',
    bullets: const [
      _Bullet('Place it inside the On Collide With World Bounds block'),
    ],
    validate: (entries) => entries.any((e) => e.block.label == 'Pause Game'),
    autoCheck: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN! to test your game.',
    bullets: const [
      _Bullet('See how fast you can get Oliver to the end of the course', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
  _ExerciseStep(
    heading: 'Click on RUN! again.',
    bullets: const [
      _Bullet('Try to complete the game faster', sub: true),
    ],
    validate: (_) => false,
    isRunStep: true,
  ),
];

List<_ExerciseStep> _stepsForExercise(int n) =>
    n == 9 ? _exercise9Steps :
    n == 8 ? _exercise8Steps :
    n == 7 ? _exercise7Steps :
    n == 6 ? _exercise6Steps :
    n == 5 ? _exercise5Steps :
    n == 4 ? _exercise4Steps :
    n == 3 ? _exercise3Steps :
    n == 2 ? _exercise2Steps : _exercise1Steps;

// ─── Lesson panel ────────────────────────────────────────────────────────────

class _LessonPanel extends StatefulWidget {
  const _LessonPanel({
    required this.workspaceEntries,
    required this.isRunning,
    required this.exerciseNumber,
    required this.exerciseSteps,
    required this.onNextExercise,
    required this.onPrevExercise,
    required this.onReset,
    this.aiClassNames = const [],
    this.modelSaved = false,
    this.modelSelected = false,
    this.worldWidth = 600,
    this.cameraTarget = 'None',
    this.onAllCompleted,
    this.placedTiles = const [],
  });
  final List<_WorkspaceEntry> workspaceEntries;
  final bool isRunning;
  final int exerciseNumber;
  final List<_ExerciseStep> exerciseSteps;
  final VoidCallback onNextExercise;
  final VoidCallback onPrevExercise;
  final VoidCallback onReset;
  final List<String> aiClassNames;
  final bool modelSaved;
  final bool modelSelected;
  final int worldWidth;
  final String cameraTarget;
  final VoidCallback? onAllCompleted;
  final List<_PlacedTile> placedTiles;

  @override
  State<_LessonPanel> createState() => _LessonPanelState();
}

class _LessonPanelState extends State<_LessonPanel> {
  int _completedSteps = 0;
  bool _showError = false;

  @override
  void didUpdateWidget(_LessonPanel old) {
    super.didUpdateWidget(old);
    // Auto-advance step 0 when a model is selected (exercise 3)
    if (!old.modelSelected && widget.modelSelected && _completedSteps == 0) {
      setState(() { _completedSteps = 1; _showError = false; });
      _checkAllComplete();
      return;
    }
    // Auto-complete all steps when model is saved
    if (!old.modelSaved && widget.modelSaved) {
      setState(() { _completedSteps = widget.exerciseSteps.length; _showError = false; });
      _checkAllComplete();
      return;
    }
    // Auto-advance run step
    if (!old.isRunning && widget.isRunning &&
        _completedSteps < widget.exerciseSteps.length &&
        widget.exerciseSteps[_completedSteps].isRunStep) {
      setState(() { _completedSteps++; _showError = false; });
      _checkAllComplete();
      return;
    }
    // Auto-advance stop step
    if (old.isRunning && !widget.isRunning &&
        _completedSteps < widget.exerciseSteps.length &&
        widget.exerciseSteps[_completedSteps].isStopStep) {
      setState(() { _completedSteps++; _showError = false; });
      _checkAllComplete();
      return;
    }
    // Auto-advance AI class name step when name matches
    _tryAutoAdvance();
    // Defer workspace-block auto-advance to post-frame so setState isn't
    // called during the widget update/build phase (avoids framework.dart:5340).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tryWorkspaceAutoAdvance();
    });
  }

  void _checkAllComplete() {
    if (_completedSteps >= widget.exerciseSteps.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onAllCompleted?.call();
      });
    }
  }

  void _tryAutoAdvance() {
    if (_completedSteps >= widget.exerciseSteps.length) return;
    final step = widget.exerciseSteps[_completedSteps];
    if (step.requiredAiClassName != null && step.aiClassIndex != null) {
      final idx = step.aiClassIndex!;
      if (widget.aiClassNames.length > idx &&
          widget.aiClassNames[idx].toLowerCase().trim() ==
              step.requiredAiClassName!.toLowerCase()) {
        setState(() { _completedSteps++; _showError = false; });
        _checkAllComplete();
      }
    }
    if (step.autoCheck == true && step.validateSettings != null) {
      if (step.validateSettings!(widget.worldWidth, widget.cameraTarget)) {
        setState(() { _completedSteps++; _showError = false; });
        _checkAllComplete();
      }
    }
    if (step.autoCheck == true && step.validateTiles != null) {
      if (step.validateTiles!(widget.placedTiles)) {
        setState(() { _completedSteps++; _showError = false; });
        _checkAllComplete();
      }
    }
  }

  void _tryWorkspaceAutoAdvance() {
    if (!mounted) return;
    if (_completedSteps >= widget.exerciseSteps.length) return;
    final step = widget.exerciseSteps[_completedSteps];
    // Use != true for null-safe bool check (dart2js can produce null for
    // bool fields on non-const objects that omit the optional parameter).
    if (step.autoCheck != true) return;
    if (step.validate(widget.workspaceEntries) != true) return;
    setState(() { _completedSteps++; _showError = false; });
    _checkAllComplete();
    _tryAutoAdvance();
    _tryWorkspaceAutoAdvance();
  }

  void _onCheck() {
    if (_completedSteps >= widget.exerciseSteps.length) return;
    final step = widget.exerciseSteps[_completedSteps];
    if (step.validate(widget.workspaceEntries) == true) {
      setState(() {
        _completedSteps++;
        _showError = false;
      });
      _checkAllComplete();
      _tryAutoAdvance();
      _tryWorkspaceAutoAdvance();
    } else {
      setState(() => _showError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // ── top nav bar ──
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFDDDDDD)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.exerciseNumber > 1 ? widget.onPrevExercise : null,
                          child: SizedBox(
                            width: 25,
                            child: Icon(
                              Icons.arrow_left,
                              color: widget.exerciseNumber > 1
                                  ? Colors.amber.shade600
                                  : Colors.amber.shade200,
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE4E4E4)),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Exercise ${widget.exerciseNumber} of 9',
                              style: const TextStyle(fontSize: 15, color: Color(0xFF203246)),
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Color(0xFF26A766), size: 18),
                        Container(width: 1, color: const Color(0xFFE4E4E4)),
                        GestureDetector(
                          onTap: widget.exerciseNumber < 9 ? widget.onNextExercise : null,
                          child: SizedBox(
                            width: 25,
                            child: Icon(
                              Icons.arrow_right,
                              color: widget.exerciseNumber < 9
                                  ? Colors.amber.shade600
                                  : Colors.amber.shade200,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const _SquareIconButton(icon: Icons.volume_up),
                const SizedBox(width: 8),
                _SquareIconButton(icon: Icons.cached, onPressed: widget.onReset),
              ],
            ),
          ),
          // ── scrollable body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.exerciseNumber == 9)
                    const _Exercise9OverviewContent()
                  else if (widget.exerciseNumber == 8)
                    const _Exercise8OverviewContent()
                  else if (widget.exerciseNumber == 7)
                    const _Exercise7OverviewContent()
                  else if (widget.exerciseNumber == 6)
                    const _Exercise6OverviewContent()
                  else if (widget.exerciseNumber == 5)
                    const _Exercise5OverviewContent()
                  else if (widget.exerciseNumber == 4)
                    const _Exercise4OverviewContent()
                  else if (widget.exerciseNumber == 3)
                    const _Exercise3OverviewContent()
                  else if (widget.exerciseNumber == 2)
                    const _Exercise2OverviewContent()
                  else
                    const _Exercise1OverviewContent(),
                  const SizedBox(height: 20),
                  // ── INSTRUCTIONS header ──
                  Row(
                    children: [
                      const Text('🚩', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Text(
                        'INSTRUCTIONS',
                        style: TextStyle(
                          color: Color(0xFF78AD50),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Container(height: 1.4, width: 60, color: const Color(0xFF78AD50)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── steps ──
                  for (int i = 0; i < widget.exerciseSteps.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _buildStep(i),
                  ],
                  // ── great job banner ──
                  if (_completedSteps >= widget.exerciseSteps.length && !widget.isRunning) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF9F1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF30A96A), width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 8),
                          const Text(
                            'Great Job!',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A6E3C),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You completed Exercise ${widget.exerciseNumber}!',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF1A6E3C)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: widget.onNextExercise,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF30A96A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 20),
                            label: const Text(
                              'NEXT',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int i) {
    final step = widget.exerciseSteps[i];
    final isDone = i < _completedSteps;
    final isActive = i == _completedSteps;

    if (isDone) {
      return _StepCard(
        bulletColor: const Color(0xFF30A96A),
        bulletIcon: Icons.check_circle,
        backgroundColor: const Color(0xFFEBF9F1),
        borderColor: const Color(0xFF30A96A),
        heading: step.heading,
        bullets: step.bullets,
        showBullets: true,
        headingStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A6E3C)),
        bulletStyle: const TextStyle(fontSize: 13, color: Color(0xFF1A6E3C)),
      );
    }

    if (isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepCard(
            bulletColor: const Color(0xFFF5B500),
            bulletIcon: Icons.star,
            backgroundColor: Colors.white,
            borderColor: const Color(0xFFF5B500),
            heading: step.heading,
            bullets: step.bullets,
            showBullets: true,
            headingStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A)),
            bulletStyle: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
          if (!step.isRunStep) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _onCheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF30A96A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('CHECK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                if (_showError) ...[
                  const SizedBox(width: 12),
                  const Flexible(child: Text(
                    'Not quite — check the workspace!',
                    style: TextStyle(color: Color(0xFFB94040), fontSize: 12.5),
                  )),
                ],
              ],
            ),
          ],
        ],
      );
    }

    // locked
    return _StepCard(
      bulletColor: const Color(0xFFBBBBBB),
      bulletIcon: Icons.star_outline,
      backgroundColor: const Color(0xFFF4F4F4),
      borderColor: const Color(0xFFDDDDDD),
      heading: step.heading,
      bullets: step.bullets,
      showBullets: false,
      headingStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFAAAAAA)),
      bulletStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.bulletColor,
    required this.bulletIcon,
    required this.backgroundColor,
    required this.borderColor,
    required this.heading,
    required this.bullets,
    required this.showBullets,
    required this.headingStyle,
    required this.bulletStyle,
  });

  final Color bulletColor;
  final IconData bulletIcon;
  final Color backgroundColor;
  final Color borderColor;
  final String heading;
  final List<_Bullet> bullets;
  final bool showBullets;
  final TextStyle headingStyle;
  final TextStyle bulletStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(bulletIcon, color: bulletColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: headingStyle),
                if (showBullets) ...[
                  const SizedBox(height: 8),
                  for (final b in bullets)
                    _BulletRow(bullet: b, style: bulletStyle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.bullet, required this.style});
  final _Bullet bullet;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final indent = bullet.sub ? 18.0 : 0.0;
    final prefix = bullet.numbered > 0
        ? '${bullet.numbered}. '
        : bullet.sub
            ? '○ '
            : '• ';
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 3),
      child: Text(prefix + bullet.text, style: style),
    );
  }
}

class _CodeExampleBox extends StatelessWidget {
  const _CodeExampleBox();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4A90D9), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScratchBlock(block: _ScratchBlockData.event('On Run')),
              _ScratchBlock(block: _ScratchBlockData.controlC('Loop')),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _ScratchBlock(block: _ScratchBlockData.movement('Step', value: '1')),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2665B5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'CODE EXAMPLE',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}


// ── Exercise overview content widgets ────────────────────────────────────────

class _Exercise1OverviewContent extends StatelessWidget {
  const _Exercise1OverviewContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          color: const Color(0xFFD9EEF8),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF50C47D), size: 23),
              SizedBox(width: 7),
              Text('Show my previous solution',
                  style: TextStyle(color: Color(0xFF2F75B5), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
            const SizedBox(width: 10),
            const Text('OVERVIEW',
                style: TextStyle(
                    color: Color(0xFF78AD50),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
          ],
        ),
        const SizedBox(height: 18),
        Builder(builder: (ctx) {
          return Row(
            children: [
              const Expanded(
                child: Text('Nice to Meet You, Oliver.',
                    style: TextStyle(
                        color: Color(0xFF101926),
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              const Text('Listen',
                  style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
              const SizedBox(width: 5),
              Icon(Icons.speaker_notes_outlined,
                  color: Colors.green.shade400),
            ],
          );
        }),
        const SizedBox(height: 12),
        const Text(
          "It's going to be an exciting night! We are going to learn\n"
          'how to build an AI-based game to move Oliver, the owl,\n'
          'between obstacles and get to the end of the route.\n\n'
          'The player will use different postures to change the size\n'
          'of the owl so it can go below or over tiles.\n'
          'This is the game you will create at the end of course:',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 12),
        Container(
          height: 220,
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
                top: 60,
                child: Container(
                  width: 70,
                  height: 74,
                  color: const Color(0xFFB24432),
                  child: CustomPaint(painter: _BrickPainter()),
                ),
              ),
              const Positioned(
                  right: 10, bottom: 6, child: _OwlSpriteFrame(frame: 0, height: 48)),
              const Positioned(
                  left: 18,
                  top: 70,
                  child: Text('00:32',
                      style: TextStyle(color: Colors.white, fontSize: 14))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
            children: [
              TextSpan(text: 'A '),
              WidgetSpan(child: _InlineCodeBlock('Loop')),
              TextSpan(
                  text: ' block repeats the blocks inside it over and over\nfor as long as the game runs.\n\n'),
              TextSpan(text: 'The '),
              WidgetSpan(child: _InlineCodeBlock('Step')),
              TextSpan(
                  text: ' block makes the Owl move.\n• The number in the step block defines how far the sprite moves.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _CodeExampleBox(),
      ],
    );
  }
}

class _Exercise2OverviewContent extends StatelessWidget {
  const _Exercise2OverviewContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          color: const Color(0xFFD9EEF8),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF50C47D), size: 23),
              SizedBox(width: 7),
              Text('Show my previous solution',
                  style: TextStyle(color: Color(0xFF2F75B5), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
            const SizedBox(width: 10),
            const Text('OVERVIEW',
                style: TextStyle(
                    color: Color(0xFF78AD50),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
          ],
        ),
        const SizedBox(height: 18),
        Builder(builder: (ctx) {
          return Row(
            children: [
              const Expanded(
                child: Text('AI to the Rescue',
                    style: TextStyle(
                        color: Color(0xFF101926),
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ),
              const Text('Listen',
                  style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
              const SizedBox(width: 5),
              Icon(Icons.speaker_notes_outlined,
                  color: Colors.green.shade400),
            ],
          );
        }),
        const SizedBox(height: 12),
        const Text(
          'In this exercise, we will create an AI model that will later be used to control the game.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 6),
        const _BulletRow(
          bullet: _Bullet('The AI model will identify gestures; also known as human poses.'),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 12),
        const Text(
          'We will use an application to train the AI model. We will train the AI model to differentiate between two different poses:',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 6),
        const _BulletRow(
          bullet: _Bullet('raising hands', numbered: 1),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const _BulletRow(
          bullet: _Bullet('standing straight', numbered: 2),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 20),
        const _DeepDiveBox(
          question: 'How do AI models learn?',
          shortText:
              'AI models learn by getting trained on datasets.\nA dataset is a big collection of data on a specific topic. The AI model is trained to recognize different poses. The dataset holds the positions of the different parts of the body.\nFor example, it can recognize if my arms are up or if I place my hands on my shoulders.',
          longText:
              '\n\nWe are recording the same pose many times in order to gather data for the dataset. Then, we train the AI model on our dataset. You should move a little when recording to get a wider coverage of the position. This will make your model recognize a posture better, and you won\'t have to stand in the exact same place as when you recorded it.',
        ),
      ],
    );
  }
}

class _Exercise3OverviewContent extends StatelessWidget {
  const _Exercise3OverviewContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          color: const Color(0xFFD9EEF8),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF50C47D), size: 23),
              SizedBox(width: 7),
              Text('Show my previous solution',
                  style: TextStyle(color: Color(0xFF2F75B5), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
            const SizedBox(width: 10),
            const Text('OVERVIEW',
                style: TextStyle(
                    color: Color(0xFF78AD50),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text('Add the Model',
                  style: TextStyle(
                      color: Color(0xFF101926),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            const Text('Listen',
                style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
            const SizedBox(width: 5),
            Icon(Icons.speaker_notes_outlined, color: Colors.green.shade400),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'After training the model, the model can identify two different poses:',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 6),
        const _BulletRow(
          bullet: _Bullet('raising hands', numbered: 1),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const _BulletRow(
          bullet: _Bullet('standing', numbered: 2),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Now, we will add the AI model to the game so that the owl can do different things for each pose.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
            children: [
              TextSpan(text: 'The AI model is used with the '),
              WidgetSpan(child: _InlineCodeBlock('On Prediction')),
              TextSpan(
                text: ' block. This is an event block that allows us to identify real-time events during the game. The event will identify the pose and perform the blocks inside it.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'When we raise our hands, the owl will jump. We will not make Oliver do something when we stand; it will continue to step.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 24),
        const _CodeExampleBox3(),
      ],
    );
  }
}

class _CodeExampleBox3 extends StatelessWidget {
  const _CodeExampleBox3();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4A90D9), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScratchBlock(block: _ScratchBlockData.event('On Run')),
              _ScratchBlock(block: _ScratchBlockData.controlC('Loop')),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _ScratchBlock(block: _ScratchBlockData.movement('Step', value: '1')),
              ),
              const SizedBox(height: 14),
              _ScratchBlock(block: _ScratchBlockData.aiC('On Prediction', value: 'raise hands')),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: _ScratchBlock(block: _ScratchBlockData.movement('Jump', value: '1')),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2665B5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'CODE EXAMPLE',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _Exercise4OverviewContent extends StatelessWidget {
  const _Exercise4OverviewContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          color: const Color(0xFFD9EEF8),
          alignment: Alignment.center,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Color(0xFF50C47D), size: 23),
              SizedBox(width: 7),
              Text('Show my previous solution',
                  style: TextStyle(color: Color(0xFF2F75B5), fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
            const SizedBox(width: 10),
            const Text('OVERVIEW',
                style: TextStyle(
                    color: Color(0xFF78AD50),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text("What's the Prediction?",
                  style: TextStyle(
                      color: Color(0xFF101926),
                      fontSize: 15,
                      fontWeight: FontWeight.w800)),
            ),
            const Text('Listen',
                style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
            const SizedBox(width: 5),
            Icon(Icons.speaker_notes_outlined, color: Colors.green.shade400),
          ],
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
            children: [
              TextSpan(text: 'The '),
              WidgetSpan(child: _InlineCodeBlock('Predict')),
              TextSpan(
                text: ' block returns the confidence percentage of your AI model for a given pose class. Use it inside ',
              ),
              WidgetSpan(child: _InlineCodeBlock('On Update')),
              TextSpan(
                text: ' to continuously display the prediction in a text widget on the stage.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'On Update runs every game frame (30–60 times per second), so the text widget will update in real time as you move.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 24),
        const _CodeExampleBox4(),
      ],
    );
  }
}

class _CodeExampleBox4 extends StatelessWidget {
  const _CodeExampleBox4();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4A90D9), width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ScratchBlock(block: _ScratchBlockData.eventC('On Update')),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ScratchBlock(
                        block: _ScratchBlockData.widgetBlock('Set text:', value: 'text', value2: 'To'),
                      ),
                      const SizedBox(width: 4),
                      _ScratchBlock(block: _ScratchBlockData.aiReporter('Predict', value: 'raise hands')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2665B5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'CODE EXAMPLE',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _Exercise5OverviewContent extends StatelessWidget {
  const _Exercise5OverviewContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
            const SizedBox(width: 10),
            const Text('OVERVIEW',
                style: TextStyle(
                    color: Color(0xFF78AD50),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2)),
            const Spacer(),
            Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Enlarge the World',
            style: TextStyle(color: Color(0xFF101926), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'In this exercise, we are going to enlarge the game area and set the camera to follow Oliver as it moves around the world.',
          style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 10),
        const Text('From the Game tab, you can change some of the game\'s properties. For example:',
            style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5)),
        const SizedBox(height: 6),
        _BulletRow(
          bullet: const _Bullet('World size'),
          style: const TextStyle(color: Color(0xFF2E2722), fontSize: 13),
        ),
        _BulletRow(
          bullet: const _Bullet('Camera target'),
          style: const TextStyle(color: Color(0xFF2E2722), fontSize: 13),
        ),
      ],
    );
  }
}

class _Exercise6OverviewContent extends StatelessWidget {
  const _Exercise6OverviewContent();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.gps_fixed, size: 34, color: Color(0xFF2E2722)),
          const SizedBox(width: 10),
          const Text('OVERVIEW', style: TextStyle(color: Color(0xFF78AD50), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Spacer(),
          Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
        ]),
        const SizedBox(height: 14),
        const Text("Let's Challenge with Obstacles",
            style: TextStyle(color: Color(0xFF101926), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          "When the game's world is bigger than the screen, use the drag icon ✛ (top right corner) to scroll beyond what is seen. Use the arrow icon to switch back.",
          style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 10),
        const Text("Let's see how we can add tiles:",
            style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, fontWeight: FontWeight.bold, height: 1.5)),
        const SizedBox(height: 6),
        const Text(
          "This is done by using the upper right icon menu where you can click on the paintbrush 🖌, choose a pattern and click on the game to add the tiles. You can always erase them.",
          style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 6),
        const Text("Let's see!", style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5)),
      ],
    );
  }
}

class _Exercise7OverviewContent extends StatelessWidget {
  const _Exercise7OverviewContent();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.psychology, size: 34, color: Color(0xFF2E2722)),
          const SizedBox(width: 10),
          const Text('OVERVIEW', style: TextStyle(color: Color(0xFF78AD50), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Spacer(),
          Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
        ]),
        const SizedBox(height: 14),
        const Text("Let's Build a New AI Model",
            style: TextStyle(color: Color(0xFF101926), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'We have a model that can identify two human poses.',
          style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'This exercise is about building a new model that can identify three different poses - squat, stand, and arms up.',
          style: TextStyle(color: Color(0xFF2E2722), fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        const _DeepDiveBox(
          question: 'We have mentioned models and classes, but what do they mean?',
          shortText:
              'Models can be thought of as programs that learn from data. The learning is done in the training process. The models analyze and categorize data, and then use that information to make predictions. For example, we can train a model to recognize images of dogs. Then, it will predict if an image is a dog.',
          longText:
              '\n\nClasses represent categories of data. It\'s a way for the computer to know which things are similar. The model organizes its data into the classes during the training. For example, if you have two classes: "cats" and "dogs", the model\'s job is to decide if an image is a cat or a dog.',
        ),
      ],
    );
  }
}

class _Exercise9OverviewContent extends StatelessWidget {
  const _Exercise9OverviewContent();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
          const SizedBox(width: 10),
          const Text('OVERVIEW', style: TextStyle(color: Color(0xFF78AD50), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Spacer(),
          Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
        ]),
        const SizedBox(height: 18),
        Builder(builder: (ctx) {
          return Row(children: [
            const Expanded(
              child: Text('How fast are You?',
                  style: TextStyle(color: Color(0xFF101926), fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const Text('Listen', style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
            const SizedBox(width: 5),
            Icon(Icons.speaker_notes_outlined, color: Colors.green.shade400),
          ]);
        }),
        const SizedBox(height: 12),
        const Text(
          "Let's time how many seconds it takes Oliver to get to the end of the game.",
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will use the Clock widget to time the seconds.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 8),
        const Text(
          'We will add another event that detects a collision with the world boundary and pause the game.',
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 18),
        // CODE EXAMPLE
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4A90D9), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScratchBlock(block: _ScratchBlockData.eventC('On Collide With World Bounds', value: 'Right')),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _ScratchBlock(block: _ScratchBlockData.game('Pause Game')),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12, top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2665B5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CODE EXAMPLE',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Exercise8OverviewContent extends StatelessWidget {
  const _Exercise8OverviewContent();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.track_changes, size: 34, color: Color(0xFF2E2722)),
          const SizedBox(width: 10),
          const Text('OVERVIEW', style: TextStyle(color: Color(0xFF78AD50), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Spacer(),
          Container(height: 1.4, width: 100, color: const Color(0xFF78AD50)),
        ]),
        const SizedBox(height: 18),
        Builder(builder: (ctx) {
          return Row(children: [
            const Expanded(
              child: Text('AI Comes to Life',
                  style: TextStyle(color: Color(0xFF101926), fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            const Text('Listen', style: TextStyle(color: Color(0xFF34B772), fontSize: 15)),
            const SizedBox(width: 5),
            Icon(Icons.speaker_notes_outlined, color: Colors.green.shade400),
          ]);
        }),
        const SizedBox(height: 12),
        const Text(
          "Let's play with the new AI model you've created. We'll make Oliver jump, shrink, or grow based on the poses we created.",
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 8),
        const Text(
          "When you squat, we will change Oliver's scale to 0.5, and when you stand, we will set it to 1.",
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 4),
        const _BulletRow(
          bullet: _Bullet('Use the Set Scale block for this'),
          style: TextStyle(fontSize: 15, height: 1.42, color: Color(0xFF0D1B2A)),
        ),
        const SizedBox(height: 18),
        // CODE EXAMPLE
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF4A90D9), width: 1.4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScratchBlock(block: _ScratchBlockData.event('On Run')),
                  _ScratchBlock(block: _ScratchBlockData.controlC('Loop')),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _ScratchBlock(block: _ScratchBlockData.movement('Step', value: '1')),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScratchBlock(block: _ScratchBlockData.aiC('On Prediction', value: 'stand')),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: _ScratchBlock(block: _ScratchBlockData.display('Set Scale', value: '1')),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScratchBlock(block: _ScratchBlockData.aiC('On Prediction', value: 'raise hands')),
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: _ScratchBlock(block: _ScratchBlockData.display('Set Scale', value: '0.5')),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ScratchBlock(block: _ScratchBlockData.aiC('On Prediction', value: 'raise hands')),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _ScratchBlock(block: _ScratchBlockData.movement('Jump', value: '1')),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12, top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2665B5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CODE EXAMPLE',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DeepDiveBox extends StatefulWidget {
  const _DeepDiveBox({
    required this.question,
    required this.shortText,
    required this.longText,
  });

  final String question;
  final String shortText;
  final String longText;

  @override
  State<_DeepDiveBox> createState() => _DeepDiveBoxState();
}

class _DeepDiveBoxState extends State<_DeepDiveBox> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00AABB), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── teal header with chevron notch ──
          ClipPath(
            clipper: _ChevronClipper(),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF00AABB),
              padding: const EdgeInsets.fromLTRB(14, 10, 40, 10),
              child: const Text(
                'DEEP DIVE',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2),
              ),
            ),
          ),
          // ── content ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.question,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 10),
                Text(
                  _expanded
                      ? widget.shortText + widget.longText
                      : widget.shortText,
                  style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Color(0xFF444444)),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'Read Less' : 'Read More',
                    style: const TextStyle(
                        color: Color(0xFF00AABB),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
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

class _ChevronClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchW = 22.0;
    const notchH = 18.0;
    final mid = size.height / 2;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - notchW, 0)
      ..lineTo(size.width, mid)
      ..lineTo(size.width - notchW, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

// ── AI Model dialog ──────────────────────────────────────────────────────────

enum _TrainingState { idle, training, done }

class _AiModelClass {
  _AiModelClass(this.name);
  String name;
  bool collapsed = false;
}

class _NewAiModelDialog extends StatefulWidget {
  const _NewAiModelDialog({this.onClassNamesChanged, this.onClose, this.onSaved});
  final ValueChanged<List<String>>? onClassNamesChanged;
  final VoidCallback? onClose;
  final ValueChanged<_SavedAiModel>? onSaved;

  @override
  State<_NewAiModelDialog> createState() => _NewAiModelDialogState();
}

class _NewAiModelDialogState extends State<_NewAiModelDialog> {
  final _nameCtrl = TextEditingController();
  final List<_AiModelClass> _classes = [
    _AiModelClass('Class 1'),
    _AiModelClass('Class 2'),
  ];

  final Map<int, int> _sampleCounts = {};
  _TrainingState _trainingState = _TrainingState.idle;
  double _trainingProgress = 0.0;
  Timer? _progressTimer;

  bool get _canTrain {
    for (int i = 0; i < _classes.length; i++) {
      if ((_sampleCounts[i] ?? 0) == 0) return false;
    }
    return _classes.isNotEmpty;
  }

  void _trainModel() {
    if (!_canTrain) return;
    setState(() {
      _trainingState = _TrainingState.training;
      _trainingProgress = 0.0;
    });
    if (kIsWeb) {
      js.context.callMethod('trainPoseModel', [_classes.length]);
      _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
        if (!mounted) { t.cancel(); return; }
        final prog = (js.context.callMethod('getTrainingProgress', []) as num).toDouble();
        setState(() => _trainingProgress = prog);
        if (prog >= 1.0) {
          t.cancel();
          setState(() => _trainingState = _TrainingState.done);
        }
      });
    } else {
      // Non-web: simulate 1.5s training
      _progressTimer = Timer.periodic(const Duration(milliseconds: 30), (t) {
        if (!mounted) { t.cancel(); return; }
        final next = _trainingProgress + (1 / 50);
        setState(() => _trainingProgress = next.clamp(0.0, 1.0));
        if (next >= 1.0) {
          t.cancel();
          setState(() => _trainingState = _TrainingState.done);
        }
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 960,
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(fontFamily: 'Chennai'),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'NEW AI MODEL - POSE',
                      style: TextStyle(
                        fontFamily: 'Chennai',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3DBE7A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 22, color: Color(0xFF666666)),
                    onPressed: () => widget.onClose?.call(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3DBE7A), thickness: 1.4, indent: 24, endIndent: 24, height: 14),
            // ── model name field ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'give your model a name',
                          hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.edit, color: Color(0xFF3DBE7A), size: 20),
                    ),
                  ],
                ),
              ),
            ),
            // ── scrollable content ──
            Flexible(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // left: class list
                        SizedBox(
                          width: 560,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < _classes.length; i++) ...[
                                _AiModelClassCard(
                                  aiClass: _classes[i],
                                  classIndex: i,
                                  onDelete: () {
                                    if (kIsWeb) js.context.callMethod('clearPoseSamples', [i]);
                                    setState(() {
                                      _classes.removeAt(i);
                                      _sampleCounts.remove(i);
                                      _trainingState = _TrainingState.idle;
                                    });
                                  },
                                  onToggle: () => setState(() => _classes[i].collapsed = !_classes[i].collapsed),
                                  onNameChanged: (v) {
                                    setState(() => _classes[i].name = v);
                                    widget.onClassNamesChanged?.call(_classes.map((c) => c.name).toList());
                                  },
                                  onSampleCountChanged: (count) {
                                    setState(() {
                                      _sampleCounts[i] = count;
                                      if (_trainingState == _TrainingState.done) {
                                        _trainingState = _TrainingState.idle;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                              // dashed add class button
                              CustomPaint(
                                painter: _DashedBorderPainter(color: const Color(0xFF3DBE7A), strokeWidth: 1.5, dash: 7, gap: 5, radius: 8),
                                child: GestureDetector(
                                  onTap: () => setState(() => _classes.add(_AiModelClass('Class ${_classes.length + 1}'))),
                                  child: Container(
                                    width: 560,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Color(0xFF3DBE7A), size: 20),
                                        SizedBox(width: 6),
                                        Text(
                                          'ADD ANOTHER CLASS',
                                          style: TextStyle(
                                            color: Color(0xFF3DBE7A),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // arrow + TRAINING + arrow + PREVIEW (vertically centered)
                        Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _AiArrow(),
                              const SizedBox(width: 16),
                              _TrainingPanel(
                                canTrain: _canTrain,
                                isTraining: _trainingState == _TrainingState.training,
                                isDone: _trainingState == _TrainingState.done,
                                progress: _trainingProgress,
                                onTrain: _trainModel,
                              ),
                              const SizedBox(width: 16),
                              const _AiArrow(),
                              const SizedBox(width: 16),
                              _PreviewSavePanel(
                                isDone: _trainingState == _TrainingState.done,
                                classNames: _classes.map((c) => c.name).toList(),
                                onSaved: widget.onSaved == null ? null : () {
                                  widget.onSaved!(_SavedAiModel(
                                    name: _nameCtrl.text.isEmpty ? 'My Model' : _nameCtrl.text,
                                    classNames: _classes.map((c) => c.name).toList(),
                                  ));
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _AiModelClassCard extends StatefulWidget {
  const _AiModelClassCard({
    required this.aiClass,
    required this.classIndex,
    required this.onDelete,
    required this.onToggle,
    required this.onNameChanged,
    this.onSampleCountChanged,
  });

  final _AiModelClass aiClass;
  final int classIndex;
  final VoidCallback onDelete;
  final VoidCallback onToggle;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<int>? onSampleCountChanged;

  @override
  State<_AiModelClassCard> createState() => _AiModelClassCardState();
}

class _AiModelClassCardState extends State<_AiModelClassCard> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  // Camera state
  bool _showCamera = false;
  bool _holdMode = true;
  html.MediaStream? _stream;
  html.VideoElement? _videoEl;
  html.CanvasElement? _poseCanvasEl;
  html.CanvasElement? _captureCanvas;
  late final String _viewId;
  bool _viewRegistered = false;

  // Recording state
  bool _isRecording = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  Timer? _captureTimer;
  Timer? _autoStopTimer;

  bool _detectorReady = false;
  Timer? _detectorCheckTimer;

  // Samples
  final List<String> _sampleUrls = [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.aiClass.name);
    _viewId = 'cam-${identityHashCode(this)}';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _captureTimer?.cancel();
    _autoStopTimer?.cancel();
    _detectorCheckTimer?.cancel();
    if (kIsWeb) js.context.callMethod('stopPoseDraw', []);
    _stream?.getTracks().forEach((t) => t.stop());
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!kIsWeb) {
      setState(() { _showCamera = true; _detectorReady = true; });
      return;
    }
    if (!_viewRegistered) {
      _viewRegistered = true;
      _videoEl = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      _poseCanvasEl = html.CanvasElement()
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';

      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(_videoEl!)
        ..append(_poseCanvasEl!);

      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => container);
    }
    try {
      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      _videoEl!.srcObject = _stream;
      js.context.callMethod('startPoseDraw', [_videoEl, _poseCanvasEl]);
      // Poll until the pose detector model is loaded (async JS, takes a few seconds)
      _detectorCheckTimer?.cancel();
      _detectorCheckTimer = Timer.periodic(const Duration(milliseconds: 400), (t) {
        if (!mounted) { t.cancel(); return; }
        if (js.context['_poseDetector'] != null) {
          t.cancel();
          setState(() => _detectorReady = true);
        }
      });
    } catch (_) {}
    if (mounted) setState(() => _showCamera = true);
  }

  // Start 5-second countdown then auto-record
  void _startCountdown() {
    if (_isRecording || _countdown > 0) return;
    setState(() => _countdown = 5);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown <= 1) {
        t.cancel();
        setState(() => _countdown = 0);
        _beginCapture();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _beginCapture() {
    if (_isRecording) return;
    _captureCanvas ??= html.CanvasElement(width: 224, height: 224);
    setState(() => _isRecording = true);
    _captureTimer = Timer.periodic(const Duration(milliseconds: 80), (_) => _captureFrame());
    _autoStopTimer = Timer(const Duration(seconds: 3), _stopCapture);
  }

  void _stopCapture() {
    _captureTimer?.cancel();
    _captureTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (mounted) setState(() => _isRecording = false);
  }

  void _captureFrame() {
    if (!kIsWeb || _videoEl == null || !mounted) return;
    _captureCanvas ??= html.CanvasElement(width: 224, height: 224);
    final ctx = _captureCanvas!.context2D;
    ctx.drawImageScaled(_videoEl!, 0, 0, 224, 224);
    if (_poseCanvasEl != null &&
        (_poseCanvasEl!.width ?? 0) > 0 &&
        (_poseCanvasEl!.height ?? 0) > 0) {
      ctx.drawImageScaled(_poseCanvasEl!, 0, 0, 224, 224);
    }
    js.context.callMethod('addPoseSample', [widget.classIndex]);
    final url = _captureCanvas!.toDataUrl('image/jpeg', 0.7);
    // Update local state first, then notify parent outside setState to avoid
    // triggering parent markNeedsBuild while child setState is still executing.
    setState(() => _sampleUrls.add(url));
    widget.onSampleCountChanged?.call(_sampleUrls.length);
  }

  @override
  Widget build(BuildContext context) {
    final sampleCount = _sampleUrls.length;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          autofocus: true,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                          onChanged: (v) => widget.onNameChanged(v),
                          onSubmitted: (v) { widget.onNameChanged(v.isEmpty ? widget.aiClass.name : v); setState(() => _editing = false); },
                        )
                      : Text(
                          widget.aiClass.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                        ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 19, color: Color(0xFF3DBE7A)), onPressed: () => setState(() => _editing = !_editing), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 19, color: Color(0xFF3DBE7A)), onPressed: widget.onDelete, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
                IconButton(icon: Icon(widget.aiClass.collapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 21, color: const Color(0xFF3DBE7A)), onPressed: widget.onToggle, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30)),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3DBE7A), thickness: 1.1, indent: 16, endIndent: 16, height: 14),
          if (!widget.aiClass.collapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sample counter row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sampleCount == 0 ? 'Add Samples' : '$sampleCount Samples',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                        ),
                      ),
                      if (sampleCount > 0)
                        GestureDetector(
                          onTap: () {
                            if (kIsWeb) js.context.callMethod('clearPoseSamples', [widget.classIndex]);
                            setState(() => _sampleUrls.clear());
                            widget.onSampleCountChanged?.call(0);
                          },
                          child: const Text(
                            'Remove All Samples',
                            style: TextStyle(fontSize: 12, color: Color(0xFF2196F3)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_showCamera) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live camera preview with countdown overlay
                        Expanded(
                          flex: 7,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 220,
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: kIsWeb
                                    ? HtmlElementView(viewType: _viewId)
                                    : const Center(child: Icon(Icons.videocam_rounded, size: 60, color: Colors.white54)),
                              ),
                              if (!_detectorReady)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 28, height: 28,
                                          child: CircularProgressIndicator(color: Color(0xFF3DBE7A), strokeWidth: 3),
                                        ),
                                        SizedBox(height: 8),
                                        Text('Loading AI model...', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_detectorReady && _countdown > 0)
                                Text(
                                  '$_countdown',
                                  style: const TextStyle(
                                    fontSize: 90,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [Shadow(blurRadius: 16, color: Colors.black)],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Thumbnail grid
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 220,
                            clipBehavior: Clip.hardEdge,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: sampleCount == 0
                                ? null
                                : GridView.builder(
                                    padding: const EdgeInsets.all(3),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 2,
                                      mainAxisSpacing: 2,
                                    ),
                                    itemCount: sampleCount,
                                    itemBuilder: (_, i) => Image.network(
                                      _sampleUrls[i],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // HOLD TO RECORD / CLICK TO RECORD / RECORDING
                        Expanded(
                          child: GestureDetector(
                            onTap: (!_detectorReady || _holdMode)
                                ? null
                                : () { if (!_isRecording && _countdown == 0) _beginCapture(); },
                            onLongPressStart: (!_detectorReady || !_holdMode)
                                ? null
                                : (_) { if (!_isRecording && _countdown == 0) _beginCapture(); },
                            onLongPressEnd: (!_detectorReady || !_holdMode) ? null : (_) => _stopCapture(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _isRecording
                                    ? const Color(0xFFBDA32A)
                                    : const Color(0xFFFFCC00),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Center(
                                child: Text(
                                  _isRecording
                                      ? 'RECORDING....'
                                      : (_holdMode ? 'HOLD TO RECORD' : 'CLICK TO RECORD'),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Timer icon: starts 5s countdown then auto-records
                        GestureDetector(
                          onTap: _detectorReady ? _startCountdown : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: !_detectorReady
                                  ? const Color(0xFFCCCCCC)
                                  : _countdown > 0
                                      ? const Color(0xFFBDA32A)
                                      : const Color(0xFF3DBE7A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: _startCamera,
                      child: Container(
                        width: 68,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3DBE7A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 5),
                            const Text('RECORD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AiArrow extends StatelessWidget {
  const _AiArrow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 64,
      child: Image.asset(
        CodeMonkeyScratchAssets.arrowRight,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => CustomPaint(
          size: const Size(88, 64),
          painter: _ArrowPainter(),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFA8D490)..style = PaintingStyle.fill;
    final w = size.width; final h = size.height; final my = h / 2;
    canvas.drawPath(Path()
      ..moveTo(0, my - 7)
      ..lineTo(w * 0.62, my - 7)
      ..lineTo(w * 0.62, my - 18)
      ..lineTo(w, my)
      ..lineTo(w * 0.62, my + 18)
      ..lineTo(w * 0.62, my + 7)
      ..lineTo(0, my + 7)
      ..close(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _TrainingPanel extends StatelessWidget {
  const _TrainingPanel({
    required this.canTrain,
    required this.isTraining,
    required this.isDone,
    required this.progress,
    required this.onTrain,
  });

  final bool canTrain;
  final bool isTraining;
  final bool isDone;
  final double progress;
  final VoidCallback onTrain;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('TRAINING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3DBE7A), letterSpacing: 0.7)),
          const Divider(color: Color(0xFF3DBE7A), thickness: 1.2, height: 14),
          if (isDone)
            const Text('Training complete!', style: TextStyle(fontSize: 13, color: Color(0xFF3DBE7A), height: 1.5, fontWeight: FontWeight.w700))
          else if (isTraining) ...[
            const Text('Training...', style: TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.5)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF3DBE7A),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ] else
            Text(
              canTrain ? 'Click Train Model to begin!' : 'first add samples to all classes',
              style: const TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.5),
            ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: (canTrain && !isTraining && !isDone) ? onTrain : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF3DBE7A)
                      : (canTrain && !isTraining)
                          ? const Color(0xFFFFCC00)
                          : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  isDone ? 'TRAINED!' : 'TRAIN MODEL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? Colors.white
                        : (canTrain && !isTraining)
                            ? Colors.black
                            : const Color(0xFFAAAAAA),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewSavePanel extends StatefulWidget {
  const _PreviewSavePanel({
    required this.isDone,
    required this.classNames,
    this.onSaved,
  });

  final bool isDone;
  final List<String> classNames;
  final VoidCallback? onSaved;

  @override
  State<_PreviewSavePanel> createState() => _PreviewSavePanelState();
}

class _PreviewSavePanelState extends State<_PreviewSavePanel> {
  html.MediaStream? _stream;
  html.VideoElement? _videoEl;
  html.CanvasElement? _poseCanvasEl;
  late final String _viewId;
  bool _viewRegistered = false;
  bool _cameraStarted = false;
  bool _saved = false;

  Timer? _predTimer;
  List<double> _confidences = [];

  @override
  void initState() {
    super.initState();
    _viewId = 'preview-${identityHashCode(this)}';
    if (widget.isDone) _startPreviewCamera();
  }

  @override
  void didUpdateWidget(_PreviewSavePanel old) {
    super.didUpdateWidget(old);
    if (!old.isDone && widget.isDone) _startPreviewCamera();
  }

  @override
  void dispose() {
    _predTimer?.cancel();
    if (kIsWeb) js.context.callMethod('stopPreviewPose', []);
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }

  Future<void> _startPreviewCamera() async {
    if (!kIsWeb || _cameraStarted) return;
    if (!_viewRegistered) {
      _viewRegistered = true;
      _videoEl = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      _poseCanvasEl = html.CanvasElement()
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';
      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(_videoEl!)
        ..append(_poseCanvasEl!);
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => container);
    }
    try {
      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      _videoEl!.srcObject = _stream;
      js.context.callMethod('startPreviewPose', [_videoEl, _poseCanvasEl]);
      _cameraStarted = true;
      _predTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        final predRaw = js.context.callMethod('getLastPrediction', []);
        if (predRaw != null) {
          final parsed = _parsePrediction(predRaw);
          if (parsed.isNotEmpty) setState(() => _confidences = parsed);
        }
      });
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isDone) {
      return Container(
        width: 210,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PREVIEW AND SAVE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3DBE7A), letterSpacing: 0.7)),
            const Divider(color: Color(0xFF3DBE7A), thickness: 1.2, height: 14),
            const Text('you must train the model in order to view it', style: TextStyle(fontSize: 13, color: Color(0xFF444444), height: 1.5)),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(24)),
                child: const Text('SAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFAAAAAA), letterSpacing: 0.3)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 210,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('PREVIEW AND SAVE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF3DBE7A), letterSpacing: 0.7)),
          const Divider(color: Color(0xFF3DBE7A), thickness: 1.2, height: 14),
          Container(
            height: 150,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: kIsWeb && _cameraStarted
                ? HtmlElementView(viewType: _viewId)
                : const Center(child: Icon(Icons.videocam_rounded, size: 40, color: Colors.white54)),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < widget.classNames.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.classNames[i],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  i < _confidences.length ? '${(_confidences[i] * 100).round()}%' : '0%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: i < _confidences.length ? _confidences[i] : 0.0,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF3DBE7A),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: _saved ? null : () {
                setState(() => _saved = true);
                widget.onSaved?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                decoration: BoxDecoration(
                  color: _saved ? const Color(0xFF3DBE7A) : const Color(0xFFFFCC00),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _saved ? 'SAVED!' : 'SAVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _saved ? Colors.white : Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Saved model card shown in the AI-Pose tab ────────────────────────────────

class _SavedModelCard extends StatelessWidget {
  const _SavedModelCard({required this.model, required this.onGiveItATry, this.onSelect, this.selected = false});

  final _SavedAiModel model;
  final VoidCallback onGiveItATry;
  final VoidCallback? onSelect;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? const Color(0xFF3DBE7A) : const Color(0xFFDDDDDD);
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: selected ? const Color(0xFFEEF9F3) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(selected ? Icons.check_circle : Icons.model_training, size: 20, color: const Color(0xFF3DBE7A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    model.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final cls in model.classNames)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF9F3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF3DBE7A)),
                    ),
                    child: Text(cls, style: const TextStyle(fontSize: 11, color: Color(0xFF3DBE7A), fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onGiveItATry,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DBE7A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Give It A Try',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live camera + confidence panel for "Give It A Try" ───────────────────────

class _GiveItATryPanel extends StatefulWidget {
  const _GiveItATryPanel({required this.model, required this.onClose});

  final _SavedAiModel model;
  final VoidCallback onClose;

  @override
  State<_GiveItATryPanel> createState() => _GiveItATryPanelState();
}

class _GiveItATryPanelState extends State<_GiveItATryPanel> {
  html.MediaStream? _stream;
  html.VideoElement? _videoEl;
  html.CanvasElement? _canvasEl;
  late final String _viewId;
  bool _viewRegistered = false;
  bool _cameraStarted = false;

  Timer? _predTimer;
  List<double> _confidences = [];

  @override
  void initState() {
    super.initState();
    _viewId = 'give-it-a-try-${identityHashCode(this)}';
    _startCamera();
  }

  @override
  void dispose() {
    _predTimer?.cancel();
    if (kIsWeb) js.context.callMethod('stopPreviewPose', []);
    _stream?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!kIsWeb || _cameraStarted) return;
    if (!_viewRegistered) {
      _viewRegistered = true;
      _videoEl = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      _canvasEl = html.CanvasElement()
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';
      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(_videoEl!)
        ..append(_canvasEl!);
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => container);
    }
    try {
      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      _videoEl!.srcObject = _stream;
      js.context.callMethod('startPreviewPose', [_videoEl, _canvasEl]);
      _cameraStarted = true;
      _predTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted) return;
        final predRaw = js.context.callMethod('getLastPrediction', []);
        if (predRaw != null) {
          final parsed = _parsePrediction(predRaw);
          if (parsed.isNotEmpty) setState(() => _confidences = parsed);
        }
      });
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.model.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF222222)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: Color(0xFFEEEEEE), shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF555555)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: kIsWeb && _cameraStarted
                ? HtmlElementView(viewType: _viewId)
                : const Center(child: Icon(Icons.videocam_rounded, size: 44, color: Colors.white54)),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < widget.model.classNames.length; i++) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.model.classNames[i],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  i < _confidences.length ? '${(_confidences[i] * 100).round()}%' : '0%',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: i < _confidences.length ? _confidences[i] : 0.0,
                backgroundColor: const Color(0xFFE0E0E0),
                color: const Color(0xFF3DBE7A),
                minHeight: 11,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StarryNightBackground extends StatelessWidget {
  const _StarryNightBackground({this.compact = false, this.asset});
  final bool compact;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final path = asset ?? CodeMonkeyScratchAssets.starryNight;
    final isNetwork = path.startsWith('blob:') ||
        path.startsWith('http:') ||
        path.startsWith('https:') ||
        path.startsWith('data:');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.none,
        repeat: ImageRepeat.repeat,
        alignment: Alignment.topLeft,
        errorBuilder: (_, __, ___) =>
            CustomPaint(painter: _StarFieldPainter(compact: compact)),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.none,
      repeat: ImageRepeat.repeat,
      alignment: Alignment.topLeft,
      errorBuilder: (_, __, ___) =>
          CustomPaint(painter: _StarFieldPainter(compact: compact)),
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
  const _SquareIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 51,
        height: 51,
        decoration: BoxDecoration(
          color: const Color(0xFFF5B719),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(offset: Offset(0, 3), color: Color(0xFFCF9212))],
        ),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
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

class _BlocksWorkspace extends StatefulWidget {
  const _BlocksWorkspace({
    required this.selectedCategory,
    required this.paletteOpen,
    required this.categories,
    required this.paletteBlocks,
    required this.workspaceEntries,
    required this.isRunning,
    required this.activeObjectName,
    this.activeObjectAsset,
    required this.onRun,
    required this.onStop,
    required this.onClear,
    required this.onSelectCategory,
    required this.onAddBlock,
    required this.onRemoveBlock,
    this.aiClassNames = const [],
    this.textWidgetNames = const [],
    this.clockWidgetNames = const [],
  });

  final String selectedCategory;
  final bool paletteOpen;
  final List<String> categories;
  final List<_ScratchBlockData> paletteBlocks;
  final List<_WorkspaceEntry> workspaceEntries;
  final bool isRunning;
  final String activeObjectName;
  final String? activeObjectAsset;
  final VoidCallback onRun;
  final VoidCallback onStop;
  final VoidCallback onClear;
  final ValueChanged<String> onSelectCategory;
  final Function(_ScratchBlockData, Offset) onAddBlock;
  final ValueChanged<int> onRemoveBlock;
  final List<String> aiClassNames;
  final List<String> textWidgetNames;
  final List<String> clockWidgetNames;

  @override
  State<_BlocksWorkspace> createState() => _BlocksWorkspaceState();
}

class _BlocksWorkspaceState extends State<_BlocksWorkspace> {
  final _canvasKey = GlobalKey();

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
                widget.activeObjectAsset != null
                    ? Image.asset(widget.activeObjectAsset!, height: 42, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.widgets, size: 36))
                    : const _OwlSpriteFrame(frame: 0, height: 42),
                const SizedBox(width: 10),
                Text(widget.activeObjectName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1C2530))),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: widget.isRunning ? widget.onStop : widget.onRun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isRunning ? const Color(0xFFE05252) : const Color(0xFF46C77E),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19),
                  ),
                  icon: Icon(widget.isRunning ? Icons.stop_circle_outlined : Icons.play_circle_fill, size: 31),
                  label: Text(widget.isRunning ? 'STOP' : 'RUN!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Expanded(
            child: DragTarget<_ScratchBlockData>(
              onAcceptWithDetails: (details) {
                if (!mounted) return;
                final ctx = _canvasKey.currentContext;
                RenderBox? box;
                if (ctx != null && ctx.mounted) {
                  final ro = ctx.findRenderObject();
                  if (ro is RenderBox && ro.attached) box = ro;
                }
                final localPos = box != null
                    ? box.globalToLocal(details.offset)
                    : const Offset(50, 50);
                widget.onAddBlock(details.data, Offset(localPos.dx.clamp(0.0, 1200.0), localPos.dy.clamp(0.0, 1200.0)));
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  key: _canvasKey,
                  width: double.infinity,
                  color: candidateData.isEmpty ? const Color(0xFFEAF2F7) : const Color(0xFFDDEFFF),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _WorkspaceDotPainter()),
                      ),
                      Positioned.fill(
                        child: _WorkspaceCanvas(
                          entries: widget.workspaceEntries,
                          onRemove: widget.onRemoveBlock,
                          aiClassNames: widget.aiClassNames,
                          textWidgetNames: widget.textWidgetNames,
                          clockWidgetNames: widget.clockWidgetNames,
                        ),
                      ),
                      if (widget.workspaceEntries.length == 1)
                        Positioned(
                          top: 90,
                          left: 20,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white),
                              ),
                              child: const Text(
                                'Drag blocks from the palette here.\nDouble-tap a block to remove it.',
                                style: TextStyle(color: Color(0xFF7D8990), fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 58,
                        right: 56,
                        child: Tooltip(
                          message: 'Clear all blocks',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.onClear,
                            child: Container(
                              width: 82,
                              height: 82,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.delete,
                                color: Color(0xFFC9CFD2),
                                size: 66,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (widget.paletteOpen)
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
                    itemCount: widget.paletteBlocks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final block = widget.paletteBlocks[index];
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
                for (final category in widget.categories)
                  _CategoryButton(
                    label: category,
                    color: _categoryColor(category),
                    selected: widget.paletteOpen && widget.selectedCategory == category,
                    onTap: () => widget.onSelectCategory(category),
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

// Static dropdown options for blocks whose choices are always fixed.
const Map<String, List<String>> _blockStaticOptions = {
  'On Collide With World Bounds': ['Left', 'Right', 'Up', 'Down', 'Any'],
  'On Swipe':  ['Left', 'Right', 'Up', 'Down'],
  'On Key':    ['→', '←', '↑', '↓', 'Space'],
  'On Collide': [],   // filled dynamically with sprite names
  'Start clock:': ['clock'], // default; replaced by live clockWidgetNames when available
};

// Converts _ScratchBlockData to a BlockDef so we can render with Scratch3Block.
BlockDef _scratchDataToBlockDef(_ScratchBlockData block, {List<String>? aiOptions, List<String>? aiClassOptions, String? editedValue, String? editedValue2}) {
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
      final opts = aiOptions ?? _blockStaticOptions[block.label] ?? const <String>[];
      final dropLabel = (editedValue != null && editedValue.isNotEmpty) ? editedValue : block.value!;
      fields.add(BlockFieldDef.dropdown(dropLabel, options: opts));
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
      fields.add(const BlockFieldDef.label('Predict'));
      final opts = aiClassOptions ?? const <String>[];
      final dropLabel = (editedValue2 != null && editedValue2.isNotEmpty) ? editedValue2 : block.value2!;
      fields.add(BlockFieldDef.dropdown(dropLabel, options: opts));
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
  const _ScratchBlock({required this.block, this.large = false, this.innerHeight, this.onValueChanged, this.dropdownOptions, this.editedValue, this.editedValue2, this.aiClassNames = const []});

  final _ScratchBlockData block;
  final bool large;
  final double? innerHeight;
  final void Function(int fieldIndex, String value)? onValueChanged;
  final List<String>? dropdownOptions;
  final String? editedValue;
  final String? editedValue2;
  final List<String> aiClassNames;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: Scratch3Block(
        block: _scratchDataToBlockDef(block, aiOptions: dropdownOptions, aiClassOptions: aiClassNames.isNotEmpty ? aiClassNames : null, editedValue: editedValue, editedValue2: editedValue2),
        color: block.color,
        darkColor: _darkenColor(block.color),
        scale: large ? 1.0 : 0.72,
        innerHeight: innerHeight,
        onFieldChanged: onValueChanged,
      ),
    );
  }
}


// ── Workspace data model ──────────────────────────────────────────────────────

class _WorkspaceEntry {
  _WorkspaceEntry({required this.block, this.position = Offset.zero});
  _ScratchBlockData block;
  Offset position;
  String? editedValue;
  String? editedValue2;
}

// ── Workspace dotted background ───────────────────────────────────────────────

class _WorkspaceDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEAF2F7));
    final paint = Paint()..color = const Color(0xFFCBD8E2);
    for (double y = 14; y < size.height; y += 20) {
      for (double x = 14; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Free-form draggable workspace canvas ─────────────────────────────────────

class _WorkspaceCanvas extends StatefulWidget {
  const _WorkspaceCanvas({
    required this.entries,
    required this.onRemove,
    this.trashKey,
    this.trashHighlight,
    this.aiClassNames = const [],
    this.textWidgetNames = const [],
    this.clockWidgetNames = const [],
  });

  final List<_WorkspaceEntry> entries;
  final ValueChanged<int> onRemove;
  final GlobalKey? trashKey;
  final ValueNotifier<bool>? trashHighlight;
  final List<String> aiClassNames;
  final List<String> textWidgetNames;
  final List<String> clockWidgetNames;

  @override
  State<_WorkspaceCanvas> createState() => _WorkspaceCanvasState();
}

class _WorkspaceCanvasState extends State<_WorkspaceCanvas> {
  late List<Offset> _positions;

  // Blocks at index >= _renderedCount are wrapped in Offstage(offstage:true)
  // so their render objects are laid out (avoiding hit-test assertions) but
  // invisible. Set to entries.length once they are ready to show.
  int _renderedCount = 0;

  // Indices of blocks that move together with the currently dragged block.
  // Computed once at pan-start so that positions shifting during drag don't break the group.
  Set<int> _dragGroup = {};

  Set<int> _getDependents(int idx) {
    final result = <int>{};
    _collectDependents(idx, result);
    return result;
  }

  void _collectDependents(int from, Set<int> result) {
    for (int i = 0; i < widget.entries.length; i++) {
      if (i == from || result.contains(i)) continue;
      if (_snapsBelow(i, from) || _snapsInsideOf(i, from)) {
        result.add(i);
        _collectDependents(i, result);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _positions = widget.entries.map((e) => e.position).toList();
    _renderedCount = widget.entries.length;
  }

  @override
  void didUpdateWidget(_WorkspaceCanvas old) {
    super.didUpdateWidget(old);
    final prevLen = _positions.length;
    // Always reload from entries — they store the authoritative position (kept in
    // sync during drags via onPanUpdate). This handles add, remove, and in-place
    // list mutations (removeWhere+add) that leave the length unchanged.
    _positions = widget.entries.map((e) => e.position).toList();
    if (widget.entries.length > prevLen) {
      // New blocks added. Keep them offstage (invisible but laid out) for this
      // frame so their render objects exist before any mouse hit-test fires.
      _renderedCount = prevLen;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (int i = prevLen; i < widget.entries.length; i++) {
          _trySnapBlock(i);
        }
        setState(() => _renderedCount = widget.entries.length);
      });
    } else {
      _renderedCount = widget.entries.length;
    }
  }

  // Static canvas height (no inner-block expansion, used for sizing inner blocks themselves).
  double _canvasHeight(_ScratchBlockData block) {
    final def = _scratchDataToBlockDef(block);
    const nd = 5.0;
    const stackH = 33.0;
    const reporterH = 25.0;
    const footH = 13.0;
    switch (def.shape) {
      case BlockShape.hat:
      case BlockShape.stack:
        final extra = def.multilineBelow != null ? 18.0 : 0.0;
        return stackH + extra + nd;
      case BlockShape.cBlock:
        return stackH + 30.0 + footH + nd;
      case BlockShape.reporter:
      case BlockShape.boolean:
        return reporterH;
    }
  }

  // True if the block at idx is a C-block container that can hold inner blocks.
  bool _isCBlockEntry(int idx) {
    final b = widget.entries[idx].block;
    return b.shape == _ScratchBlockShape.cBlock &&
        b.kind != _ScratchBlockKind.endEvent;
  }

  // Height of all blocks snapped inside C-block j (min 30 so the slot is always visible).
  double _innerSlotHeightForIdx(int cblockIdx) {
    final innerX = _positions[cblockIdx].dx + 22;
    double total = 0;
    for (int i = 0; i < widget.entries.length; i++) {
      if (i == cblockIdx) continue;
      if ((_positions[i].dx - innerX).abs() < 14) {
        total += _canvasHeight(widget.entries[i].block);
      }
    }
    return math.max(30.0, total);
  }

  // Dynamic canvas height: C-blocks expand to contain their inner blocks.
  double _canvasHeightForIdx(int idx) {
    final block = widget.entries[idx].block;
    if (_isCBlockEntry(idx)) {
      const stackH = 33.0;
      const footH = 13.0;
      const nd = 5.0;
      return stackH + _innerSlotHeightForIdx(idx) + footH + nd;
    }
    return _canvasHeight(block);
  }

  // Y where the next block's top should sit: end of block j's body.
  double _bottomConnectorY(int j) =>
      _positions[j].dy + _canvasHeightForIdx(j) - 5.0;

  // Returns the Offset where the next block should snap inside C-block j.
  // If nothing is inside yet, returns the top of the inner slot.
  // If inner blocks exist, returns below the last one.
  Offset _innerSlotBottom(int cblockIdx) {
    final innerX = _positions[cblockIdx].dx + 22;
    final baseY = _positions[cblockIdx].dy + 33; // stackH
    double maxBottomY = baseY;
    for (int i = 0; i < widget.entries.length; i++) {
      if (i == cblockIdx) continue;
      if ((_positions[i].dx - innerX).abs() < 14) {
        final bottom = _positions[i].dy + _canvasHeight(widget.entries[i].block) - 5;
        if (bottom > maxBottomY) maxBottomY = bottom;
      }
    }
    return Offset(innerX, maxBottomY);
  }

  // True if block j's outer bottom connector is already occupied by another block.
  bool _isOuterConnectorOccupied(int j, int excludeIdx) {
    final snapY = _bottomConnectorY(j);
    final snapX = _positions[j].dx;
    for (int k = 0; k < _positions.length; k++) {
      if (k == j || k == excludeIdx) continue;
      if ((_positions[k].dx - snapX).abs() < 10 &&
          (_positions[k].dy - snapY).abs() < 10) {
        return true;
      }
    }
    return false;
  }

  // Block b snaps below block a: same X (tight tolerance), top of b at a's bottom connector.
  bool _snapsBelow(int b, int a) {
    const thX = 12.0; // tight so inner blocks (offset +22) aren't treated as "below" outer blocks
    const thY = 55.0;
    return (_positions[b].dx - _positions[a].dx).abs() < thX &&
        (_positions[b].dy - _bottomConnectorY(a)).abs() < thY;
  }

  // Block i is snapped inside the C-block at j.
  bool _snapsInsideOf(int i, int j) {
    if (!_isCBlockEntry(j)) return false;
    const thX = 12.0;
    const thY = 55.0;
    final innerX = _positions[j].dx + 22;
    final innerY = _positions[j].dy + 33; // stackH — top of inner slot
    return (_positions[i].dx - innerX).abs() < thX &&
        (_positions[i].dy - innerY).abs() < thY;
  }

  Set<int> _connectedIndices() {
    final connected = <int>{};
    for (int i = 0; i < widget.entries.length; i++) {
      final b = widget.entries[i].block;
      if (b.kind == _ScratchBlockKind.event ||
          (b.shape == _ScratchBlockShape.cBlock && b.kind != _ScratchBlockKind.endEvent)) {
        connected.add(i);
      }
    }
    if (connected.isEmpty) return {};
    bool changed = true;
    while (changed) {
      changed = false;
      for (int i = 0; i < widget.entries.length; i++) {
        if (connected.contains(i)) continue;
        for (final j in connected.toList()) {
          if (_snapsBelow(i, j) || _snapsInsideOf(i, j)) {
            connected.add(i);
            changed = true;
            break;
          }
        }
      }
    }
    return connected;
  }

  // A block is considered connected when it is attached above/below another block,
  // or when it is inside / contains a C-block slot. The delete X should only show
  // on fully free blocks, so connected chains are not accidentally deleted.
  bool _hasAnyConnection(int i) {
    if (i <= 0 || i >= widget.entries.length) return true;
    for (int j = 0; j < widget.entries.length; j++) {
      if (j == i) continue;
      if (_snapsBelow(i, j) ||
          _snapsBelow(j, i) ||
          _snapsInsideOf(i, j) ||
          _snapsInsideOf(j, i)) {
        return true;
      }
    }
    return false;
  }

  // We no longer delete by checking a trash RenderObject.
  // The old version used `trashKey.currentContext?.findRenderObject()` while
  // blocks were being removed/rebuilt, which can throw:
  // "Cannot get renderObject of inactive element" on Flutter Web.
  // Individual deletion is now handled by the small X button on each block.

  void _trySnapBlock(int i) {
    if (i >= _positions.length) return;
    const snapZoneX = 80.0;
    const snapZoneY = 80.0;
    final connected = _connectedIndices();

    Offset? bestSnap;
    double bestDist = double.infinity;

    for (int j = 0; j < widget.entries.length; j++) {
      if (j == i || !connected.contains(j)) continue;

      // Outer bottom connector — skip if already occupied by another block.
      if (!_isOuterConnectorOccupied(j, i)) {
        final snapX = _positions[j].dx;
        final snapY = _bottomConnectorY(j);
        final dx = (_positions[i].dx - snapX).abs();
        final dy = (_positions[i].dy - snapY).abs();
        if (dx < snapZoneX && dy < snapZoneY) {
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < bestDist) {
            bestDist = dist;
            bestSnap = Offset(snapX, snapY);
          }
        }
      }

      // Inner slot connector — available for all C-blocks (chains inside automatically).
      if (_isCBlockEntry(j)) {
        final inner = _innerSlotBottom(j);
        final dx = (_positions[i].dx - inner.dx).abs();
        final dy = (_positions[i].dy - inner.dy).abs();
        if (dx < snapZoneX && dy < snapZoneY) {
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < bestDist) {
            bestDist = dist;
            bestSnap = Offset(inner.dx, inner.dy);
          }
        }
      }
    }

    if (bestSnap != null) {
      final snap = bestSnap;
      final delta = snap - _positions[i];
      setState(() {
        _positions[i] = snap;
        widget.entries[i].position = snap;
        for (final dep in _dragGroup) {
          _positions[dep] += delta;
          widget.entries[dep].position = _positions[dep];
        }
      });
    }
    _dragGroup = {};
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int i = 0; i < widget.entries.length; i++)
          Positioned(
            left: _positions[i].dx,
            top: _positions[i].dy,
            // Offstage keeps the render object laid out (hasSize=true) so it
            // won't trigger a "never been laid out" hit-test assertion on web
            // when the mouse moves between build and the first layout pass.
            child: Offstage(
              offstage: i >= _renderedCount,
              child: GestureDetector(
                onDoubleTap: () {
                  if (i == 0 || _hasAnyConnection(i)) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || i >= widget.entries.length) return;
                    widget.onRemove(i);
                  });
                },
                onPanStart: (_) {
                  _dragGroup = _getDependents(i);
                },
                onPanUpdate: (d) {
                  setState(() {
                    _positions[i] += d.delta;
                    widget.entries[i].position = _positions[i];
                    for (final dep in _dragGroup) {
                      _positions[dep] += d.delta;
                      widget.entries[dep].position = _positions[dep];
                    }
                  });
                },
                onPanEnd: (_) {
                  _trySnapBlock(i);
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _ScratchBlock(
                      block: widget.entries[i].block,
                      large: true,
                      innerHeight: _isCBlockEntry(i) ? _innerSlotHeightForIdx(i) : null,
                      dropdownOptions: widget.entries[i].block.kind == _ScratchBlockKind.ai && widget.aiClassNames.isNotEmpty
                          ? widget.aiClassNames
                          : widget.entries[i].block.label == 'Start clock:' && widget.clockWidgetNames.isNotEmpty
                              ? widget.clockWidgetNames
                              : widget.entries[i].block.kind == _ScratchBlockKind.widget && widget.textWidgetNames.isNotEmpty
                                  ? widget.textWidgetNames
                                  : null,
                      aiClassNames: widget.aiClassNames,
                      editedValue: widget.entries[i].editedValue,
                      editedValue2: widget.entries[i].editedValue2,
                      onValueChanged: (fi, v) {
                        if (fi == 0) {
                          widget.entries[i].editedValue = v;
                        } else {
                          widget.entries[i].editedValue2 = v;
                        }
                        setState(() {});
                      },
                    ),
                    if (i != 0 && !_hasAnyConnection(i))
                      Positioned(
                        top: -10,
                        right: -10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Delay removal until after the current pointer event.
                            // This prevents removing the element while Flutter is still
                            // processing gestures/layout for that same element.
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted || i >= widget.entries.length) return;
                              widget.onRemove(i);
                            });
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE05555),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.20),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    required this.owlVisible,
    required this.isRunning,
    required this.exerciseNumber,
    required this.projectSprites,
    required this.stageWidgets,
    required this.selectedObjectId,
    required this.onAddSpritePressed,
    required this.onOliverSettingsChanged,
    required this.onOliverSelected,
    required this.onSpriteDeleted,
    required this.onSpriteDuplicated,
    required this.onWidgetAdded,
    required this.onWidgetRemoved,
    required this.onWidgetSelected,
    required this.onWidgetChanged,
    required this.onAiClassNamesChanged,
    this.onModelSaved,
    this.savedModels = const [],
    this.worldWidth = 600,
    this.worldHeight = 400,
    this.cameraTarget = 'None',
    this.gravity = 1800,
    this.physics = 'ARCADE',
    this.onWorldWidthChanged,
    this.onWorldHeightChanged,
    this.onCameraTargetChanged,
    this.onGravityChanged,
    this.onPhysicsChanged,
    this.onFullscreen,
    this.placedTiles = const [],
    this.onTilesChanged,
    this.background = 'assets/images/starry_night.png',
    this.onBackgroundChanged,
    this.spriteStagePositions = const {},
    this.onSpritePositionChanged,
    this.onOliverPositionChanged,
  });

  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final int owlFrame;
  final bool owlVisible;
  final bool isRunning;
  final int exerciseNumber;
  final List<_SpriteAssetData> projectSprites;
  final List<_AddedGameWidget> stageWidgets;
  final String selectedObjectId;
  final VoidCallback onAddSpritePressed;
  final ValueChanged<_SpriteSettings> onOliverSettingsChanged;
  final VoidCallback onOliverSelected;
  final ValueChanged<_SpriteAssetData> onSpriteDeleted;
  final ValueChanged<_SpriteAssetData> onSpriteDuplicated;
  final ValueChanged<_AddedGameWidget> onWidgetAdded;
  final ValueChanged<_AddedGameWidget> onWidgetRemoved;
  final ValueChanged<_AddedGameWidget> onWidgetSelected;
  final VoidCallback onWidgetChanged;
  final ValueChanged<List<String>> onAiClassNamesChanged;
  final ValueChanged<_SavedAiModel>? onModelSaved;
  final List<_SavedAiModel> savedModels;
  final int worldWidth;
  final int worldHeight;
  final String cameraTarget;
  final double gravity;
  final String physics;
  final ValueChanged<int>? onWorldWidthChanged;
  final ValueChanged<int>? onWorldHeightChanged;
  final ValueChanged<String>? onCameraTargetChanged;
  final ValueChanged<double>? onGravityChanged;
  final ValueChanged<String>? onPhysicsChanged;
  final VoidCallback? onFullscreen;
  final List<_PlacedTile> placedTiles;
  final ValueChanged<List<_PlacedTile>>? onTilesChanged;
  final String background;
  final ValueChanged<String>? onBackgroundChanged;
  final Map<_SpriteAssetData, Offset> spriteStagePositions;
  final void Function(_SpriteAssetData, Offset)? onSpritePositionChanged;
  final void Function(double, double)? onOliverPositionChanged;

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
              owlVisible: owlVisible,
              isRunning: isRunning,
              stageWidgets: stageWidgets,
              worldWidth: worldWidth,
              cameraTarget: cameraTarget,
              onFullscreen: onFullscreen,
              placedTiles: placedTiles,
              onTilesChanged: onTilesChanged,
              background: background,
              projectSprites: projectSprites,
              spriteStagePositions: spriteStagePositions,
              onSpritePositionChanged: onSpritePositionChanged,
              onOliverPositionChanged: onOliverPositionChanged,
            ),
          ),
          Expanded(
            flex: 48,
            child: _SpriteInspector(
              exerciseNumber: exerciseNumber,
              projectSprites: projectSprites,
              stageWidgets: stageWidgets,
              selectedObjectId: selectedObjectId,
              onAddSpritePressed: onAddSpritePressed,
              owlX: owlX,
              owlY: owlY,
              owlScale: owlScale,
              owlRotation: owlRotation,
              owlOpacity: owlOpacity,
              onOliverSettingsChanged: onOliverSettingsChanged,
              onOliverSelected: onOliverSelected,
              onSpriteDeleted: onSpriteDeleted,
              onSpriteDuplicated: onSpriteDuplicated,
              onWidgetAdded: onWidgetAdded,
              onWidgetRemoved: onWidgetRemoved,
              onWidgetSelected: onWidgetSelected,
              onWidgetChanged: onWidgetChanged,
              onAiClassNamesChanged: onAiClassNamesChanged,
              onModelSaved: onModelSaved,
              savedModels: savedModels,
              worldWidth: worldWidth,
              worldHeight: worldHeight,
              cameraTarget: cameraTarget,
              gravity: gravity,
              physics: physics,
              onWorldWidthChanged: onWorldWidthChanged,
              onWorldHeightChanged: onWorldHeightChanged,
              onCameraTargetChanged: onCameraTargetChanged,
              onGravityChanged: onGravityChanged,
              onPhysicsChanged: onPhysicsChanged,
              isRunning: isRunning,
              background: background,
              onBackgroundChanged: onBackgroundChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePreview extends StatefulWidget {
  const _StagePreview({
    required this.owlX,
    required this.owlY,
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.owlFrame,
    required this.owlVisible,
    required this.isRunning,
    required this.stageWidgets,
    this.worldWidth = 600,
    this.cameraTarget = 'None',
    this.onFullscreen,
    this.placedTiles = const [],
    this.onTilesChanged,
    this.background = 'assets/images/starry_night.png',
    this.projectSprites = const [],
    this.spriteStagePositions = const {},
    this.onSpritePositionChanged,
    this.onOliverPositionChanged,
  });

  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final int owlFrame;
  final bool owlVisible;
  final bool isRunning;
  final List<_AddedGameWidget> stageWidgets;
  final int worldWidth;
  final String cameraTarget;
  final VoidCallback? onFullscreen;
  final List<_PlacedTile> placedTiles;
  final ValueChanged<List<_PlacedTile>>? onTilesChanged;
  final String background;
  final List<_SpriteAssetData> projectSprites;
  final Map<_SpriteAssetData, Offset> spriteStagePositions;
  final void Function(_SpriteAssetData, Offset)? onSpritePositionChanged;
  final void Function(double, double)? onOliverPositionChanged;

  @override
  State<_StagePreview> createState() => _StagePreviewState();
}

class _StagePreviewState extends State<_StagePreview> {
  String _tool = 'arrow';
  _TileType _selectedTileType = _TileType.grass;
  double _panOffset = 0.0;
  Offset _hoverPos = Offset.zero;
  String? _selectedStageId;

  void _onTapDown(TapDownDetails d, BoxConstraints constraints) {
    const tileSize = 30.0;
    final bool followCam = widget.cameraTarget == 'Oliver';
    const spriteSize = 74.0;
    final double viewCenterX = constraints.maxWidth / 2 - spriteSize / 2;
    final double maxScroll = math.max(0.0, widget.worldWidth - constraints.maxWidth);
    final double cameraOffset = followCam
        ? (widget.owlX - viewCenterX).clamp(0.0, maxScroll)
        : 0.0;
    final double worldX = d.localPosition.dx + cameraOffset + _panOffset;
    final double worldY = d.localPosition.dy;
    final int gridX = (worldX / tileSize).floor();
    final int gridY = (worldY / tileSize).floor();
    if (gridX < 0 || gridY < 0) return;
    final tiles = List<_PlacedTile>.from(widget.placedTiles);
    if (_tool == 'paint') {
      final newTile = _PlacedTile(gridX: gridX, gridY: gridY, type: _selectedTileType);
      tiles.removeWhere((t) => t.gridX == gridX && t.gridY == gridY);
      tiles.add(newTile);
      widget.onTilesChanged?.call(tiles);
    } else if (_tool == 'erase') {
      tiles.removeWhere((t) => t.gridX == gridX && t.gridY == gridY);
      widget.onTilesChanged?.call(tiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spriteSize = 74.0;
        final maxTop = math.max(0.0, constraints.maxHeight - spriteSize - 8);
        final top = widget.owlY.clamp(0.0, maxTop);

        final bool followCam = widget.cameraTarget == 'Oliver';
        final double viewCenterX = constraints.maxWidth / 2 - spriteSize / 2;
        final double maxScroll = math.max(0.0, widget.worldWidth - constraints.maxWidth);
        final double cameraOffset = followCam
            ? (widget.owlX - viewCenterX).clamp(0.0, maxScroll)
            : 0.0;
        // Subtract _panOffset so Oliver moves with the world (same as tiles) when dragging.
        final double displayLeft = followCam ? viewCenterX : widget.owlX - _panOffset;

        return MouseRegion(
          onHover: (e) => setState(() => _hoverPos = e.localPosition),
          child: GestureDetector(
            onTapDown: (_tool == 'paint' || _tool == 'erase')
                ? (d) => _onTapDown(d, constraints)
                : null,
            onTap: _tool == 'arrow'
                ? () => setState(() => _selectedStageId = null)
                : null,
            onPanUpdate: _tool == 'drag'
                ? (d) => setState(() {
                    _panOffset = (_panOffset - d.delta.dx)
                        .clamp(0.0, math.max(0.0, widget.worldWidth.toDouble() - constraints.maxWidth));
                  })
                : null,
            child: ClipRect(
              child: Stack(
                children: [
                  // Scrolling background
                  Positioned(
                    left: -cameraOffset - _panOffset,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth + widget.worldWidth,
                    child: _StarryNightBackground(asset: widget.background),
                  ),
                  // House decoration (world-space)
                  Positioned(
                    left: constraints.maxWidth * .30 - cameraOffset - _panOffset,
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
                  // Placed tiles (world-space, before Oliver)
                  for (final tile in widget.placedTiles)
                    Positioned(
                      left: tile.gridX * 30.0 - cameraOffset - _panOffset,
                      top: tile.gridY * 30.0,
                      width: 30,
                      height: 30,
                      child: _TileWidget(type: tile.type),
                    ),
                  // Project sprites (world-space, selectable + draggable)
                  for (final sprite in widget.projectSprites)
                    Positioned(
                      left: (widget.spriteStagePositions[sprite]?.dx ?? 50.0) - cameraOffset - _panOffset,
                      top: widget.spriteStagePositions[sprite]?.dy ?? 50.0,
                      width: spriteSize,
                      height: spriteSize,
                      child: GestureDetector(
                        behavior: _tool == 'arrow' ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                        onTap: () => setState(() => _selectedStageId = sprite.assetPath),
                        onPanUpdate: _tool == 'arrow' ? (d) {
                          final cur = widget.spriteStagePositions[sprite] ?? const Offset(50, 50);
                          widget.onSpritePositionChanged?.call(sprite, Offset(
                            (cur.dx + d.delta.dx).clamp(0.0, widget.worldWidth.toDouble() - spriteSize),
                            (cur.dy + d.delta.dy).clamp(0.0, constraints.maxHeight - spriteSize),
                          ));
                          setState(() => _selectedStageId = sprite.assetPath);
                        } : null,
                        child: Container(
                          width: spriteSize,
                          height: spriteSize,
                          decoration: _selectedStageId == sprite.assetPath
                              ? BoxDecoration(border: Border.all(color: const Color(0xFF91C75B), width: 4))
                              : null,
                          alignment: Alignment.center,
                          child: _SpriteSheetFrame(sprite: sprite, height: spriteSize - 6),
                        ),
                      ),
                    ),
                  // Oliver (selectable + draggable when not running)
                  Positioned(
                    left: followCam ? displayLeft : displayLeft - _panOffset,
                    top: top,
                    width: spriteSize,
                    height: spriteSize,
                    child: GestureDetector(
                      behavior: _tool == 'arrow' ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                      onTap: () => setState(() => _selectedStageId = 'oliver'),
                      onPanUpdate: _tool == 'arrow' && !widget.isRunning ? (d) {
                        widget.onOliverPositionChanged?.call(
                          (widget.owlX + d.delta.dx).clamp(0.0, widget.worldWidth.toDouble() - spriteSize),
                          (widget.owlY + d.delta.dy).clamp(0.0, constraints.maxHeight - spriteSize),
                        );
                        setState(() => _selectedStageId = 'oliver');
                      } : null,
                      child: Container(
                        width: spriteSize,
                        height: spriteSize,
                        decoration: _selectedStageId == 'oliver'
                            ? BoxDecoration(border: Border.all(color: const Color(0xFF91C75B), width: 4))
                            : null,
                        alignment: Alignment.center,
                        child: Opacity(
                          opacity: widget.owlOpacity.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: widget.owlScale,
                            child: Transform.rotate(
                              angle: (widget.owlRotation * math.pi / 180) + (widget.isRunning ? -.05 : -.16),
                              child: _OwlSpriteFrame(frame: widget.owlFrame, height: 66),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Stage widget overlays (selectable + draggable)
                  for (final w in widget.stageWidgets)
                    if (w.show)
                      if (w.type == _GameWidgetType.dialog)
                        Positioned(
                          top: 18, left: 18, right: 18, bottom: 60,
                          child: Opacity(
                            opacity: w.opacity.clamp(0.0, 1.0),
                            child: _StageWidgetOverlay(gameWidget: w, isRunning: widget.isRunning),
                          ),
                        )
                      else
                        Positioned(
                          top: w.stageY,
                          left: w.stageX,
                          child: GestureDetector(
                            behavior: _tool == 'arrow' ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                            onTap: () => setState(() => _selectedStageId = w.id),
                            onPanUpdate: _tool == 'arrow' ? (d) {
                              setState(() {
                                _selectedStageId = w.id;
                                w.stageX = (w.stageX + d.delta.dx).clamp(0.0, constraints.maxWidth - 10);
                                w.stageY = (w.stageY + d.delta.dy).clamp(0.0, constraints.maxHeight - 10);
                              });
                            } : null,
                            child: Container(
                              decoration: _selectedStageId == w.id
                                  ? BoxDecoration(border: Border.all(color: const Color(0xFF91C75B), width: 4))
                                  : null,
                              child: Opacity(
                                opacity: w.opacity.clamp(0.0, 1.0),
                                child: _StageWidgetOverlay(gameWidget: w, isRunning: widget.isRunning),
                              ),
                            ),
                          ),
                        ),
                  // Coordinate display (top-left)
                  Positioned(
                    top: 2,
                    left: 4,
                    child: Text(
                      'x:${(_hoverPos.dx + cameraOffset + _panOffset).round()}  y:${_hoverPos.dy.round()}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ),
                  // Tool icons (viewport-fixed)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() { _tool = 'arrow'; _panOffset = 0; }),
                          child: _StageToolAsset(
                            assetPath: CodeMonkeyScratchAssets.toolDefault,
                            selected: _tool == 'arrow',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _tool = 'drag'),
                          child: _StageToolAsset(
                            assetPath: CodeMonkeyScratchAssets.toolDrag,
                            selected: _tool == 'drag',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _tool = 'erase'),
                          child: _StageToolAsset(
                            assetPath: CodeMonkeyScratchAssets.toolErase,
                            selected: _tool == 'erase',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _tool = 'paint'),
                          child: _StageToolAsset(
                            assetPath: CodeMonkeyScratchAssets.toolPaint,
                            selected: _tool == 'paint',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tile palette (right side, visible only in paint mode)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: _TilePalette(
                      selectedType: _selectedTileType,
                      onSelect: (t) => setState(() => _selectedTileType = t),
                      visible: _tool == 'paint',
                    ),
                  ),
                  // Fullscreen button
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: widget.onFullscreen,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StageToolAsset extends StatelessWidget {
  const _StageToolAsset({required this.assetPath, this.selected = false});

  final String assetPath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 41,
      height: 38,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF8ABCD1) : const Color(0xFFC4C7C8),
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
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

class _TileWidget extends StatelessWidget {
  const _TileWidget({required this.type});
  final _TileType type;
  @override
  Widget build(BuildContext context) {
    switch (type) {
      case _TileType.grass:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26, width: 0.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5AAE2E), Color(0xFF5AAE2E), Color(0xFF7B4F2E), Color(0xFF7B4F2E)],
              stops: [0.0, 0.25, 0.25, 1.0],
            ),
          ),
        );
      case _TileType.dirt:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7B4F2E),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        );
      case _TileType.brick:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFC44B32),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        );
      case _TileType.stone:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF7A8A9A),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        );
      case _TileType.sand:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8C565),
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        );
    }
  }
}

class _TilePalette extends StatelessWidget {
  const _TilePalette({required this.selectedType, required this.onSelect, required this.visible});
  final _TileType selectedType;
  final ValueChanged<_TileType> onSelect;
  final bool visible;
  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      width: 36,
      color: const Color(0xFF1A1A2E).withAlpha(200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _TileType.values.map((t) {
          final isSelected = t == selectedType;
          return GestureDetector(
            onTap: () => onSelect(t),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.yellow : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: _TileWidget(type: t),
            ),
          );
        }).toList(),
      ),
    );
  }
}


// ── Stage widget overlay (counter, text, timer, etc shown on stage) ───────────
class _StageWidgetOverlay extends StatefulWidget {
  const _StageWidgetOverlay({required this.gameWidget, required this.isRunning});
  final _AddedGameWidget gameWidget;
  final bool isRunning;

  @override
  State<_StageWidgetOverlay> createState() => _StageWidgetOverlayState();
}

class _StageWidgetOverlayState extends State<_StageWidgetOverlay> {
  html.MediaStream? _stream;
  html.VideoElement? _videoEl;
  html.CanvasElement? _poseCanvasEl;
  late final String _viewId;
  bool _cameraStarted = false;

  @override
  void initState() {
    super.initState();
    if (widget.gameWidget.type == _GameWidgetType.webcam && kIsWeb) {
      _viewId = 'stage-webcam-${identityHashCode(this)}';
      final videoEl = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      final canvasEl = html.CanvasElement()
        ..style.position = 'absolute'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';
      final container = html.DivElement()
        ..style.position = 'relative'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(videoEl)
        ..append(canvasEl);
      ui_web.platformViewRegistry.registerViewFactory(_viewId, (_) => container);
      _videoEl = videoEl;
      _poseCanvasEl = canvasEl;
      if (widget.isRunning) _startCamera();
    }
  }

  @override
  void didUpdateWidget(_StageWidgetOverlay old) {
    super.didUpdateWidget(old);
    if (widget.gameWidget.type != _GameWidgetType.webcam) return;
    if (!old.isRunning && widget.isRunning) _startCamera();
    if (old.isRunning && !widget.isRunning) _stopCamera();
  }

  @override
  void dispose() {
    if (widget.gameWidget.type == _GameWidgetType.webcam) _stopCamera();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!kIsWeb || _cameraStarted || _videoEl == null) return;
    try {
      _stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      _videoEl!.srcObject = _stream;
      js.context.callMethod('startPreviewPose', [_videoEl, _poseCanvasEl]);
      _cameraStarted = true;
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _stopCamera() {
    if (!kIsWeb) return;
    js.context.callMethod('stopPreviewPose', []);
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
    _cameraStarted = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gameWidget.type == _GameWidgetType.dialog) {
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
                widget.gameWidget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.gameWidget.textColor,
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

    if (widget.gameWidget.type == _GameWidgetType.webcam) {
      return Container(
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF91C75B), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: kIsWeb && _cameraStarted
              ? HtmlElementView(viewType: _viewId)
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam, color: Colors.white54, size: 44),
                    SizedBox(height: 4),
                    Text('webcam', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
        ),
      );
    }

    if (widget.gameWidget.type == _GameWidgetType.button) {
      return Transform.rotate(
        angle: widget.gameWidget.rotation * 3.14159265 / 180,
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
                  _AddedGameWidget.buttonImages[widget.gameWidget.buttonImageIndex],
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

    final label = switch (widget.gameWidget.type) {
      _GameWidgetType.counter => '0',
      _GameWidgetType.text    => widget.gameWidget.text,
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
          color: widget.gameWidget.textColor,
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
    required this.exerciseNumber,
    required this.projectSprites,
    required this.stageWidgets,
    required this.selectedObjectId,
    required this.onAddSpritePressed,
    required this.owlX,
    required this.owlY,
    required this.owlScale,
    required this.owlRotation,
    required this.owlOpacity,
    required this.onOliverSettingsChanged,
    required this.onOliverSelected,
    required this.onSpriteDeleted,
    required this.onSpriteDuplicated,
    required this.onWidgetAdded,
    required this.onWidgetRemoved,
    required this.onWidgetSelected,
    required this.onWidgetChanged,
    required this.onAiClassNamesChanged,
    this.onModelSaved,
    this.savedModels = const [],
    this.worldWidth = 600,
    this.worldHeight = 400,
    this.cameraTarget = 'None',
    this.gravity = 1800,
    this.physics = 'ARCADE',
    this.onWorldWidthChanged,
    this.onWorldHeightChanged,
    this.onCameraTargetChanged,
    this.onGravityChanged,
    this.onPhysicsChanged,
    this.isRunning = false,
    this.background = 'assets/images/starry_night.png',
    this.onBackgroundChanged,
  });

  final int exerciseNumber;
  final List<_SpriteAssetData> projectSprites;
  final List<_AddedGameWidget> stageWidgets;
  final String selectedObjectId;
  final VoidCallback onAddSpritePressed;
  final double owlX;
  final double owlY;
  final double owlScale;
  final double owlRotation;
  final double owlOpacity;
  final ValueChanged<_SpriteSettings> onOliverSettingsChanged;
  final VoidCallback onOliverSelected;
  final ValueChanged<_SpriteAssetData> onSpriteDeleted;
  final ValueChanged<_SpriteAssetData> onSpriteDuplicated;
  final ValueChanged<_AddedGameWidget> onWidgetAdded;
  final ValueChanged<_AddedGameWidget> onWidgetRemoved;
  final ValueChanged<_AddedGameWidget> onWidgetSelected;
  final VoidCallback onWidgetChanged;
  final ValueChanged<List<String>> onAiClassNamesChanged;
  final ValueChanged<_SavedAiModel>? onModelSaved;
  final List<_SavedAiModel> savedModels;
  final int worldWidth;
  final int worldHeight;
  final String cameraTarget;
  final double gravity;
  final String physics;
  final ValueChanged<int>? onWorldWidthChanged;
  final ValueChanged<int>? onWorldHeightChanged;
  final ValueChanged<String>? onCameraTargetChanged;
  final ValueChanged<double>? onGravityChanged;
  final ValueChanged<String>? onPhysicsChanged;
  final bool isRunning;
  final String background;
  final ValueChanged<String>? onBackgroundChanged;

  @override
  State<_SpriteInspector> createState() => _SpriteInspectorState();
}

class _SpriteInspectorState extends State<_SpriteInspector> {
  _SpriteSettings? _active;
  bool _showPreview = false;
  int _activeTab = 0;
  _AddedGameWidget? _activeWidget;
  OverlayEntry? _aiModelEntry;

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
  void dispose() {
    _removeAiModelPanel();
    super.dispose();
  }

  void _showAiModelPanel(BuildContext ctx) {
    _removeAiModelPanel();
    _aiModelEntry = OverlayEntry(builder: (overlayCtx) {
      final sw = MediaQuery.of(overlayCtx).size.width;
      return Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: sw * 0.63,
        child: Material(
          elevation: 12,
          color: Colors.white,
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
          child: _NewAiModelDialog(
            onClassNamesChanged: widget.onAiClassNamesChanged,
            onClose: _removeAiModelPanel,
            onSaved: (model) {
              _removeAiModelPanel();
              widget.onModelSaved?.call(model);
            },
          ),
        ),
      );
    });
    Overlay.of(ctx, rootOverlay: true).insert(_aiModelEntry!);
    setState(() {});
  }

  void _removeAiModelPanel() {
    _aiModelEntry?.remove();
    _aiModelEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              _InspectorTab(label: 'Sprites',  selected: _activeTab == 0, onTap: () => _switchTab(0)),
              _InspectorTab(label: 'Widgets',  selected: _activeTab == 1, onTap: () => _switchTab(1)),
              _InspectorTab(label: 'Sounds',   selected: _activeTab == 2, onTap: () => _switchTab(2)),
              if (widget.exerciseNumber >= 2)
                _InspectorTab(label: 'AI - Pose', selected: _activeTab == 3, onTap: () => _switchTab(3)),
              _InspectorTab(label: 'Game',     selected: _activeTab == 4, onTap: () => _switchTab(4)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: switch (_activeTab) {
              1 => _activeWidget != null ? _buildWidgetSettingsPanel(_activeWidget!) : _buildWidgetsTab(),
              3 => _buildAiPoseTab(),
              4 => _buildGameTab(),
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
                isSelected: widget.selectedObjectId == 'oliver',
                onTap: widget.onOliverSelected,
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

  _SavedAiModel? _giveItATryModel;
  _SavedAiModel? _selectedModel;

  Widget _buildAiPoseTab() {
    if (_giveItATryModel != null) {
      return _GiveItATryPanel(
        model: _giveItATryModel!,
        onClose: () => setState(() => _giveItATryModel = null),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () => _showAiModelPanel(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DBE7A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_rounded, size: 28),
                SizedBox(width: 10),
                Text(
                  'ADD NEW MODEL',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                ),
              ],
            ),
          ),
          if (widget.savedModels.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'Select a model to use in the game',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            for (final model in widget.savedModels)
              _SavedModelCard(
                model: model,
                selected: _selectedModel == model,
                onSelect: () {
                  setState(() => _selectedModel = model);
                  widget.onAiClassNamesChanged(model.classNames);
                },
                onGiveItATry: () => setState(() => _giveItATryModel = model),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGameTab() {
    final spriteNames = ['None', 'Oliver', ...widget.projectSprites.map((s) => s.displayName)];
    final widthOptions  = [600, 1200, 1800, 2400, 3000, 3600];
    final heightOptions = [400, 800, 1200, 1400, 1800, 2200];
    final disabled = widget.isRunning;

    const labelStyle = TextStyle(
      fontSize: 10, fontWeight: FontWeight.w800,
      color: Color(0xFF888888), letterSpacing: 0.6,
    );

    Widget settingCol(String label, Widget control) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 4),
        control,
      ],
    );

    Widget dd<T>(T value, List<T> options, ValueChanged<T>? cb) => Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        border: Border.all(color: const Color(0xFFCDD5E0)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF2E3A4E)),
          items: options.map((o) => DropdownMenuItem<T>(value: o, child: Text(o.toString()))).toList(),
          onChanged: (disabled || cb == null) ? null : (v) { if (v != null) cb(v); },
        ),
      ),
    );

    Widget gravityControl() => Row(
      children: [
        Expanded(
          child: Container(
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              border: Border.all(color: const Color(0xFFCDD5E0)),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
            ),
            child: Text(widget.gravity.round().toString(),
                style: const TextStyle(fontSize: 12, color: Color(0xFF2E3A4E))),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCDD5E0)),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 26, height: 17,
                child: InkWell(
                  onTap: disabled ? null : () => widget.onGravityChanged?.call((widget.gravity + 100).clamp(0, 9999)),
                  child: const Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF555555)),
                ),
              ),
              const Divider(height: 0.5, color: Color(0xFFCDD5E0)),
              SizedBox(
                width: 26, height: 17,
                child: InkWell(
                  onTap: disabled ? null : () => widget.onGravityChanged?.call((widget.gravity - 100).clamp(0, 9999)),
                  child: const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF555555)),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return AbsorbPointer(
      absorbing: disabled,
      child: Opacity(
        opacity: disabled ? 0.55 : 1.0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GAME SETTINGS', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900,
                color: Color(0xFF888888), letterSpacing: 1.0)),
              const SizedBox(height: 12),
              // Row 1: Background | Camera Target
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: settingCol('Background',
                    Row(children: [
                      Flexible(
                        child: Text(
                          _kBackgrounds.where((b) => b.asset == widget.background).map((b) => b.name).firstOrNull ?? 'starry_night',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDialog<String>(
                            context: context,
                            builder: (_) => _ChooseBackgroundDialog(current: widget.background),
                          );
                          if (picked != null) widget.onBackgroundChanged?.call(picked);
                        },
                        child: const Text('| Change', style: TextStyle(fontSize: 12, color: Color(0xFF2F75B5))),
                      ),
                    ]),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: settingCol('Camera Target',
                    dd<String>(widget.cameraTarget, spriteNames, widget.onCameraTargetChanged))),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: World Width | World Height
              Row(
                children: [
                  Expanded(child: settingCol('World Width',
                    dd<int>(widget.worldWidth, widthOptions, widget.onWorldWidthChanged))),
                  const SizedBox(width: 10),
                  Expanded(child: settingCol('World Height',
                    dd<int>(widget.worldHeight, heightOptions, widget.onWorldHeightChanged))),
                ],
              ),
              const SizedBox(height: 10),
              // Row 3: Gravity | Physics
              Row(
                children: [
                  Expanded(child: settingCol('Gravity', gravityControl())),
                  const SizedBox(width: 10),
                  Expanded(child: settingCol('Physics',
                    dd<String>(widget.physics, const ['ARCADE', 'P2'], widget.onPhysicsChanged))),
                ],
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
  const _OliverSpriteCard({required this.onSettingsTap, required this.onTap, required this.isSelected});

  final VoidCallback onSettingsTap;
  final VoidCallback onTap;
  final bool isSelected;

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
        border: Border.all(
          color: isSelected ? const Color(0xFF3DBE7A) : const Color(0xFF84B75C),
          width: isSelected ? 4 : 3,
        ),
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
  double stageX = 12.0;
  double stageY = 12.0;
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

  factory _ScratchBlockData.widgetBlock(String label, {String? value, String? value2, bool value2Dropdown = false}) => _ScratchBlockData(
        label: label,
        value: value,
        value2: value2,
        valueDropdown: value != null,
        value2Dropdown: value2Dropdown,
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

// ── Choose Background Dialog ─────────────────────────────────────────────────

class _ChooseBackgroundDialog extends StatefulWidget {
  const _ChooseBackgroundDialog({required this.current});
  final String current;

  @override
  State<_ChooseBackgroundDialog> createState() => _ChooseBackgroundDialogState();
}

class _ChooseBackgroundDialogState extends State<_ChooseBackgroundDialog> {
  late String _selected;
  String? _uploadedBlobUrl;
  String _uploadedName = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
    // If current is already an uploaded URL, remember it
    if (widget.current.startsWith('blob:') ||
        widget.current.startsWith('http') ||
        widget.current.startsWith('data:')) {
      _uploadedBlobUrl = widget.current;
      _uploadedName = 'my background';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (!mounted) return;
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final name = result.files.single.name;
      final mime = name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      final blob = html.Blob([bytes], mime);
      final url = html.Url.createObjectUrlFromBlob(blob);
      setState(() {
        if (_uploadedBlobUrl != null && _uploadedBlobUrl!.startsWith('blob:')) {
          html.Url.revokeObjectUrl(_uploadedBlobUrl!);
        }
        _uploadedBlobUrl = url;
        _uploadedName = name.replaceAll(RegExp(r'\.[^.]+$'), '');
        _selected = url;
      });
    }
  }

  Widget _buildTile(String asset, String name, {bool isNetwork = false}) {
    final isSelected = asset == _selected;
    return InkWell(
      onTap: () => setState(() => _selected = asset),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF9A9A9A) : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Expanded(
                    child: isNetwork
                        ? Image.network(
                            asset,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF24343D)),
                          )
                        : Image.asset(
                            asset,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            repeat: ImageRepeat.repeat,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF24343D)),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: -10,
              right: -10,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF58C88B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 26),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUpload = _uploadedBlobUrl != null;
    // slot 0 = upload action tile, slot 1 (if hasUpload) = uploaded tile, rest = library
    final itemCount = _kBackgrounds.length + 1 + (hasUpload ? 1 : 0);

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
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'CHOOSE A BACKGROUND',
                style: TextStyle(
                  color: Color(0xFF7BAE55),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              Container(height: 1, color: const Color(0xFF9DCA76)),
              const SizedBox(height: 16),
              // Grid
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(28, 12, 18, 14),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisExtent: 148,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, i) {
                      // Upload action tile
                      if (i == 0) {
                        return _SpriteDialogActionTile(
                          icon: Icons.upload,
                          label: 'UPLOAD\nBACKGROUND',
                          onTap: _pickBackground,
                        );
                      }
                      // Uploaded image tile
                      if (hasUpload && i == 1) {
                        return _buildTile(
                          _uploadedBlobUrl!,
                          _uploadedName,
                          isNetwork: true,
                        );
                      }
                      final bgIdx = i - 1 - (hasUpload ? 1 : 0);
                      final bg = _kBackgrounds[bgIdx];
                      return _buildTile(bg.asset, bg.name);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3F2016),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 13),
                    ),
                    child: const Text('CANCEL', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 64),
                  SizedBox(
                    width: 176,
                    height: 47,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4D861D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── Course Completed Dialog ──────────────────────────────────────────────────

class _CourseCompletedDialog extends StatelessWidget {
  final VoidCallback onBackToHome;

  const _CourseCompletedDialog({required this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              _buildProgressRow(),
              _buildBody(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFC107),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Course Completed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'You Completed: 9 / 9 exercises',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '100%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/monkey1.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emoji_events, size: 64, color: Color(0xFFFFC107)),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Some ideas to tweak your game:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 8),
                ...[
                  'Add sound effects',
                  'Have the owl move in both directions',
                  'Make the owl move faster when the player stays in a squat',
                  'Add enemies that move around',
                ].map((idea) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 13, color: Color(0xFF00BCD4), fontWeight: FontWeight.w700)),
                          Expanded(child: Text(idea, style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFC107), width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, color: Color(0xFFFFC107), size: 18),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Achievement Unlocked! Perfect Poser',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7B6000)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('KEEP EDITING', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('PLAY YOUR GAME', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onBackToHome,
            child: const Text(
              'BACK TO HOME',
              style: TextStyle(color: Color(0xFF00BCD4), fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reference Cards ───────────────────────────────────────────────────────────

class _RefCard {
  const _RefCard({
    required this.title,
    required this.description,
    required this.tab,
    this.code,
  });
  final String title;
  final String description;
  final String tab;
  final List<List<String>>? code;
}

const _kRefCards = <_RefCard>[
  // ── SPRITES ──────────────────────────────────────────────────────────────
  _RefCard(title: 'Sprite', tab: 'SPRITES', description: 'A game object represented as an image on the screen at specific coordinates. Sprites also allow running animation, events and physics motion.'),
  _RefCard(title: "Sprite's name", tab: 'SPRITES', description: 'Used to reference the sprite throughout the game.'),
  _RefCard(title: "Sprite's X", tab: 'SPRITES', description: "A property of the sprite. The sprite's initial x position."),
  _RefCard(title: "Sprite's Y", tab: 'SPRITES', description: "A property of the sprite. The sprite's initial y position."),
  _RefCard(title: 'Rotation', tab: 'SPRITES', description: 'A property of the sprite. Changing a sprite\'s rotation changes the way it is "pointing" by turning it about its center point.'),
  _RefCard(title: 'Scale', tab: 'SPRITES', description: 'A property of the sprite. The scale defines the size of the sprite relative to its original size. A scale of 1 means the original size, 2 means double, 0.5 means half.'),
  _RefCard(title: 'Immovable', tab: 'SPRITES', description: 'A property of the sprite. This option applies when two sprites collide. Check this option when a sprite should not move during a collision with another sprite. If a sprite is not immovable another sprite that runs into it can push it.'),
  _RefCard(title: 'Allow gravity', tab: 'SPRITES', description: 'A property of the sprite. Defines if the sprite is affected by gravity (checked) or not (unchecked). This option applies only when the game has gravity. If the game has gravity and this box is checked - when running the game the sprite will fall until it reaches a surface (world boundary, tiles, or another sprite). If the box is unchecked, the sprite will not move upon running the game.'),
  _RefCard(title: 'Collide world bounds', tab: 'SPRITES', description: "A property of the sprite. Defines whether the sprite collides with the world's bounds (checked) or if it can move beyond it (unchecked)."),
  _RefCard(title: 'Show sprite', tab: 'SPRITES', description: 'A property of the sprite. Show or hide the sprite on the game screen.'),
  _RefCard(title: 'Opacity', tab: 'SPRITES', description: 'A property of the sprite. Defines the transparency of the sprite. A value of 1 means fully visible, 0 means fully transparent.'),
  _RefCard(title: 'Frame', tab: 'SPRITES', description: 'A property of the sprite. Defines which animation frame of the sprite sheet is displayed.'),
  _RefCard(title: 'Animation name', tab: 'SPRITES', description: 'The name used to reference a specific animation sequence for the sprite.'),
  _RefCard(title: 'Loop animation', tab: 'SPRITES', description: 'When checked, the animation will repeat continuously. When unchecked, it plays once and stops.'),
  _RefCard(title: 'On Overlap', tab: 'SPRITES', description: 'This block is called when the sprite overlaps with another sprite. Use it to detect when two sprites touch each other.'),
  _RefCard(title: 'On Collide', tab: 'SPRITES', description: 'This block is called when the sprite collides with a tile. Use it to detect when a sprite hits the ground or a wall.'),
  _RefCard(title: 'Set Frame', tab: 'SPRITES', description: 'Changes the displayed animation frame of the sprite to the value in the block.', code: [['E:On Run'], ['A:Set Frame', 'I:0']]),
  _RefCard(title: 'Set Opacity', tab: 'SPRITES', description: 'Sets the transparency of the sprite. A value of 1 means fully visible, 0 means fully transparent.', code: [['E:On Run'], ['A:Set Opacity', 'I:0.5']]),
  _RefCard(title: 'Set Scale', tab: 'SPRITES', description: "Sets the scale of the sprite. Changes the sprite's size relative to its original size.", code: [['E:On Run'], ['A:Set Scale', 'I:2']]),
  _RefCard(title: 'Animate', tab: 'SPRITES', description: 'Plays a named animation on the sprite.', code: [['E:On Run'], ['A:Animate', 'I:walk']]),
  // ── WIDGETS ──────────────────────────────────────────────────────────────
  _RefCard(title: 'Widget', tab: 'WIDGETS', description: 'A game object that displays information or interacts with the player.'),
  _RefCard(title: "Widget's name", tab: 'WIDGETS', description: 'Used to reference the widget throughout the game.'),
  _RefCard(title: 'Show widget', tab: 'WIDGETS', description: 'Show or hide the widget on the game screen.'),
  _RefCard(title: 'Sounds', tab: 'WIDGETS', description: 'A game object that represents a sound. The sound can be played using the Play block.'),
  _RefCard(title: "Sound's name", tab: 'WIDGETS', description: 'Used to reference the sound throughout the game.'),
  _RefCard(title: 'Play sound', tab: 'WIDGETS', description: 'Plays the selected sound in the game.', code: [['E:On Run'], ['A:Play', 'I:sound1']]),
  _RefCard(title: 'Stop sound', tab: 'WIDGETS', description: 'Stops the selected sound if it is currently playing.', code: [['E:On Run'], ['A:Stop', 'I:sound1']]),
  _RefCard(title: 'Counter widget', tab: 'WIDGETS', description: 'The Counter widget is used to keep count and can be displayed in the game.'),
  _RefCard(title: "Counter's name", tab: 'WIDGETS', description: 'Used to reference the counter throughout the game.'),
  _RefCard(title: 'Set counter', tab: 'WIDGETS', description: 'Sets the counter to a specific value.', code: [['E:On Run'], ['A:Set counter', 'I:0']]),
  _RefCard(title: 'Add to counter', tab: 'WIDGETS', description: 'Adds a value to the current counter value.', code: [['E:On Run'], ['A:Add to counter', 'I:1']]),
  _RefCard(title: 'Text widget', tab: 'WIDGETS', description: "The Text widget is used to display labels or texts on the game's screen."),
  _RefCard(title: 'Set text', tab: 'WIDGETS', description: 'Sets the text displayed by the Text widget.', code: [['E:On Run'], ['A:Set text', 'I:Hello!']]),
  _RefCard(title: 'Timer widget', tab: 'WIDGETS', description: 'The Timer widget is used to time activities in the game. It counts the seconds backwards until it reaches zero.'),
  _RefCard(title: 'On End', tab: 'WIDGETS', description: "This block will be called when the timer's countdown reaches 0.", code: [['E:On End'], ['A:Jump', 'I:1']]),
  _RefCard(title: 'Start timer', tab: 'WIDGETS', description: 'Starts the countdown of the timer widget.', code: [['E:On Run'], ['A:Start timer']]),
  _RefCard(title: 'Stop timer', tab: 'WIDGETS', description: 'Stops the countdown of the timer widget.', code: [['E:On Run'], ['A:Stop timer']]),
  _RefCard(title: 'Clock widget', tab: 'WIDGETS', description: 'The Clock widget is used to show the elapsed time. It counts the elapsed seconds starting from 0.'),
  _RefCard(title: 'Button widget', tab: 'WIDGETS', description: 'The Button widget is used to create a simple interface in the game.'),
  _RefCard(title: 'On Down', tab: 'WIDGETS', description: 'This block is called repeatedly when the user clicks on the button for as long as the mouse button is held down.', code: [['E:On Down'], ['A:Jump', 'I:1']]),
  _RefCard(title: 'button.On Click', tab: 'WIDGETS', description: 'This block is called just once when the user clicks on the button, at the time when the mouse button is released.', code: [['E:On Click'], ['A:Pause Game']]),
  _RefCard(title: 'Dialog widget', tab: 'WIDGETS', description: 'The Dialog widget is used to display a message to the player. The message is a string.'),
  _RefCard(title: 'On Confirm', tab: 'WIDGETS', description: 'This block is called when the user presses the check button on the dialog widget.', code: [['E:On Confirm'], ['A:Reset Game']]),
  _RefCard(title: 'Webcam widget', tab: 'WIDGETS', description: 'The Webcam widget displays the live camera feed inside the game.'),
  _RefCard(title: 'Video widget', tab: 'WIDGETS', description: 'The Video widget plays a video file inside the game.'),
  _RefCard(title: 'Arrow widget', tab: 'WIDGETS', description: 'The Arrow widget provides on-screen directional controls for the player.'),
  // ── GAME ─────────────────────────────────────────────────────────────────
  _RefCard(title: 'On Run', tab: 'GAME', description: 'This block exists in each sprite and widget and cannot be deleted. When the player clicks on the Run button (to play the game), the blocks attached to the On Run block are executed.'),
  _RefCard(title: 'Game', tab: 'GAME', description: 'An object representing the game as a whole. Properties of the game object include the width and height of the game world, which sprite the game camera should follow, and the strength of gravity in the game world.'),
  _RefCard(title: 'World width', tab: 'GAME', description: "Sets the world's width. The visible part of the world is 600 by 400."),
  _RefCard(title: 'World height', tab: 'GAME', description: "Sets the world's height. The visible part of the world is 600 by 400."),
  _RefCard(title: 'Gravity', tab: 'GAME', description: 'Defines the level of gravity in the game. Zero means that there is no gravity and the sprites do not fall down.'),
  _RefCard(title: 'Camera target', tab: 'GAME', description: 'Defines which sprite to follow. This is useful if the game world is bigger than 600 by 400. When the target sprite moves, the game window will scroll to keep up with it.'),
  _RefCard(title: 'Physics', tab: 'GAME', description: 'In game design physics refers to system used to make game objects behave like objects in the real world. For example, it is the physics system that stops a sprite from moving if it runs into a "solid" object like a tile or immovable sprite. In some games, the physics system also includes gravity that automatically caused objects to fall towards the bottom of the screen unless something stops them. In Game Builder there are two possible physics systems, ARCADE and P2. ARCADE is easier to use and should be the choice for most games. P2 allows for more realistic simulations and provides more control over sprites\' speed and rotation.'),
  _RefCard(title: 'Tilemap', tab: 'GAME', description: 'A game object made up of individual square tiles. Tiles can be used to "draw" the game world. They take up space and stop sprites from moving through them.'),
  _RefCard(title: 'x, y coordinates', tab: 'GAME', description: 'The world has width (represented by the x coordinates) and height (represented by the y coordinates). Each sprite in the world has x and y coordinates that define its position. The top left corner of the game world has coordinates x = 0, y = 0 As you move to the right, the value of x get bigger; as you move down, the value of y gets bigger. The x and y coordinates are displayed in the top left corner and are changed as the mouse cursor is moved.'),
  _RefCard(title: 'Background', tab: 'GAME', description: 'Sets the background image of the game world.'),
  _RefCard(title: 'Pause game', tab: 'GAME', description: 'Pauses the game. All sprites and widgets stop moving.', code: [['E:On Click'], ['A:Pause Game']]),
  _RefCard(title: 'Resume game', tab: 'GAME', description: 'Resumes the game after it has been paused.', code: [['E:On Click'], ['A:Resume Game']]),
  _RefCard(title: 'Reset game', tab: 'GAME', description: 'Resets the game to its initial state. All sprites go back to their starting positions.', code: [['E:On Confirm'], ['A:Reset Game']]),
  _RefCard(title: 'Add Score', tab: 'GAME', description: 'Adds a value to the current score.', code: [['E:On Overlap'], ['A:Add Score', 'I:10']]),
  _RefCard(title: 'Get Score', tab: 'GAME', description: 'Returns the current score value.', code: [['E:On Run'], ['A:Set text', 'G:Get Score']]),
  _RefCard(title: 'Score', tab: 'GAME', description: "The score is a number that keeps track of the player's progress. Use Add Score to increase it and Get Score to read it."),
  // ── MOVEMENT ─────────────────────────────────────────────────────────────
  _RefCard(title: 'Step', tab: 'MOVEMENT', description: "Makes the sprite try to move. The sprite's movement can be blocked if there are tiles or other sprites in the way. The value defines the number of pixels the sprite will move. Positive values tell the sprite to move to the right, negative values mean move to the left.", code: [['E:On Run'], ['A:Step', 'I:1']]),
  _RefCard(title: 'Jump', tab: 'MOVEMENT', description: 'Makes the sprite jump. The sprite will jump to a certain height (based on the gravity of the game).', code: [['E:On Run'], ['A:Jump', 'I:1']]),
  _RefCard(title: 'Get X', tab: 'MOVEMENT', description: "Returns the sprite's x position.", code: [['E:On Run'], ['A:Set X', 'G:Get X', 'OP:+', 'I:50']]),
  _RefCard(title: 'Get Y', tab: 'MOVEMENT', description: "Returns the sprite's y position.", code: [['E:On Run'], ['A:Set Y', 'G:Get Y', 'OP:+', 'I:50']]),
  _RefCard(title: 'Set X', tab: 'MOVEMENT', description: "Sets the sprite's x position based on the value in the block. The sprite is placed at the new position.", code: [['E:On Run'], ['A:Set X', 'I:300']]),
  _RefCard(title: 'Set Y', tab: 'MOVEMENT', description: "Sets the sprite's y position based on the value in the block. The sprite is placed at the new position.", code: [['E:On Run'], ['A:Set Y', 'I:200']]),
  _RefCard(title: 'Get Rotation', tab: 'MOVEMENT', description: "Returns the sprite's rotation.", code: [['E:On Run'], ['A:Set Rotation', 'G:Get Rotation']]),
  _RefCard(title: 'Set Rotation', tab: 'MOVEMENT', description: 'Rotates the sprite based on the value (given in degrees) in the block. Positive values rotate the sprite clockwise, negative values rotate counterclockwise.', code: [['E:On Run'], ['A:Set Rotation', 'I:180']]),
  _RefCard(title: 'Get Velocity X', tab: 'MOVEMENT', description: "Returns the sprite's horizontal velocity.", code: [['E:On Run'], ['A:Set text', 'G:Get Velocity X']]),
  _RefCard(title: 'Get Velocity Y', tab: 'MOVEMENT', description: "Returns the sprite's vertical velocity.", code: [['E:On Run'], ['A:Set text', 'G:Get Velocity Y']]),
  _RefCard(title: 'Set Speed', tab: 'MOVEMENT', description: "Sets the speed of the sprite. This block changes the speed of the sprite in multiples of its default speed (the default is 1). The block Set Speed doesn't move the sprite itself. Instead it affects how fast or slow the sprite moves when the block Step is called.", code: [['E:On Run'], ['A:Set Speed', 'I:2'], ['A:Step', 'I:300']]),
  _RefCard(title: 'Stop', tab: 'MOVEMENT', description: 'Stops the sprite from moving. Sets the velocity to zero.', code: [['E:On Collide'], ['A:Stop']]),
  _RefCard(title: 'Face Left', tab: 'MOVEMENT', description: 'Flips the sprite to face left.', code: [['E:On Key', 'I:←'], ['A:Face Left'], ['A:Step', 'I:-5']]),
  _RefCard(title: 'Face Right', tab: 'MOVEMENT', description: 'Flips the sprite to face right.', code: [['E:On Key', 'I:→'], ['A:Face Right'], ['A:Step', 'I:5']]),
  _RefCard(title: 'Set Allow Gravity', tab: 'MOVEMENT', description: 'Sets the allow gravity to true. When the block is called, the sprite will be affected by gravity.', code: [['E:On Click'], ['A:Set Allow Gravity', 'B:true']]),
  _RefCard(title: 'Thrust', tab: 'MOVEMENT', description: 'Applies force that pushes the sprite towards the top of the screen. The number is the amount of force. If the game world includes gravity, this number must be large enough to overcome gravity or the sprite will not move.', code: [['E:On Key', 'I:↑'], ['A:Thrust', 'I:2000']]),
  _RefCard(title: 'Rotate Left', tab: 'MOVEMENT', description: 'Rotates the sprite to the left. The number is the speed with which the sprite starts rotating. The sprite slows down automatically so it will not spin forever.', code: [['E:On Key', 'I:←'], ['A:Rotate Left', 'I:5']]),
  _RefCard(title: 'Rotate Right', tab: 'MOVEMENT', description: 'Rotates the sprite to the right. The number is the speed with which the sprite starts rotating. The sprite slows down automatically so it will not spin forever.', code: [['E:On Key', 'I:→'], ['A:Rotate Right', 'I:5']]),
  _RefCard(title: 'Flip', tab: 'MOVEMENT', description: 'Flips the sprite horizontally, mirroring its image.', code: [['E:On Run'], ['A:Flip']]),
  _RefCard(title: 'On Key', tab: 'MOVEMENT', description: 'This block is called when the specified key is pressed. Use it to control sprites with keyboard input.', code: [['E:On Key', 'I:Space'], ['A:Jump', 'I:1']]),
  _RefCard(title: 'If / Else', tab: 'MOVEMENT', description: 'Executes the blocks inside based on a condition. If the condition is true, the first set of blocks runs; otherwise the else blocks run.'),
  _RefCard(title: 'Repeat', tab: 'MOVEMENT', description: 'Repeats the blocks inside a set number of times.', code: [['E:On Run'], ['A:Repeat', 'I:5'], ['A:Step', 'I:10']]),
  _RefCard(title: 'Wait', tab: 'MOVEMENT', description: 'Pauses execution for a number of seconds before continuing.', code: [['E:On Run'], ['A:Wait', 'I:2'], ['A:Jump', 'I:1']]),
  _RefCard(title: 'Add to X', tab: 'MOVEMENT', description: "Adds a value to the sprite's current x position.", code: [['E:On Run'], ['A:Add to X', 'I:50']]),
  _RefCard(title: 'Add to Y', tab: 'MOVEMENT', description: "Adds a value to the sprite's current y position.", code: [['E:On Run'], ['A:Add to Y', 'I:50']]),
  _RefCard(title: 'Set Velocity X', tab: 'MOVEMENT', description: "Sets the sprite's horizontal velocity directly.", code: [['E:On Run'], ['A:Set Velocity X', 'I:200']]),
  _RefCard(title: 'Set Velocity Y', tab: 'MOVEMENT', description: "Sets the sprite's vertical velocity directly.", code: [['E:On Run'], ['A:Set Velocity Y', 'I:-400']]),
  _RefCard(title: 'Set Immovable', tab: 'MOVEMENT', description: 'Sets whether the sprite is immovable. When true, other sprites cannot push this sprite on collision.', code: [['E:On Run'], ['A:Set Immovable', 'B:true']]),
  _RefCard(title: 'Get Distance', tab: 'MOVEMENT', description: 'Returns the distance in pixels between this sprite and another sprite.', code: [['E:On Run'], ['A:Set text', 'G:Get Distance']]),
];

// ── Reference Cards overlay ───────────────────────────────────────────────────

class _ReferenceCardsOverlay extends StatefulWidget {
  const _ReferenceCardsOverlay({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_ReferenceCardsOverlay> createState() => _ReferenceCardsOverlayState();
}

class _ReferenceCardsOverlayState extends State<_ReferenceCardsOverlay> {
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<_RefCard> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _kRefCards;
    return _kRefCards
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            c.tab.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cards = _filtered;
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          child: Container(color: Colors.black.withValues(alpha: 0.35)),
        ),
        Positioned(
          top: 0, right: 0, bottom: 0,
          width: 480,
          child: Container(
            color: const Color(0xFFF5C830),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reference Cards (${cards.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.close, color: Color(0xFF444444), size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 15),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: const Icon(Icons.search, color: Color(0xFF888888), size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF78AD50), width: 1.5)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF78AD50), width: 1.5)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF78AD50), width: 2)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollCtrl,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: cards.length,
                      itemBuilder: (context, i) => _RefCardItem(card: cards[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RefCardItem extends StatefulWidget {
  const _RefCardItem({required this.card});
  final _RefCard card;

  @override
  State<_RefCardItem> createState() => _RefCardItemState();
}

class _RefCardItemState extends State<_RefCardItem> {
  bool _codeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final hasCode = card.code != null && card.code!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF78AD50), width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFE8E8E8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(card.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.description, style: const TextStyle(fontSize: 13, color: Color(0xFF3E7A28), height: 1.45)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Appears in tab:', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                      const SizedBox(width: 6),
                      _TabChip(label: card.tab),
                    ],
                  ),
                  if (hasCode) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _codeExpanded = !_codeExpanded),
                      child: Text(
                        _codeExpanded ? 'Code Example ∧' : 'Code Example ∨',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF4A7AB5)),
                      ),
                    ),
                    if (_codeExpanded) ...[
                      const SizedBox(height: 8),
                      _CodeExampleWidget(rows: card.code!),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF78AD50)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF527A2F), fontWeight: FontWeight.w600)),
    );
  }
}

class _CodeExampleWidget extends StatelessWidget {
  const _CodeExampleWidget({required this.rows});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFDDDDDD)),
      ),
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < rows.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 4, left: i == 0 ? 0 : 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int j = 0; j < rows[i].length; j++) ...[
                        if (j > 0) const SizedBox(width: 3),
                        _buildToken(rows[i][j]),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToken(String token) {
    final colon = token.indexOf(':');
    if (colon < 0) return Text(token);
    final type = token.substring(0, colon);
    final text = token.substring(colon + 1);
    switch (type) {
      case 'E': return _block(text, const Color(0xFF8B3A3A));
      case 'A': return _block(text, const Color(0xFF527A2F));
      case 'G': return _block(text, const Color(0xFF7B6B45), oval: true);
      case 'I': return _input(text);
      case 'B': return _boolBox(text);
      case 'OP': return _block(text, const Color(0xFF7B6B45), small: true);
      default:   return Text(text, style: const TextStyle(fontSize: 12));
    }
  }

  Widget _block(String text, Color color, {bool oval = false, bool small = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 4 : 6),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(oval ? 20 : 4)),
    child: Text(text, style: TextStyle(color: Colors.white, fontSize: small ? 11 : 12, fontWeight: FontWeight.w600)),
  );

  Widget _input(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFE8D9A8), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFC8B878))),
    child: Text(text, style: const TextStyle(color: Color(0xFF444444), fontSize: 12, fontWeight: FontWeight.w500)),
  );

  Widget _boolBox(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF2D3B2D), borderRadius: BorderRadius.circular(4)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 2),
        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
      ],
    ),
  );
}
