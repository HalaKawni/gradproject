import 'package:client/app/navigation/app_route_data.dart';
import 'package:client/app/navigation/app_routes.dart';
import 'package:client/core/models/auth_session.dart';
import 'package:flutter/material.dart';

enum _GameCreatorOption { frontView, topView }

class UserHomePage extends StatelessWidget {
  final AuthSession session;

  const UserHomePage({super.key, required this.session});

  void _logout(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  void _openFrontViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.builder,
      arguments: BuilderRouteData(session: session),
    );
  }

  void _openTopViewBuilder(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.topViewBuilder,
      arguments: TopViewBuilderRouteData(session: session),
    );
  }

  void _openDiscover(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.discover,
      arguments: DiscoverRouteData(session: session),
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
          ],
        );
      },
    );

    if (!context.mounted || selection == null) {
      return;
    }

    switch (selection) {
      case _GameCreatorOption.frontView:
        _openFrontViewBuilder(context);
      case _GameCreatorOption.topView:
        _openTopViewBuilder(context);
    }
  }

  void _openMyGames(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.myGames,
      arguments: MyGamesRouteData(session: session),
    );
  }

  void _openMyPublishedGames(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.myPublishedGames,
      arguments: MyPublishedGamesRouteData(session: session),
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
            onPressed: () => _showCreateGameDialog(context),
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

          PopupMenuButton<String>(
            icon: const Icon(Icons.menu_open, color: Colors.black),
            
            onSelected: (value) {
              if (value == 'profile') {
                print('Profile clicked');
              } else if (value == 'settings') {
                print('Settings clicked');
              } else if (value == 'Sign Out') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'Language', child: Text('Language')),
              PopupMenuItem(value: 'Home', child: Text('Home')),
              PopupMenuItem(value: 'My Account', child: Text('My Account')),
              PopupMenuItem(value: 'Contact Us', child: Text('Contact Us')),
              PopupMenuItem(value: 'Sign Out', child: Text('Sign Out'), ),
            ],
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 69, 47, 40),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openMyPublishedGames(context),
                        icon: const Icon(Icons.public_outlined),
                        label: const Text('My Published Games'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              title: const Text('Courses'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('My Games'),
              onTap: () => _openMyGames(context),
            ),
            ListTile(
              title: const Text('Discover'),
              onTap: () => _openDiscover(context),
            ),
          ],
        ),
      ),
    );
  }
}
