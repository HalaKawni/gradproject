import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:highlight/languages/coffeescript.dart';

import '../../scratch_builder/models/instruction_section.dart';
import '../../scratch_builder/widgets/instruction_editor_panel.dart';
import '../../front_view/shared/builder_collectable.dart';
import '../../front_view/shared/builder_character.dart';
import '../../shared/widgets/course_level_nav_banner.dart';
import '../../shared/widgets/challenge_leave_dialog.dart';
import '../../shared/widgets/game_builder_back_icon.dart';
import '../../shared/widgets/game_builder_level_title_field.dart';
import '../../shared/widgets/kids_top_bar_style.dart';
import '../controllers/fourth_demo_controller.dart';
import '../flame/fourth_demo_game.dart';
import '../language/game_code_controller.dart';
import '../language/game_code_indenter.dart';
import '../language/game_command.dart';
import '../language/game_diagnostics.dart';
import '../language/game_language_spec.dart';
import '../models/fourth_demo_project.dart';

class FourthDemoBuilderPage extends StatefulWidget {
  final AuthSession session;
  final String? initialProjectId;
  final bool allowPublishedAccess;
  final bool playMode;
  final String? initialTitle;
  final bool showRatingOnLeave;
  final bool useAdminLevelApi;
  final String? initialCourseId;
  final int? initialOrderInCourse;
  final String initialDifficulty;
  final String initialStatus;
  final String? courseProgressCourseId;
  final String? courseProgressLevelId;

  const FourthDemoBuilderPage({
    super.key,
    required this.session,
    this.initialProjectId,
    this.allowPublishedAccess = false,
    this.playMode = false,
    this.initialTitle,
    this.showRatingOnLeave = true,
    this.useAdminLevelApi = false,
    this.initialCourseId,
    this.initialOrderInCourse,
    this.initialDifficulty = 'medium',
    this.initialStatus = 'draft',
    this.courseProgressCourseId,
    this.courseProgressLevelId,
  });

  @override
  State<FourthDemoBuilderPage> createState() => _FourthDemoBuilderPageState();
}

class _FourthDemoBuilderPageState extends State<FourthDemoBuilderPage> {
  late final FourthDemoController controller;
  late final FourthDemoGame game;
  late final GameCodeController codeController;
  late final TextEditingController titleController;
  final FocusNode stageFocusNode = FocusNode();
  final FocusNode codeFocusNode = FocusNode();
  final List<InstructionSection> instructionSections = <InstructionSection>[];
  bool _loadingCodeIntoEditor = false;
  bool _savingCodeFromEditor = false;
  bool _controllerRefreshScheduled = false;
  bool _isSavingProject = false;
  bool _isLoadingProject = false;
  String? _savedProjectId;
  late String? _courseId;
  late int? _orderInCourse;
  late String _difficulty;
  late String _status;
  String? _codeSpriteId;
  bool _hasSavedCourseProgress = false;
  Map<String, String> _creatorSolutionBySpriteId = <String, String>{};

  final PageController _mobilePageController = PageController();
  int _mobilePage = 0;

  String get _activeCodeSpriteId {
    return _codeSpriteId ??= controller.project.selectedSpriteId;
  }

