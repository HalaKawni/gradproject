import 'dart:convert';
import 'dart:typed_data';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';
import 'package:client/shared/widgets/help_button.dart';
import 'package:client/shared/widgets/hint_card.dart';
import 'package:client/core/services/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/saved_builder_project.dart';

enum _GameCreatorOption { scratch, frontView, topView, fourthDemo }

class MyGamesPage extends StatefulWidget {
  final AuthSession session;
  final String title;
  final String emptyMessage;
  final String? statusFilter;
  final bool openProjectOnTap;
  final bool playProjectOnTap;
  final String pendingTapMessage;

  const MyGamesPage({
    super.key,
    required this.session,
    this.title = 'My Games',
    this.emptyMessage = 'No saved games yet.',
    this.statusFilter,
    this.openProjectOnTap = true,
    this.playProjectOnTap = false,
    this.pendingTapMessage = 'Opening published games will be connected next.',
  });

  @override
  State<MyGamesPage> createState() => _MyGamesPageState();
}

class _MyGamesPageState extends State<MyGamesPage> {
  static const double _cardWidth = 240;
  static const double _cardHeight = 250;

  static const _tips = [
    HelpTip(
      icon: Icons.add_circle_rounded,
      color: Color(0xFF328CBD),
      title: 'Tap "Create New Game" to Start',
      description:
          'Hit the Create New Game button at the top to begin building. Choose your preferred game style first.',
    ),
    HelpTip(
      icon: Icons.view_carousel_rounded,
      color: Color(0xFF7C4DFF),
      title: 'Slides — Easiest for Beginners',
      description:
          'Slides style is the best starting point. Build interactive story-style games with simple drag-and-drop blocks.',
    ),
    HelpTip(
      icon: Icons.videogame_asset_rounded,
      color: Color(0xFF43A047),
      title: 'Top View & Front View — Platformers',
      description:
          'Want to make a running or jumping game? Try Front View (side-scroller) or Top View (overhead map) styles.',
    ),
    HelpTip(
      icon: Icons.code_rounded,
      color: Color(0xFFE8B400),
      title: 'Scratch — Full Code Control',
      description:
          'If you know some coding, Scratch style lets you use block-based programming to control every detail of your game.',
    ),
  ];

