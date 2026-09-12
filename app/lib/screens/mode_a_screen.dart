import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/sign_recognition_provider.dart';
import '../state/sign_recognition_provider.dart' as rec;

class ModeAScreen extends ConsumerStatefulWidget {
  const ModeAScreen({super.key});
  @override
  ConsumerState<ModeAScreen> createState() => _ModeAScreenState();
}

class _ModeAScreenState extends ConsumerState<ModeAScreen>
    with WidgetsBindingObserver {
  rec.SignRecognitionNotifierBase? _notifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture the notifier while ref is still usable, so dispose() can stop
    // the camera without touching ref.
    _notifier ??= ref.read(signRecognitionProvider.notifier);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop the camera stream when leaving the screen. The loaded TFLite
    // interpreter stays cached in the provider for a fast restart.
    unawaited(_notifier?.stopProcessing());
    _notifier = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Android camera surfaces must be released while backgrounded.
      unawaited(_notifier?.stopProcessing());
    }
  }

  Future<void> _toggleProcessing() async {
    HapticFeedback.lightImpact();
    final notifier = _notifier ?? ref.read(signRecognitionProvider.notifier);
    if (notifier == null) return;
    if (ref.read(signRecognitionProvider).isProcessing) {
      await notifier.stopProcessing();
    } else {
      await notifier.startProcessing();
    }
  }

  void _speakTTS() {
    HapticFeedback.lightImpact();
    final state = ref.read(signRecognitionProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔊 Speaking: "${state.sentenceEn.isEmpty
            ? state.currentResult?.labelEn ?? ''
            : state.sentenceEn}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signRecognitionProvider);
    final notifier = ref.watch(signRecognitionProvider.notifier);
    final running = state.isProcessing;
    final cameraReady = notifier.cameraReady;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: const Text('Sign to Text'),
        actions: [
          if (state.sentence.isNotEmpty)
            IconButton(
              tooltip: 'Clear sentence',
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.clearSentence(),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          children: [
            SizedBox(
              height: 220,
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
                      if (cameraReady)
                        _CameraPreview(
                          controller:
                              notifier.cameraController! as CameraController,
                        )
                      else
                        Center(
                          child: running
                              ? const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        color: Colors.white70,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Loading camera & ISL model…',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                )
                              : const Icon(
                                  Icons.videocam_outlined,
                                  color: Colors.white54,
                                  size: 64,
                                ),
                        ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _StatusPill(active: running),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        right: 14,
                        child: Text(
                          state.errorMessage != null
                              ? state.errorMessage!
                              : running
                              ? 'Signing detected — hold the pose for a moment.'
                              : 'Press Start to open the camera and recognise ISL signs.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: state.errorMessage != null
                                    ? Colors.amberAccent
                                    : Colors.white70,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Start / stop recognition — kept directly under the camera so
            // the control is always above the fold, on every screen size.
            // Both buttons override the theme's infinite-min-width button
            // style, which cannot lay out inside a Row.
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _toggleProcessing,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor:
                          running ? Theme.of(context).colorScheme.error : null,
                    ),
                    icon: Icon(running ? Icons.stop : Icons.play_arrow),
                    label: Text(running ? 'Stop' : 'Start signing'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: state.sentenceEn.isNotEmpty ? _speakTTS : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.record_voice_over_outlined),
                  label: const Text('Speak'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bilingual recognition card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live translation',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Flexible(
                          flex: 4,
                          child: Text(
                            state.currentResult != null
                                ? '${(state.confidence * 100).toInt()}% match'
                                : running
                                ? 'Watching…'
                                : 'Waiting',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: state.currentResult != null
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight: FontWeight.w700,
                            ),
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
                                state.currentResult?.labelEn ??
                                    (state.sentenceEn.isEmpty
                                        ? 'Ready to sign'
                                        : state.sentenceEn),
                                style: Theme.of(context).textTheme.headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.currentResult?.labelHi ??
                                    (state.sentenceHi.isEmpty
                                        ? 'संकेत करने के लिए तैयार'
                                        : state.sentenceHi),
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (state.currentResult != null)
                          IconButton.filledTonal(
                            tooltip: 'Speak Aloud (TTS)',
                            onPressed: _speakTTS,
                            icon: const Icon(Icons.volume_up_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: state.currentResult != null ? state.confidence : 0,
                      minHeight: 6,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sentence builder accumulator
            Text(
              'Sentence builder',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: state.sentence.isEmpty
                    ? Text(
                        'Recognized signs will accumulate here into a sentence.',
                        style: TextStyle(color: Colors.grey.shade600),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: state.sentence
                            .map(
                              (r) => Chip(
                                label: Text(
                                  r.labelEn,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Live camera feed, mirrored for the front camera (natural signing view).
class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final mirrored =
        controller.description.lensDirection == CameraLensDirection.front;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.diagonal3Values(mirrored ? -1.0 : 1.0, 1.0, 1.0),
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.zero,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.circle : Icons.pause_circle_outline,
            size: 12,
            color: active ? Colors.white : Colors.white60,
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
