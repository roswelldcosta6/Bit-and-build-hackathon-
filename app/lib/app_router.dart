import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/mode_a_screen.dart';
import 'screens/mode_b_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(path: '/mode-a', builder: (_, _) => const ModeAScreen()),
        GoRoute(path: '/mode-b', builder: (_, _) => const ModeBScreen()),
        GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _indexFor(GoRouterState.of(context).uri.path),
      onDestinationSelected: (index) =>
          context.go(const ['/', '/history', '/settings'][index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Settings',
        ),
      ],
    ),
  );

  int _indexFor(String path) => path == '/history'
      ? 1
      : path == '/settings'
      ? 2
      : 0;
}