  bool isLoading = true;
  String? errorMessage;
  List<SavedBuilderProject> projects = const [];
  final Set<String> deletingProjectIds = <String>{};
  int _hintIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _initHintIndex();
  }

  Future<void> _initHintIndex() async {
    final h0 = await OnboardingService.isHintDismissed('mygames_create');
    final h1 = await OnboardingService.isHintDismissed('mygames_style');
    if (!mounted) return;
    setState(() => _hintIndex = h0 ? (h1 ? 2 : 1) : 0);
  }

  Future<void> _loadProjects() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getAllBuilderProjects(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final rawData = result['data'];
        final items = rawData is List ? rawData : const [];
        final normalizedStatusFilter = widget.statusFilter
            ?.trim()
            .toLowerCase();
        final loadedProjects = items
            .whereType<Map>()
            .map(
              (item) =>
                  SavedBuilderProject.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((project) => project.id.isNotEmpty)
            .where((project) {
              if (normalizedStatusFilter == null ||
                  normalizedStatusFilter.isEmpty) {
                return true;
              }

              return project.status.trim().toLowerCase() ==
                  normalizedStatusFilter;
            })
            .toList();

        setState(() {
          projects = loadedProjects;
        });
      } else {
        setState(() {
          errorMessage =
              result['message']?.toString() ?? 'Failed to load games.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load games: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openProject(SavedBuilderProject project) async {
    final routeName = project.isTopView
        ? AppRoutes.topViewBuilder
        : project.isScratch
        ? AppRoutes.scratchBuilder
        : project.isFourthDemo
        ? AppRoutes.fourthDemoBuilder
        : AppRoutes.builder;
    final routeData = project.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
          )
        : project.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
          )
        : project.isFourthDemo
        ? FourthDemoBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
          )
        : BuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  Future<void> _playProject(SavedBuilderProject project) async {
    final routeName = project.isTopView
        ? AppRoutes.topViewBuilder
        : project.isScratch
        ? AppRoutes.scratchBuilder
        : project.isFourthDemo
        ? AppRoutes.fourthDemoBuilder
        : AppRoutes.builderPlay;
    final routeData = project.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: project.title,
          )
        : project.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: project.title,
          )
        : project.isFourthDemo
        ? FourthDemoBuilderRouteData(
            session: widget.session,
            initialProjectId: project.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: project.title,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: project.id,
            initialTitle: project.title,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);

    if (!mounted) {
      return;
    }

    await _loadProjects();
  }

  Future<void> _confirmDeleteProject(SavedBuilderProject project) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isPublished = project.status.trim().toLowerCase() == 'published';

        return AlertDialog(
          title: const Text('Delete game?'),
          content: Text(
            isPublished
                ? 'Are you sure you want to delete "${project.title}"? This game is published, so it will become unavailable for other users too.'
                : 'Are you sure you want to delete "${project.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _deleteProject(project);
  }

  Future<void> _deleteProject(SavedBuilderProject project) async {
    if (deletingProjectIds.contains(project.id)) {
      return;
    }

    setState(() {
      deletingProjectIds.add(project.id);
    });

    try {
      final result = await ApiService.deleteBuilderProject(
        authToken: widget.session.token,
        projectId: project.id,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        setState(() {
          projects = projects.where((item) => item.id != project.id).toList();
        });

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Game deleted successfully.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Failed to delete game.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Failed to delete game: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          deletingProjectIds.remove(project.id);
        });
      }
    }
  }

  void _handleProjectPressed(SavedBuilderProject project) {
    if (widget.openProjectOnTap) {
      _openProject(project);
      return;
    }

    if (widget.playProjectOnTap) {
      _playProject(project);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(widget.pendingTapMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openFrontViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(session: widget.session),
    );
  }

  void _openTopViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.topViewBuilder,
      arguments: TopViewBuilderRouteData(session: widget.session),
    );
  }

  void _openScratchBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.scratchBuilder,
      arguments: ScratchBuilderRouteData(session: widget.session),
    );
  }

  void _openFourthDemoBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.fourthDemoBuilder,
      arguments: FourthDemoBuilderRouteData(session: widget.session),
    );
  }

  Future<void> _showCreateGameDialog(BuildContext context) async {
    final selection = await showDialog<_GameCreatorOption>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Game'),
          content: const Text('Choose the type of game creator to open.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.scratch);
              },
              child: const Text('Scratch Builder'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.frontView);
              },
              child: const Text('Front View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.topView);
              },
              child: const Text('Top View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(_GameCreatorOption.fourthDemo);
              },
              child: const Text('Fourth Demo'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || selection == null) {
      return;
    }

    switch (selection) {
      case _GameCreatorOption.scratch:
        _openScratchBuilder(context);
      case _GameCreatorOption.frontView:
        _openFrontViewBuilder(context);
      case _GameCreatorOption.topView:
        _openTopViewBuilder(context);
      case _GameCreatorOption.fourthDemo:
        _openFourthDemoBuilder(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 46),
            child: TextButton.icon(
              onPressed: () => _showCreateGameDialog(context),
              // icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Create New Game',
                style: TextStyle(color: Colors.black),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // 👈 your color
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: HelpButton(
        pageTitle: 'My Games',
        tips: _tips,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hintIndex == 0)
            HintCard(
              key: ValueKey('mygames_create_$_hintIndex'),
              hintKey: 'mygames_create',
              icon: Icons.add_circle_rounded,
              color: Color(0xFF328CBD),
              title: 'Create your first game',
              message: 'Tap "Create New Game" above. Slides style is easiest for beginners — no coding needed!',
              onDismissed: () => setState(() => _hintIndex = 1),
            ),
          if (_hintIndex == 1)
            HintCard(
              key: ValueKey('mygames_style_$_hintIndex'),
              hintKey: 'mygames_style',
              icon: Icons.view_carousel_rounded,
              color: Color(0xFF7C4DFF),
              title: 'Pick the right game style',
              message: 'Slides = story-style (easiest), Front/Top View = platformer games, Scratch = full code control.',
              onDismissed: () => setState(() => _hintIndex = 2),
            ),
          Expanded(child: RefreshIndicator(
        onRefresh: _loadProjects,
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (errorMessage != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadProjects,
                    child: const Text('Try Again'),
                  ),
                ],
              );
            }

            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(widget.emptyMessage, textAlign: TextAlign.center),
                ],
              );
            }

            return GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: _cardWidth,
                mainAxisExtent: _cardHeight,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                final isDeleting = deletingProjectIds.contains(project.id);

                return _MyGameProjectCard(
                  title: project.title,
                  description: project.description,
                  builderTypeLabel: _builderTypeLabel(project),
                  imageBase64: project.coverImageBase64,
                  coverFrameScale: project.coverFrameScale,
                  coverFrameOffsetX: project.coverFrameOffsetX,
                  coverFrameOffsetY: project.coverFrameOffsetY,
                  isPublished: project.isPublished,
                  isDeleting: isDeleting,
                  actionIcon: widget.playProjectOnTap
                      ? Icons.play_circle_outline_rounded
                      : Icons.chevron_right_rounded,
                  onTap: isDeleting
                      ? null
                      : () => _handleProjectPressed(project),
                  onDelete: isDeleting
                      ? null
                      : () => _confirmDeleteProject(project),
                );
              },
            );
          },
        ),
      )),
      ],
    ),
    );
  }

  String _builderTypeLabel(SavedBuilderProject project) {
    if (project.isTopView) {
      return 'Top View';
    }
    if (project.isScratch) {
      return 'Scratch';
    }
    if (project.isFourthDemo) {
      return 'Fourth Demo';
    }
    return 'Front View';
  }
}