  @override
  void initState() {
    super.initState();
    _savedProjectId = widget.initialProjectId;
    _courseId = widget.initialCourseId;
    _orderInCourse = widget.initialOrderInCourse;
    _difficulty = widget.initialDifficulty;
    _status = widget.initialStatus;
    controller = FourthDemoController();
    if (widget.initialTitle != null && widget.initialTitle!.trim().isNotEmpty) {
      controller.project = controller.project.copyWith(
        title: widget.initialTitle!.trim(),
      );
    }
    controller.addListener(_handleControllerChanged);
    game = FourthDemoGame(controller: controller);
    codeController =
        GameCodeController(
            text: controller.selectedCode,
            language: coffeescript,
            modifiers: const [TabModifier()],
          )
          ..projectContext = controller.project
          ..addListener(_handleCodeControllerChanged);
    titleController = TextEditingController(text: controller.project.title)
      ..addListener(_handleTitleChanged);
    _codeSpriteId = controller.project.selectedSpriteId;
    instructionSections.addAll(_defaultInstructionSections());
    _captureCreatorSolutions();
    if (widget.playMode) {
      _preparePlayerModeProject();
    }
    if (widget.initialProjectId != null) {
      _loadProject(widget.initialProjectId!);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanged);
    controller.dispose();
    game.onRemove();
    codeController
      ..removeListener(_handleCodeControllerChanged)
      ..dispose();
    titleController
      ..removeListener(_handleTitleChanged)
      ..dispose();
    stageFocusNode.dispose();
    codeFocusNode.dispose();
    _mobilePageController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_controllerRefreshScheduled) {
        return;
      }
      _controllerRefreshScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controllerRefreshScheduled = false;
        _refreshFromController();
      });
      return;
    }

    _refreshFromController();
  }

  void _refreshFromController() {
    if (!mounted) {
      return;
    }

    if (titleController.text != controller.project.title) {
      titleController.value = titleController.value.copyWith(
        text: controller.project.title,
        selection: TextSelection.collapsed(
          offset: controller.project.title.length,
        ),
      );
    }
    final selectedSpriteId = controller.project.selectedSpriteId;
    var activeCodeSpriteId = _activeCodeSpriteId;
    if (activeCodeSpriteId != selectedSpriteId) {
      _saveDisplayedCode();
      _codeSpriteId = selectedSpriteId;
      activeCodeSpriteId = selectedSpriteId;
    }

    _loadCodeForSprite(activeCodeSpriteId);
    codeController.projectContext = controller.project;
    if (widget.playMode && controller.exerciseComplete) {
      unawaited(_saveCourseProgress());
    }
    setState(() {});
  }

  Future<void> _saveCourseProgress() async {
    if (_hasSavedCourseProgress) {
      return;
    }
    final courseId = widget.courseProgressCourseId;
    final levelId = widget.courseProgressLevelId ?? _savedProjectId;
    if (courseId == null ||
        courseId.isEmpty ||
        levelId == null ||
        levelId.isEmpty) {
      return;
    }
    _hasSavedCourseProgress = true;
    final result = await ApiService.completePublicCourseLevel(
      authToken: widget.session.token,
      courseId: courseId,
      levelId: levelId,
    );
    if (result['success'] != true) {
      _hasSavedCourseProgress = false;
    } else if (mounted) {
      setState(() {});
    }
  }

  void _loadCodeForSprite(String spriteId) {
    final nextCode =
        controller.project.codeBySpriteId[spriteId] ??
        FourthDemoProject.starterCode;

    if (codeController.text == nextCode) {
      return;
    }

    _loadingCodeIntoEditor = true;
    try {
      codeController.value = TextEditingValue(
        text: nextCode,
        selection: TextSelection.collapsed(offset: nextCode.length),
      );
    } finally {
      _loadingCodeIntoEditor = false;
    }
  }

  void _handleTitleChanged() {
    controller.setTitle(titleController.text);
  }

  void _handleCodeControllerChanged() {
    if (_loadingCodeIntoEditor || _savingCodeFromEditor) {
      return;
    }
    _syncCodeToProject(codeController.text, spriteId: _activeCodeSpriteId);
  }

  void _syncCodeToProject(String value, {required String spriteId}) {
    final currentCode =
        controller.project.codeBySpriteId[spriteId] ??
        FourthDemoProject.starterCode;
    if (value == currentCode) {
      return;
    }
    _savingCodeFromEditor = true;
    try {
      controller.updateCodeForSprite(spriteId, value, notify: false);
    } finally {
      _savingCodeFromEditor = false;
    }
  }

  void _saveDisplayedCode() {
    _syncCodeToProject(codeController.text, spriteId: _activeCodeSpriteId);
  }

  void _selectSprite(String spriteId) {
    if (!controller.project.sprites.any((sprite) => sprite.id == spriteId)) {
      return;
    }
    if (controller.project.selectedSpriteId == spriteId &&
        _activeCodeSpriteId == spriteId) {
      return;
    }
    _saveDisplayedCode();
    _codeSpriteId = spriteId;
    _loadCodeForSprite(spriteId);
    controller.selectSprite(spriteId);
  }

  void _runCode() {
    _saveDisplayedCode();
    if (!controller.runCode()) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        stageFocusNode.requestFocus();
      }
    });
  }

  void _captureCreatorSolutions() {
    _creatorSolutionBySpriteId = Map<String, String>.from(
      controller.project.codeBySpriteId,
    );
  }

  String get _playerSpriteId {
    return controller.project.sprites
            .where((sprite) => sprite.kind == FourthDemoSpriteKind.player)
            .firstOrNull
            ?.id ??
        controller.project.selectedSpriteId;
  }

  void _preparePlayerModeProject() {
    final playerSpriteId = _playerSpriteId;
    final creatorCode =
        _creatorSolutionBySpriteId[playerSpriteId] ??
        controller.project.codeBySpriteId[playerSpriteId] ??
        '';
    final editableCodeBySpriteId = Map<String, String>.from(
      controller.project.codeBySpriteId,
    );
    editableCodeBySpriteId[playerSpriteId] = _buildPlayerStarterCode(
      creatorCode,
    );
    controller.project = controller.project.copyWith(
      selectedSpriteId: playerSpriteId,
      codeBySpriteId: editableCodeBySpriteId,
    );
    _codeSpriteId = playerSpriteId;
    codeController.projectContext = controller.project;
    _loadCodeForSprite(playerSpriteId);
  }

  String get _visibleSolutionCode {
    final currentSpriteId = _activeCodeSpriteId;
    final currentCode =
        _creatorSolutionBySpriteId[currentSpriteId]?.trim() ?? '';
    if (currentCode.isNotEmpty) {
      return _creatorSolutionBySpriteId[currentSpriteId]!;
    }
    final playerCode =
        _creatorSolutionBySpriteId[_playerSpriteId]?.trim() ?? '';
    if (playerCode.isNotEmpty) {
      return _creatorSolutionBySpriteId[_playerSpriteId]!;
    }
    return FourthDemoProject.starterCode;
  }

  void _showSolutionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) =>
          _SolutionCodeDialog(title: 'Solution', code: _visibleSolutionCode),
    );
  }

  String _buildPlayerStarterCode(String creatorCode) {
    final remainingCode = _removePlayerOnKeyHandlers(creatorCode).trim();
    if (remainingCode.isEmpty) {
      return FourthDemoProject.starterCode;
    }
    return '${FourthDemoProject.starterCode}\n\n$remainingCode';
  }

  String _removePlayerOnKeyHandlers(String code) {
    final lines = const LineSplitter().convert(code);
    if (lines.isEmpty) {
      return code;
    }

    final buffer = <String>[];
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      if (_isPlayerOnKeyHeader(line)) {
        index += 1;
        while (index < lines.length) {
          final nextLine = lines[index];
          if (nextLine.trim().isEmpty || _isIndentedInstructionLine(nextLine)) {
            index += 1;
            continue;
          }
          break;
        }
        continue;
      }
      buffer.add(line);
      index += 1;
    }

    return buffer.join('\n').trim();
  }

  bool _isPlayerOnKeyHeader(String line) {
    return RegExp(
      r'^@onKey\s*=\s*\(\s*key\s*\)\s*=>\s*$',
    ).hasMatch(line.trim());
  }

  bool _isIndentedInstructionLine(String line) {
    return line.startsWith(' ') || line.startsWith('\t');
  }

  Future<void> _handleLeaveRequested() async {
    final projectId = _savedProjectId ?? widget.initialProjectId;
    if (!widget.playMode || projectId == null || projectId.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (!widget.showRatingOnLeave || widget.courseProgressCourseId != null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    final shouldLeave = await showChallengeLeaveDialog(
      context: context,
      title: titleController.text.trim().isEmpty
          ? controller.project.title
          : titleController.text.trim(),
      onSubmitRating: (rating) async {
        final result = await ApiService.rateBuilderProject(
          authToken: widget.session.token,
          projectId: projectId,
          rating: rating,
        );
        if (result['success'] == true) {
          return null;
        }
        return result['message']?.toString() ?? 'Failed to save rating.';
      },
    );

    if (shouldLeave && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final language = AppLanguage.of(context);
    return PopScope(
      canPop: !widget.playMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !widget.playMode) {
          return;
        }
        unawaited(_handleLeaveRequested());
      },
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: const Color(0xFFE8F4EC),
          appBar: AppBar(
            toolbarHeight: KidsTopBarStyle.toolbarHeight,
            backgroundColor: KidsTopBarStyle.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            bottom: KidsTopBarStyle.appBarBottom(),
            leading: IconButton(
              onPressed: widget.playMode
                  ? _handleLeaveRequested
                  : () => Navigator.of(context).maybePop(),
              icon: const GameBuilderBackIcon(),
            ),
            title: widget.playMode
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          titleController.text,
                          style: KidsTopBarStyle.titleTextStyle,
                        ),
                      ),
                      CourseLevelNavBanner(
                        session: widget.session,
                        courseId: widget.courseProgressCourseId,
                        currentLevelId:
                            widget.courseProgressLevelId ?? _savedProjectId,
                        currentLevelSolved: _hasSavedCourseProgress,
                        topBarMode: true,
                      ),
                    ],
                  )
                : GameBuilderLevelTitleField(
                    controller: titleController,
                    hintText: language.t('builder.newLevel'),
                  ),
            actions: widget.playMode
                ? <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: OutlinedButton.icon(
                        onPressed: _showSolutionDialog,
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Show Solution'),
                      ),
                    ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextButton(
                        onPressed:
                            _isSavingProject ||
                                _isLoadingProject ||
                                controller.isPlaying
                            ? null
                            : () => _saveProject(publish: false),
                        style: KidsTopBarStyle.playfulText(
                          KidsTopBarStyle.blue,
                        ),
                        child: Text(language.t('builder.save')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: FilledButton(
                        onPressed:
                            _isSavingProject ||
                                _isLoadingProject ||
                                controller.isPlaying
                            ? null
                            : () => _saveProject(publish: true),
                        style: KidsTopBarStyle.playfulFilled(
                          KidsTopBarStyle.green,
                        ),
                        child: _isSavingProject
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(language.t('builder.publish')),
                      ),
                    ),
                  ],
          ),
          body: _isLoadingProject
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 34,
                            child: widget.playMode
                                ? _InstructionPreviewPanel(
                                    sections: instructionSections,
                                  )
                                : InstructionEditorPanel(
                                    sections: instructionSections,
                                    onAddSection: _addInstructionSection,
                                    onRemoveSection: _removeInstructionSection,
                                    onReorderSections:
                                        _reorderInstructionSections,
                                    onTitleChanged: _updateInstructionTitle,
                                    onContentChanged: _updateInstructionContent,
                                    onAddItem: _addInstructionItem,
                                    onItemChanged: _updateInstructionItem,
                                    onRemoveItem: _removeInstructionItem,
                                  ),
                          ),
                          Expanded(
                            flex: 46,
                            child: _CodeColumn(
                              controller: controller,
                              codeController: codeController,
                              codeFocusNode: codeFocusNode,
                              onRun: _runCode,
                              readOnly: false,
                            ),
                          ),
                          Expanded(
                            flex: 44,
                            child: _StageColumn(
                              controller: controller,
                              game: game,
                              focusNode: stageFocusNode,
                              onSelectSprite: _selectSprite,
                              readOnly: false,
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

  Future<void> _saveProject({required bool publish}) async {
    if (_isSavingProject) {
      return;
    }

    _saveDisplayedCode();
    final validation = controller.project.validate();
    if (validation.isNotEmpty) {
      _showSnackBar(
        validation.join('\n'),
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final status = publish ? 'published' : 'draft';
    setState(() {
      _isSavingProject = true;
    });

    try {
      final projectJson = _buildProjectJson(status: status);
      final response = _savedProjectId == null
          ? await ApiService.createBuilderProject(
              authToken: widget.session.token,
              projectJson: projectJson,
            )
          : widget.useAdminLevelApi
          ? await ApiService.updateAdminLevel(
              authToken: widget.session.token,
              levelId: _savedProjectId!,
              levelJson: {
                'title': projectJson['title'],
                'description': projectJson['description'],
                'status': projectJson['status'],
                'builderType': projectJson['builderType'],
                'difficulty': projectJson['difficulty'],
                'courseId': projectJson['courseId'],
                'orderInCourse': projectJson['orderInCourse'],
                'codeBySpriteId': projectJson['codeBySpriteId'],
                'draftData': projectJson,
              },
            )
          : await ApiService.updateBuilderProject(
              authToken: widget.session.token,
              projectId: _savedProjectId!,
              projectJson: projectJson,
            );

      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map && data['_id'] != null) {
          _savedProjectId = data['_id'].toString();
        }
        _status = status;
        _showSnackBar(
          publish
              ? language.t('builder.projectPublished')
              : language.t('builder.draftSaved'),
          backgroundColor: Colors.green.shade600,
        );
      } else {
        final errors = response['errors'];
        _showSnackBar(
          errors is List && errors.isNotEmpty
              ? errors.join('\n')
              : response['message']?.toString() ??
                    language.t('builder.saveFailedGeneric'),
          backgroundColor: Colors.red.shade600,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        language.t('builder.saveFailed', params: {'error': e.toString()}),
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProject = false;
        });
      }
    }
  }

  Future<void> _loadProject(String projectId) async {
    setState(() {
      _isLoadingProject = true;
    });

    try {
      final response = widget.allowPublishedAccess
          ? await ApiService.getPublishedBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            )
          : widget.useAdminLevelApi
          ? await ApiService.getAdminLevelById(
              authToken: widget.session.token,
              levelId: projectId,
            )
          : await ApiService.getBuilderProjectById(
              authToken: widget.session.token,
              projectId: projectId,
            );

      if (!mounted) {
        return;
      }

      if (response['success'] != true) {
        _showSnackBar(
          response['message']?.toString() ??
              language.t('builder.loadTopViewFailedGeneric'),
          backgroundColor: Colors.red.shade600,
        );
        return;
      }

      final rawData = response['data'];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{};
      final rawDraftData = data['draftData'];
      final draftData = rawDraftData is Map
          ? Map<String, dynamic>.from(rawDraftData)
          : data;

      controller.importJson(const JsonEncoder().convert(draftData));
      final title =
          data['title']?.toString() ??
          draftData['title']?.toString() ??
          widget.initialTitle;
      if (title != null && title.trim().isNotEmpty) {
        controller.setTitle(title);
      }

      _captureCreatorSolutions();
      if (widget.playMode) {
        _preparePlayerModeProject();
      }

      setState(() {
        _savedProjectId = data['_id']?.toString() ?? projectId;
        _courseId =
            data['courseId']?.toString() ??
            draftData['courseId']?.toString() ??
            _courseId;
        _orderInCourse =
            _readInt(data['orderInCourse']) ??
            _readInt(draftData['orderInCourse']) ??
            _orderInCourse;
        _difficulty =
            data['difficulty']?.toString() ??
            draftData['difficulty']?.toString() ??
            _difficulty;
        _status =
            data['status']?.toString() ??
            draftData['status']?.toString() ??
            _status;
        instructionSections
          ..clear()
          ..addAll(_readInstructionSections(draftData['instructionSections']));
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(
        language.t('builder.loadFailed', params: {'error': e.toString()}),
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProject = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildProjectJson({required String status}) {
    return <String, dynamic>{
      ...controller.project.toJson(),
      'builderType': 'fourthDemo',
      'title': titleController.text.trim().isEmpty
          ? AppLanguage.instance.t('builder.newLevel')
          : titleController.text.trim(),
      'description': '',
      'status': status,
      'codeBySpriteId': Map<String, String>.from(
        controller.project.codeBySpriteId,
      ),
      'courseId': _courseId,
      'orderInCourse': _orderInCourse,
      'difficulty': _difficulty,
      'instructionSections': instructionSections
          .map(_instructionSectionToJson)
          .toList(),
    };
  }

  Map<String, dynamic> _instructionSectionToJson(InstructionSection section) {
    return <String, dynamic>{
      'id': section.id,
      'type': section.type.name,
      'title': section.title,
      'content': section.content,
      'items': section.items,
      'collapsed': section.collapsed,
    };
  }

  List<InstructionSection> _readInstructionSections(Object? rawValue) {
    if (rawValue is! List) {
      return _defaultInstructionSections();
    }

    final sections = <InstructionSection>[];
    for (final rawSection in rawValue) {
      if (rawSection is! Map) {
        continue;
      }
      final section = Map<String, dynamic>.from(rawSection);
      final type = _readInstructionSectionType(section['type']);
      sections.add(
        InstructionSection(
          id: section['id']?.toString() ?? 'section-${sections.length + 1}',
          type: type,
          title: _normalizedInstructionSectionTitle(
            type: type,
            rawTitle: section['title']?.toString(),
          ),
          content: section['content']?.toString() ?? '',
          items: section['items'] is List
              ? (section['items'] as List)
                    .map((item) => item.toString())
                    .toList()
              : const <String>[],
          collapsed: section['collapsed'] == true,
        ),
      );
    }

    return sections.isEmpty ? _defaultInstructionSections() : sections;
  }

  InstructionSectionType _readInstructionSectionType(Object? value) {
    final name = value?.toString();
    for (final type in InstructionSectionType.values) {
      if (type.name == name) {
        return type;
      }
    }
    return InstructionSectionType.custom;
  }

  int? _readInt(Object? value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  AppLanguage get language => AppLanguage.instance;

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  List<InstructionSection> _defaultInstructionSections() {
    final language = AppLanguage.instance;
    return <InstructionSection>[
      InstructionSection(
        id: 'overview',
        type: InstructionSectionType.overview,
        title: language.t('builder.overview'),
        content: '',
      ),
      InstructionSection(
        id: 'code-example',
        type: InstructionSectionType.codeExample,
        title: language.t('builder.codeExample'),
        content: '',
      ),
      InstructionSection(
        id: 'instructions',
        type: InstructionSectionType.instructions,
        title: language.t('builder.instructions'),
        content: '',
      ),
    ];
  }

  String _normalizedInstructionSectionTitle({
    required InstructionSectionType type,
    required String? rawTitle,
  }) {
    final title = rawTitle?.trim() ?? '';
    if (type == InstructionSectionType.overview &&
        (title.isEmpty ||
            title.toLowerCase() ==
                AppLanguage.instance
                    .t('builder.welcomeGameBuilder')
                    .trim()
                    .toLowerCase())) {
      return AppLanguage.instance.t('builder.overview');
    }
    return title.isEmpty ? instructionSectionLabel(type) : title;
  }

  void _addInstructionSection(InstructionSectionType type) {
    setState(() {
      instructionSections.add(
        InstructionSection(
          id: 'section-${DateTime.now().microsecondsSinceEpoch}',
          type: type,
          title: instructionSectionLabel(type),
        ),
      );
    });
  }

  void _removeInstructionSection(String id) {
    setState(() {
      instructionSections.removeWhere((section) => section.id == id);
    });
  }

  void _reorderInstructionSections(int oldIndex, int newIndex) {
    setState(() {
      final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final section = instructionSections.removeAt(oldIndex);
      instructionSections.insert(adjustedNewIndex, section);
    });
  }

  void _updateInstructionTitle(String id, String title) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      instructionSections[index] = instructionSections[index].copyWith(
        title: title,
      );
    });
  }

  void _updateInstructionContent(String id, String content) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      instructionSections[index] = instructionSections[index].copyWith(
        content: content,
      );
    });
  }

  void _addInstructionItem(String id) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      instructionSections[index] = section.copyWith(
        items: <String>[...section.items, ''],
      );
    });
  }

  void _updateInstructionItem(String id, int itemIndex, String value) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) {
        return;
      }
      final items = List<String>.from(section.items)..[itemIndex] = value;
      instructionSections[index] = section.copyWith(items: items);
    });
  }

  void _removeInstructionItem(String id, int itemIndex) {
    setState(() {
      final index = instructionSections.indexWhere(
        (section) => section.id == id,
      );
      if (index == -1) {
        return;
      }
      final section = instructionSections[index];
      if (itemIndex < 0 || itemIndex >= section.items.length) {
        return;
      }
      final items = List<String>.from(section.items)..removeAt(itemIndex);
      instructionSections[index] = section.copyWith(items: items);
    });
  }
}

