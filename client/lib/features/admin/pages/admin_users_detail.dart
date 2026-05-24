import 'package:client/core/localization/app_language.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:client/core/services/api_service.dart';
import 'package:client/features/admin/models/admin_user.dart';
import 'package:flutter/material.dart';

class AdminUserDetailsPage extends StatefulWidget {
  const AdminUserDetailsPage({super.key, required this.session});

  final AuthSession session;

  @override
  State<AdminUserDetailsPage> createState() => _AdminUserDetailsPageState();
}

class _AdminUserDetailsPageState extends State<AdminUserDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminUser> _users = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int? page}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final nextPage = page ?? _page;
    final result = await ApiService.getAdminUsers(
      authToken: widget.session.token,
      search: _searchController.text,
      page: nextPage,
      limit: 20,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      final data = result['data'];
      final dataMap = data is Map ? Map<String, dynamic>.from(data) : {};
      final users = dataMap['users'] is List ? dataMap['users'] as List : [];

      setState(() {
        _users = users
            .whereType<Map>()
            .map((item) => AdminUser.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        _page = _readInt(dataMap['page'], fallback: nextPage);
        _totalPages = _readInt(dataMap['totalPages'], fallback: 1);
        _total = _readInt(dataMap['total']);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message']?.toString() ?? 'Failed to load users';
        _isLoading = false;
      });
    }
  }

  int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _showCreateAdminDialog() async {
    final language = AppLanguage.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('createAdminUser')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: language.t('name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: language.t('email'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: language.t('password'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  return;
                }

                Navigator.pop(context, {
                  'name': name,
                  'email': email,
                  'password': password,
                });
              },
              child: Text(language.t('create')),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    if (payload == null) {
      return;
    }

    final result = await ApiService.createAdminUser(
      authToken: widget.session.token,
      userJson: payload,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadUsers(page: 1);
      _showMessage('Admin user created successfully');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to create admin');
    }
  }

  Future<void> _showPromoteUserDialog() async {
    final language = AppLanguage.of(context);
    final emailController = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('promoteUserToAdmin')),
          content: SizedBox(
            width: 420,
            child: TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: language.t('email'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final value = emailController.text.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(context, value);
              },
              child: Text(language.t('promote')),
            ),
          ],
        );
      },
    );

    emailController.dispose();

    if (email == null) {
      return;
    }

    final result = await ApiService.promoteUserToAdmin(
      authToken: widget.session.token,
      email: email,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadUsers(page: 1);
      _showMessage('User promoted to admin successfully');
    } else {
      _showMessage(
        result['message']?.toString() ?? 'Failed to promote user to admin',
      );
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final language = AppLanguage.of(context);
    if (user.role == 'admin') {
      _showMessage('Admin accounts cannot be deleted.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(language.t('delete')),
          content: Text('Are you sure you want to delete "${user.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(language.t('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.deleteAdminUser(
      authToken: widget.session.token,
      userId: user.id,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadUsers();
      _showMessage('"${user.name}" deleted');
    } else {
      _showMessage(result['message']?.toString() ?? 'Failed to delete user');
    }
  }

  Future<void> _toggleUserSuspension(AdminUser user) async {
    final language = AppLanguage.of(context);
    if (user.role == 'admin') {
      _showMessage('Admin accounts cannot be suspended.');
      return;
    }

    final shouldSuspend = !user.isSuspended;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            shouldSuspend ? language.t('suspend') : language.t('restore'),
          ),
          content: Text(
            shouldSuspend
                ? 'Suspend "${user.name}"? They will not be able to sign in.'
                : 'Restore "${user.name}" so they can sign in again?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(language.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                shouldSuspend ? language.t('suspend') : language.t('restore'),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final result = await ApiService.updateAdminUserSuspension(
      authToken: widget.session.token,
      userId: user.id,
      isSuspended: shouldSuspend,
    );

    if (!mounted) {
      return;
    }

    if (result['success'] == true) {
      await _loadUsers();
      _showMessage(
        shouldSuspend ? '"${user.name}" suspended' : '"${user.name}" restored',
      );
    } else {
      _showMessage(
        result['message']?.toString() ??
            (shouldSuspend
                ? 'Failed to suspend user'
                : 'Failed to restore user'),
      );
    }
  }

  String _roleLabel(String role) {
    final language = AppLanguage.of(context);
    if (role.isEmpty) {
      return language.t('unknown');
    }

    switch (role) {
      case 'admin':
        return language.t('adminRole');
      case 'parent':
        return language.t('parentRole');
      case 'child':
        return language.isArabic ? 'طفل' : 'Child';
      default:
        return role[0].toUpperCase() + role.substring(1);
    }
  }

  String _joinedLabel(DateTime date) {
    return date.toLocal().toIso8601String().split('T').first;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _loadUsers(),
              icon: const Icon(Icons.refresh),
              label: Text(language.t('retry')),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              language.t('users'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(width: 12),
            Text(language.t('totalCount', params: {'count': '$_total'})),
            const Spacer(),
            SizedBox(
              width: 280,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadUsers(page: 1),
                decoration: InputDecoration(
                  hintText: language.t('searchUsers'),
                  suffixIcon: IconButton(
                    tooltip: language.t('search'),
                    onPressed: () => _loadUsers(page: 1),
                    icon: const Icon(Icons.search),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: language.t('refreshUsers'),
              onPressed: () => _loadUsers(),
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _showPromoteUserDialog,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: Text(language.t('promoteToAdmin')),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showCreateAdminDialog,
              icon: const Icon(Icons.person_add_alt),
              label: Text(language.t('createAdmin')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _users.isEmpty
              ? Center(child: Text(language.t('noUsersFound')))
              : RefreshIndicator(
                  onRefresh: () => _loadUsers(),
                  child: ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isCurrentUser = user.id == widget.session.user.id;
                      final isAdmin = user.role == 'admin';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(
                            user.name.isEmpty
                                ? language.t('unnamedUser')
                                : user.name,
                          ),
                          subtitle: Text(
                            '${user.email} - ${_roleLabel(user.role)} - ${language.t('joined')} ${_joinedLabel(user.joinedAt)}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (isCurrentUser)
                                Chip(label: Text(language.t('currentAdmin'))),
                              if (user.isSuspended)
                                Chip(
                                  label: Text(language.t('suspended')),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.errorContainer,
                                ),
                              OutlinedButton.icon(
                                onPressed: isAdmin
                                    ? null
                                    : () => _toggleUserSuspension(user),
                                icon: Icon(
                                  user.isSuspended
                                      ? Icons.lock_open_outlined
                                      : Icons.block,
                                ),
                                label: Text(
                                  user.isSuspended
                                      ? language.t('restore')
                                      : language.t('suspend'),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: isAdmin
                                    ? null
                                    : () => _deleteUser(user),
                                icon: const Icon(Icons.delete_outline),
                                label: Text(language.t('delete')),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _page <= 1
                    ? null
                    : () => _loadUsers(page: _page - 1),
                icon: const Icon(Icons.chevron_left),
                label: Text(language.t('previous')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  language.t(
                    'pageOf',
                    params: {'page': '$_page', 'total': '$_totalPages'},
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _page >= _totalPages
                    ? null
                    : () => _loadUsers(page: _page + 1),
                icon: const Icon(Icons.chevron_right),
                label: Text(language.t('next')),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