class _MyGameProjectCard extends StatefulWidget {
  const _MyGameProjectCard({
    required this.title,
    required this.description,
    required this.builderTypeLabel,
    required this.isPublished,
    required this.isDeleting,
    required this.actionIcon,
    required this.onTap,
    required this.onDelete,
    this.imageBase64,
    this.coverFrameScale = 1,
    this.coverFrameOffsetX = 0,
    this.coverFrameOffsetY = 0,
  });

  final String title;
  final String description;
  final String builderTypeLabel;
  final String? imageBase64;
  final double coverFrameScale;
  final double coverFrameOffsetX;
  final double coverFrameOffsetY;
  final bool isPublished;
  final bool isDeleting;
  final IconData actionIcon;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  State<_MyGameProjectCard> createState() => _MyGameProjectCardState();
}

class _MyGameProjectCardState extends State<_MyGameProjectCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  Uint8List? _safeDecodeBase64(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  Widget _fallbackHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFF4DD0C4),
      child: Center(
        child: Icon(
          Icons.videogame_asset_rounded,
          size: 38,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _MyGamesPageState._cardWidth,
          height: _MyGamesPageState._cardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered && widget.onTap != null
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: widget.imageBase64 != null
                      ? FramedImagePreview(
                          bytes: _safeDecodeBase64(widget.imageBase64),
                          scale: widget.coverFrameScale,
                          offsetX: widget.coverFrameOffsetX,
                          offsetY: widget.coverFrameOffsetY,
                          placeholderIcon: Icons.videogame_asset_rounded,
                        )
                      : _fallbackHeader(),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF222222),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isPublished
                                  ? const Color(0xFF4DD0C4)
                                  : const Color(0xFFFFC83D),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.isPublished ? 'Published' : 'Draft',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.isPublished
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: const Color(0xFF888888),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Color(0xFF888888),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.builderTypeLabel,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: const Color(0xFF888888),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.isDeleting)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else ...[
                            IconButton(
                              tooltip: 'Open game',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: widget.onTap,
                              icon: Icon(
                                widget.actionIcon,
                                size: 20,
                                color: const Color(0xFF4DD0C4),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete game',
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: widget.onDelete,
                              icon: const Icon(
                                Icons.settings_rounded,
                                size: 18,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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
