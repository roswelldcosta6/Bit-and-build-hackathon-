import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/settings_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.darkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtextColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF64748B);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardBorderColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back to Landing button & Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Back to Landing',
                    icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 24),
                    onPressed: () => context.go('/landing'),
                  ),
                  const SizedBox(width: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo_emblem.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        '🤟',
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SignBridge',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Card 1: Sign → Text (Changed from "Sign → Speak" as requested)
              _ModeSelectionCard(
                icon: Icons.videocam_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: isDark ? const Color(0xFF382916) : const Color(0xFFFEF3C7),
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                titleColor: textColor,
                subtitleColor: subtextColor,
                title: 'Sign → Text',
                subtitle: 'ISL gestures to\nbilingual text + speech',
                onTap: () => context.push('/mode-a'),
              ),

              const SizedBox(height: 20),

              // Card 2: Speak → Sign
              _ModeSelectionCard(
                icon: Icons.mic_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: isDark ? const Color(0xFF132B25) : const Color(0xFFD1FAE5),
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                titleColor: textColor,
                subtitleColor: subtextColor,
                title: 'Speak → Sign',
                subtitle: 'Hindi/English speech to\nISL avatar',
                onTap: () => context.push('/mode-b'),
              ),

              const Spacer(),

              // Subdued hint
              Center(
                child: Text(
                  'Select a mode to begin translation',
                  style: TextStyle(
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelectionCard extends StatelessWidget {
  const _ModeSelectionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.cardBorderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color cardBgColor;
  final Color cardBorderColor;
  final Color titleColor;
  final Color subtitleColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular icon container
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing chevron
              Icon(
                Icons.chevron_right_rounded,
                color: subtitleColor,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
