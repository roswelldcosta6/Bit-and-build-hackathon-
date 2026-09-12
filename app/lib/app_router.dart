import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/mode_a_screen.dart';
import 'screens/mode_b_screen.dart';
import 'screens/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/landing',
  routes: [
    GoRoute(path: '/landing', builder: (_, _) => const LandingScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
    GoRoute(path: '/mode-a', builder: (_, _) => const ModeAScreen()),
    GoRoute(path: '/mode-b', builder: (_, _) => const ModeBScreen()),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFor(path);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          border: Border(
            top: BorderSide(color: Color(0xFF1F1F1F), width: 0.8),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home / Logo Icon
            IconButton(
              icon: Icon(
                Icons.home_rounded,
                color: selectedIndex == 0 ? Colors.white : Colors.white38,
                size: 26,
              ),
              tooltip: 'Home',
              onPressed: () => context.go('/home'),
            ),

            // History Icon (matching screenshot)
            IconButton(
              icon: Icon(
                Icons.history_rounded,
                color: selectedIndex == 1 ? Colors.white : Colors.white38,
                size: 26,
              ),
              tooltip: 'History',
              onPressed: () => context.go('/history'),
            ),

            // Settings Icon (matching screenshot)
            IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: selectedIndex == 2 ? Colors.white : Colors.white38,
                size: 25,
              ),
              tooltip: 'Settings',
              onPressed: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }

  int _indexFor(String path) {
    if (path == '/history') return 1;
    if (path == '/settings') return 2;
    return 0;
  }
}
