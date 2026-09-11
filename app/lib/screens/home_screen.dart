import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.sign_language_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SignBridge',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Text('Indian Sign Language, two ways'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Text(
            'How would you like to communicate?',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text('Choose a translation mode to get started.'),
          const SizedBox(height: 26),
          _ModeCard(
            color: AppTheme.mint,
            icon: Icons.videocam_outlined,
            title: 'Sign to Speak',
            subtitle: 'Use the camera to translate ISL into English and Hindi.',
            cta: 'Open camera',
            onTap: () => context.push('/mode-a'),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            color: Theme.of(context).colorScheme.primary,
            icon: Icons.record_voice_over_outlined,
            title: 'Speak to Sign',
            subtitle:
                'Speak or type in Hindi or English and watch the avatar sign.',
            cta: 'Start speaking',
            onTap: () => context.push('/mode-b'),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Designed for real conversations',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Text(
                          'Mode A can be connected to the on-device recognizer when the model is added.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 31),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  cta,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: color),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
