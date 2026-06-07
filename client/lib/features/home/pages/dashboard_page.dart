import 'dart:convert';
import 'dart:typed_data';
import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/services/api_service.dart' as LegacyApiService;
import 'package:client/features/builder/models/saved_builder_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import 'world_map_page.dart';
import '../widgets/unlock_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:client/features/home/services/game_api_service.dart';
import 'package:client/digitalgame/digital_literacy_page.dart';
import 'package:client/datagame/data_course_page.dart';
import 'package:client/aicourse/ai_hoot_page_game.dart';
import 'package:client/features/classroom/pages/classroom_page.dart';
import 'package:client/utils/responsive.dart';
import 'package:client/mycourses/course_detail_page.dart';
import 'package:client/mycourses/create_course_page.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';

class DashboardPage extends StatefulWidget {
  final AuthSession session;
  final String username;
  const DashboardPage({
    super.key,
    required this.session,
    this.username = 'Student',
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

enum _DashboardSection { courses, discover, myCreations }

enum _DiscoverContentTab { challenges, assets, favorites }

enum _MyCreationContentTab { challenges, assets }

enum _CreationBuilderOption { slides, frontView, topView, scratch, fourthDemo }

class _DashboardPageState extends State<DashboardPage> {
  static const double _creationCardWidth = 240;
  static const double _levelCardHeight = 250;
  static const double _myCreationLevelCoverAspectRatio = 240 / 104;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _DashboardSection _activeSection = _DashboardSection.courses;
  _DiscoverContentTab _discoverContentTab = _DiscoverContentTab.challenges;
  _MyCreationContentTab _myCreationContentTab =
      _MyCreationContentTab.challenges;
  String _profileAvatarType = 'asset';
  String _selectedAvatarPath = 'assets/images/sprites/avatar00.png';
  String? _profilePhotoBase64;
  double _profilePhotoFrameScale = 1;
  double _profilePhotoFrameOffsetX = 0;
  double _profilePhotoFrameOffsetY = 0;
  bool _isSavingAvatar = false;
  bool _showFilterExpanded = false;
  bool _showLevelError = false;
  bool _showCategoryError = false;
  bool _showTopicError = false;
  String _activeTab = 'Filter';
  bool _hasShownEmailVerificationNotice = false;
  bool _isSendingVerificationEmail = false;

  Future<List<Map<String, dynamic>>>? _coursesFuture;
  String? _linkCode;
  bool _linkCodeLoading = false;
  String? _linkCodeError;
  Map<String, dynamic>? _myStats;
  List<_CourseData> _publicCourses = const [];
  bool _isLoadingPublicCourses = false;
  List<SavedBuilderProject> _publishedGames = const [];
  bool _isLoadingPublishedGames = false;
  String? _publishedGamesErrorMessage;
  List<_PublishedBuilderAsset> _publishedAssets = const [];
  bool _isLoadingPublishedAssets = false;
  String? _publishedAssetsErrorMessage;
  Set<String> _favoriteChallengeIds = {};
  Set<String> _favoriteAssetIds = {};
  bool _showFavoriteChallenges = true;
  bool _showFavoriteAssets = true;
  List<SavedBuilderProject> _myBuilderProjects = const [];
  bool _isLoadingMyBuilderProjects = false;
  String? _myBuilderProjectsErrorMessage;
  List<_PublishedBuilderAsset> _myBuilderAssets = const [];
  bool _isLoadingMyBuilderAssets = false;
  String? _myBuilderAssetsErrorMessage;

  @override
  void initState() {
    super.initState();
    _syncAvatarFromUser(widget.session.user);
    _loadProfileAvatar();
    _loadDiscoverFavorites();
    _loadPublicCourses();
    _loadPublishedGames();
    _loadPublishedAssets();
    _loadMyStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog(context: context, builder: (_) => const UnlockDialog());
      _showEmailVerificationNoticeIfNeeded();
    });
  }

  void _showEmailVerificationNoticeIfNeeded() {
    if (_hasShownEmailVerificationNotice || widget.session.user.emailVerified) {
      return;
    }

    _hasShownEmailVerificationNotice = true;
    _showEmailVerificationNotice();
  }

  void _showEmailVerificationNotice() {
    final overlay = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (_) => _EmailVerificationNotice(
        email: widget.session.user.email,
        isSending: _isSendingVerificationEmail,
        onClose: () => entry?.remove(),
        onResend: () async {
          if (_isSendingVerificationEmail) {
            return;
          }

          setState(() {
            _isSendingVerificationEmail = true;
          });
          entry?.markNeedsBuild();

          final result = await ApiService.resendVerificationEmail(
            email: widget.session.user.email,
          );

          if (!mounted) {
            entry?.remove();
            return;
          }

          setState(() {
            _isSendingVerificationEmail = false;
          });
          entry?.markNeedsBuild();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ??
                    (result['success'] == true
                        ? 'Verification email sent.'
                        : 'Failed to send verification email.'),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(entry);
  }

  void _syncAvatarFromUser(AuthUser user) {
    _profileAvatarType = user.profileAvatarType == 'upload'
        ? 'upload'
        : 'asset';
    _selectedAvatarPath = user.profileAvatarAssetPath.isNotEmpty
        ? user.profileAvatarAssetPath
        : 'assets/images/sprites/avatar00.png';
    _profilePhotoBase64 = user.profilePhotoBase64;
    _profilePhotoFrameScale = user.profilePhotoFrameScale;
    _profilePhotoFrameOffsetX = user.profilePhotoFrameOffsetX;
    _profilePhotoFrameOffsetY = user.profilePhotoFrameOffsetY;
  }

  Future<void> _loadProfileAvatar() async {
    final result = await ApiService.getProfile(authToken: widget.session.token);
    if (!mounted || result['success'] != true) {
      return;
    }

    final profileJson = _extractProfileJson(result['data']);
    if (profileJson.isEmpty) {
      return;
    }

    setState(() {
      _syncAvatarFromUser(AuthUser.fromJson(profileJson));
    });
  }

  Future<void> _loadMyStats() async {
    final stats = await LegacyApiService.ApiService.getMyStats();
    if (mounted) {
      setState(() => _myStats = stats);
    }
  }

  String get _favoritesStoragePrefix =>
      'dashboard.discoverFavorites.${widget.session.user.id}';

  Future<void> _loadDiscoverFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _favoriteChallengeIds =
          prefs.getStringList('$_favoritesStoragePrefix.challenges')?.toSet() ??
          <String>{};
      _favoriteAssetIds =
          prefs.getStringList('$_favoritesStoragePrefix.assets')?.toSet() ??
          <String>{};
    });
  }

