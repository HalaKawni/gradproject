import 'dart:convert';
import 'dart:typed_data';

import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/shared/widgets/framed_image_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:client/core/utils/web_redirect.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    required this.session,
    this.showAppBar = true,
  });

  final AuthSession session;
  final bool showAppBar;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = true;
  String? _errorMessage;
  late AuthUser _profileUser;
  String _createdAt = '';
  String _updatedAt = '';
  String _lastLoginAt = '';
  int _totalProjects = 0;
  int _publishedProjects = 0;
  int _draftProjects = 0;
  String _profileAvatarType = 'asset';
  String _selectedAvatarPath = 'assets/images/sprites/avatar00.png';
  String? _profilePhotoBase64;
  double _profilePhotoFrameScale = 1;
  double _profilePhotoFrameOffsetX = 0;
  double _profilePhotoFrameOffsetY = 0;
  bool _isSavingAvatar = false;
  bool _isSendingVerificationEmail = false;

  @override
  void initState() {
    super.initState();
    _profileUser = widget.session.user;
    _syncAvatarFromUser(_profileUser);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final profileResult = await ApiService.getProfile(
      authToken: widget.session.token,
    );
    final projectsResult = await ApiService.getAllBuilderProjects(
      authToken: widget.session.token,
    );

    if (!mounted) {
      return;
    }

    if (profileResult['success'] != true) {
      setState(() {
        _errorMessage =
            profileResult['message']?.toString() ?? 'Failed to load profile';
        _isLoading = false;
      });
      return;
    }

    final profileJson = _extractProfileJson(profileResult['data']);
    final projects = _parseList(projectsResult['data']);

    setState(() {
      if (profileJson.isNotEmpty) {
        _profileUser = AuthUser.fromJson(profileJson);
      }
      _syncAvatarFromUser(_profileUser);
      _createdAt = _formatDate(profileJson['createdAt']);
      _updatedAt = _formatDate(profileJson['updatedAt']);
      _lastLoginAt = _formatDate(profileJson['lastLoginAt']);
      _totalProjects = projects.length;
      _publishedProjects = projects
          .where((project) => project['status']?.toString() == 'published')
          .length;
      _draftProjects = projects
          .where((project) => project['status']?.toString() == 'draft')
          .length;
      _isLoading = false;
    });
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

  List<Map<String, dynamic>> _parseList(Object? value) {
    final rawList = value is List ? value : const [];

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatDate(Object? value) {
    final rawValue = value?.toString();

    if (rawValue == null || rawValue.isEmpty) {
      return '';
    }

    final parsedDate = DateTime.tryParse(rawValue);

    if (parsedDate == null) {
      return rawValue;
    }

    final localDate = parsedDate.toLocal();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');

    return '${localDate.year}-$month-$day';
  }

  String _roleLabel(String role) {
    final language = AppLanguage.of(context);
    switch (role) {
      case 'admin':
        return language.t('adminRole');
      case 'parent':
        return language.t('parentRole');
      case 'child':
        return language.t('studentRole');
      default:
        return role.isEmpty ? language.t('userRole') : role;
    }
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _openMyGames() {
    Navigator.of(context).pushNamed(
      AppRoutes.myGames,
      arguments: MyGamesRouteData(session: widget.session),
    );
  }

  void _openPublishedGames() {
    Navigator.of(context).pushNamed(
      AppRoutes.myPublishedGames,
      arguments: MyPublishedGamesRouteData(session: widget.session),
    );
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
          _profileUser = AuthUser.fromJson(profileJson);
          _syncAvatarFromUser(_profileUser);
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

    await _loadProfile();
  }

  Future<void> _resendVerificationEmail() async {
    if (_isSendingVerificationEmail) {
      return;
    }

    setState(() {
      _isSendingVerificationEmail = true;
    });

    final result = await ApiService.resendVerificationEmail(
      email: _profileUser.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSendingVerificationEmail = false;
    });

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
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    var hideCurrentPassword = true;
    var hideNewPassword = true;
    var hideConfirmPassword = true;
    var isSubmitting = false;
    String? errorMessage;

    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLanguage.of(context).t('changePassword')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: hideCurrentPassword,
                      decoration: InputDecoration(
                        labelText: AppLanguage.of(context).t('currentPassword'),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideCurrentPassword
                              ? AppLanguage.of(context).t('showPassword')
                              : AppLanguage.of(context).t('hidePassword'),
                          onPressed: () {
                            setDialogState(() {
                              hideCurrentPassword = !hideCurrentPassword;
                            });
                          },
                          icon: Icon(
                            hideCurrentPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: hideNewPassword,
                      decoration: InputDecoration(
                        labelText: AppLanguage.of(context).t('newPassword'),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideNewPassword
                              ? AppLanguage.of(context).t('showPassword')
                              : AppLanguage.of(context).t('hidePassword'),
                          onPressed: () {
                            setDialogState(() {
                              hideNewPassword = !hideNewPassword;
                            });
                          },
                          icon: Icon(
                            hideNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,
                      decoration: InputDecoration(
                        labelText: AppLanguage.of(
                          context,
                        ).t('confirmNewPassword'),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideConfirmPassword
                              ? AppLanguage.of(context).t('showPassword')
                              : AppLanguage.of(context).t('hidePassword'),
                          onPressed: () {
                            setDialogState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },
                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: Text(AppLanguage.of(context).t('cancel')),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPassword =
                              currentPasswordController.text;
                          final newPassword = newPasswordController.text;
                          final confirmPassword =
                              confirmPasswordController.text;

                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            setDialogState(() {
                              errorMessage = 'Fill in all password fields.';
                            });
                            return;
                          }

                          if (newPassword.length < 6) {
                            setDialogState(() {
                              errorMessage =
                                  'New password must be at least 6 characters.';
                            });
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            setDialogState(() {
                              errorMessage = 'New passwords do not match.';
                            });
                            return;
                          }

                          setDialogState(() {
                            errorMessage = null;
                            isSubmitting = true;
                          });

                          final result = await ApiService.changePassword(
                            authToken: widget.session.token,
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                          );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          if (result['success'] == true) {
                            Navigator.pop(dialogContext, true);
                            return;
                          }

                          setDialogState(() {
                            errorMessage =
                                result['message']?.toString() ??
                                'Failed to change password.';
                            isSubmitting = false;
                          });
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLanguage.of(context).t('change')),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (!mounted || changed != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLanguage.of(context).t('passwordChanged'))),
    );
  }

  void _logout() {
    webRedirect('http://localhost:8080/');
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCB7C7),
        foregroundColor: const Color(0xFF3A2A00),
        elevation: 0,
        title: Text(
          AppLanguage.of(context).tr('myProfile', 'My Profile'),
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w900),
        ),
      ),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final language = AppLanguage.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: Text(language.t('retry')),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFF0F0ED)),
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 34),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      initials: _initials(_profileUser.name),
                      name: _profileUser.name,
                      email: _profileUser.email,
                      role: _roleLabel(_profileUser.role),
                      verified: _profileUser.emailVerified,
                      avatarType: _profileAvatarType,
                      avatarPath: _selectedAvatarPath,
                      profilePhotoBase64: _profilePhotoBase64,
                      profilePhotoFrameScale: _profilePhotoFrameScale,
                      profilePhotoFrameOffsetX: _profilePhotoFrameOffsetX,
                      profilePhotoFrameOffsetY: _profilePhotoFrameOffsetY,
                      isSavingAvatar: _isSavingAvatar,
                      onAvatarSelected: _saveAssetAvatar,
                      onUploadPhoto: _uploadProfilePhoto,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatTile(
                          icon: Icons.extension_rounded,
                          label: language.tr('projects', 'Projects'),
                          value: '$_totalProjects',
                          color: const Color(0xFF58C4DD),
                        ),
                        _StatTile(
                          icon: Icons.public_rounded,
                          label: language.tr('published', 'Published'),
                          value: '$_publishedProjects',
                          color: const Color(0xFF6DB84A),
                        ),
                        _StatTile(
                          icon: Icons.edit_note_rounded,
                          label: language.tr('drafts', 'Drafts'),
                          value: '$_draftProjects',
                          color: const Color(0xFFFFC83D),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionPanel(
                      title: language.tr('accountDetails', 'Account Details'),
                      icon: Icons.badge_rounded,
                      children: [
                        _DetailRow(
                          icon: Icons.person_rounded,
                          label: language.tr('name', 'Name'),
                          value: _profileUser.name,
                        ),
                        _DetailRow(
                          icon: Icons.mail_rounded,
                          label: language.tr('email', 'Email'),
                          value: _profileUser.email,
                        ),
                        _DetailRow(
                          icon: Icons.verified_user_rounded,
                          label: language.tr('role', 'Role'),
                          value: _roleLabel(_profileUser.role),
                        ),
                        _DetailRow(
                          icon: Icons.check_circle_rounded,
                          label: language.tr('emailStatus', 'Email Status'),
                          value: _profileUser.emailVerified
                              ? language.tr('verified', 'Verified')
                              : language.tr('unverified', 'Unverified'),
                        ),
                        if (_createdAt.isNotEmpty)
                          _DetailRow(
                            icon: Icons.calendar_today_rounded,
                            label: language.tr('created', 'Created'),
                            value: _createdAt,
                          ),
                        if (_updatedAt.isNotEmpty)
                          _DetailRow(
                            icon: Icons.update_rounded,
                            label: language.tr('lastUpdated', 'Last Updated'),
                            value: _updatedAt,
                          ),
                        if (_lastLoginAt.isNotEmpty)
                          _DetailRow(
                            icon: Icons.login_rounded,
                            label: language.tr('lastLogin', 'Last Login'),
                            value: _lastLoginAt,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SectionPanel(
                      title: language.tr('quickActions', 'Quick Actions'),
                      icon: Icons.bolt_rounded,
                      children: [
                        _LanguageSelector(),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ActionTile(
                              icon: Icons.lock_reset_rounded,
                              title: language.tr(
                                'changePassword',
                                'Change Password',
                              ),
                              subtitle: language.tr(
                                'updatePasswordSubtitle',
                                'Keep your account safe.',
                              ),
                              onPressed: _showChangePasswordDialog,
                              color: const Color(0xFF58C4DD),
                            ),
                            _ActionTile(
                              icon: Icons.folder_copy_rounded,
                              title: language.tr('myGames', 'My Games'),
                              subtitle: language.tr(
                                'myGamesSubtitle',
                                'Open the games you created.',
                              ),
                              onPressed: _openMyGames,
                              color: const Color(0xFF6DB84A),
                            ),
                            _ActionTile(
                              icon: Icons.public_rounded,
                              title: language.tr(
                                'publishedGames',
                                'Published Games',
                              ),
                              subtitle: language.tr(
                                'publishedGamesSubtitle',
                                'See your shared games.',
                              ),
                              onPressed: _openPublishedGames,
                              color: const Color(0xFFFFC83D),
                            ),
                            if (!_profileUser.emailVerified)
                              _ActionTile(
                                icon: Icons.mark_email_unread_rounded,
                                title: language.tr(
                                  'sendVerificationEmail',
                                  'Send Verification Email',
                                ),
                                subtitle: _isSendingVerificationEmail
                                    ? language.tr(
                                        'sendingVerificationEmail',
                                        'Sending email...',
                                      )
                                    : language.tr(
                                        'verifyEmailSubtitle',
                                        'Send a new verification link.',
                                      ),
                                onPressed: _isSendingVerificationEmail
                                    ? () {}
                                    : _resendVerificationEmail,
                                color: const Color(0xFFE85D75),
                              ),
                            _ActionTile(
                              icon: Icons.logout_rounded,
                              title: language.tr('logout', 'Sign Out'),
                              subtitle: language.tr(
                                'logoutSubtitle',
                                'Leave this device safely.',
                              ),
                              onPressed: _logout,
                              color: const Color(0xFFE85D75),
                              isDestructive: true,
                            ),
                          ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.role,
    required this.verified,
    required this.avatarType,
    required this.avatarPath,
    required this.profilePhotoBase64,
    required this.profilePhotoFrameScale,
    required this.profilePhotoFrameOffsetX,
    required this.profilePhotoFrameOffsetY,
    required this.isSavingAvatar,
    required this.onAvatarSelected,
    required this.onUploadPhoto,
  });

  final String initials;
  final String name;
  final String email;
  final String role;
  final bool verified;
  final String avatarType;
  final String avatarPath;
  final String? profilePhotoBase64;
  final double profilePhotoFrameScale;
  final double profilePhotoFrameOffsetX;
  final double profilePhotoFrameOffsetY;
  final bool isSavingAvatar;
  final ValueChanged<String> onAvatarSelected;
  final VoidCallback onUploadPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC83D), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final avatar = _ProfileAvatarWidget(
            avatarType: avatarType,
            avatarPath: avatarPath,
            profilePhotoBase64: profilePhotoBase64,
            profilePhotoFrameScale: profilePhotoFrameScale,
            profilePhotoFrameOffsetX: profilePhotoFrameOffsetX,
            profilePhotoFrameOffsetY: profilePhotoFrameOffsetY,
            isSavingAvatar: isSavingAvatar,
            size: 96,
            onSelect: onAvatarSelected,
            onUploadPhoto: onUploadPhoto,
            fallbackInitials: initials,
          );
          final details = Column(
            crossAxisAlignment: isCompact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                name,
                textAlign: isCompact ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF3A2A00),
                  fontSize: isCompact ? 28 : 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                email,
                textAlign: isCompact ? TextAlign.center : TextAlign.start,
                style: GoogleFonts.nunito(
                  color: const Color(0xFF667064),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: isCompact
                    ? WrapAlignment.center
                    : WrapAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ProfileBadge(
                    icon: Icons.star_rounded,
                    label: role,
                    color: const Color(0xFF6DB84A),
                  ),
                  _ProfileBadge(
                    icon: verified
                        ? Icons.verified_rounded
                        : Icons.info_rounded,
                    label: verified ? 'Verified' : 'Unverified',
                    color: verified
                        ? const Color(0xFF58C4DD)
                        : const Color(0xFFE85D75),
                  ),
                ],
              ),
            ],
          );

          if (isCompact) {
            return Column(
              children: [avatar, const SizedBox(height: 14), details],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: const Color(0xFF3A2A00),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatarWidget extends StatefulWidget {
  const _ProfileAvatarWidget({
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
    required this.fallbackInitials,
  });

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
  final String fallbackInitials;

  @override
  State<_ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<_ProfileAvatarWidget> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _hovered = value;
    });
  }

  void _showAvatarDialog() {
    showDialog(
      context: context,
      builder: (_) => _ProfileAvatarSelectionDialog(
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
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showAvatarDialog,
        child: Container(
          width: widget.size,
          height: widget.size,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58C4DD).withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.avatarType == 'upload'
                    ? FramedImagePreview(
                        bytes: _safeDecodeBase64(widget.profilePhotoBase64),
                        scale: widget.profilePhotoFrameScale,
                        offsetX: widget.profilePhotoFrameOffsetX,
                        offsetY: widget.profilePhotoFrameOffsetY,
                        placeholderIcon: Icons.person_rounded,
                      )
                    : Image.asset(
                        widget.avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            alignment: Alignment.center,
                            color: const Color(0xFF58C4DD),
                            child: Text(
                              widget.fallbackInitials,
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        },
                      ),
                if (_hovered)
                  Image.asset(
                    'assets/images/sprites/avatar_change.png',
                    fit: BoxFit.cover,
                  ),
                if (widget.isSavingAvatar)
                  Container(
                    color: Colors.white.withValues(alpha: 0.72),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarSelectionDialog extends StatefulWidget {
  const _ProfileAvatarSelectionDialog({
    required this.currentAvatar,
    required this.onSelect,
    required this.onUploadPhoto,
  });

  final String currentAvatar;
  final ValueChanged<String> onSelect;
  final VoidCallback onUploadPhoto;

  @override
  State<_ProfileAvatarSelectionDialog> createState() =>
      _ProfileAvatarSelectionDialogState();
}

class _ProfileAvatarSelectionDialogState
    extends State<_ProfileAvatarSelectionDialog> {
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF4CAF50), thickness: 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            onTap: () => setState(() {
                              _selected = path;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4A7DBF)
                                      : Colors.transparent,
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF3A2A00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF667064),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8E7E9), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCB7C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF3A2A00)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF3A2A00),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final language = AppLanguage.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC83D), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF58C4DD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.language_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  language.tr('appLanguage', 'App Language'),
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF3A2A00),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  language.tr(
                    'languageSubtitle',
                    'Choose how the app talks with you.',
                  ),
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF667064),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<String>(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            segments: [
              ButtonSegment(
                value: 'en',
                label: Text(language.tr('english', 'EN')),
              ),
              ButtonSegment(
                value: 'ar',
                label: Text(language.tr('arabic', 'AR')),
              ),
            ],
            selected: {language.locale.languageCode},
            onSelectionChanged: (selection) async {
              final code = selection.first;
              await AppLanguage.instance.setLanguage(code);
              if (context.mounted) {
                await context.setLocale(Locale(code));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: const Color(0xFF58C4DD)),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                color: const Color(0xFF667064),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: GoogleFonts.nunito(
                color: const Color(0xFF3A2A00),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.color,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final Color color;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isDestructive ? const Color(0xFFE85D75) : color;

    return SizedBox(
      width: 290,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: foregroundColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: foregroundColor.withValues(alpha: 0.32),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: foregroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF3A2A00),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF667064),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: foregroundColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
