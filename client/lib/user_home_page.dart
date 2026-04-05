import 'package:flutter/material.dart';

import 'features/builder/pages/builder_page.dart';
import 'features/builder/pages/my_games_page.dart';
import 'login_page.dart';
import 'models/auth_session.dart';

class UserHomePage extends StatelessWidget {
  final AuthSession session;

  const UserHomePage({
    super.key,
    required this.session,
  });

  void _logout(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  void _openBuilder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BuilderPage(session: session),
      ),
    );
  }

  void _openMyGames(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MyGamesPage(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name),
        actions: [
          TextButton(
            onPressed: () => _openBuilder(context),
            child: const Text(
              'Create New Game',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => _openMyGames(context),
            child: const Text(
              'My Games',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Welcome, ${user.name}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Role: ${user.role}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${user.email}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
