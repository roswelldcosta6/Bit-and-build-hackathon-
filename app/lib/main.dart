import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'state/settings_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SignBridgeApp()));
}

class SignBridgeApp extends ConsumerWidget {
  const SignBridgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'SignBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.fontScale),
      darkTheme: AppTheme.dark(settings.fontScale),
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
