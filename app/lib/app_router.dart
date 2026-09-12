import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/mode_a_screen.dart';
import 'screens/mode_b_screen.dart';
import 'screens/settings_screen.dart';
import 'state/settings_controller.dart';

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

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFor(path);
    final settings = ref.watch(settingsProvider);
    final isDark = settings.darkMode;

    final barBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderCol = isDark ? const Color(0xFF1F1F1F) : const Color(0xFFE5E7EB);
    final activeCol = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveCol = isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBg,
          border: Border(
            top: BorderSide(color: borderCol, width: 0.8),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Home / Logo Icon
            IconButton(
              icon: Icon(
                Icons.home_rounded,
                color: selectedIndex == 0 ? activeCol : inactiveCol,
                size: 26,
              ),
              tooltip: 'Home',
              onPressed: () => context.go('/home'),
            ),

            // History Icon
            IconButton(
              icon: Icon(
                Icons.history_rounded,
                color: selectedIndex == 1 ? activeCol : inactiveCol,
                size: 26,
              ),
              tooltip: 'History',
              onPressed: () => context.go('/history'),
            ),

            // Settings Icon
            IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: selectedIndex == 2 ? activeCol : inactiveCol,
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
