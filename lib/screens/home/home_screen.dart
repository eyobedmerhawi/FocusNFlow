
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to log out. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FocusNFlow'),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'You are logged in!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                user?.displayName ??
                    user?.email ??
                    'Authenticated user',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
