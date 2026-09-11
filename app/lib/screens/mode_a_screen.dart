import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ModeAScreen extends StatefulWidget {
  const ModeAScreen({super.key});
  @override
  State<ModeAScreen> createState() => _ModeAScreenState();
}

class _ModeAScreenState extends State<ModeAScreen> {
  bool _running = false;
  String _english = 'Ready to sign';
  String _hindi = 'संकेत करने के लिए तैयार';
  void _demoRecognition() {
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _english = 'Help';
      _hindi = 'मदद';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign to Speak')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AspectRatio(
            aspectRatio: .83,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF17233A), Color(0xFF355375)],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Colors.white54,
                        size: 72,
                      ),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      child: _StatusPill(active: _running),
                    ),
                    Positioned(
                      bottom: 18,
                      left: 18,
                      right: 18,
                      child: Text(
                        'CameraView is ready for P2’s on-device landmark stream.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.mint),
                      const SizedBox(width: 8),
                      Text(
                        'Live translation',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        _running ? '91%' : 'Waiting',
                        style: TextStyle(
                          color: _running ? AppTheme.mint : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _english,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(_hindi, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _running ? .91 : .08,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Sentence builder',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                _running
                    ? 'Help'
                    : 'Recognized signs will appear here as a sentence.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _demoRecognition,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Try recognition demo'),
          ),
        ],
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.circle : Icons.pause_circle_outline,
            size: 12,
            color: active ? const Color(0xFF76E1B3) : Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Recognizing' : 'Camera ready',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
