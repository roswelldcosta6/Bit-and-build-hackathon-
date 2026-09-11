import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/home_screen.dart';
import 'screens/mode_a_screen.dart';
import 'screens/mode_b_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mode-a',
        name: 'modeA',
        builder: (context, state) => const ModeAScreen(),
      ),
      GoRoute(
        path: '/mode-b',
        name: 'modeB',
        builder: (context, state) => const ModeBScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