class _InstructionPreviewPanel extends StatelessWidget {
  final List<InstructionSection> sections;

  const _InstructionPreviewPanel({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sections.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  final hasContent =
                      section.content.trim().isNotEmpty ||
                      section.items.any((item) => item.trim().isNotEmpty);
                  if (!hasContent) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xfff8fafc),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffd9e1ea)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _previewSectionTitle(context, section),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InstructionContentPreview(section: section),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionContentPreview extends StatelessWidget {
  final InstructionSection section;

  const _InstructionContentPreview({required this.section});

  @override
  Widget build(BuildContext context) {
    final items = section.items
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
    final richContent = section.content.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (richContent.isNotEmpty)
          _RichInstructionPreview(content: richContent),
        if (items.isNotEmpty) ...[
          if (richContent.isNotEmpty) const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: 8),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF475569),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        height: 1.55,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

String _previewSectionTitle(BuildContext context, InstructionSection section) {
  final title = section.title.trim();
  if (section.type == InstructionSectionType.overview) {
    final welcomeTitle = AppLanguage.of(
      context,
    ).t('builder.welcomeGameBuilder').trim().toLowerCase();
    if (title.isEmpty || title.toLowerCase() == welcomeTitle) {
      return AppLanguage.of(context).t('builder.overview');
    }
  }
  if (title.isEmpty) {
    return localizedInstructionSectionLabel(
      AppLanguage.of(context),
      section.type,
    );
  }
  return title;
}

class _RichInstructionPreview extends StatefulWidget {
  final String content;

  const _RichInstructionPreview({required this.content});

  @override
  State<_RichInstructionPreview> createState() =>
      _RichInstructionPreviewState();
}

class _RichInstructionPreviewState extends State<_RichInstructionPreview> {
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: _documentFromValue(widget.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode(skipTraversal: true);
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _RichInstructionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content == widget.content) {
      return;
    }
    _controller.document = _documentFromValue(widget.content);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: QuillEditor.basic(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        config: QuillEditorConfig(
          autoFocus: false,
          scrollable: false,
          expands: false,
          padding: EdgeInsets.zero,
          showCursor: false,
          embedBuilders: FlutterQuillEmbeds.defaultEditorBuilders(),
          customStyles: DefaultStyles(
            paragraph: DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF334155),
                height: 1.6,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(0, 10),
              const VerticalSpacing(0, 0),
              null,
            ),
            h1: DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(8, 10),
              const VerticalSpacing(0, 0),
              null,
            ),
            h2: DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(6, 8),
              const VerticalSpacing(0, 0),
              null,
            ),
            h3: DefaultTextBlockStyle(
              const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
              const HorizontalSpacing(0, 0),
              const VerticalSpacing(4, 6),
              const VerticalSpacing(0, 0),
              null,
            ),
          ),
        ),
      ),
    );
  }
}

Document _documentFromValue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return Document();
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is List) {
      return Document.fromJson(decoded);
    }
  } catch (_) {
    // Older projects stored raw instruction text.
  }

  final document = Document();
  document.insert(0, value);
  return document;
}

class _SolutionCodeDialog extends StatelessWidget {
  final String title;
  final String code;

  const _SolutionCodeDialog({required this.title, required this.code});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF8FBFD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF24465A),
        ),
      ),
      content: SizedBox(
        width: 760,
        height: 460,
        child: _ReadOnlyCodeViewer(code: code),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ReadOnlyCodeViewer extends StatefulWidget {
  final String code;

  const _ReadOnlyCodeViewer({required this.code});

  @override
  State<_ReadOnlyCodeViewer> createState() => _ReadOnlyCodeViewerState();
}

class _ReadOnlyCodeViewerState extends State<_ReadOnlyCodeViewer> {
  static const double _gutterWidth = 46;
  static const double _editorFontSize = 16;
  static const double _editorLineHeightFactor = 1.45;
  static const double _editorLineHeight =
      _editorFontSize * _editorLineHeightFactor;
  static const double _editorVerticalPadding = 16;

  late final GameCodeController _controller;
  late final FocusNode _focusNode;
  double _verticalScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = GameCodeController(
      text: widget.code,
      language: coffeescript,
      modifiers: const [TabModifier()],
    );
    _focusNode = FocusNode(skipTraversal: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LineNumberGutter(
            controller: _controller,
            scrollOffset: _verticalScrollOffset,
            width: _gutterWidth,
            lineHeight: _editorLineHeight,
            topPadding: _editorVerticalPadding,
          ),
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: atomOneLightTheme),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis != Axis.vertical) {
                    return false;
                  }
                  final nextOffset = notification.metrics.pixels;
                  if ((nextOffset - _verticalScrollOffset).abs() > 0.5) {
                    setState(() => _verticalScrollOffset = nextOffset);
                  }
                  return false;
                },
                child: CodeField(
                  controller: _controller,
                  focusNode: _focusNode,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  readOnly: true,
                  wrap: false,
                  background: const Color(0xFFEEF6FA),
                  cursorColor: const Color(0xFF24465A),
                  gutterStyle: GutterStyle.none,
                  padding: const EdgeInsets.all(14),
                  textStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: _editorFontSize,
                    height: _editorLineHeightFactor,
                    color: Color(0xFF24465A),
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

class _CodeColumn extends StatelessWidget {
  final FourthDemoController controller;
  final GameCodeController codeController;
  final FocusNode codeFocusNode;
  final VoidCallback onRun;
  final bool readOnly;

  const _CodeColumn({
    required this.controller,
    required this.codeController,
    required this.codeFocusNode,
    required this.onRun,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F8FA),
        border: Border.symmetric(
          vertical: BorderSide(color: Color(0xFFC6D2D9), width: 2),
        ),
      ),
      child: Column(
        children: [
          _CodeHeader(controller: controller, onRun: onRun, readOnly: readOnly),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _CodeEditor(
                    controller: controller,
                    codeController: codeController,
                    codeFocusNode: codeFocusNode,
                    readOnly: readOnly,
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: _DiagnosticsPanel(
                    controller: controller,
                    codeController: codeController,
                    codeFocusNode: codeFocusNode,
                  ),
                ),
              ],
            ),
          ),
          _FunctionPalette(
            controller: controller,
            codeController: codeController,
            readOnly: readOnly,
          ),
        ],
      ),
    );
  }
}

