import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:flutter/material.dart';

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
              'Failed to load published games.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = 'Failed to load published games: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSearchComingSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Search will be added soon.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openGame(SavedBuilderProject game) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.builderPlay,
      arguments: BuilderPlayRouteData(
        session: widget.session,
        projectId: game.id,
        initialTitle: game.title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EA),
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 69, 47, 40),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchComingSoon,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPublishedGames,
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
                    onPressed: _loadPublishedGames,
                    child: const Text('Try Again'),
                  ),
                ],
              );
            }

            if (publishedGames.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  Text(
                    'No published games available yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 16.0;
                const idealCardWidth = 220.0;
                const maxCardsPerRow = 5;
                final maxContentWidth =
                    (idealCardWidth * maxCardsPerRow) +
                    (spacing * (maxCardsPerRow - 1));
                final cardWidth = (constraints.maxWidth - 32).clamp(
                  180.0,
                  idealCardWidth,
                );

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.start,
                        children: publishedGames
                            .map(
                              (game) => SizedBox(
                                width: cardWidth,
                                child: _PublishedGameCard(
                                  game: game,
                                  onTap: () => _openGame(game),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
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
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _GamePreviewPlaceholder(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF332018),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Publisher: ${game.publisherName}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6E5A52),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _GamePreviewPlaceholder extends StatelessWidget {
  const _GamePreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B5E4A), Color(0xFFD7A86E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.image_outlined, size: 52, color: Colors.white),
              SizedBox(height: 10),
              Text(
                'Preview coming soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
