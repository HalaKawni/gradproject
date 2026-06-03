import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscoverPage extends StatefulWidget {
  final AuthSession session;

  const DiscoverPage({super.key, required this.session});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  bool isLoading = true;
  String? errorMessage;
  List<SavedBuilderProject> publishedGames = const [];
  _DiscoverTab selectedTab = _DiscoverTab.challenges;

  @override
  void initState() {
    super.initState();
    _loadPublishedGames();
  }

  Future<void> _loadPublishedGames() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getPublishedBuilderProjects(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final rawData = result['data'];
        final items = rawData is List ? rawData : const [];
        final loadedGames = items
            .whereType<Map>()
            .map(
              (item) =>
                  SavedBuilderProject.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((project) => project.id.isNotEmpty)
            .toList();

        setState(() {
          publishedGames = loadedGames;
        });
      } else {
        setState(() {
          errorMessage =
              result['message']?.toString() ??
              'Failed to load published challenges.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load published challenges: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openGame(SavedBuilderProject game) async {
    final routeName = game.isTopView
        ? AppRoutes.topViewBuilder
        : game.isScratch
        ? AppRoutes.scratchBuilder
        : AppRoutes.builderPlay;
    final routeData = game.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: game.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: game.title,
          )
        : game.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: game.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: game.title,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: game.id,
            initialTitle: game.title,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);
  }

  void _openCourses() {
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.dashboard,
      arguments: DashboardRouteData(session: widget.session),
    );
  }

  void _openMyCreations() {
    Navigator.of(context).pushNamed(
      AppRoutes.myGames,
      arguments: MyGamesRouteData(session: widget.session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0ED),
      body: Row(
        children: [
          _DiscoverSidebar(
            onCoursesTap: _openCourses,
            onMyCreationsTap: _openMyCreations,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopNavbar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPublishedGames,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildBannerAndTabs()),
                        SliverToBoxAdapter(child: _buildTabBodyHeader()),
                        _buildCurrentTabContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'nameofweb',
            style: GoogleFonts.montserrat(
              color: const Color.fromARGB(255, 202, 97, 128),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7DBF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.menu, color: Colors.white, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerAndTabs() {
    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(child: _DiscoverBannerPlaceholder()),
              const SizedBox(height: 34),
            ],
          ),
        ),
        Positioned(
          left: 18,
          bottom: 0,
          child: Row(
            children: [
              _DiscoverTabButton(
                label: 'CHALLENGES',
                isSelected: selectedTab == _DiscoverTab.challenges,
                onTap: () => setState(() {
                  selectedTab = _DiscoverTab.challenges;
                }),
              ),
              const SizedBox(width: 6),
              _DiscoverTabButton(
                label: 'MY CREATIONS',
                isSelected: selectedTab == _DiscoverTab.creations,
                onTap: () => setState(() {
                  selectedTab = _DiscoverTab.creations;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBodyHeader() {
    final isChallenges = selectedTab == _DiscoverTab.challenges;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Text(
            isChallenges ? 'Discover Challenges' : 'My Creations',
            style: GoogleFonts.nunito(
              color: const Color(0xFF243A1B),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (isChallenges)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadPublishedGames,
              icon: const Icon(Icons.refresh, color: Color(0xFF6C9D43)),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    if (selectedTab == _DiscoverTab.creations) {
      return const SliverToBoxAdapter(
        child: _DiscoverMessage(
          icon: Icons.auto_awesome_outlined,
          message: 'Your created assets will appear here soon.',
        ),
      );
    }

    if (isLoading) {
      return const SliverToBoxAdapter(
        child: _DiscoverMessage(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SliverToBoxAdapter(
        child: _DiscoverMessage(
          icon: Icons.error_outline,
          message: errorMessage!,
          actionLabel: 'Try Again',
          onAction: _loadPublishedGames,
        ),
      );
    }

    if (publishedGames.isEmpty) {
      return const SliverToBoxAdapter(
        child: _DiscoverMessage(
          icon: Icons.extension_outlined,
          message: 'No published challenges are available yet.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      sliver: SliverGrid.builder(
        itemCount: publishedGames.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 260,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.86,
        ),
        itemBuilder: (context, index) {
          final game = publishedGames[index];
          return _PublishedGameCard(game: game, onTap: () => _openGame(game));
        },
      ),
    );
  }
}

enum _DiscoverTab { challenges, creations }

class _DiscoverSidebar extends StatelessWidget {
  final VoidCallback onCoursesTap;
  final VoidCallback onMyCreationsTap;

  const _DiscoverSidebar({
    required this.onCoursesTap,
    required this.onMyCreationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: const Color(0xFF253B1C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _DiscoverSidebarItem(label: 'COURSES', onTap: onCoursesTap),
          _DiscoverSidebarItem(
            label: 'MY CREATIONS',
            onTap: onMyCreationsTap,
          ),
          _DiscoverSidebarItem(
            label: 'DISCOVER',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _DiscoverSidebarItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DiscoverSidebarItem({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<_DiscoverSidebarItem> createState() => _DiscoverSidebarItemState();
}

class _DiscoverSidebarItemState extends State<_DiscoverSidebarItem> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() {
        hovered = true;
      }),
      onExit: (_) => setState(() {
        hovered = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: widget.isActive
              ? const Color(0xFF91B867)
              : hovered
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Text(
            widget.label,
            style: GoogleFonts.montserrat(
              color: widget.isActive ? const Color(0xFF162511) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverBannerPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFA6C957)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BannerTexturePainter()),
          Center(
            child: Container(
              width: 560,
              height: 136,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.36),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'Banner image placeholder',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF3C551D),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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

class _DiscoverTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DiscoverTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF7F7F7) : const Color(0xFF8DB75C),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: SizedBox(
          width: 190,
          height: 56,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: isSelected ? const Color(0xFF8EA231) : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PublishedGameCard extends StatelessWidget {
  final SavedBuilderProject game;
  final VoidCallback onTap;

  const _PublishedGameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GamePreviewPlaceholder(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF243A1B),
                        fontSize: 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By ${game.publisherName}',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF667064),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.play_circle_fill,
                          color: Color(0xFF6C9D43),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          game.difficulty.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF6C9D43),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

class _GamePreviewPlaceholder extends StatelessWidget {
  const _GamePreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFDDEDC7)),
        child: Center(
          child: Icon(
            Icons.videogame_asset_outlined,
            size: 44,
            color: const Color(0xFF6C9D43).withValues(alpha: 0.86),
          ),
        ),
      ),
    );
  }
}

class _DiscoverMessage extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DiscoverMessage({
    this.child,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 76, 24, 24),
      child: Center(
        child:
            child ??
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 44, color: const Color(0xFF6C9D43)),
                const SizedBox(height: 12),
                Text(
                  message ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF45523F),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}

class _BannerTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A9D3B).withValues(alpha: 0.16)
      ..strokeWidth = 1;

    for (var x = -size.height; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_BannerTexturePainter oldDelegate) => false;
}
