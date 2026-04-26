import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _profileUser = widget.session.user;
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
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'parent':
        return 'Parent';
      case 'child':
        return 'Student';
      default:
        return role.isEmpty ? 'User' : role;
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
              title: const Text('Change Password'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: hideCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideCurrentPassword
                              ? 'Show password'
                              : 'Hide password',
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
                        labelText: 'New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideNewPassword
                              ? 'Show password'
                              : 'Hide password',
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
                        labelText: 'Confirm New Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: hideConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
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
                  child: const Text('Cancel'),
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
                      : const Text('Change'),
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
      const SnackBar(content: Text('Password changed successfully')),
    );
  }

  void _logout() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: content,
    );
  }

  Widget _buildContent(BuildContext context) {
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
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _ProfileHeader(
            initials: _initials(_profileUser.name),
            name: _profileUser.name,
            email: _profileUser.email,
            role: _roleLabel(_profileUser.role),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(
                icon: Icons.extension_outlined,
                label: 'Projects',
                value: '$_totalProjects',
              ),
              _StatTile(
                icon: Icons.public_outlined,
                label: 'Published',
                value: '$_publishedProjects',
              ),
              _StatTile(
                icon: Icons.edit_note_outlined,
                label: 'Drafts',
                value: '$_draftProjects',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionPanel(
            title: 'Account Details',
            children: [
              _DetailRow(
                icon: Icons.mail_outline,
                label: 'Email',
                value: _profileUser.email,
              ),
              _DetailRow(
                icon: Icons.verified_user_outlined,
                label: 'Role',
                value: _roleLabel(_profileUser.role),
              ),
              if (_createdAt.isNotEmpty)
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Created',
                  value: _createdAt,
                ),
              if (_updatedAt.isNotEmpty)
                _DetailRow(
                  icon: Icons.update_outlined,
                  label: 'Last Updated',
                  value: _updatedAt,
                ),
              if (_lastLoginAt.isNotEmpty)
                _DetailRow(
                  icon: Icons.login_outlined,
                  label: 'Last Login',
                  value: _lastLoginAt,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionPanel(
            title: 'Quick Actions',
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onPressed: _showChangePasswordDialog,
                  ),
                  _ActionTile(
                    icon: Icons.folder_copy_outlined,
                    title: 'My Games',
                    subtitle: 'Open your saved builder projects',
                    onPressed: _openMyGames,
                  ),
                  _ActionTile(
                    icon: Icons.public_outlined,
                    title: 'Published Games',
                    subtitle: 'Play and review shared games',
                    onPressed: _openPublishedGames,
                  ),
                  _ActionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out of this session',
                    onPressed: _logout,
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ],
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
  });

  final String initials;
  final String name;
  final String email;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(email, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Chip(label: Text(role)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text(label)),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
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
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = isDestructive
        ? colorScheme.error
        : colorScheme.primary;

    return SizedBox(
      width: 260,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: foregroundColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: foregroundColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
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
