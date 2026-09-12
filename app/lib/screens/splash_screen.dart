import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _minDelayTimer;
  bool _minDelayDone = false;
  bool _routed = false;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void initState() {
    super.initState();
    _minDelayTimer = Timer(const Duration(milliseconds: 1100), () {
      _minDelayDone = true;
      _routeWhenReady();
    });
    // Validate any restored session against the backend, then route.
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    // Validates any restored token; clears the gate when invalid or absent.
    await ref.read(authProvider.notifier).checkSession();
    _routeWhenReady();
  }

  void _routeWhenReady() {
    if (!_minDelayDone || _routed || !mounted) return;
    _routed = true;
    // Signed in -> straight to the app; otherwise show the public landing
    // page (Get Started leads into the login gate).
    context.go(authGate.value ? '/' : '/landing');
  }

  @override
  void dispose() {
    _minDelayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.sign_language,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'SignBridge',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Communication without barriers',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
