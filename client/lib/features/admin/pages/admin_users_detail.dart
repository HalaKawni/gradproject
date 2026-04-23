import 'package:client/core/models/auth_session.dart';
import 'package:client/features/admin/widgets/detail_row.dart';
import 'package:flutter/material.dart';

class AdminUserDetailsPage extends StatelessWidget {
  const AdminUserDetailsPage({
    super.key,
    required this.session,
  });

  final AuthSession session;

  String _buildRoleLabel(String role) {
    if (role == 'admin') {
      return 'Admin';
    }
    if (role.isEmpty) {
      return 'Unknown';
    }
    return role[0].toUpperCase() + role.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty ? user.name : 'Admin User',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email.isNotEmpty
                                  ? user.email
                                  : 'No email available',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DetailRow(
                    label: 'User ID',
                    value: user.id.isNotEmpty ? user.id : 'Unavailable',
                  ),
                  DetailRow(
                    label: 'Role',
                    value: _buildRoleLabel(user.role),
                  ),
                  DetailRow(
                    label: 'Session Status',
                    value: session.isValid ? 'Active' : 'Invalid',
                  ),
                  DetailRow(
                    label: 'Token',
                    value: session.token.isNotEmpty ? 'Available' : 'Missing',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit User'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          session.isValid ? 'Session Active' : 'Session Invalid',
                        ),
                      ),
                    ],
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