  Future<void> _saveDiscoverFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_favoritesStoragePrefix.challenges',
      _favoriteChallengeIds.toList(),
    );
    await prefs.setStringList(
      '$_favoritesStoragePrefix.assets',
      _favoriteAssetIds.toList(),
    );
  }

  void _toggleFavoriteChallenge(SavedBuilderProject game) {
    setState(() {
      if (_favoriteChallengeIds.contains(game.id)) {
        _favoriteChallengeIds.remove(game.id);
      } else {
        _favoriteChallengeIds.add(game.id);
      }
    });
    _saveDiscoverFavorites();
  }

  void _toggleFavoriteAsset(_PublishedBuilderAsset asset) {
    setState(() {
      if (_favoriteAssetIds.contains(asset.id)) {
        _favoriteAssetIds.remove(asset.id);
      } else {
        _favoriteAssetIds.add(asset.id);
      }
    });
    _saveDiscoverFavorites();
  }

  Widget _buildAvatarWidget({double size = 80}) {
    return _AvatarWidget(
      avatarType: _profileAvatarType,
      avatarPath: _selectedAvatarPath,
      profilePhotoBase64: _profilePhotoBase64,
      profilePhotoFrameScale: _profilePhotoFrameScale,
      profilePhotoFrameOffsetX: _profilePhotoFrameOffsetX,
      profilePhotoFrameOffsetY: _profilePhotoFrameOffsetY,
      isSavingAvatar: _isSavingAvatar,
      size: size,
      onSelect: _saveAssetAvatar,
      onUploadPhoto: _uploadProfilePhoto,
    );
  }

  Future<void> _loadPublicCourses() async {
    setState(() {
      _isLoadingPublicCourses = true;
    });

    final result = await ApiService.getPublicCourses(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final courses = _parseList(result['data'])
          .map(_CourseData.fromPublicCourseJson)
          .where((course) => course.publicCourseId.isNotEmpty)
          .toList();
      setState(() {
        _publicCourses = courses;
        _isLoadingPublicCourses = false;
      });
      return;
    }

    setState(() {
      _isLoadingPublicCourses = false;
    });
  }

  Future<void> _loadPublishedGames() async {
    setState(() {
      _isLoadingPublishedGames = true;
      _publishedGamesErrorMessage = null;
    });

    try {
      final result = await ApiService.getPublishedBuilderProjects(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final games = _parseList(result['data'])
            .map(SavedBuilderProject.fromJson)
            .where(
              (project) =>
                  project.id.isNotEmpty &&
                  project.isPublished &&
                  project.isUserCreated &&
                  project.ownerId != widget.session.user.id,
            )
            .toList();
        setState(() {
          _publishedGames = games;
          _isLoadingPublishedGames = false;
        });
        return;
      }

      setState(() {
        _publishedGamesErrorMessage =
            result['message']?.toString() ??
            'Failed to load published challenges.';
        _isLoadingPublishedGames = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _publishedGamesErrorMessage = 'Failed to load published challenges: $e';
        _isLoadingPublishedGames = false;
      });
    }
  }

  Future<void> _loadPublishedAssets() async {
    setState(() {
      _isLoadingPublishedAssets = true;
      _publishedAssetsErrorMessage = null;
    });

    try {
      final result = await ApiService.getPublishedBuilderAssets(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final assets = _parseList(result['data'])
            .map(_PublishedBuilderAsset.fromJson)
            .where(
              (asset) =>
                  asset.id.isNotEmpty &&
                  asset.isPublic &&
                  asset.isUserCreated &&
                  asset.ownerId != widget.session.user.id,
            )
            .toList();
        setState(() {
          _publishedAssets = assets;
          _isLoadingPublishedAssets = false;
        });
        return;
      }

      setState(() {
        _publishedAssetsErrorMessage =
            result['message']?.toString() ?? 'Failed to load published assets.';
        _isLoadingPublishedAssets = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _publishedAssetsErrorMessage = 'Failed to load published assets: $e';
        _isLoadingPublishedAssets = false;
      });
    }
  }

  void _loadMyCreations() {
    setState(() {
      _coursesFuture = LegacyApiService.ApiService.getCourses(
        authToken: widget.session.token,
      );
    });
    _loadMyBuilderProjects();
    _loadMyBuilderAssets();
  }

  Future<void> _loadMyBuilderProjects() async {
    setState(() {
      _isLoadingMyBuilderProjects = true;
      _myBuilderProjectsErrorMessage = null;
    });

    try {
      final result = await ApiService.getAllBuilderProjects(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final projects = _parseList(result['data'])
            .map(SavedBuilderProject.fromJson)
            .where((project) => project.id.isNotEmpty && project.isUserCreated)
            .toList();
        setState(() {
          _myBuilderProjects = projects;
          _isLoadingMyBuilderProjects = false;
        });
        return;
      }

      setState(() {
        _myBuilderProjectsErrorMessage =
            result['message']?.toString() ?? 'Failed to load your challenges.';
        _isLoadingMyBuilderProjects = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _myBuilderProjectsErrorMessage = 'Failed to load your challenges: $e';
        _isLoadingMyBuilderProjects = false;
      });
    }
  }

  Future<void> _loadMyBuilderAssets() async {
    setState(() {
      _isLoadingMyBuilderAssets = true;
      _myBuilderAssetsErrorMessage = null;
    });

    try {
      final result = await ApiService.getBuilderAssets(
        authToken: widget.session.token,
      );

      if (!mounted) {
        return;
      }

      if (result['success'] == true) {
        final assets = _parseList(result['data'])
            .map(_PublishedBuilderAsset.fromJson)
            .where((asset) => asset.id.isNotEmpty && asset.isUserCreated)
            .toList();
        setState(() {
          _myBuilderAssets = assets;
          _isLoadingMyBuilderAssets = false;
        });
        return;
      }

      setState(() {
        _myBuilderAssetsErrorMessage =
            result['message']?.toString() ?? 'Failed to load your assets.';
        _isLoadingMyBuilderAssets = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _myBuilderAssetsErrorMessage = 'Failed to load your assets: $e';
        _isLoadingMyBuilderAssets = false;
      });
    }
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractProfileJson(Object? value) {
    if (value is Map) {
      final data = Map<String, dynamic>.from(value);
      final rawUser = data['user'];

      if (rawUser is Map) {
        return Map<String, dynamic>.from(rawUser);
      }

      return data;
    }

    return {};
  }

  Future<void> _saveAssetAvatar(String path) async {
    await _saveProfileAvatar(
      avatarJson: {
        'profileAvatarType': 'asset',
        'profileAvatarAssetPath': path,
      },
      applyLocally: () {
        _profileAvatarType = 'asset';
        _selectedAvatarPath = path;
        _profilePhotoBase64 = null;
        _profilePhotoFrameScale = 1;
        _profilePhotoFrameOffsetX = 0;
        _profilePhotoFrameOffsetY = 0;
      },
    );
  }

  Future<void> _uploadProfilePhoto() async {
    final result = await showFramedImageUploadDialog(
      context: context,
      title: 'Fit Profile Photo',
      initialImageBase64: _profileAvatarType == 'upload'
          ? _profilePhotoBase64
          : null,
      initialScale: _profilePhotoFrameScale,
      initialOffsetX: _profilePhotoFrameOffsetX,
      initialOffsetY: _profilePhotoFrameOffsetY,
      aspectRatio: 1,
      circularFrame: true,
    );

    if (!mounted || result == null || result.imageBase64 == null) {
      return;
    }

    await _saveProfileAvatar(
      avatarJson: {
        'profileAvatarType': 'upload',
        'profilePhotoBase64': result.imageBase64,
        'profilePhotoFrameScale': result.scale,
        'profilePhotoFrameOffsetX': result.offsetX,
        'profilePhotoFrameOffsetY': result.offsetY,
      },
      applyLocally: () {
        _profileAvatarType = 'upload';
        _profilePhotoBase64 = result.imageBase64;
        _profilePhotoFrameScale = result.scale;
        _profilePhotoFrameOffsetX = result.offsetX;
        _profilePhotoFrameOffsetY = result.offsetY;
      },
    );
  }

  Future<void> _saveProfileAvatar({
    required Map<String, dynamic> avatarJson,
    required VoidCallback applyLocally,
  }) async {
    if (_isSavingAvatar) {
      return;
    }

    setState(() {
      _isSavingAvatar = true;
      applyLocally();
    });

    final result = await ApiService.updateProfileAvatar(
      authToken: widget.session.token,
      avatarJson: avatarJson,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingAvatar = false;
    });

    if (result['success'] == true) {
      final profileJson = _extractProfileJson(result['data']);
      if (profileJson.isNotEmpty) {
        setState(() {
          _syncAvatarFromUser(AuthUser.fromJson(profileJson));
        });
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ?? 'Failed to update profile photo.',
        ),
      ),
    );

    await _loadProfileAvatar();
  }

  void _showCoursesHome() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeSection = _DashboardSection.courses;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: ProfileRouteData(session: widget.session),
    );

    if (mounted) {
      await _loadProfileAvatar();
    }
  }

  void _signOut() {
    web.window.location.href = 'http://localhost:8080/';
  }

  Future<void> _showLanguageDialog() async {
    final nextLanguage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final language = AppLanguage.of(dialogContext);
        final selectedCode = language.locale.languageCode;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEF2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF78C9D7), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCB7C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF3A2A00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        language.tr('chooseLanguage', 'Choose Language'),
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3A2A00),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _LanguageChoiceButton(
                  title: language.tr('english', 'English'),
                  subtitle: 'EN',
                  isSelected: selectedCode == 'en',
                  color: const Color(0xFF58C4DD),
                  onTap: () => Navigator.of(dialogContext).pop('en'),
                ),
                const SizedBox(height: 10),
                _LanguageChoiceButton(
                  title: language.tr('arabic', 'Arabic'),
                  subtitle: 'AR',
                  isSelected: selectedCode == 'ar',
                  color: const Color(0xFF6DB84A),
                  onTap: () => Navigator.of(dialogContext).pop('ar'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (nextLanguage == null || !mounted) {
      return;
    }

    await AppLanguage.instance.setLanguage(nextLanguage);
    if (mounted) {
      await context.setLocale(Locale(nextLanguage));
    }
  }

  final Set<String> _selectedLevels = {
    'Novice',
    'Beginner',
    'Intermediate',
    'Advanced',
  };
  final Set<String> _selectedCategories = {'Main Courses', 'Mini Courses'};
  final Set<String> _selectedTopics = {
    'Coding',
    'Digital Literacy',
    'CS Topics',
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final content = _activeSection == _DashboardSection.myCreations
        ? _buildMyCreationsView()
        : SingleChildScrollView(child: _buildMainSection());

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF0F0ED),
        drawer: Drawer(width: 220, child: SafeArea(child: _buildSidebar())),
        body: Column(
          children: [
            _buildMobileTopNavbar(),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0ED),
      body: Column(
        children: [
          _buildTopNavbar(),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SIDEBAR ──
  Widget _buildMobileTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _DashboardAccountMenu(
            onLanguage: _showLanguageDialog,
            onHome: _showCoursesHome,
            onProfile: _openProfile,
            onSignOut: _signOut,
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/sprites/logocodey.png',
            height: 32,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          _buildAvatarWidget(size: 32),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: const Color.fromARGB(255, 158, 211, 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _SidebarItem(
            label: 'dashboard.courses_section'.tr(),
            isActive: _activeSection == _DashboardSection.courses,
            onTap: () => setState(() {
              _activeSection = _DashboardSection.courses;
            }),
          ),
          _SidebarItem(
            label: 'dashboard.my_creations'.tr(),
            isActive: _activeSection == _DashboardSection.myCreations,
            onTap: () {
              setState(() {
                _activeSection = _DashboardSection.myCreations;
              });
              _loadMyCreations();
            },
          ),
          _SidebarItem(
            label: 'dashboard.discover'.tr(),
            isActive: _activeSection == _DashboardSection.discover,
            onTap: () => setState(() {
              _activeSection = _DashboardSection.discover;
            }),
          ),
          _SidebarItem(
            label: 'My Classroom',
            isActive: false,
            icon: Icons.school,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClassroomPage()),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${(_myStats?['streak'] as int?) ?? 0} Day Streak',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _SidebarItem(
            label: 'dashboard.help_center'.tr(),
            isActive: false,
            icon: Icons.help_outline,
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    if (_activeSection == _DashboardSection.discover) {
      return _buildDiscoverSection();
    }

    return Column(
      children: [
        _buildHeroBanner(),
        _buildShareWithParentBanner(),
        _buildFilterSection(),
        const SizedBox(height: 16),
        _buildMyScoresSection(),
        const SizedBox(height: 16),
        _buildCoursesSection(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── TOP NAVBAR ──
  Widget _buildTopNavbar() {
    return Container(
      color: const Color.fromARGB(255, 252, 183, 199),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/sprites/logocodey.png',
            height: 44,
            fit: BoxFit.contain,
          ),
          Row(
            children: [
              _buildAvatarWidget(size: 36),
              const SizedBox(width: 16),
              _DashboardAccountMenu(
                onLanguage: _showLanguageDialog,
                onHome: _showCoursesHome,
                onProfile: _openProfile,
                onSignOut: _signOut,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Container(
            color: const Color.fromARGB(255, 254, 253, 153),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildAvatarWidget(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'dashboard.welcome'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3A2A00),
                        ),
                      ),
                      Text(
                        '${widget.username}!',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3A2A00),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WorldMapPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A7DBF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'dashboard.continue_coding'.tr(),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox(
            height: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/hot_air_baloon.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  alignment: Alignment.bottomLeft,
                ),
                Container(color: Colors.black.withValues(alpha: 0.25)),
                ClipPath(
                  clipper: _WelcomeBannerClipper(),
                  child: Container(
                    color: const Color.fromARGB(255, 254, 253, 153),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAvatarWidget(size: 80),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: constraints.maxWidth * 0.22,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'dashboard.welcome'.tr(),
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A2A00),
                                ),
                              ),
                              Text(
                                '${widget.username}!',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3A2A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.42,
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: GameApiService.getProgress('codemonkey-jr'),
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          final completed = data != null
                              ? (data['highestLevelReached'] ?? 0) as int
                              : 0;
                          const total = 15;
                          final percent = (completed / total).clamp(0.0, 1.0);
                          final percentText = '${(percent * 100).round()}%';

                          return SizedBox(
                            width: 90,
                            height: 90,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value: percent,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.3,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF4DD0E1),
                                        ),
                                  ),
                                ),
                                Text(
                                  percentText,
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'dashboard.current_course'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'dashboard.codemonkey_jr'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'dashboard.sequencing_loops'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: Color(0xFFFFD700),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'dashboard.achievements'.tr(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorldMapPage(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            254,
                            253,
                            153,
                          ),
                          foregroundColor: const Color(0xFF3A2A00),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.play_circle_fill, size: 22),
                        label: Text(
                          'dashboard.continue_coding'.tr(),
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── FILTER SECTION ──
  Widget _buildShareWithParentBanner() {
    return Container(
      color: const Color(0xFFF0F6FF),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.link, color: Color(0xFF4A7DBF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: _linkCodeLoading
                ? Row(
                    children: [
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4A7DBF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'dashboard.generate_code'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  )
                : _linkCode != null
                ? Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        'dashboard.your_link_code'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF555555),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _linkCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Copied!',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF4A7DBF),
                                behavior: SnackBarBehavior.floating,
                                width: 120,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A7DBF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _linkCode!,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'dashboard.share_code_hint'.tr(),
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: const Color(0xFF888888),
                        ),
                      ),
                    ],
                  )
                : _linkCodeError != null
                ? Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFE53935),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _linkCodeError!,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'dashboard.share_with_parent'.tr(),
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A7DBF),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          if (_linkCode != null)
            TextButton(
              onPressed: () => setState(() {
                _linkCode = null;
                _linkCodeError = null;
              }),
              child: Text(
                'dashboard.hide_code'.tr(),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A7DBF),
                ),
              ),
            )
          else if (!_linkCodeLoading)
            TextButton(
              onPressed: () async {
                setState(() {
                  _linkCodeLoading = true;
                  _linkCodeError = null;
                });
                try {
                  final code =
                      await LegacyApiService.ApiService.generateLinkCode();
                  if (mounted) {
                    setState(() {
                      _linkCode = code;
                      _linkCodeLoading = false;
                    });
                  }
                } catch (e) {
                  if (mounted)
                    setState(() {
                      _linkCodeError = e.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );
                      _linkCodeLoading = false;
                    });
                }
              },
              child: Text(
                _linkCodeError != null
                    ? 'dashboard.retry'.tr()
                    : 'dashboard.generate_code'.tr(),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _linkCodeError != null
                      ? const Color(0xFFE53935)
                      : const Color(0xFF4A7DBF),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _scoreGameNames = {
    'codemonkey-jr': 'CodeMonkey Jr.',
    'linus-lemur': 'Linus the Lemur',
    'data-everywhere': 'Data is Everywhere',
    'digital-literacy': 'Digital Literacy',
    'ai-hoot': 'Coding Chatbots',
    'scratch-game': 'Coding Chatbots',
  };

  Widget _buildMyScoresSection() {
    final s = _myStats ?? {};
    final games = (s['games'] as List? ?? [])
        .map((g) => g as Map<String, dynamic>)
        .toList();
    if (games.isEmpty) return const SizedBox.shrink();

    final totalScore = s['totalScore'] as int? ?? 0;
    final totalStars = s['totalStars'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4A7DBF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Text(
                  'MY SCORES',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$totalStars stars',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.sports_score,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalScore pts',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Game rows
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: games.map((g) {
                final gameId = g['gameId'] as String? ?? '';
                final name = _scoreGameNames[gameId] ?? gameId;
                final levelCount = g['levelCount'] as int? ?? 0;
                final stars = g['totalStars'] as int? ?? 0;
                final score = g['totalScore'] as int? ?? 0;
                // Cap star display at 3 icons (scale from raw star count)
                final starFill = (stars / 5.0).clamp(0.0, 3.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7DBF).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.videogame_asset,
                          color: Color(0xFF4A7DBF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            Text(
                              '$levelCount activities completed',
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Star display
                      Row(
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < starFill.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Score badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7DBF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$score pts',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── FILTER / SEARCH TABS ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _activeTab = 'Filter';
                    _showFilterExpanded = !_showFilterExpanded;
                  }),
                  child: Text(
                    'dashboard.filter'.tr(),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _activeTab == 'Filter'
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : const Color(0xFF888888),
                      decoration: _activeTab == 'Filter'
                          ? TextDecoration.underline
                          : null,
                      decorationColor: const Color.fromARGB(255, 68, 172, 255),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => setState(() => _activeTab = 'Search'),
                  child: Text(
                    'dashboard.search'.tr(),
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _activeTab == 'Search'
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : const Color(0xFF888888),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── FILTER PILLS ROW ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                _buildFilterGroup('dashboard.level'.tr(), [
                  _FilterPill(
                    label: 'common.all'.tr(),
                    isSelected: true,
                    onTap: () => setState(
                      () => _showFilterExpanded = !_showFilterExpanded,
                    ),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('dashboard.category'.tr(), [
                  _FilterPill(
                    label: 'dashboard.main_courses'.tr(),
                    isSelected: _selectedCategories.contains('Main Courses'),
                    onTap: () => setState(
                      () => _showFilterExpanded = !_showFilterExpanded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'dashboard.mini_courses'.tr(),
                    isSelected: _selectedCategories.contains('Mini Courses'),
                    onTap: () => setState(
                      () => _showFilterExpanded = !_showFilterExpanded,
                    ),
                  ),
                ]),
                const SizedBox(width: 24),
                _buildFilterGroup('dashboard.topic'.tr(), [
                  _FilterPill(
                    label: 'common.all'.tr(),
                    isSelected: true,
                    onTap: () => setState(
                      () => _showFilterExpanded = !_showFilterExpanded,
                    ),
                  ),
                ]),
                const Spacer(),
                if (_showFilterExpanded)
                  GestureDetector(
                    onTap: () => setState(() => _showFilterExpanded = false),
                    child: const Icon(
                      Icons.keyboard_arrow_up,
                      color: Color(0xFF888888),
                    ),
                  ),
              ],
            ),
          ),

          // ── EXPANDED FILTER ──
          if (_showFilterExpanded) ...[
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCheckboxColumn(
                    title: 'dashboard.level'.tr(),
                    items: ['Novice', 'Beginner', 'Intermediate', 'Advanced'],
                    displayLabels: [
                      'dashboard.novice'.tr(),
                      'dashboard.beginner'.tr(),
                      'dashboard.intermediate'.tr(),
                      'dashboard.advanced'.tr(),
                    ],
                    selected: _selectedLevels,
                    showError: _showLevelError,
                    onToggle: (val) => setState(() {
                      if (_selectedLevels.contains(val)) {
                        _selectedLevels.remove(val);
                      } else {
                        _selectedLevels.add(val);
                      }
                    }),
                  ),
                  const SizedBox(width: 60),
                  _buildCheckboxColumn(
                    title: 'dashboard.category'.tr(),
                    items: [
                      'Main Courses',
                      'Mini Courses',
                      'Seasonal Activities',
                    ],
                    displayLabels: [
                      'dashboard.main_courses'.tr(),
                      'dashboard.mini_courses'.tr(),
                      'dashboard.seasonal'.tr(),
                    ],
                    selected: _selectedCategories,
                    showError: _showCategoryError,
                    onToggle: (val) => setState(() {
                      if (_selectedCategories.contains(val)) {
                        _selectedCategories.remove(val);
                      } else {
                        _selectedCategories.add(val);
                      }
                    }),
                  ),
                  const SizedBox(width: 60),
                  _buildCheckboxColumn(
                    title: 'dashboard.topic'.tr(),
                    items: ['Coding', 'Digital Literacy', 'CS Topics'],
                    displayLabels: [
                      'dashboard.coding'.tr(),
                      'dashboard.digital_literacy'.tr(),
                      'dashboard.cs_topics'.tr(),
                    ],
                    selected: _selectedTopics,
                    showError: _showTopicError,
                    onToggle: (val) => setState(() {
                      if (_selectedTopics.contains(val)) {
                        _selectedTopics.remove(val);
                      } else {
                        _selectedTopics.add(val);
                      }
                    }),
                  ),
                  const Spacer(),
                  // ── APPLY BUTTON ──
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLevelError = _selectedLevels.isEmpty;
                        _showCategoryError = _selectedCategories.isEmpty;
                        _showTopicError = _selectedTopics.isEmpty;
                        if (!_showLevelError &&
                            !_showCategoryError &&
                            !_showTopicError) {
                          _showFilterExpanded = false;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 252, 183, 199),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'common.apply'.tr(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterGroup(String title, List<Widget> pills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF555555),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(children: pills),
      ],
    );
  }

  Widget _buildCheckboxColumn({
    required String title,
    required List<String> items,
    List<String>? displayLabels,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
    bool showError = false,
  }) {
    final allSelected = items.every((i) => selected.contains(i));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
                letterSpacing: 0.5,
              ),
            ),
            if (showError) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      size: 12,
                      color: Color(0xFFE53935),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'error.selection_required'.tr(),
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFFE53935),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() {
            if (allSelected) {
              selected.clear();
            } else {
              selected.addAll(items);
            }
          }),
          child: Text(
            allSelected ? 'common.unselect_all'.tr() : 'common.select_all'.tr(),
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF1A73E8),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final displayLabel =
              (displayLabels != null && idx < displayLabels.length)
              ? displayLabels[idx]
              : item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                onToggle(item);
                setState(() {
                  _showLevelError = false;
                  _showCategoryError = false;
                  _showTopicError = false;
                });
              },
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: selected.contains(item)
                          ? const Color.fromARGB(255, 68, 172, 255)
                          : Colors.white,
                      border: Border.all(
                        color: selected.contains(item)
                            ? const Color.fromARGB(255, 68, 172, 255)
                            : const Color(0xFFBBBBBB),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: selected.contains(item)
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displayLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── COURSES SECTION ──
  Widget _buildCoursesSection() {
    final courses = [
      _CourseData(
        topic: 'Coding',
        level: 'Novice',
        title: 'Linus the Lemur',
        subtitle: 'Computers',
        color: const Color(0xFF5B9EA0),
        imagePath: 'assets/images/course2.jpg',
        description:
            'Linus is having fun using computers! Help him collect items he needs such as a screen and mouse. The Chameleon will raise and lower the trees making Linus reach different heights or just clearing the path.',
      ),
      _CourseData(
        topic: 'Coding',
        level: 'Novice',
        title: 'CodeMonkey Jr.',
        subtitle: 'Sequencing & Loops',
        color: const Color(0xFF7BC67E),
        imagePath: 'assets/images/course1.jpg',
        description:
            'Learn sequencing and loops by guiding the monkey through fun challenges and puzzles!',
      ),
      _CourseData(
        topic: 'CS Topics',
        level: 'Beginner',
        title: 'Data is Everywhere',
        subtitle: 'Functions & Variables',
        color: const Color(0xFF4A90C4),
        imagePath: 'assets/images/datacourse.png',
        description:
            'Get a glimpse into the world of data. Learn what data is and how to collect it. You will also learn how to organize your data using different graphing visualizations.',
      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Beginner',
        title: 'Banana Tales',
        subtitle: 'Loops & Conditions',
        color: const Color(0xFFE8A838),
        imagePath: 'assets/images/elephant.png',
      ),
      _CourseData(
        topic: 'Digital Literacy',
        level: 'Beginner',
        title: 'Digital Literacy',
        subtitle: 'Internet Safety',
        color: const Color(0xFF9B7BCB),
        imagePath: 'assets/images/digitalcourse.png',
        description:
            'A short introduction to some important topics in the digital world: How to use computers, what are software and hardware, possible threats online and protecting your privacy.',
      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Intermediate',
        title: 'Game Builder',
        subtitle: 'Game Design',
        color: const Color(0xFFE57373),
        imagePath: 'assets/images/monkey_yes.png',
      ),
      _CourseData(
        topic: 'Coding',
        level: 'Intermediate',
        title: 'Coding Chatbots',
        subtitle: 'AI & Logic',
        color: const Color(0xFF4DB6AC),
        imagePath: 'assets/images/monkey_no.png',
      ),
      _CourseData(
        topic: 'Text Coding',
        level: 'Advanced',
        title: 'Data Science',
        subtitle: 'Python & Data',
        color: const Color(0xFF7986CB),
        imagePath: 'assets/images/elephant.png',
      ),
      ..._publicCourses,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard.courses_section'.tr(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color.fromARGB(255, 68, 172, 255),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  color: const Color.fromARGB(255, 68, 172, 255),
                ),
              ],
            ),
          ),
          if (_isLoadingPublicCourses)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: courses
                  .where((course) {
                    return _selectedLevels.contains(course.level) &&
                        _selectedTopics.contains(course.topic);
                  })
                  .map(
                    (course) =>
                        _CourseCard(session: widget.session, course: course),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDiscoverBannerAndTabs(),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 24, 8),
          child: Text(
            switch (_discoverContentTab) {
              _DiscoverContentTab.challenges => 'Discover Challenges',
              _DiscoverContentTab.assets => 'Assets',
              _DiscoverContentTab.favorites => 'Favorites',
            },
            style: GoogleFonts.nunito(
              color: const Color(0xFF243A1B),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        switch (_discoverContentTab) {
          _DiscoverContentTab.challenges => _buildDiscoverChallenges(),
          _DiscoverContentTab.assets => _buildDiscoverAssets(),
          _DiscoverContentTab.favorites => _buildDiscoverFavorites(),
        },
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDiscoverBannerAndTabs() {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          child: Column(
            children: [
              Expanded(child: _DashboardDiscoverBannerPlaceholder()),
              const SizedBox(height: 42),
            ],
          ),
        ),
        Positioned(
          left: 10,
          bottom: 42,
          child: Row(
            children: [
              _DashboardDiscoverTabButton(
                label: 'CHALLENGES',
                isSelected:
                    _discoverContentTab == _DiscoverContentTab.challenges,
                onTap: () => setState(() {
                  _discoverContentTab = _DiscoverContentTab.challenges;
                }),
              ),
              const SizedBox(width: 6),
              _DashboardDiscoverTabButton(
                label: 'ASSETS',
                isSelected: _discoverContentTab == _DiscoverContentTab.assets,
                onTap: () => setState(() {
                  _discoverContentTab = _DiscoverContentTab.assets;
                }),
              ),
              const SizedBox(width: 6),
              _DashboardDiscoverTabButton(
                label: 'FAVORITES',
                isSelected:
                    _discoverContentTab == _DiscoverContentTab.favorites,
                onTap: () => setState(() {
                  _discoverContentTab = _DiscoverContentTab.favorites;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverChallenges() {
    if (_isLoadingPublishedGames) {
      return const _DashboardDiscoverMessage(
        child: CircularProgressIndicator(),
      );
    }

    if (_publishedGamesErrorMessage != null) {
      return _DashboardDiscoverMessage(
        icon: Icons.error_outline,
        message: _publishedGamesErrorMessage!,
        actionLabel: 'Try Again',
        onAction: _loadPublishedGames,
      );
    }

    if (_publishedGames.isEmpty) {
      return const _DashboardDiscoverMessage(
        icon: Icons.extension_outlined,
        message: 'No community challenges are available yet.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth / 4 - 12).clamp(
            220.0,
            _creationCardWidth,
          );
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ..._publishedGames.map(
                (game) => SizedBox(
                  width: cardWidth,
                  child: _DashboardPublishedGameCard(
                    game: game,
                    onTap: () => _openPublishedGame(game),
                    isFavorite: _favoriteChallengeIds.contains(game.id),
                    onFavoriteToggle: () => _toggleFavoriteChallenge(game),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDiscoverAssets() {
    if (_isLoadingPublishedAssets) {
      return const _DashboardDiscoverMessage(
        child: CircularProgressIndicator(),
      );
    }

    if (_publishedAssetsErrorMessage != null) {
      return _DashboardDiscoverMessage(
        icon: Icons.error_outline,
        message: _publishedAssetsErrorMessage!,
        actionLabel: 'Try Again',
        onAction: _loadPublishedAssets,
      );
    }

    if (_publishedAssets.isEmpty) {
      return const _DashboardDiscoverMessage(
        icon: Icons.auto_awesome_outlined,
        message: 'No published user assets are available yet.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth / 5 - 13).clamp(170.0, 220.0);
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _publishedAssets
                .map(
                  (asset) => SizedBox(
                    width: cardWidth,
                    child: _DashboardPublishedAssetCard(
                      asset: asset,
                      authToken: widget.session.token,
                      isFavorite: _favoriteAssetIds.contains(asset.id),
                      onFavoriteToggle: () => _toggleFavoriteAsset(asset),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverFavorites() {
    final favoriteGames = _publishedGames
        .where((game) => _favoriteChallengeIds.contains(game.id))
        .toList();
    final favoriteAssets = _publishedAssets
        .where((asset) => _favoriteAssetIds.contains(asset.id))
        .toList();
    final showGames = _showFavoriteChallenges;
    final showAssets = _showFavoriteAssets;
    final hasVisibleItems =
        (showGames && favoriteGames.isNotEmpty) ||
        (showAssets && favoriteAssets.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDEDC7)),
            ),
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Show',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF45523F),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _DashboardFavoriteFilterCheckbox(
                  label: 'Challenges',
                  value: _showFavoriteChallenges,
                  onChanged: (value) => setState(() {
                    _showFavoriteChallenges = value ?? true;
                  }),
                ),
                _DashboardFavoriteFilterCheckbox(
                  label: 'Assets',
                  value: _showFavoriteAssets,
                  onChanged: (value) => setState(() {
                    _showFavoriteAssets = value ?? true;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isLoadingPublishedGames || _isLoadingPublishedAssets)
            const _DashboardDiscoverMessage(child: CircularProgressIndicator())
          else if (!_showFavoriteChallenges && !_showFavoriteAssets)
            const _DashboardDiscoverMessage(
              icon: Icons.check_box_outline_blank_rounded,
              message: 'Choose Challenges or Assets to show your favorites.',
            )
          else if (!hasVisibleItems)
            const _DashboardDiscoverMessage(
              icon: Icons.favorite_border_rounded,
              message:
                  'No favorites yet. Tap the heart on a challenge or asset to save it here.',
            )
          else ...[
            if (showGames && favoriteGames.isNotEmpty) ...[
              _DashboardFavoritesSectionTitle(
                title: 'Challenges',
                count: favoriteGames.length,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth / 4 - 12).clamp(
                    220.0,
                    _creationCardWidth,
                  );
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: favoriteGames
                        .map(
                          (game) => SizedBox(
                            width: cardWidth,
                            child: _DashboardPublishedGameCard(
                              game: game,
                              onTap: () => _openPublishedGame(game),
                              isFavorite: true,
                              onFavoriteToggle: () =>
                                  _toggleFavoriteChallenge(game),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
            if (showGames &&
                favoriteGames.isNotEmpty &&
                showAssets &&
                favoriteAssets.isNotEmpty)
              const SizedBox(height: 24),
            if (showAssets && favoriteAssets.isNotEmpty) ...[
              _DashboardFavoritesSectionTitle(
                title: 'Assets',
                count: favoriteAssets.length,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth / 5 - 13).clamp(
                    170.0,
                    220.0,
                  );
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: favoriteAssets
                        .map(
                          (asset) => SizedBox(
                            width: cardWidth,
                            child: _DashboardPublishedAssetCard(
                              asset: asset,
                              authToken: widget.session.token,
                              isFavorite: true,
                              onFavoriteToggle: () =>
                                  _toggleFavoriteAsset(asset),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _openPublishedGame(SavedBuilderProject game) async {
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

  Widget _buildMyCreationsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: const Color(0xFFB8D9E8),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'dashboard.my_creations'.tr(),
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF1A73E8),
                ),
                label: Text(
                  'MY PROFILE',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ),
        ),

        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DashboardDiscoverTabButton(
                label: 'CHALLENGES',
                isSelected:
                    _myCreationContentTab == _MyCreationContentTab.challenges,
                onTap: () => setState(() {
                  _myCreationContentTab = _MyCreationContentTab.challenges;
                }),
              ),
              const SizedBox(width: 6),
              _DashboardDiscoverTabButton(
                label: 'ASSETS',
                isSelected:
                    _myCreationContentTab == _MyCreationContentTab.assets,
                onTap: () => setState(() {
                  _myCreationContentTab = _MyCreationContentTab.assets;
                }),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateCourseDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DB84A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Create',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFEEEEEE),
            child: _myCreationContentTab == _MyCreationContentTab.assets
                ? _buildMyCreationAssets()
                : _buildMyCreationChallenges(),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCreationChallenges() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _coursesFuture,
      builder: (context, snapshot) {
        final isLoadingCourses =
            snapshot.connectionState == ConnectionState.waiting;
        final courses = snapshot.data ?? const <Map<String, dynamic>>[];

        if (isLoadingCourses || _isLoadingMyBuilderProjects) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_myBuilderProjectsErrorMessage != null) {
          return _DashboardDiscoverMessage(
            icon: Icons.error_outline,
            message: _myBuilderProjectsErrorMessage!,
            actionLabel: 'Try Again',
            onAction: _loadMyBuilderProjects,
          );
        }

        if (courses.isEmpty && _myBuilderProjects.isEmpty) {
          return const _DashboardDiscoverMessage(
            icon: Icons.add_circle_outline_rounded,
            message: 'No challenges yet. Create your first one!',
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final levelWidth = (constraints.maxWidth / 4 - 15).clamp(
                220.0,
                _creationCardWidth,
              );
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  ...courses.map((course) {
                    final lessons = (course['lessons'] as List? ?? []);
                    return _CreationCard(
                      title: course['title'] as String? ?? 'Untitled',
                      description: course['description'] as String? ?? '',
                      lessonCount: lessons.length,
                      imageBase64: course['courseImageBase64'] as String?,
                      isPublished: course['isPublished'] as bool? ?? false,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CourseDetailPage(
                              course: course,
                              session: widget.session,
                              onRefresh: () => setState(() {
                                _coursesFuture =
                                    LegacyApiService.ApiService.getCourses(
                                      authToken: widget.session.token,
                                    );
                              }),
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _coursesFuture =
                                LegacyApiService.ApiService.getCourses(
                                  authToken: widget.session.token,
                                );
                          });
                        }
                      },
                      onDelete: () async {
                        final id = course['_id'] as String?;
                        if (id == null) return;
                        await LegacyApiService.ApiService.deleteCourse(
                          id,
                          authToken: widget.session.token,
                        );
                        if (mounted) {
                          setState(() {
                            _coursesFuture =
                                LegacyApiService.ApiService.getCourses(
                                  authToken: widget.session.token,
                                );
                          });
                        }
                      },
                    );
                  }),
                  ..._myBuilderProjects.map(
                    (project) => SizedBox(
                      width: levelWidth,
                      child: _MyCreationLevelCard(
                        project: project,
                        onOpen: () => _openMyBuilderProject(project),
                        onSettings: () => _showBuilderProjectSettings(project),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMyCreationAssets() {
    if (_isLoadingMyBuilderAssets) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myBuilderAssetsErrorMessage != null) {
      return _DashboardDiscoverMessage(
        icon: Icons.error_outline,
        message: _myBuilderAssetsErrorMessage!,
        actionLabel: 'Try Again',
        onAction: _loadMyBuilderAssets,
      );
    }

    if (_myBuilderAssets.isEmpty) {
      return const _DashboardDiscoverMessage(
        icon: Icons.auto_awesome_outlined,
        message: 'No assets yet. Add assets inside a game builder.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth / 5 - 16).clamp(180.0, 230.0);
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: _myBuilderAssets
                .map(
                  (asset) => SizedBox(
                    width: cardWidth,
                    child: _MyCreationAssetCard(
                      asset: asset,
                      authToken: widget.session.token,
                      onSettings: () => _showBuilderAssetSettings(asset),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Future<void> _openMyBuilderProject(SavedBuilderProject project) async {
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

    if (mounted) {
      _loadMyBuilderProjects();
    }
  }

  Future<void> _showBuilderProjectSettings(SavedBuilderProject project) async {
    final titleController = TextEditingController(text: project.title);
    String? coverImageBase64 = project.coverImageBase64;
    double coverFrameScale = project.coverFrameScale;
    double coverFrameOffsetX = project.coverFrameOffsetX;
    double coverFrameOffsetY = project.coverFrameOffsetY;
    String difficulty = project.difficulty.toLowerCase();
    if (!['easy', 'medium', 'hard'].contains(difficulty)) {
      difficulty = 'medium';
    }
    String status = project.status.toLowerCase() == 'published'
        ? 'published'
        : 'draft';

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: _CreationSettingsShell(
                title: 'Challenge Settings',
                subtitle: project.title,
                icon: Icons.tune_rounded,
                color: const Color(0xFF8DB75C),
                actions: [
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, {'action': 'delete'}),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, {'action': 'openBuilder'}),
                    icon: const Icon(Icons.extension_outlined),
                    label: const Text('Edit Layout'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isEmpty) return;
                      Navigator.pop(context, {
                        'title': title,
                        'difficulty': difficulty,
                        'status': status,
                        'coverImageBase64': coverImageBase64,
                        'coverFrameScale': coverFrameScale,
                        'coverFrameOffsetX': coverFrameOffsetX,
                        'coverFrameOffsetY': coverFrameOffsetY,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8DB75C),
                    ),
                    child: const Text('Save'),
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SettingsTextField(
                      controller: titleController,
                      label: 'Level name',
                      icon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 12),
                    _SettingsDropdown(
                      label: 'Difficulty',
                      icon: Icons.speed_rounded,
                      value: difficulty,
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('Easy')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'hard', child: Text('Hard')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => difficulty = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _SettingsDropdown(
                      label: 'Visibility',
                      icon: Icons.public_rounded,
                      value: status,
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => status = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await showFramedImageUploadDialog(
                          context: context,
                          title: 'Upload cover',
                          initialImageBase64: coverImageBase64,
                          initialScale: coverFrameScale,
                          initialOffsetX: coverFrameOffsetX,
                          initialOffsetY: coverFrameOffsetY,
                          aspectRatio: _myCreationLevelCoverAspectRatio,
                        );
                        if (result == null) {
                          return;
                        }
                        setDialogState(() {
                          coverImageBase64 = result.imageBase64;
                          coverFrameScale = result.scale;
                          coverFrameOffsetX = result.offsetX;
                          coverFrameOffsetY = result.offsetY;
                        });
                      },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload cover'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();

    if (!mounted || payload == null) {
      return;
    }

    if (payload['action'] == 'openBuilder') {
      await _openMyBuilderProject(project);
      return;
    }

    if (payload['action'] == 'delete') {
      await _confirmDeleteBuilderProject(project);
      return;
    }

    final result = await ApiService.updateBuilderProjectSettings(
      authToken: widget.session.token,
      projectId: project.id,
      settingsJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadMyBuilderProjects();
      _showDashboardMessage('Challenge updated successfully.');
    } else {
      _showDashboardMessage(
        result['message']?.toString() ?? 'Failed to update challenge.',
      );
    }
  }

  Future<void> _showBuilderAssetSettings(_PublishedBuilderAsset asset) async {
    final nameController = TextEditingController(text: asset.name);
    bool isPublic = asset.isPublic;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: _CreationSettingsShell(
                title: 'Asset Settings',
                subtitle: asset.name,
                icon: Icons.image_rounded,
                color: const Color(0xFF58C4DD),
                actions: [
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, {'action': 'delete'}),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;
                      Navigator.pop(context, {
                        'name': name,
                        'isPublic': isPublic,
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF58C4DD),
                    ),
                    child: const Text('Save'),
                  ),
                ],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SettingsTextField(
                      controller: nameController,
                      label: 'Asset name',
                      icon: Icons.drive_file_rename_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD9E7EC)),
                      ),
                      child: SwitchListTile(
                        value: isPublic,
                        activeThumbColor: const Color(0xFF58C4DD),
                        onChanged: (value) =>
                            setDialogState(() => isPublic = value),
                        title: Text(
                          'Public asset',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF243A1B),
                          ),
                        ),
                        subtitle: Text(
                          isPublic
                              ? 'Other users can discover and use it.'
                              : 'Only you can use it in builders.',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF667064),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();

    if (!mounted || payload == null) {
      return;
    }

    if (payload['action'] == 'delete') {
      await _confirmDeleteBuilderAsset(asset);
      return;
    }

    final result = await ApiService.updateBuilderAsset(
      authToken: widget.session.token,
      assetId: asset.id,
      assetJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadMyBuilderAssets();
      await _loadPublishedAssets();
      _showDashboardMessage('Asset updated successfully.');
    } else {
      _showDashboardMessage(
        result['message']?.toString() ?? 'Failed to update asset.',
      );
    }
  }

  Future<void> _confirmDeleteBuilderProject(SavedBuilderProject project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Challenge?'),
          content: Text('Delete "${project.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final result = await ApiService.deleteBuilderProject(
      authToken: widget.session.token,
      projectId: project.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadMyBuilderProjects();
      await _loadPublishedGames();
      _showDashboardMessage('Challenge deleted.');
    } else {
      _showDashboardMessage(
        result['message']?.toString() ?? 'Failed to delete challenge.',
      );
    }
  }

  Future<void> _confirmDeleteBuilderAsset(_PublishedBuilderAsset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Asset?'),
          content: Text('Delete "${asset.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    final result = await ApiService.deleteBuilderAsset(
      authToken: widget.session.token,
      assetId: asset.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadMyBuilderAssets();
      await _loadPublishedAssets();
      _showDashboardMessage('Asset deleted.');
    } else {
      _showDashboardMessage(
        result['message']?.toString() ?? 'Failed to delete asset.',
      );
    }
  }

  void _showDashboardMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showCreateCourseDialog() async {
    final selection = await showDialog<_CreationBuilderOption>(
      context: context,
      builder: (_) => const _CreationBuilderPickerDialog(),
    );

    if (!mounted || selection == null) {
      return;
    }

    switch (selection) {
      case _CreationBuilderOption.slides:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateCoursePage(session: widget.session),
          ),
        );
      case _CreationBuilderOption.frontView:
        await Navigator.of(context).pushNamed(
          AppRoutes.builder,
          arguments: BuilderRouteData(session: widget.session),
        );
      case _CreationBuilderOption.topView:
        await Navigator.of(context).pushNamed(
          AppRoutes.topViewBuilder,
          arguments: TopViewBuilderRouteData(session: widget.session),
        );
      case _CreationBuilderOption.scratch:
        await Navigator.of(context).pushNamed(
          AppRoutes.scratchBuilder,
          arguments: ScratchBuilderRouteData(session: widget.session),
        );
      case _CreationBuilderOption.fourthDemo:
        await Navigator.of(context).pushNamed(
          AppRoutes.fourthDemoBuilder,
          arguments: FourthDemoBuilderRouteData(session: widget.session),
        );
    }

    if (mounted) {
      _loadMyCreations();
    }
  }
}

class _CreationBuilderPickerDialog extends StatelessWidget {
  const _CreationBuilderPickerDialog();

  static const List<_CreationBuilderCardData> _options = [
    _CreationBuilderCardData(
      option: _CreationBuilderOption.slides,
      title: 'Create Slides',
      subtitle: 'Build a lesson with pages, images, and activities.',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFFFFB84D),
      accentColor: Color(0xFFFFF2C7),
    ),
    _CreationBuilderCardData(
      option: _CreationBuilderOption.frontView,
      title: 'Block Sequence',
      subtitle: 'Place blocks and plan steps from the front.',
      icon: Icons.view_in_ar_rounded,
      color: Color(0xFF58C4DD),
      accentColor: Color(0xFFE4F9FD),
    ),
    _CreationBuilderCardData(
      option: _CreationBuilderOption.topView,
      title: 'Coding Sequence',
      subtitle: 'Design grid adventures with code directions.',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF72C665),
      accentColor: Color(0xFFEAF9E5),
    ),
    _CreationBuilderCardData(
      option: _CreationBuilderOption.scratch,
      title: 'Scratch Coding',
      subtitle: 'Create friendly drag-and-drop coding challenges.',
      icon: Icons.extension_rounded,
      color: Color(0xFFB98AF3),
      accentColor: Color(0xFFF4ECFF),
    ),
    _CreationBuilderCardData(
      option: _CreationBuilderOption.fourthDemo,
      title: 'Game Builder',
      subtitle: 'Make a custom playable game world.',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFFF7C9B),
      accentColor: Color(0xFFFFEDF2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF9ED3DC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEFD99),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_reaction_rounded,
                        color: Color(0xFF3A2A00),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose what to create',
                            style: GoogleFonts.montserrat(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF2E4E55),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pick a builder and start making something fun.',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4C737A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF2E4E55),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = isMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _options
                          .map(
                            (option) => _CreationBuilderChoiceCard(
                              data: option,
                              width: cardWidth,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationBuilderCardData {
  final _CreationBuilderOption option;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color accentColor;

  const _CreationBuilderCardData({
    required this.option,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.accentColor,
  });
}

class _CreationBuilderChoiceCard extends StatefulWidget {
  final _CreationBuilderCardData data;
  final double width;

  const _CreationBuilderChoiceCard({required this.data, required this.width});

  @override
  State<_CreationBuilderChoiceCard> createState() =>
      _CreationBuilderChoiceCardState();
}

class _CreationBuilderChoiceCardState
    extends State<_CreationBuilderChoiceCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(widget.data.option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.width,
          constraints: const BoxConstraints(minHeight: 128),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? widget.data.color : widget.data.accentColor,
              width: _hovered ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.data.color.withValues(
                  alpha: _hovered ? 0.24 : 0.12,
                ),
                blurRadius: _hovered ? 18 : 8,
                offset: Offset(0, _hovered ? 8 : 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: widget.data.accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.data.icon,
                  color: widget.data.color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.data.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2B2B2B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.data.subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF686868),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open builder',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: widget.data.color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: widget.data.color,
                        ),
                      ],
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
}

class _DashboardDiscoverTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DashboardDiscoverTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF8DB75C) : const Color(0xFFF7F7F7),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: SizedBox(
          width: 150,
          height: 42,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : const Color(0xFF8EA231),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardFavoriteFilterCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _DashboardFavoriteFilterCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C9D43),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: const Color(0xFF45523F),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardFavoritesSectionTitle extends StatelessWidget {
  final String title;
  final int count;

  const _DashboardFavoritesSectionTitle({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF243A1B),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDDEDC7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF6C9D43),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardDiscoverBannerPlaceholder extends StatelessWidget {
  const _DashboardDiscoverBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Crop the source artwork slightly so the top white strip stays out of view.
    const double imageZoom = 1.14;

    // x: -1 left, 0 center, 1 right
    // y: -1 top, 0 center, 1 bottom
    const Alignment imagePosition = Alignment(0.0, -0.48);

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return OverflowBox(
            alignment: imagePosition,
            minWidth: constraints.maxWidth * imageZoom,
            maxWidth: constraints.maxWidth * imageZoom,
            minHeight: constraints.maxHeight * imageZoom,
            maxHeight: constraints.maxHeight * imageZoom,
            child: Image.asset(
              'assets/images/discovery banner.png',
              width: constraints.maxWidth * imageZoom,
              height: constraints.maxHeight * imageZoom,
              fit: BoxFit.cover,
              alignment: imagePosition,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _DashboardFavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isFavorite
          ? const Color(0xFFFFD84D)
          : Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite
                ? const Color(0xFF7A6000)
                : const Color(0xFF6C9D43),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _DashboardPublishedGameCard extends StatelessWidget {
  final SavedBuilderProject game;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _DashboardPublishedGameCard({
    required this.game,
    required this.onTap,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  Uint8List? _safeDecodeCover(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _DashboardPageState._levelCardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(color: Color(0xFFDDEDC7)),
                      child: game.coverImageBase64 == null
                          ? const Center(
                              child: Icon(
                                Icons.videogame_asset_outlined,
                                size: 44,
                                color: Color(0xFF6C9D43),
                              ),
                            )
                          : FramedImagePreview(
                              bytes: _safeDecodeCover(game.coverImageBase64),
                              scale: game.coverFrameScale,
                              offsetX: game.coverFrameOffsetX,
                              offsetY: game.coverFrameOffsetY,
                              placeholderIcon: Icons.videogame_asset_outlined,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _DashboardFavoriteButton(
                        isFavorite: isFavorite,
                        onPressed: onFavoriteToggle,
                      ),
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }
}

class _DashboardPublishedAssetCard extends StatelessWidget {
  final _PublishedBuilderAsset asset;
  final String authToken;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const _DashboardPublishedAssetCard({
    required this.asset,
    required this.authToken,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFDDEDC7)),
                    child: Image.network(
                      '${ApiService.baseUrl}/api/builder/assets/${asset.id}/data',
                      headers: {'Authorization': 'Bearer $authToken'},
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Color(0xFF6C9D43),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _DashboardFavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: onFavoriteToggle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF243A1B),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'By ${asset.ownerName}',
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF667064),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      asset.type.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF6C9D43),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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

class _MyCreationLevelCard extends StatelessWidget {
  final SavedBuilderProject project;
  final VoidCallback onOpen;
  final VoidCallback onSettings;

  const _MyCreationLevelCard({
    required this.project,
    required this.onOpen,
    required this.onSettings,
  });

  Color _builderColor() {
    if (project.isScratch) {
      return const Color(0xFFB98AF3);
    }
    if (project.isTopView) {
      return const Color(0xFF72C665);
    }
    if (project.isFourthDemo) {
      return const Color(0xFFFF7C9B);
    }
    return const Color(0xFF58C4DD);
  }

  String _builderLabel() {
    if (project.isScratch) {
      return 'Scratch Coding';
    }
    if (project.isTopView) {
      return 'Coding Sequence';
    }
    if (project.isFourthDemo) {
      return 'Game Builder';
    }
    return 'Block Sequence';
  }

  IconData _builderIcon() {
    if (project.isScratch) {
      return Icons.extension_rounded;
    }
    if (project.isTopView) {
      return Icons.grid_view_rounded;
    }
    if (project.isFourthDemo) {
      return Icons.sports_esports_rounded;
    }
    return Icons.view_in_ar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _builderColor();
    final isPublished = project.status.toLowerCase() == 'published';

    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          height: _DashboardPageState._levelCardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 104,
                width: double.infinity,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.18)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: project.coverImageBase64 == null
                          ? Center(
                              child: Icon(
                                _builderIcon(),
                                size: 48,
                                color: color,
                              ),
                            )
                          : FramedImagePreview(
                              bytes: _safeDecodeBuilderCover(
                                project.coverImageBase64,
                              ),
                              scale: project.coverFrameScale,
                              offsetX: project.coverFrameOffsetX,
                              offsetY: project.coverFrameOffsetY,
                              placeholderIcon: _builderIcon(),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CreationCardIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        onTap: onSettings,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF243A1B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project.description.isEmpty
                            ? _builderLabel()
                            : project.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF667064),
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          _CreationStatusChip(
                            label: _builderLabel(),
                            color: color,
                          ),
                          _CreationStatusChip(
                            label: project.difficulty.toUpperCase(),
                            color: const Color(0xFFFFA726),
                          ),
                          _CreationStatusChip(
                            label: isPublished ? 'PUBLIC' : 'DRAFT',
                            color: isPublished
                                ? const Color(0xFF4DB6AC)
                                : const Color(0xFF9E9E9E),
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
      ),
    );
  }

  Uint8List? _safeDecodeBuilderCover(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

class _MyCreationAssetCard extends StatelessWidget {
  final _PublishedBuilderAsset asset;
  final String authToken;
  final VoidCallback onSettings;

  const _MyCreationAssetCard({
    required this.asset,
    required this.authToken,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 270,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 158,
              width: double.infinity,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFEAF9E5)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        '${ApiService.baseUrl}/api/builder/assets/${asset.id}/data',
                        headers: {'Authorization': 'Bearer $authToken'},
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 42,
                              color: Color(0xFF6C9D43),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CreationCardIconButton(
                        icon: Icons.settings_rounded,
                        tooltip: 'Settings',
                        onTap: onSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        color: const Color(0xFF243A1B),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      asset.type.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF6C9D43),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _CreationStatusChip(
                      label: asset.isPublic ? 'PUBLIC' : 'PRIVATE',
                      color: asset.isPublic
                          ? const Color(0xFF4DB6AC)
                          : const Color(0xFF9E9E9E),
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

class _CreationCardIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CreationCardIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: const Color(0xFF45523F)),
          ),
        ),
      ),
    );
  }
}

class _CreationSettingsShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final List<Widget> actions;

  const _CreationSettingsShell({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF243A1B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF667064),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF45523F),
                  ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.all(18), child: child),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(children: actions),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E7EC)),
        ),
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _SettingsDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E7EC)),
        ),
      ),
    );
  }
}

class _CreationStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CreationStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PublishedBuilderAsset {
  final String id;
  final String name;
  final String type;
  final String ownerId;
  final String ownerName;
  final String ownerRole;
  final bool isPublic;

  const _PublishedBuilderAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRole,
    required this.isPublic,
  });

  bool get isUserCreated => ownerRole.trim().toLowerCase() != 'admin';

  factory _PublishedBuilderAsset.fromJson(Map<String, dynamic> json) {
    return _PublishedBuilderAsset(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled asset',
      type: json['type']?.toString() ?? 'asset',
      ownerId: json['ownerId']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? 'Unknown creator',
      ownerRole: json['ownerRole']?.toString() ?? '',
      isPublic: json['isPublic'] == true,
    );
  }
}

class _DashboardDiscoverMessage extends StatelessWidget {
  final Widget? child;
  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _DashboardDiscoverMessage({
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

// // ── COURSE DATA MODEL ──
// class _CourseData {
//   final String topic;
//   final String level;
//   final String title;
//   final String subtitle;
//   final Color color;
//   final String imagePath;

//   const _CourseData({
//     required this.topic,
//     required this.level,
//     required this.title,
//     required this.subtitle,
//     required this.color,
//     required this.imagePath,
//   });
// }
class _CourseData {
  final String publicCourseId;
  final String publicCourseKey;
  final String topic;
  final String level;
  final String title;
  final String subtitle;
  final Color color;
  final String imagePath;
  final String? imageBase64;
  final double coverFrameScale;
  final double coverFrameOffsetX;
  final double coverFrameOffsetY;
  final String description;

  const _CourseData({
    this.publicCourseId = '',
    this.publicCourseKey = '',
    required this.topic,
    required this.level,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.imagePath,
    this.imageBase64,
    this.coverFrameScale = 1,
    this.coverFrameOffsetX = 0,
    this.coverFrameOffsetY = 0,
    this.description = 'Start this course to learn exciting coding concepts!',
  });

  factory _CourseData.fromPublicCourseJson(Map<String, dynamic> json) {
    final title =
        json['courseName']?.toString() ??
        json['title']?.toString() ??
        'Untitled Course';
    final category = json['category']?.toString().trim();
    final topic =
        category == 'Coding' ||
            category == 'Digital Literacy' ||
            category == 'CS Topics'
        ? category!
        : 'Coding';

    return _CourseData(
      publicCourseId: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      publicCourseKey: json['courseId']?.toString() ?? '',
      topic: topic,
      level: _normalizeLevel(json['difficulty']?.toString()),
      title: title,
      subtitle: json['subtitle']?.toString() ?? 'Admin Course',
      color: const Color(0xFF4A90C4),
      imagePath: 'assets/images/course1.jpg',
      imageBase64: json['courseImageBase64']?.toString(),
      coverFrameScale: _readCourseDouble(json['coverFrameScale'], fallback: 1),
      coverFrameOffsetX: _readCourseDouble(json['coverFrameOffsetX']),
      coverFrameOffsetY: _readCourseDouble(json['coverFrameOffsetY']),
      description:
          json['description']?.toString() ??
          'Open this course to play the levels built by your teacher.',
    );
  }

  bool get isPublicCourse => publicCourseId.isNotEmpty;

  static String _normalizeLevel(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'novice':
      case 'beginner':
      case 'intermediate':
      case 'advanced':
        return raw![0].toUpperCase() + raw.substring(1).toLowerCase();
      case 'easy':
        return 'Beginner';
      case 'hard':
        return 'Advanced';
      case 'medium':
      default:
        return 'Beginner';
    }
  }

  static double _readCourseDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class _CourseCard extends StatefulWidget {
  final AuthSession session;
  final _CourseData course;
  const _CourseCard({required this.session, required this.course});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  void _showCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _CourseDialog(session: widget.session, course: widget.course),
    );
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: () => _showCourseDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TOP TAG BAR ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.course.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.widgets,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.topic,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.bar_chart,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.level,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── IMAGE WITH HOVER OVERLAY ──
              Stack(
                children: [
                  ClipRRect(
                    child: SizedBox(
                      width: 220,
                      height: 140,
                      child: widget.course.imageBase64 == null
                          ? Image.asset(
                              widget.course.imagePath,
                              fit: BoxFit.cover,
                            )
                          : FramedImagePreview(
                              bytes: _safeDecodeBase64(
                                widget.course.imageBase64,
                              ),
                              scale: widget.course.coverFrameScale,
                              offsetX: widget.course.coverFrameOffsetX,
                              offsetY: widget.course.coverFrameOffsetY,
                              placeholderIcon: Icons.menu_book_rounded,
                            ),
                    ),
                  ),
                  if (_hovered)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),

              // ── TITLE & SUBTITLE ──
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.course.subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(2),
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
}

// ── SIDEBAR ITEM ──
class _SidebarItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final IconData? icon;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: widget.isActive
              ? const Color.fromARGB(255, 68, 172, 255)
              : _hovered
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white60, size: 16),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isActive ? Colors.white : Colors.white70,
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

// ── FILTER PILL ──
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF888888)
                : const Color(0xFFDDDDDD),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

// ── UNDERWATER PAINTER ──
class _UnderwaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (double x in [80, 160, 240]) {
      final path = Path();
      path.moveTo(x, size.height);
      path.cubicTo(
        x - 20,
        size.height * 0.7,
        x + 20,
        size.height * 0.4,
        x,
        size.height * 0.1,
      );
      path.cubicTo(
        x + 20,
        size.height * 0.4,
        x - 20,
        size.height * 0.7,
        x,
        size.height,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF2D6B4A).withOpacity(0.7)
          ..style = PaintingStyle.fill,
      );
    }

    paint.color = Colors.white.withOpacity(0.3);
    for (final pos in [
      const Offset(50, 30),
      const Offset(120, 60),
      const Offset(200, 20),
    ]) {
      canvas.drawCircle(pos, 8, paint);
    }

    paint.color = const Color(0xFFE8834A).withOpacity(0.9);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(350, 50), width: 40, height: 20),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(420, 80), width: 30, height: 15),
      paint,
    );
  }

  @override
  bool shouldRepaint(_UnderwaterPainter old) => false;
}

class _CourseDialog extends StatefulWidget {
  final AuthSession session;
  final _CourseData course;
  const _CourseDialog({required this.session, required this.course});

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  int _imageIndex = 0;
  bool _isOpeningCourse = false;
  // Add more screenshot paths per course if you have them
  List<String> get _screenshots => [widget.course.imagePath];
  Widget? _getGamePage(String title) {
    switch (title) {
      case 'CodeMonkey Jr.':
        return const WorldMapPage();
      case 'Linus the Lemur':
        return null; // replace with LinusGamePage() when ready
      case 'Coding Adventure':
        return null; // replace with CodingAdventurePage() when ready
      case 'Digital Literacy':
        return const DigitalLiteracyPage();
      case 'Data is Everywhere':
        return const DataCoursePage();
      case 'Coding Chatbots':
        return const CodeMonkeyScratchPage();
      default:
        return null;
    }
  }

  Future<void> _startCoding() async {
    if (_isOpeningCourse) {
      return;
    }

    if (!widget.course.isPublicCourse) {
      _openLegacyCourse();
      return;
    }

    setState(() {
      _isOpeningCourse = true;
    });

    try {
      final levels = await _loadPublicCourseLevels();
      if (!mounted) {
        return;
      }
      if (levels.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No published levels are available yet.'),
          ),
        );
        return;
      }

      final progress = await _loadCourseProgress();
      if (!mounted) {
        return;
      }
      final nextLevel = _nextLevelForProgress(levels, progress);
      _openPublicCourseLevel(nextLevel);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start course: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningCourse = false;
        });
      }
    }
  }

  void _openLegacyCourse() {
    final navigator = Navigator.of(context);
    final page = _getGamePage(widget.course.title);
    if (page == null) {
      navigator.pop();
      return;
    }

    final routeName = switch (widget.course.title) {
      'Data is Everywhere' => 'data_course_hub',
      'Coding Chatbots' => 'ai_hoot_hub',
      _ => 'digital_literacy_hub',
    };

    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  Future<List<SavedBuilderProject>> _loadPublicCourseLevels() async {
    final result = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: _courseLookupId,
    );
    if (result['success'] != true) {
      throw result['message']?.toString() ?? 'Failed to load course levels';
    }

    return _parseList(result['data'])
        .map(SavedBuilderProject.fromJson)
        .where((level) => level.id.isNotEmpty)
        .toList()
      ..sort(_compareLevels);
  }

  Future<_DashboardCourseProgress> _loadCourseProgress() async {
    final result = await ApiService.getPublicCourseProgress(
      authToken: widget.session.token,
      courseId: _courseLookupId,
    );
    if (result['success'] != true) {
      return const _DashboardCourseProgress();
    }
    final data = result['data'];
    return _DashboardCourseProgress.fromJson(
      data is Map ? Map<String, dynamic>.from(data) : const {},
    );
  }

  SavedBuilderProject _nextLevelForProgress(
    List<SavedBuilderProject> levels,
    _DashboardCourseProgress progress,
  ) {
    final lastOrder = progress.lastCompletedOrderInCourse;
    if (lastOrder <= 0 && progress.completedLevelIds.isEmpty) {
      return levels.first;
    }
    if (lastOrder <= 0) {
      return levels.firstWhere(
        (level) => !progress.completedLevelIds.contains(level.id),
        orElse: () => levels.last,
      );
    }

    return levels.firstWhere(
      (level) => level.orderInCourse > lastOrder,
      orElse: () => levels.last,
    );
  }

  void _openPublicCourseLevel(SavedBuilderProject level) {
    final navigator = Navigator.of(context);
    final routeName = level.isTopView
        ? AppRoutes.topViewBuilder
        : level.isScratch
        ? AppRoutes.scratchBuilder
        : level.isFourthDemo
        ? AppRoutes.fourthDemoBuilder
        : AppRoutes.builderPlay;
    final routeData = level.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : level.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : level.isFourthDemo
        ? FourthDemoBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: level.id,
            initialTitle: level.title,
            courseProgressCourseId: _courseLookupId,
            courseProgressLevelId: level.id,
          );

    navigator.pop();
    navigator.pushNamed(routeName, arguments: routeData);
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int _compareLevels(SavedBuilderProject a, SavedBuilderProject b) {
    final orderComparison = a.orderInCourse.compareTo(b.orderInCourse);
    if (orderComparison != 0) {
      return orderComparison;
    }
    return a.title.compareTo(b.title);
  }

  String get _courseLookupId {
    return widget.course.publicCourseKey.isNotEmpty
        ? widget.course.publicCourseKey
        : widget.course.publicCourseId;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── HEADER ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${widget.course.title}: ',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: widget.course.subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: screenshot + arrows ──
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _screenshots[_imageIndex],
                          width: 260,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ArrowBtn(
                            icon: Icons.chevron_left,
                            onTap: () => setState(() {
                              _imageIndex =
                                  (_imageIndex - 1 + _screenshots.length) %
                                  _screenshots.length;
                            }),
                          ),
                          const SizedBox(width: 12),
                          _ArrowBtn(
                            icon: Icons.chevron_right,
                            onTap: () => setState(() {
                              _imageIndex =
                                  (_imageIndex + 1) % _screenshots.length;
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // ── RIGHT: status + description ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_border,
                                color: Color(0xFFFFB300),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'dashboard.not_started'.tr(),
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A6000),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Text(
                          widget.course.description,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF444444),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FOOTER ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: ElevatedButton(
                onPressed: _isOpeningCourse ? null : _startCoding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6DB84A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isOpeningCourse
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'dashboard.start_coding'.tr(),
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ARROW BUTTON ──
class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6DB84A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _DashboardPublicCourseLevelsPage extends StatefulWidget {
  final AuthSession session;
  final _CourseData course;

  const _DashboardPublicCourseLevelsPage({
    required this.session,
    required this.course,
  });

  @override
  State<_DashboardPublicCourseLevelsPage> createState() =>
      _DashboardPublicCourseLevelsPageState();
}

class _DashboardPublicCourseLevelsPageState
    extends State<_DashboardPublicCourseLevelsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<SavedBuilderProject> _levels = const [];

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getPublicCourseLevels(
      authToken: widget.session.token,
      courseId: widget.course.publicCourseKey.isNotEmpty
          ? widget.course.publicCourseKey
          : widget.course.publicCourseId,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final levels =
          _parseList(result['data'])
              .map(SavedBuilderProject.fromJson)
              .where((level) => level.id.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final orderComparison = a.orderInCourse.compareTo(
                b.orderInCourse,
              );
              if (orderComparison != 0) {
                return orderComparison;
              }
              return a.title.compareTo(b.title);
            });

      setState(() {
        _levels = levels;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage =
          result['message']?.toString() ?? 'Failed to load course levels';
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];
    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _openLevel(SavedBuilderProject level) async {
    final routeName = level.isTopView
        ? AppRoutes.topViewBuilder
        : level.isScratch
        ? AppRoutes.scratchBuilder
        : AppRoutes.builderPlay;
    final routeData = level.isTopView
        ? TopViewBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
          )
        : level.isScratch
        ? ScratchBuilderRouteData(
            session: widget.session,
            initialProjectId: level.id,
            allowPublishedAccess: true,
            playMode: true,
            initialTitle: level.title,
          )
        : BuilderPlayRouteData(
            session: widget.session,
            projectId: level.id,
            initialTitle: level.title,
          );

    await Navigator.of(context).pushNamed(routeName, arguments: routeData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: RefreshIndicator(
        onRefresh: _loadLevels,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const _DashboardScrollableMessage(
                child: CircularProgressIndicator(),
              );
            }

            if (_errorMessage != null) {
              return _DashboardScrollableMessage(
                child: Text(_errorMessage!, textAlign: TextAlign.center),
              );
            }

            if (_levels.isEmpty) {
              return const _DashboardScrollableMessage(
                child: Text('No published levels are available yet.'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _levels.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final level = _levels[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(level.title),
                    subtitle: Text(
                      '${level.isTopView
                          ? 'Top View'
                          : level.isScratch
                          ? 'Scratch'
                          : 'Front View'} - ${level.difficulty}',
                    ),
                    trailing: const Icon(Icons.play_arrow_rounded),
                    onTap: () => _openLevel(level),
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

class _DashboardScrollableMessage extends StatelessWidget {
  final Widget child;

  const _DashboardScrollableMessage({required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
        Center(child: child),
      ],
    );
  }
}

class _DashboardCourseProgress {
  const _DashboardCourseProgress({
    this.completedLevelIds = const <String>{},
    this.lastCompletedOrderInCourse = 0,
  });

  final Set<String> completedLevelIds;
  final int lastCompletedOrderInCourse;

  factory _DashboardCourseProgress.fromJson(Map<String, dynamic> json) {
    final completedLevels = json['completedLevels'] is List
        ? json['completedLevels'] as List
        : const [];
    return _DashboardCourseProgress(
      completedLevelIds: completedLevels
          .whereType<Map>()
          .map((item) => item['levelId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet(),
      lastCompletedOrderInCourse: _readInt(json['lastCompletedOrderInCourse']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _CreationCard extends StatefulWidget {
  final String title;
  final String description;
  final int lessonCount;
  final String? imageBase64;
  final bool isPublished;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CreationCard({
    required this.title,
    required this.description,
    required this.lessonCount,
    required this.onTap,
    required this.onDelete,
    this.imageBase64,
    this.isPublished = false,
  });

  @override
  State<_CreationCard> createState() => _CreationCardState();
}

class _CreationCardState extends State<_CreationCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() => _hovered = value);
  }

  Widget _fallbackHeader() => Container(
    height: 120,
    width: double.infinity,
    color: const Color(0xFF4DD0C4),
    child: Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 38,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    ),
  );

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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: _DashboardPageState._creationCardWidth,
          height: _DashboardPageState._levelCardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
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
                child: widget.imageBase64 != null
                    ? Image.memory(
                        _safeDecodeBase64(widget.imageBase64) ?? Uint8List(0),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackHeader(),
                      )
                    : _fallbackHeader(),
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
                          Text(
                            '${widget.lessonCount} lesson${widget.lessonCount == 1 ? '' : 's'}',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: const Color(0xFF888888),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    backgroundColor: Colors.transparent,
                                    insetPadding: const EdgeInsets.all(20),
                                    child: _CreationSettingsShell(
                                      title: 'Course Settings',
                                      subtitle: widget.title,
                                      icon: Icons.menu_book_rounded,
                                      color: const Color(0xFF4DD0C4),
                                      actions: [
                                        TextButton.icon(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            widget.onDelete();
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          label: const Text('Delete'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFFE53935,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                      child: Text(
                                        'Manage this course from My Creations.',
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF667064),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Icon(
                              Icons.settings_rounded,
                              size: 18,
                              color: Color(0xFFCCCCCC),
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
      ),
    );
  }
}

class _DashboardAccountMenu extends StatelessWidget {
  const _DashboardAccountMenu({
    required this.onLanguage,
    required this.onHome,
    required this.onProfile,
    required this.onSignOut,
  });

  final VoidCallback onLanguage;
  final VoidCallback onHome;
  final VoidCallback onProfile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_DashboardAccountMenuAction>(
      tooltip: 'Menu',
      offset: const Offset(0, 34),
      color: const Color(0xFF3A2018),
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 224),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF140C09), width: 1.2),
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (action) {
        switch (action) {
          case _DashboardAccountMenuAction.language:
            onLanguage();
          case _DashboardAccountMenuAction.home:
            onHome();
          case _DashboardAccountMenuAction.profile:
            onProfile();
          case _DashboardAccountMenuAction.signOut:
            onSignOut();
        }
      },
      itemBuilder: (context) {
        final language = AppLanguage.of(context);
        final code = language.locale.languageCode.toUpperCase();
        return [
          PopupMenuItem(
            value: _DashboardAccountMenuAction.language,
            child: _DashboardMenuRow(
              icon: Icons.language_rounded,
              label: language.tr('language', 'Language'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF9BD46A)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF9BD46A),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          PopupMenuItem(
            value: _DashboardAccountMenuAction.home,
            child: _DashboardMenuRow(
              icon: Icons.home_rounded,
              label: language.tr('home', 'Home'),
            ),
          ),
          PopupMenuItem(
            value: _DashboardAccountMenuAction.profile,
            child: _DashboardMenuRow(
              icon: Icons.account_circle_rounded,
              label: language.tr('myProfile', 'My Profile'),
            ),
          ),
          PopupMenuItem(
            value: _DashboardAccountMenuAction.signOut,
            height: 54,
            padding: EdgeInsets.zero,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF9DD36A),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    language.tr('signOut', 'Sign Out').toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF4F4A56),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF4F4A56),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ];
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/images/sprites/btn_menu.png',
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}

enum _DashboardAccountMenuAction { language, home, profile, signOut }

class _DashboardMenuRow extends StatelessWidget {
  const _DashboardMenuRow({
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFEDE7E2), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: const Color(0xFFEDE7E2),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _LanguageChoiceButton extends StatelessWidget {
  const _LanguageChoiceButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.18) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE1DED6),
            width: isSelected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF3A2A00),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 26),
          ],
        ),
      ),
    );
  }
}

class _EmailVerificationNotice extends StatelessWidget {
  const _EmailVerificationNotice({
    required this.email,
    required this.isSending,
    required this.onResend,
    required this.onClose,
  });

  final String email;
  final bool isSending;
  final VoidCallback onResend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 18,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 520,
              constraints: const BoxConstraints(maxWidth: 520),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.mark_email_unread_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please verify your email${email.isEmpty ? '' : ' ($email)'}.',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isSending ? null : onResend,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'SEND EMAIL',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── AVATAR WIDGET ──
class _AvatarWidget extends StatefulWidget {
  final String avatarType;
  final String avatarPath;
  final String? profilePhotoBase64;
  final double profilePhotoFrameScale;
  final double profilePhotoFrameOffsetX;
  final double profilePhotoFrameOffsetY;
  final bool isSavingAvatar;
  final double size;
  final ValueChanged<String> onSelect;
  final VoidCallback onUploadPhoto;

  const _AvatarWidget({
    required this.avatarType,
    required this.avatarPath,
    required this.profilePhotoBase64,
    required this.profilePhotoFrameScale,
    required this.profilePhotoFrameOffsetX,
    required this.profilePhotoFrameOffsetY,
    required this.isSavingAvatar,
    required this.size,
    required this.onSelect,
    required this.onUploadPhoto,
  });

  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  bool _hovered = false;

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (_) => _AvatarSelectionDialog(
        currentAvatar: widget.avatarPath,
        onSelect: widget.onSelect,
        onUploadPhoto: widget.onUploadPhoto,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showAvatarDialog,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              ClipOval(
                child: widget.avatarType == 'upload'
                    ? FramedImagePreview(
                        bytes: _safeDecodeBase64(widget.profilePhotoBase64),
                        scale: widget.profilePhotoFrameScale,
                        offsetX: widget.profilePhotoFrameOffsetX,
                        offsetY: widget.profilePhotoFrameOffsetY,
                        placeholderIcon: Icons.person_rounded,
                      )
                    : Image.asset(
                        widget.avatarPath,
                        width: widget.size,
                        height: widget.size,
                        fit: BoxFit.cover,
                      ),
              ),
              if (_hovered)
                ClipOval(
                  child: Image.asset(
                    'assets/images/sprites/avatar_change.png',
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.cover,
                  ),
                ),
              if (widget.isSavingAvatar)
                ClipOval(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
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

// ── AVATAR SELECTION DIALOG ──
class _AvatarSelectionDialog extends StatefulWidget {
  final String currentAvatar;
  final ValueChanged<String> onSelect;
  final VoidCallback onUploadPhoto;

  const _AvatarSelectionDialog({
    required this.currentAvatar,
    required this.onSelect,
    required this.onUploadPhoto,
  });

  @override
  State<_AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<_AvatarSelectionDialog> {
  late String _selected;

  static const List<String> _avatars = [
    'assets/images/sprites/avatar1.png',
    'assets/images/sprites/avatar2.png',
    'assets/images/sprites/avatar3.png',
    'assets/images/sprites/avatar4.png',
    'assets/images/sprites/avatar5.png',
    'assets/images/sprites/avatar6.png',
    'assets/images/sprites/avatar7.png',
    'assets/images/sprites/avatar8.png',
    'assets/images/sprites/avatar9.png',
    'assets/images/sprites/avatar10.png',
    'assets/images/sprites/avatar11.png',
    'assets/images/sprites/avatar12.png',
    'assets/images/sprites/avatar13.png',
    'assets/images/sprites/avatar14.png',
    'assets/images/sprites/avatar15.png',
    'assets/images/sprites/avatar16.png',
    'assets/images/sprites/avatar17.png',
    'assets/images/sprites/avatar18.png',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHANGE AVATAR',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4CAF50),
                      letterSpacing: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF4CAF50), thickness: 2),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current avatar preview
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF8B6914),
                        width: 3,
                      ),
                      color: const Color(0xFF8B6914),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: Image.asset(_selected, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Scrollable grid of avatars
                  Expanded(
                    child: SizedBox(
                      height: 240,
                      child: GridView.count(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: _avatars.map((path) {
                          final isSelected = path == _selected;
                          return GestureDetector(
                            onTap: () => setState(() => _selected = path),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: const Color(0xFF4A7DBF),
                                        width: 3,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 3,
                                      ),
                              ),
                              child: ClipOval(
                                child: Image.asset(path, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onUploadPhoto();
                    },
                    icon: const Icon(Icons.upload_rounded),
                    label: Text(
                      'UPLOAD PHOTO',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF555555),
                      side: const BorderSide(color: Color(0xFFBBBBBB)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSelect(_selected);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'SAVE',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
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

class _WelcomeBannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.40, 0)
      ..lineTo(size.width * 0.42, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(_WelcomeBannerClipper oldClipper) => false;
}