class _CodeHeader extends StatelessWidget {
  final FourthDemoController controller;
  final VoidCallback onRun;
  final bool readOnly;

  const _CodeHeader({
    required this.controller,
    required this.onRun,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);
    final sprite = controller.selectedSprite;
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFD9DEE2), width: 2)),
      ),
      child: Row(
        children: [
          _SpriteAvatar(sprite: sprite, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sprite?.name ?? language.t('builder.noSprite'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: readOnly
                ? null
                : controller.isPlaying
                ? controller.stop
                : onRun,
            icon: Icon(controller.isPlaying ? Icons.stop : Icons.play_arrow),
            label: Text(
              controller.isPlaying
                  ? language.t('builder.stop').toUpperCase()
                  : language.t('builder.run').toUpperCase(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: controller.isPlaying
                  ? const Color(0xFFD94836)
                  : const Color(0xFF66B64A),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeEditor extends StatefulWidget {
  final FourthDemoController controller;
  final GameCodeController codeController;
  final FocusNode codeFocusNode;
  final bool readOnly;

  const _CodeEditor({
    required this.controller,
    required this.codeController,
    required this.codeFocusNode,
    this.readOnly = false,
  });

  @override
  State<_CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<_CodeEditor> {
  static const double _gutterWidth = 46;
  static const double _editorFontSize = 16;
  static const double _editorLineHeightFactor = 1.45;
  static const double _editorLineHeight =
      _editorFontSize * _editorLineHeightFactor;
  static const double _editorVerticalPadding = 16;
  double _verticalScrollOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF6FA),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LineNumberGutter(
            controller: widget.codeController,
            scrollOffset: _verticalScrollOffset,
            width: _gutterWidth,
            lineHeight: _editorLineHeight,
            topPadding: _editorVerticalPadding,
          ),
          Expanded(
            child: CodeTheme(
              data: CodeThemeData(styles: atomOneLightTheme),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis != Axis.vertical) {
                      return false;
                    }
                    final nextOffset = notification.metrics.pixels;
                    if ((nextOffset - _verticalScrollOffset).abs() > 0.5) {
                      setState(() => _verticalScrollOffset = nextOffset);
                    }
                    return false;
                  },
                  child: CodeField(
                    controller: widget.codeController,
                    focusNode: widget.codeFocusNode,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    readOnly: widget.controller.isPlaying || widget.readOnly,
                    wrap: false,
                    background: const Color(0xFFEEF6FA),
                    cursorColor: const Color(0xFF24465A),
                    gutterStyle: GutterStyle.none,
                    padding: const EdgeInsets.all(14),
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: _editorFontSize,
                      height: _editorLineHeightFactor,
                      color: Color(0xFF24465A),
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
}

class _LineNumberGutter extends StatelessWidget {
  final GameCodeController controller;
  final double scrollOffset;
  final double width;
  final double lineHeight;
  final double topPadding;

  const _LineNumberGutter({
    required this.controller,
    required this.scrollOffset,
    required this.width,
    required this.lineHeight,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: const Color(0xFFDDEBF2),
      child: ClipRect(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _LineNumberPainter(
                lineCount: controller.text.split('\n').length,
                scrollOffset: scrollOffset,
                lineHeight: lineHeight,
                topPadding: topPadding,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _LineNumberPainter extends CustomPainter {
  final int lineCount;
  final double scrollOffset;
  final double lineHeight;
  final double topPadding;

  const _LineNumberPainter({
    required this.lineCount,
    required this.scrollOffset,
    required this.lineHeight,
    required this.topPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const rightPadding = 8.0;
    final firstLine = math.max(
      0,
      ((scrollOffset - topPadding) / lineHeight).floor() - 1,
    );
    final lastLine = math.min(
      lineCount - 1,
      ((scrollOffset + size.height - topPadding) / lineHeight).ceil() + 1,
    );

    for (var index = firstLine; index <= lastLine; index += 1) {
      final painter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
            height: 1.45,
            color: Color(0xFF6A8291),
          ),
        ),
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width - rightPadding);
      final y =
          topPadding -
          scrollOffset +
          index * lineHeight +
          (lineHeight - painter.height) / 2;
      painter.paint(
        canvas,
        Offset(size.width - rightPadding - painter.width, y),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineNumberPainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.topPadding != topPadding;
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  final FourthDemoController controller;
  final GameCodeController codeController;
  final FocusNode codeFocusNode;

  const _DiagnosticsPanel({
    required this.controller,
    required this.codeController,
    required this.codeFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final diagnostics = controller.diagnostics;
    if (diagnostics.isEmpty && controller.codeError == null) {
      return const SizedBox.shrink();
    }
    final visibleDiagnostics = diagnostics.isEmpty
        ? <GameDiagnostic>[
            GameDiagnostic(
              message: controller.codeError ?? 'Check your code.',
              line: 1,
            ),
          ]
        : diagnostics;

    return Material(
      elevation: 8,
      shadowColor: const Color(0x553A241D),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 96),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            children: [
              for (final entry in visibleDiagnostics.asMap().entries)
                _DiagnosticTile(
                  diagnostic: entry.value,
                  prominent: entry.key == 0,
                  onDismiss: controller.dismissDiagnostics,
                  onGoToLine: () {
                    codeController.moveCursorToLineColumn(
                      entry.value.line,
                      entry.value.column,
                    );
                    codeFocusNode.requestFocus();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  final GameDiagnostic diagnostic;
  final bool prominent;
  final VoidCallback onGoToLine;
  final VoidCallback onDismiss;

  const _DiagnosticTile({
    required this.diagnostic,
    required this.prominent,
    required this.onGoToLine,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (diagnostic.severity) {
      GameDiagnosticSeverity.error => const Color(0xFFD94836),
      GameDiagnosticSeverity.warning => const Color(0xFFD58A00),
      GameDiagnosticSeverity.info => const Color(0xFF2B78C2),
    };
    final background = switch (diagnostic.severity) {
      GameDiagnosticSeverity.error => const Color(0xFFFFF0ED),
      GameDiagnosticSeverity.warning => const Color(0xFFFFF7DF),
      GameDiagnosticSeverity.info => const Color(0xFFEFF6FF),
    };
    final title = switch (diagnostic.type) {
      GameDiagnosticType.syntax => 'Syntax error',
      GameDiagnosticType.validation => 'Validation error',
      GameDiagnosticType.runtime => 'Runtime error',
    };

    return Container(
      margin: EdgeInsets.only(bottom: prominent ? 6 : 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            diagnostic.severity == GameDiagnosticSeverity.error
                ? Icons.error_outline
                : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title - Line ${diagnostic.line}, Column ${diagnostic.column}',
                  style: TextStyle(
                    color: color,
                    fontSize: prominent ? 13 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  diagnostic.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (diagnostic.hint != null && diagnostic.hint!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Hint: ${diagnostic.hint}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5B6777),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onGoToLine,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 30),
                  foregroundColor: color,
                ),
                child: const Text('Go to line'),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
                color: color,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunctionPalette extends StatefulWidget {
  final FourthDemoController controller;
  final GameCodeController codeController;
  final bool readOnly;

  const _FunctionPalette({
    required this.controller,
    required this.codeController,
    this.readOnly = false,
  });

  @override
  State<_FunctionPalette> createState() => _FunctionPaletteState();
}

class _FunctionPaletteState extends State<_FunctionPalette> {
  bool _isTyping = false;
  static const int _typingCharactersPerTick = 3;
  static const Duration _typingTickDelay = Duration(milliseconds: 8);
  static const GameCodeIndenter _indenter = GameCodeIndenter();

  @override
  Widget build(BuildContext context) {
    final items = GameLanguageSpec.byCategory(
      _categoryForTab(widget.controller.paletteTab),
    );
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        color: Color(0xFFE7ECEF),
        border: Border(top: BorderSide(color: Color(0xFFC6D2D9), width: 2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in FourthDemoPaletteTab.values)
                _TabButton(
                  text: _paletteLabel(context, tab),
                  active: widget.controller.paletteTab == tab,
                  onTap: () => widget.controller.setPaletteTab(tab),
                ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final command in items)
                    _CommandPill(
                      label: _commandLabel(context, command),
                      enabled: !widget.controller.isPlaying && !widget.readOnly,
                      onTap: () => _typeSnippet(command),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static GameCommandCategory _categoryForTab(FourthDemoPaletteTab tab) {
    return switch (tab) {
      FourthDemoPaletteTab.movement => GameCommandCategory.movement,
      FourthDemoPaletteTab.events => GameCommandCategory.events,
      FourthDemoPaletteTab.display => GameCommandCategory.display,
      FourthDemoPaletteTab.control => GameCommandCategory.control,
      FourthDemoPaletteTab.operators => GameCommandCategory.operators,
    };
  }

  static String _paletteLabel(BuildContext context, FourthDemoPaletteTab tab) {
    final language = AppLanguage.of(context);
    return switch (tab) {
      FourthDemoPaletteTab.movement => language.t('builder.movement'),
      FourthDemoPaletteTab.events => language.t('builder.events'),
      FourthDemoPaletteTab.display => language.t('builder.display'),
      FourthDemoPaletteTab.control => language.t('builder.control'),
      FourthDemoPaletteTab.operators => language.t('builder.operators'),
    };
  }

  static String _commandLabel(BuildContext context, GameCommand command) {
    return AppLanguage.of(
      context,
    ).tr('builder.command.${command.label}', command.label);
  }

  Future<void> _typeSnippet(GameCommand command) async {
    if (_isTyping || widget.controller.isPlaying) {
      return;
    }
    _isTyping = true;

    try {
      final text = widget.codeController.text;
      final selection = widget.codeController.selection;
      final start = selection.isValid ? selection.start : text.length;
      final end = selection.isValid ? selection.end : text.length;
      final insertion = _indenter.insertCommand(
        code: text,
        start: start,
        end: end,
        command: command,
      );
      final insertText = insertion.text.substring(
        insertion.animationStart,
        insertion.animationEnd,
      );
      var next = text.replaceRange(insertion.animationStart, end, '');
      widget.codeController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: insertion.animationStart),
      );

      var offset = insertion.animationStart;
      final units = insertText.characters.toList();
      for (
        var index = 0;
        index < units.length;
        index += _typingCharactersPerTick
      ) {
        if (!mounted) {
          return;
        }

        final chunk = units.skip(index).take(_typingCharactersPerTick).join();
        next = widget.codeController.text.replaceRange(offset, offset, chunk);
        offset += chunk.length;
        widget.codeController.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: offset),
        );
        await Future<void>.delayed(_typingTickDelay);
      }

      widget.codeController.value = TextEditingValue(
        text: widget.codeController.text,
        selection: TextSelection.collapsed(offset: insertion.cursorOffset),
      );
    } finally {
      _isTyping = false;
    }
  }
}

class _StageColumn extends StatelessWidget {
  final FourthDemoController controller;
  final FourthDemoGame game;
  final FocusNode focusNode;
  final ValueChanged<String> onSelectSprite;
  final bool readOnly;

  const _StageColumn({
    required this.controller,
    required this.game,
    required this.focusNode,
    required this.onSelectSprite,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F1),
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: IgnorePointer(
              ignoring: readOnly,
              child: _StagePanel(
                controller: controller,
                game: game,
                focusNode: focusNode,
                onSelectSprite: onSelectSprite,
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: IgnorePointer(
              ignoring: readOnly,
              child: _AssetManager(
                controller: controller,
                onSelectSprite: onSelectSprite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePanel extends StatefulWidget {
  final FourthDemoController controller;
  final FourthDemoGame game;
  final FocusNode focusNode;
  final ValueChanged<String> onSelectSprite;

  const _StagePanel({
    required this.controller,
    required this.game,
    required this.focusNode,
    required this.onSelectSprite,
  });

  @override
  State<_StagePanel> createState() => _StagePanelState();
}

class _StagePanelState extends State<_StagePanel> {
  Offset? _hoveredWorldPosition;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return KeyboardListener(
      focusNode: widget.focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          widget.controller.handleKeyDown(event.logicalKey);
        } else if (event is KeyUpEvent) {
          widget.controller.handleKeyUp(event.logicalKey);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: MouseRegion(
                      onHover: (event) {
                        setState(() {
                          _hoveredWorldPosition = widget.game
                              .worldPositionFromCanvas(event.localPosition);
                        });
                      },
                      onExit: (_) {
                        setState(() => _hoveredWorldPosition = null);
                      },
                      child: GestureDetector(
                        onTapDown: (details) {
                          widget.focusNode.requestFocus();
                          final worldPosition = widget.game
                              .worldPositionFromCanvas(details.localPosition);
                          controller.handleClick(worldPosition);
                          if (!controller.isPlaying) {
                            final hit = controller.spriteAt(worldPosition);
                            if (hit != null) {
                              widget.onSelectSprite(hit.id);
                            }
                            controller.beginDrag(worldPosition);
                            controller.endDrag();
                          }
                        },
                        onPanStart: (details) {
                          widget.focusNode.requestFocus();
                          final worldPosition = widget.game
                              .worldPositionFromCanvas(details.localPosition);
                          if (!controller.isPlaying) {
                            final hit = controller.spriteAt(worldPosition);
                            if (hit != null) {
                              widget.onSelectSprite(hit.id);
                            }
                          }
                          controller.beginDrag(worldPosition);
                        },
                        onPanUpdate: (details) => controller.dragTo(
                          widget.game.worldPositionFromCanvas(
                            details.localPosition,
                          ),
                        ),
                        onPanEnd: (details) {
                          if (controller.draggingSpriteId != null ||
                              controller.draggingWidgetId != null) {
                            controller.endDrag();
                            return;
                          }
                          if (controller.isPlaying) {
                            final direction = _swipeDirection(
                              details.velocity.pixelsPerSecond,
                            );
                            if (direction != null) {
                              controller.handleSwipe(direction);
                            }
                          }
                        },
                        onPanCancel: () {
                          if (controller.draggingSpriteId != null ||
                              controller.draggingWidgetId != null) {
                            controller.endDrag();
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: GameWidget(game: widget.game),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_hoveredWorldPosition != null)
              Positioned(
                top: 10,
                left: 10,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      border: Border.all(color: const Color(0xFFC6D2D9)),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        'x: ${_hoveredWorldPosition!.dx.round()}  '
                        'y: ${_hoveredWorldPosition!.dy.round()}',
                        style: const TextStyle(
                          color: Color(0xFF263238),
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _ToolButton(
                    icon: Icons.north_west,
                    active: controller.stageTool == FourthDemoStageTool.select,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.select),
                  ),
                  _ToolButton(
                    icon: Icons.open_with,
                    active: controller.stageTool == FourthDemoStageTool.move,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.move),
                  ),
                  _ToolButton(
                    icon: Icons.auto_fix_off,
                    active: controller.stageTool == FourthDemoStageTool.eraser,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.eraser),
                  ),
                  _ToolButton(
                    icon: Icons.brush,
                    active: controller.stageTool == FourthDemoStageTool.brush,
                    onTap: () =>
                        controller.setStageTool(FourthDemoStageTool.brush),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _swipeDirection(Offset velocity) {
    const minimumVelocity = 240.0;
    if (velocity.distance < minimumVelocity) {
      return null;
    }
    if (velocity.dx.abs() >= velocity.dy.abs()) {
      return velocity.dx > 0 ? 'right' : 'left';
    }
    return velocity.dy > 0 ? 'down' : 'up';
  }
}

class _AssetManager extends StatefulWidget {
  final FourthDemoController controller;
  final ValueChanged<String> onSelectSprite;

  const _AssetManager({required this.controller, required this.onSelectSprite});

  @override
  State<_AssetManager> createState() => _AssetManagerState();
}

class _AssetManagerState extends State<_AssetManager> {
  String? _editingSpriteId;
  String? _editingWidgetId;
  String? _editingSoundId;

  FourthDemoController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFC6D2D9), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final tab in FourthDemoAssetTab.values)
                _TabButton(
                  text: _assetLabel(context, tab),
                  active: controller.assetTab == tab,
                  onTap: () {
                    setState(_clearEditing);
                    controller.setAssetTab(tab);
                  },
                ),
            ],
          ),
          Expanded(
            child: switch (controller.assetTab) {
              FourthDemoAssetTab.sprites =>
                _editingSpriteId == null
                    ? _buildSpritesGrid(context)
                    : _buildSpriteSettings(context),
              FourthDemoAssetTab.widgets =>
                _editingWidgetId == null
                    ? _buildWidgetsGrid(context)
                    : _buildWidgetSettings(context),
              FourthDemoAssetTab.sounds =>
                _editingSoundId == null
                    ? _buildSoundsGrid(context)
                    : _buildSoundSettings(context),
              FourthDemoAssetTab.game => _GameTab(controller: controller),
            },
          ),
        ],
      ),
    );
  }

  static String _assetLabel(BuildContext context, FourthDemoAssetTab tab) {
    final language = AppLanguage.of(context);
    return switch (tab) {
      FourthDemoAssetTab.sprites => language.t('builder.sprites'),
      FourthDemoAssetTab.widgets => language.t('builder.widgets'),
      FourthDemoAssetTab.sounds => language.t('builder.sounds'),
      FourthDemoAssetTab.game => language.t('builder.game'),
    };
  }

  void _clearEditing() {
    _editingSpriteId = null;
    _editingWidgetId = null;
    _editingSoundId = null;
  }

  Widget _buildSpritesGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSprite(context)),
            for (final sprite in controller.project.sprites)
              _SpriteCard(
                sprite: sprite,
                selected: sprite.id == controller.project.selectedSpriteId,
                onTap: () => widget.onSelectSprite(sprite.id),
                onSettings: () => setState(() => _editingSpriteId = sprite.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSprite(BuildContext context) async {
    final choice = await _showSpriteChoiceDialog(context);
    if (choice == null || !context.mounted) {
      return;
    }
    final sprite = controller.addSpriteFromAsset(
      name: choice.label,
      kind: choice.kind,
      assetId: choice.id,
    );
    widget.onSelectSprite(sprite.id);
    setState(() => _editingSpriteId = sprite.id);
  }

  Widget _buildWidgetsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddWidget(context)),
            for (final widget in controller.project.widgets)
              _MiniAssetCard(
                title: widget.name,
                icon: _widgetIcon(widget.type),
                onTap: () => setState(() => _editingWidgetId = widget.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddWidget(BuildContext context) async {
    final type = await _showWidgetChoiceDialog(context);
    if (type == null || !context.mounted) {
      return;
    }
    final widget = controller.addWidget(type);
    setState(() => _editingWidgetId = widget.id);
  }

  Widget _buildSoundsGrid(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          alignment: WrapAlignment.start,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _AddNewCard(onTap: () => _handleAddSound(context)),
            for (final sound in controller.project.sounds)
              _SoundCard(
                sound: sound,
                onSettings: () => setState(() => _editingSoundId = sound.id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAddSound(BuildContext context) async {
    final choice = await _showSoundChoiceDialog(context);
    if (choice == null || !context.mounted) {
      return;
    }
    final sound = controller.addSoundFromAsset(
      name: choice.label,
      assetPath: _normalizeSoundAssetPath(choice.assetPath),
    );
    setState(() => _editingSoundId = sound.id);
  }

  Widget _buildSpriteSettings(BuildContext context) {
    final sprite = controller.project.sprites
        .where((sprite) => sprite.id == _editingSpriteId)
        .firstOrNull;
    if (sprite == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingSpriteId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _SpriteInlineSettings(
      sprite: sprite,
      onBack: () => setState(() => _editingSpriteId = null),
      onChanged: controller.updateSprite,
      onDelete: () {
        if (controller.deleteSprite(sprite.id)) {
          widget.onSelectSprite(controller.project.selectedSpriteId);
          setState(() => _editingSpriteId = null);
        }
      },
      onDuplicate: () {
        final copy = controller.duplicateSprite(sprite.id);
        if (copy != null) {
          widget.onSelectSprite(copy.id);
          setState(() => _editingSpriteId = copy.id);
        }
      },
    );
  }

  Widget _buildWidgetSettings(BuildContext context) {
    final widget = controller.project.widgets
        .where((widget) => widget.id == _editingWidgetId)
        .firstOrNull;
    if (widget == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingWidgetId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _WidgetInlineSettings(
      widget: widget,
      onBack: () => setState(() => _editingWidgetId = null),
      onChanged: controller.updateWidget,
      onDelete: () {
        controller.deleteWidget(widget.id);
        setState(() => _editingWidgetId = null);
      },
      onDuplicate: () {
        final copy = controller.duplicateWidget(widget.id);
        if (copy != null) {
          setState(() => _editingWidgetId = copy.id);
        }
      },
    );
  }

  Widget _buildSoundSettings(BuildContext context) {
    final sound = controller.project.sounds
        .where((sound) => sound.id == _editingSoundId)
        .firstOrNull;
    if (sound == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _editingSoundId = null);
        }
      });
      return const SizedBox.shrink();
    }
    return _SoundInlineSettings(
      sound: sound,
      onBack: () => setState(() => _editingSoundId = null),
      onChanged: controller.updateSound,
      onDelete: () {
        controller.deleteSound(sound.id);
        setState(() => _editingSoundId = null);
      },
    );
  }
}

class _SpriteCard extends StatelessWidget {
  final FourthDemoSprite sprite;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onSettings;

  const _SpriteCard({
    required this.sprite,
    required this.selected,
    required this.onTap,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF66B64A) : const Color(0xFFD9DEE2),
            width: selected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            _SpriteAvatar(sprite: sprite, size: 54),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sprite.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  tooltip: AppLanguage.of(context).t('builder.settings'),
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  final FourthDemoSound sound;
  final VoidCallback onSettings;

  const _SoundCard({required this.sound, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 124,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF2B78C2), size: 34),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                sound.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SoundPlayButton(assetPath: sound.assetPath, compact: true),
                IconButton(
                  tooltip: AppLanguage.of(context).t('builder.settings'),
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 34,
                    height: 34,
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

class _SpriteInlineSettings extends StatelessWidget {
  final FourthDemoSprite sprite;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoSprite> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SpriteInlineSettings({
    required this.sprite,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.spriteSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetTextField(
            label: AppLanguage.of(context).t('builder.name').toUpperCase(),
            value: sprite.name,
            onChanged: (value) => onChanged(
              sprite.copyWith(
                name: value.trim().isEmpty ? sprite.name : value.trim(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _NumberStepperField(
                label: 'X',
                value: sprite.x,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(x: value, startX: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: sprite.y,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(y: value, startY: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(context).t('builder.scale').toUpperCase(),
                value: sprite.scale,
                step: 0.1,
                min: 0.1,
                decimals: 1,
                onChanged: (value) => onChanged(sprite.copyWith(scale: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(
                  context,
                ).t('builder.rotation').toUpperCase(),
                value: sprite.rotation,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(rotation: value)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DirectionSelector(
            value: sprite.facing,
            onChanged: (value) => onChanged(sprite.copyWith(facing: value)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 0,
            children: [
              _BoolOption(
                label: AppLanguage.of(context).t('builder.allowGravity'),
                value: sprite.allowGravity,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(allowGravity: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.collideWorldBounds'),
                value: sprite.collideWorldBounds,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideWorldBounds: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.immovable'),
                value: sprite.immovable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(immovable: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.show'),
                value: sprite.visible,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(visible: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.collideOtherSprites'),
                value: sprite.collideOtherSprites,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(collideOtherSprites: value)),
              ),
              _BoolOption(
                label: AppLanguage.of(context).t('builder.draggable'),
                value: sprite.draggable,
                onChanged: (value) =>
                    onChanged(sprite.copyWith(draggable: value)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _DirectionSelector extends StatelessWidget {
  final FourthDemoSpriteFacing value;
  final ValueChanged<FourthDemoSpriteFacing> onChanged;

  const _DirectionSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLanguage.of(context).t('builder.direction').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        SegmentedButton<FourthDemoSpriteFacing>(
          segments: [
            ButtonSegment(
              value: FourthDemoSpriteFacing.left,
              icon: const Icon(Icons.arrow_back),
              label: Text(AppLanguage.of(context).t('builder.left')),
            ),
            ButtonSegment(
              value: FourthDemoSpriteFacing.right,
              icon: const Icon(Icons.arrow_forward),
              label: Text(AppLanguage.of(context).t('builder.right')),
            ),
          ],
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ],
    );
  }
}

class _WidgetInlineSettings extends StatelessWidget {
  final FourthDemoScreenWidget widget;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoScreenWidget> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _WidgetInlineSettings({
    required this.widget,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.widgetSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _widgetIcon(widget.type),
                  color: const Color(0xFF24465A),
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _AssetTextField(
                      label: AppLanguage.of(
                        context,
                      ).t('builder.name').toUpperCase(),
                      value: widget.name,
                      onChanged: (value) => onChanged(
                        widget.copyWith(
                          name: value.trim().isEmpty
                              ? widget.name
                              : value.trim(),
                        ),
                      ),
                    ),
                    _AssetTextField(
                      label: AppLanguage.of(
                        context,
                      ).t('builder.text').toUpperCase(),
                      value: widget.text,
                      onChanged: (value) =>
                          onChanged(widget.copyWith(text: value)),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _WidgetTextAlignSelector(
                        value: widget.textAlign,
                        onChanged: (value) =>
                            onChanged(widget.copyWith(textAlign: value)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 18,
            children: [
              _NumberStepperField(
                label: 'X',
                value: widget.x,
                onChanged: (value) => onChanged(widget.copyWith(x: value)),
              ),
              _NumberStepperField(
                label: 'Y',
                value: widget.y,
                onChanged: (value) => onChanged(widget.copyWith(y: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(context).t('builder.value').toUpperCase(),
                value: widget.value,
                onChanged: (value) => onChanged(widget.copyWith(value: value)),
              ),
              _NumberStepperField(
                label: AppLanguage.of(
                  context,
                ).t('builder.opacity').toUpperCase(),
                value: widget.opacity,
                step: 0.1,
                min: 0,
                max: 1,
                decimals: 1,
                onChanged: (value) =>
                    onChanged(widget.copyWith(opacity: value)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _BoolOption(
                label: AppLanguage.of(context).t('builder.show'),
                value: widget.visible,
                onChanged: (value) =>
                    onChanged(widget.copyWith(visible: value)),
              ),
              const Spacer(),
              Text(
                AppLanguage.of(context).t('builder.textColor'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              _ColorPickerButton(
                color: Color(widget.textColorValue),
                onChanged: (color) => onChanged(
                  widget.copyWith(textColorValue: color.toARGB32()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsActions(onDelete: onDelete, onDuplicate: onDuplicate),
        ],
      ),
    );
  }
}

class _WidgetTextAlignSelector extends StatelessWidget {
  final FourthDemoWidgetTextAlign value;
  final ValueChanged<FourthDemoWidgetTextAlign> onChanged;

  const _WidgetTextAlignSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<FourthDemoWidgetTextAlign>(
      segments: const [
        ButtonSegment(
          value: FourthDemoWidgetTextAlign.left,
          icon: Icon(Icons.format_align_left),
        ),
        ButtonSegment(
          value: FourthDemoWidgetTextAlign.center,
          icon: Icon(Icons.format_align_center),
        ),
        ButtonSegment(
          value: FourthDemoWidgetTextAlign.right,
          icon: Icon(Icons.format_align_right),
        ),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SoundInlineSettings extends StatelessWidget {
  final FourthDemoSound sound;
  final VoidCallback onBack;
  final ValueChanged<FourthDemoSound> onChanged;
  final VoidCallback onDelete;

  const _SoundInlineSettings({
    required this.sound,
    required this.onBack,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _InlineSettingsScaffold(
      title: AppLanguage.of(context).t('builder.soundSettings'),
      onBack: onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  color: Color(0xFF24465A),
                  size: 44,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _AssetTextField(
                  label: AppLanguage.of(
                    context,
                  ).t('builder.name').toUpperCase(),
                  value: sound.name,
                  commitOnEditingComplete: true,
                  onChanged: (value) => onChanged(
                    sound.copyWith(
                      name: value.trim().isEmpty ? sound.name : value.trim(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingRow(
            label: AppLanguage.of(context).tr('builder.soundAsset', 'Asset'),
            value: _soundFileName(sound.assetPath),
          ),
          const SizedBox(height: 8),
          _SoundPlayerPanel(sound: sound),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.cancel),
              label: Text(
                AppLanguage.of(context).t('builder.delete').toUpperCase(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundPlayerPanel extends StatelessWidget {
  final FourthDemoSound sound;

  const _SoundPlayerPanel({required this.sound});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Row(
        children: [
          _SoundPlayButton(assetPath: sound.assetPath),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _soundFileName(sound.assetPath),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundPlayButton extends StatefulWidget {
  final String assetPath;
  final bool compact;

  const _SoundPlayButton({required this.assetPath, this.compact = false});

  @override
  State<_SoundPlayButton> createState() => _SoundPlayButtonState();
}

class _SoundPlayButtonState extends State<_SoundPlayButton> {
  late final AudioPlayer _player;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer()
      ..onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() => _playing = false);
        }
      });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 30.0 : 42.0;
    return IconButton.filled(
      tooltip: AppLanguage.of(context).tr('builder.playSound', 'Play sound'),
      onPressed: _toggle,
      icon: Icon(_playing ? Icons.stop : Icons.play_arrow, size: 18),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFF66B64A),
        foregroundColor: Colors.white,
        fixedSize: Size(size, size),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _toggle() async {
    final assetPath = _normalizeSoundAssetPath(widget.assetPath);
    try {
      if (_playing) {
        await _player.stop();
        if (mounted) {
          setState(() => _playing = false);
        }
        return;
      }

      await _player.stop();
      final audio = await _loadSoundAssetData(assetPath);
      final bytes = Uint8List.view(
        audio.buffer,
        audio.offsetInBytes,
        audio.lengthInBytes,
      );
      await _player.play(
        BytesSource(bytes, mimeType: _audioMimeType(assetPath)),
      );
      if (mounted) {
        setState(() => _playing = true);
      }
    } catch (error) {
      debugPrint('Failed to play sound: $assetPath');
      debugPrint('$error');
      if (!mounted) {
        return;
      }
      setState(() => _playing = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Could not load sound: ${_soundFileName(assetPath)}'),
        ),
      );
    }
  }
}

Future<ByteData> _loadSoundAssetData(String assetPath) async {
  Object? lastError;
  for (final candidate in _soundAssetBundleCandidates(assetPath)) {
    try {
      return await rootBundle.load(candidate);
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError ?? FlutterError('Sound asset was not found: $assetPath');
}

List<String> _soundAssetBundleCandidates(String assetPath) {
  final normalized = _normalizeSoundAssetPath(assetPath);
  final withoutAssetPrefix = normalized.startsWith('assets/')
      ? normalized.substring('assets/'.length)
      : normalized;
  final withAssetPrefix = withoutAssetPrefix.startsWith('assets/')
      ? withoutAssetPrefix
      : 'assets/$withoutAssetPrefix';
  return <String>{normalized, withAssetPrefix, withoutAssetPrefix}.toList();
}

String _audioMimeType(String assetPath) {
  final extension = assetPath.split('.').last.toLowerCase();
  return switch (extension) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'ogg' => 'audio/ogg',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    _ => 'application/octet-stream',
  };
}

String _soundFileName(String assetPath) {
  final normalized = _normalizeSoundAssetPath(assetPath).replaceAll('\\', '/');
  final fileName = normalized.split('/').last;
  final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  return withoutExtension
      .split(RegExp(r'[-_]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _InlineSettingsScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _InlineSettingsScaffold({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFD9DEE2))),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: AppLanguage.of(context).t('builder.back'),
                onPressed: onBack,
                icon: const GameBuilderBackIcon(),
              ),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _AssetTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool commitOnEditingComplete;

  const _AssetTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.commitOnEditingComplete = false,
  });

  @override
  State<_AssetTextField> createState() => _AssetTextFieldState();
}

class _AssetTextFieldState extends State<_AssetTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String? _lastCommittedValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _lastCommittedValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _AssetTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
      _lastCommittedValue = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: _fieldDecoration(widget.label),
        onChanged: widget.commitOnEditingComplete ? null : widget.onChanged,
        onEditingComplete: () {
          _commit();
          _focusNode.unfocus();
        },
      ),
    );
  }

  void _handleFocusChanged() {
    if (widget.commitOnEditingComplete && !_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final next = _controller.text;
    if (_lastCommittedValue == next) {
      return;
    }
    _lastCommittedValue = next;
    widget.onChanged(next);
  }
}

class _NumberStepperField extends StatefulWidget {
  final String label;
  final double value;
  final double step;
  final double? min;
  final double? max;
  final int decimals;
  final ValueChanged<double> onChanged;

  const _NumberStepperField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min,
    this.max,
    this.decimals = 0,
  });

  @override
  State<_NumberStepperField> createState() => _NumberStepperFieldState();
}

class _NumberStepperFieldState extends State<_NumberStepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _format(widget.value);
    if (oldWidget.value != widget.value && _controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _fieldDecoration(widget.label).copyWith(
          suffixIcon: SizedBox(
            width: 26,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _nudge(widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
                InkWell(
                  onTap: () => _nudge(-widget.step),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Color(0xFF82B366),
                  ),
                ),
              ],
            ),
          ),
        ),
        onChanged: (raw) {
          final value = double.tryParse(raw);
          if (value != null) {
            widget.onChanged(_clamp(value));
          }
        },
      ),
    );
  }

  void _nudge(double amount) {
    final current = double.tryParse(_controller.text) ?? widget.value;
    final next = _clamp(current + amount);
    _controller.text = _format(next);
    widget.onChanged(next);
  }

  double _clamp(double value) {
    final min = widget.min;
    final max = widget.max;
    var next = value;
    if (min != null && next < min) {
      next = min;
    }
    if (max != null && next > max) {
      next = max;
    }
    return next;
  }

  String _format(double value) => value.toStringAsFixed(widget.decimals);
}

class _BoolOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BoolOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: CheckboxListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SettingsActions extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _SettingsActions({required this.onDelete, required this.onDuplicate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.cancel),
          label: Text(
            AppLanguage.of(context).t('builder.delete').toUpperCase(),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF777777),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onDuplicate,
          icon: const Icon(Icons.add_circle),
          label: Text(
            AppLanguage.of(context).t('builder.duplicate').toUpperCase(),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF57C78A),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onChanged;

  const _ColorPickerButton({required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorSelector(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 72,
        height: 42,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0D0D0)),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: const Color(0xFF777777)),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorSelector(BuildContext context) async {
    var draft = color;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.of(context).t('builder.textColor')),
        content: SizedBox(
          width: 260,
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (value) {
              draft = value;
              onChanged(value);
            },
            enableAlpha: false,
            displayThumbColor: true,
            pickerAreaHeightPercent: 0.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(draft);
              Navigator.of(context).pop();
            },
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
        ],
      ),
    );
  }
}

class _AddNewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 128,
        height: 124,
        decoration: BoxDecoration(
          color: const Color(0xFF66B64A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3E8D41), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.white, size: 38),
            const SizedBox(height: 8),
            Text(
              AppLanguage.of(context).t('builder.addNew').toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTab extends StatelessWidget {
  final FourthDemoController controller;

  const _GameTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    final settings = controller.project.settings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _SettingRow(
            label: AppLanguage.of(context).t('builder.background'),
            value: settings.background,
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.worldWidth'),
            value: settings.worldWidth,
            onChanged: (value) =>
                controller.updateSettings(settings.copyWith(worldWidth: value)),
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.worldHeight'),
            value: settings.worldHeight,
            onChanged: (value) => controller.updateSettings(
              settings.copyWith(worldHeight: value),
            ),
          ),
          _NumberSetting(
            label: AppLanguage.of(context).t('builder.gravity'),
            value: settings.gravity,
            onChanged: (value) =>
                controller.updateSettings(settings.copyWith(gravity: value)),
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.physicsMode'),
            value: settings.physicsMode.name,
          ),
          _CameraTargetSetting(controller: controller, settings: settings),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.tilemap'),
            value: 'ground, platform, obstacle',
          ),
          _SettingRow(
            label: AppLanguage.of(context).t('builder.soundSettingsLabel'),
            value: 'enabled',
          ),
        ],
      ),
    );
  }
}

class _MiniAssetCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniAssetCard({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 128,
        height: 124,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2B78C2), size: 38),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpriteAvatar extends StatelessWidget {
  final FourthDemoSprite? sprite;
  final double size;

  const _SpriteAvatar({required this.sprite, required this.size});

  @override
  Widget build(BuildContext context) {
    final kind = sprite?.kind;
    final assetId = sprite?.assetId ?? '';
    final playerAssetPath = builderCharacterById(
      assetId.isEmpty ? defaultBuilderCharacterId : assetId,
    ).idlePreviewAssetPath;
    final collectableAssetPath = builderCollectableById(
      assetId.isEmpty ? defaultBuilderCollectableId : assetId,
    ).flutterAssetPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child:
          kind == FourthDemoSpriteKind.player ||
              kind == FourthDemoSpriteKind.collectible
          ? Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Image.asset(
                kind == FourthDemoSpriteKind.player
                    ? playerAssetPath
                    : collectableAssetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
              ),
            )
          : Icon(
              switch (kind) {
                FourthDemoSpriteKind.collectible => Icons.eco,
                FourthDemoSpriteKind.prop => Icons.category,
                null => Icons.help,
                FourthDemoSpriteKind.player => Icons.face,
              },
              color: Color(sprite?.colorValue ?? 0xFF66B64A),
              size: size * 0.62,
            ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? Colors.white : const Color(0xFFD3D9DD),
        borderRadius: active
            ? BorderRadius.zero
            : const BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
        child: InkWell(
          onTap: onTap,
          borderRadius: active
              ? const BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                )
              : BorderRadius.zero,
          child: SizedBox(
            height: 54,
            child: Center(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: active ? FontWeight.w900 : FontWeight.w500,
                  color: active ? Colors.black : const Color(0xFF6C747A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _CommandPill({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFEAF8EA) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: enabled ? const Color(0xFF66B64A) : const Color(0xFFCBD5E1),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.black : const Color(0xFF94A3B8),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: IconButton.filled(
        tooltip: AppLanguage.of(context).t('builder.stageTool'),
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: active ? const Color(0xFF66B64A) : Colors.white,
          foregroundColor: active ? Colors.white : const Color(0xFF3A241D),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD9DEE2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B78C2),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraTargetSetting extends StatelessWidget {
  final FourthDemoController controller;
  final FourthDemoGameSettings settings;

  const _CameraTargetSetting({
    required this.controller,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final sprites = controller.project.sprites;
    final currentValue =
        sprites.any((sprite) => sprite.id == settings.cameraTargetId)
        ? settings.cameraTargetId
        : (sprites.isEmpty ? '' : sprites.first.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        initialValue: currentValue.isEmpty ? null : currentValue,
        decoration: _fieldDecoration(
          AppLanguage.of(context).t('builder.cameraTarget'),
        ),
        items: [
          for (final sprite in sprites)
            DropdownMenuItem<String>(
              value: sprite.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SpriteAvatar(sprite: sprite, size: 26),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      sprite.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: controller.isPlaying
            ? null
            : (value) {
                if (value == null || value.isEmpty) {
                  return;
                }
                controller.updateSettings(
                  settings.copyWith(cameraTargetId: value),
                );
              },
      ),
    );
  }
}

class _NumberSetting extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toStringAsFixed(0),
        keyboardType: TextInputType.number,
        decoration: _fieldDecoration(label),
        onFieldSubmitted: (raw) => onChanged(double.tryParse(raw) ?? value),
      ),
    );
  }
}

class _SpriteAssetChoice {
  final String id;
  final String label;
  final String assetPath;
  final FourthDemoSpriteKind kind;

  const _SpriteAssetChoice({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.kind,
  });
}

class _SoundAssetChoice {
  final String id;
  final String label;
  final String assetPath;

  const _SoundAssetChoice({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

Future<_SpriteAssetChoice?> _showSpriteChoiceDialog(
  BuildContext context,
) async {
  final choices = <_SpriteAssetChoice>[
    for (final character in builderCharacters)
      _SpriteAssetChoice(
        id: character.id,
        label: localizedBuilderCharacterLabel(
          AppLanguage.of(context),
          character.id,
        ),
        assetPath: character.idlePreviewAssetPath,
        kind: FourthDemoSpriteKind.player,
      ),
    for (final collectable in builderCollectables)
      _SpriteAssetChoice(
        id: collectable.id,
        label: localizedBuilderCollectableLabel(
          AppLanguage.of(context),
          collectable.id,
        ),
        assetPath: collectable.flutterAssetPath,
        kind: FourthDemoSpriteKind.collectible,
      ),
  ];
  var selected = choices.first;

  return showDialog<_SpriteAssetChoice>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSprite'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 520,
            height: 430,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemCount: choices.length,
              itemBuilder: (context, index) {
                final choice = choices[index];
                return _ImageChoiceTile(
                  label: _localizedSpriteChoiceLabel(context, choice),
                  assetPath: choice.assetPath,
                  selected:
                      selected.id == choice.id && selected.kind == choice.kind,
                  onTap: () => setState(() => selected = choice),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Future<FourthDemoWidgetKind?> _showWidgetChoiceDialog(
  BuildContext context,
) async {
  var selected = FourthDemoWidgetKind.counter;

  return showDialog<FourthDemoWidgetKind>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseWidget'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final type in FourthDemoWidgetKind.values)
                  _IconChoiceTile(
                    label: _widgetLabel(context, type),
                    icon: _widgetIcon(type),
                    selected: selected == type,
                    onTap: () => setState(() => selected = type),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<_SoundAssetChoice?> _showSoundChoiceDialog(BuildContext context) async {
  final sounds = await _loadSoundAssetChoices();
  if (!context.mounted || sounds.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text(
            'No sound assets found. Check pubspec.yaml and assets/game_builder/sound effects/.',
          ),
        ),
      );
    }
    return null;
  }
  var selected = sounds.first;

  return showDialog<_SoundAssetChoice>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => _CourseDialog(
          title: AppLanguage.of(context).t('builder.chooseSound'),
          action: FilledButton(
            onPressed: () => Navigator.of(context).pop(selected),
            child: Text(AppLanguage.of(context).t('builder.ok')),
          ),
          child: SizedBox(
            width: 430,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final sound in sounds)
                  _SoundChoiceTile(
                    label: AppLanguage.of(
                      context,
                    ).tr('builder.sound.${sound.id}', sound.label),
                    assetPath: sound.assetPath,
                    selected: selected.id == sound.id,
                    onTap: () => setState(() => selected = sound),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<List<_SoundAssetChoice>> _loadSoundAssetChoices() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final soundAssets =
      manifest
          .listAssets()
          .map(_normalizeSoundAssetPath)
          .where((asset) {
            final normalized = asset.replaceAll('\\', '/');
            final withoutAssetPrefix = normalized.startsWith('assets/')
                ? normalized.substring('assets/'.length)
                : normalized;
            final isInSoundFolder = withoutAssetPrefix.startsWith(
              'game_builder/sound effects/',
            );
            final isAudioFile = RegExp(
              r'\.(mp3|wav|ogg|m4a|aac)$',
              caseSensitive: false,
            ).hasMatch(normalized);
            return isInSoundFolder && isAudioFile;
          })
          .toSet()
          .toList()
        ..sort();
  return [
    for (final assetPath in soundAssets)
      _SoundAssetChoice(
        id: _soundChoiceId(assetPath),
        label: _soundFileName(assetPath),
        assetPath: assetPath,
      ),
  ];
}

String _soundChoiceId(String assetPath) {
  return _soundFileName(assetPath)
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join();
}

String _normalizeSoundAssetPath(String assetPath) {
  var path = assetPath.trim().replaceAll('\\', '/');
  for (var i = 0; i < 3; i++) {
    try {
      final decoded = Uri.decodeFull(path);
      if (decoded == path) {
        break;
      }
      path = decoded;
    } on FormatException {
      break;
    }
  }
  return path.replaceAll('%20', ' ');
}

class _ImageChoiceTile extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _ImageChoiceTile({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class _IconChoiceTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoiceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Icon(icon, color: const Color(0xFF2B78C2), size: 38),
    );
  }
}

class _SoundChoiceTile extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  const _SoundChoiceTile({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChoiceShell(
      label: label,
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF2B78C2), size: 26),
          const SizedBox(height: 4),
          _SoundPlayButton(assetPath: assetPath, compact: true),
        ],
      ),
    );
  }
}

class _ChoiceShell extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _ChoiceShell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF66B64A)
                          : const Color(0xFFD9DEE2),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: child,
                ),
                if (selected)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.check_circle,
                      color: Color(0xFF2F9F46),
                      size: 24,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _widgetIcon(FourthDemoWidgetKind type) {
  return switch (type) {
    FourthDemoWidgetKind.counter => Icons.exposure_plus_1,
    FourthDemoWidgetKind.text => Icons.text_fields,
    FourthDemoWidgetKind.timer => Icons.timer,
    FourthDemoWidgetKind.clock => Icons.schedule,
    FourthDemoWidgetKind.button => Icons.smart_button,
    FourthDemoWidgetKind.dialog => Icons.chat_bubble_outline,
  };
}

String _localizedSpriteChoiceLabel(
  BuildContext context,
  _SpriteAssetChoice choice,
) {
  return switch (choice.kind) {
    FourthDemoSpriteKind.player => localizedBuilderCharacterLabel(
      AppLanguage.of(context),
      choice.id,
    ),
    FourthDemoSpriteKind.collectible => localizedBuilderCollectableLabel(
      AppLanguage.of(context),
      choice.id,
    ),
    FourthDemoSpriteKind.prop => choice.label,
  };
}

String _widgetLabel(BuildContext context, FourthDemoWidgetKind type) {
  final language = AppLanguage.of(context);
  return switch (type) {
    FourthDemoWidgetKind.counter => language.tr(
      'builder.widget.counter',
      'Counter',
    ),
    FourthDemoWidgetKind.text => language.t('builder.text'),
    FourthDemoWidgetKind.timer => language.tr('builder.widget.timer', 'Timer'),
    FourthDemoWidgetKind.clock => language.tr('builder.widget.clock', 'Clock'),
    FourthDemoWidgetKind.button => language.tr(
      'builder.widget.button',
      'Button',
    ),
    FourthDemoWidgetKind.dialog => language.tr(
      'builder.widget.dialog',
      'Dialog',
    ),
  };
}

class _CourseDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget action;

  const _CourseDialog({
    required this.title,
    required this.child,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFCF2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF3A241D),
        ),
      ),
      content: SizedBox(width: 520, child: child),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLanguage.of(context).t('builder.cancel')),
        ),
        action,
      ],
    );
  }
}

InputDecoration _fieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD9DEE2)),
    ),
  );
}
