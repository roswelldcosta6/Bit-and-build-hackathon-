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
  double _confidence = 0.08;
  final List<String> _sentence = [];

  final List<Map<String, String>> _demoSigns = [
    {'en': 'Help', 'hi': 'मदद'},
    {'en': 'Doctor', 'hi': 'डॉक्टर'},
    {'en': 'Water', 'hi': 'पानी'},
    {'en': 'Hospital', 'hi': 'अस्पताल'},
    {'en': 'Please', 'hi': 'कृपया'},
  ];
  int _demoIndex = 0;

  void _triggerSign(String en, String hi) {
    HapticFeedback.mediumImpact();
    setState(() {
      _running = true;
      _english = en;
      _hindi = hi;
      _confidence = 0.93;
      if (!_sentence.contains(en)) {
        _sentence.add(en);
      }
    });
  }

  void _nextDemo() {
    final sign = _demoSigns[_demoIndex % _demoSigns.length];
    _demoIndex++;
    _triggerSign(sign['en']!, sign['hi']!);
  }

  void _speakTTS() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 Speaking: "$_english / $_hindi"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearSentence() {
    setState(() {
      _sentence.clear();
      _english = 'Ready to sign';
      _hindi = 'संकेत करने के लिए तैयार';
      _running = false;
      _confidence = 0.08;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sign to Speak'),
      actions: [
        if (_sentence.isNotEmpty)
          IconButton(
            tooltip: 'Clear sentence',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clearSentence,
          ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                        size: 64,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _StatusPill(active: _running),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      right: 14,
                      child: Text(
                        'Camera stream ready for on-device MediaPipe landmark detector.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Bilingual Recognition Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.mint, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Live translation',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      Text(
                        _running ? '${(_confidence * 100).toInt()}% match' : 'Waiting',
                        style: TextStyle(
                          color: _running ? AppTheme.mint : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _english,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _hindi,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      if (_running)
                        IconButton.filledTonal(
                          tooltip: 'Speak Aloud (TTS)',
                          onPressed: _speakTTS,
                          icon: const Icon(Icons.volume_up_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: _confidence,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sentence Builder Accumulator
          Text(
            'Sentence builder',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _sentence.isEmpty
                  ? Text(
                      'Recognized signs will accumulate here into a sentence.',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _sentence
                          .map(
                            (w) => Chip(
                              label: Text(
                                w,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Simulation Buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _nextDemo,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Simulate Next Sign'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _running ? _speakTTS : null,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text('Speak'),
              ),
            ],
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
      color: Colors.black54,
      borderRadius: BorderRadius.circular(40),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            active ? 'Live Inference' : 'Camera Ready',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
