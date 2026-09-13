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
    _notifier ??= ref.read(signRecognitionProvider.notifier);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_notifier?.stopProcessing());
    _notifier = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_notifier?.stopProcessing());
    }
  }

  Future<void> _toggleProcessing() async {
    HapticFeedback.lightImpact();
    final notifier = _notifier ?? ref.read(signRecognitionProvider.notifier);
    if (ref.read(signRecognitionProvider).isProcessing) {
      await notifier?.stopProcessing();
    } else {
      await notifier?.startProcessing();
    }
  }

  Future<void> _toggleCamera() async {
    HapticFeedback.mediumImpact();
    final notifier = _notifier ?? ref.read(signRecognitionProvider.notifier);
    await notifier?.switchCamera();
  }

  void _speakTTS() {
    HapticFeedback.lightImpact();
    final notifier = _notifier ?? ref.read(signRecognitionProvider.notifier);
    notifier?.speakCurrentOrSentence();

    final state = ref.read(signRecognitionProvider);
    final text = state.sentenceEn.isEmpty
        ? state.currentResult?.labelEn ?? ''
        : state.sentenceEn;
    if (text.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔊 Speaking: "$text"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signRecognitionProvider);
    final notifier = ref.watch(signRecognitionProvider.notifier);
    final running = state.isProcessing;
    final cameraReady = notifier.cameraReady;
    final isFront = state.usingFrontCamera;

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
          // Camera flip button — only shown while camera is active
          if (running)
            IconButton(
              tooltip: isFront ? 'Switch to back camera' : 'Switch to front camera',
              icon: Icon(
                isFront ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
              ),
              onPressed: _toggleCamera,
            ),
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
              height: 280,
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
                        Positioned.fill(
                          child: _CameraPreviewWithSkeleton(
                            controller:
                                notifier.cameraController! as CameraController,
                            landmarks: state.visualLandmarks,
                            isFront: isFront,
                          ),
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
                      if (running && cameraReady)
                        Positioned(
                          top: 14,
                          left: 140,
                          child: _HandStatusBadge(handsDetected: state.handsDetected),
                        ),
                      // Floating camera toggle button on preview card
                      if (cameraReady)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.60),
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: IconButton(
                              tooltip: isFront
                                  ? 'Switch to Back Camera'
                                  : 'Switch to Front Camera',
                              icon: Icon(
                                isFront
                                    ? Icons.camera_rear_rounded
                                    : Icons.camera_front_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: _toggleCamera,
                            ),
                          ),
                        ),
                      // Lens badge (front/back indicator)
                      if (cameraReady)
                        Positioned(
                          bottom: 42,
                          right: 14,
                          child: _LensBadge(isFront: isFront),
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
                // Camera flip shortcut button below camera
                if (running)
                  FilledButton.tonalIcon(
                    onPressed: _toggleCamera,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    icon: const Icon(Icons.flip_camera_android_rounded),
                    label: Text(isFront ? 'Back' : 'Front'),
                  ),
                if (running) const SizedBox(width: 8),
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

// ─── Camera Preview with Synchronized Skeleton ────────────────────────────────

/// Live camera feed and skeleton overlay unified in the exact same coordinate space.
///
/// Front camera preview is horizontally flipped along with the skeleton painter so
/// the signer sees an intuitive mirror image where movements never reverse.
class _CameraPreviewWithSkeleton extends StatelessWidget {
  const _CameraPreviewWithSkeleton({
    required this.controller,
    required this.landmarks,
    required this.isFront,
  });

  final CameraController controller;
  final List<Offset> landmarks;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(isFront ? -1.0 : 1.0, 1.0, 1.0),
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(controller),
                  if (landmarks.isNotEmpty)
                    CustomPaint(
                      painter: _SkeletonPainter(landmarks: landmarks),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status widgets ────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.circle : Icons.pause_circle_outline,
            size: 12,
            color: active ? Colors.greenAccent : Colors.white60,
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

class _HandStatusBadge extends StatelessWidget {
  const _HandStatusBadge({required this.handsDetected});
  final bool handsDetected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: handsDetected ? const Color(0xE610B981) : const Color(0xE6F59E0B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: handsDetected ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (handsDetected ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                .withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            handsDetected ? Icons.front_hand_rounded : Icons.pan_tool_outlined,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            handsDetected ? 'Hands Tracked' : 'Raise Hands',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LensBadge extends StatelessWidget {
  const _LensBadge({required this.isFront});
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFront ? Icons.camera_front : Icons.camera_rear,
            size: 13,
            color: Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            isFront ? 'Front' : 'Back',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 37-Point Articulated Skeleton Painter ───────────────────────────────────

/// Visual landmarks:
/// Right hand (0-10):
///   0:rWrist, 1:rThumbMcp, 2:rThumbTip, 3:rIndexMcp, 4:rIndexTip,
///   5:rMiddleMcp, 6:rMiddleTip, 7:rRingMcp, 8:rRingTip, 9:rPinkyMcp, 10:rPinkyTip
/// Left hand (11-21):
///   11:lWrist, 12:lThumbMcp, 13:lThumbTip, 14:lIndexMcp, 15:lIndexTip,
///   16:lMiddleMcp, 17:lMiddleTip, 18:lRingMcp, 19:lRingTip, 20:lPinkyMcp, 21:lPinkyTip
/// Arms (22-25):
///   22:rElbow, 23:rShoulder, 24:lElbow, 25:lShoulder
/// Head & Neck (26-32):
///   26:nose, 27:lEye, 28:rEye, 29:lEar, 30:rEar, 31:headTop, 32:neck
/// Lower Body (33-36):
///   33:rHip, 34:lHip, 35:rKnee, 36:lKnee
class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({required this.landmarks});

  final List<Offset> landmarks;

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length < 37) return;

    Offset toCanvas(Offset norm) =>
        Offset(norm.dx * size.width, norm.dy * size.height);

    final pts = landmarks.map(toCanvas).toList();

    final armPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.90)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final handPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.95)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final torsoPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final facePaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    void line(int a, int b, Paint p) {
      if (a < pts.length && b < pts.length) canvas.drawLine(pts[a], pts[b], p);
    }

    // ── Body Skeleton ────────────────────────────────────────────────────────
    // Right arm
    line(23, 22, armPaint); // R Shoulder → R Elbow
    line(22, 0, armPaint);  // R Elbow    → R Wrist
    // Left arm
    line(25, 24, armPaint); // L Shoulder → L Elbow
    line(24, 11, armPaint); // L Elbow    → L Wrist

    // Torso
    line(23, 25, torsoPaint); // Shoulders bar
    line(23, 33, torsoPaint); // R Shoulder → R Hip
    line(25, 34, torsoPaint); // L Shoulder → L Hip
    line(33, 34, torsoPaint); // Hips bar
    line(33, 35, torsoPaint); // R Hip → R Knee
    line(34, 36, torsoPaint); // L Hip → L Knee

    // ── Head & Neck ──────────────────────────────────────────────────────────
    line(32, 26, facePaint); // Neck → Nose
    line(26, 31, facePaint); // Nose → Head Top (cranium)
    line(26, 27, facePaint); // Nose → L Eye
    line(26, 28, facePaint); // Nose → R Eye
    line(27, 28, facePaint); // L Eye ↔ R Eye
    line(27, 29, facePaint); // L Eye → L Ear
    line(28, 30, facePaint); // R Eye → R Ear
    line(29, 32, facePaint); // L Ear → Neck
    line(30, 32, facePaint); // R Ear → Neck

    // Head contour circle
    final headRadius = ((pts[26] - pts[31]).distance * 0.90).clamp(16.0, 52.0);
    final headCenter = Offset(pts[26].dx, (pts[26].dy + pts[31].dy) / 2.0);
    canvas.drawCircle(
      headCenter,
      headRadius,
      Paint()
        ..color = const Color(0xFFFBBF24).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // ── Right Hand (5 articulated fingers) ───────────────────────────────────
    // Palm contour
    line(0, 1, handPaint);  // Wrist → Thumb MCP
    line(1, 3, handPaint);  // Thumb MCP → Index MCP
    line(3, 5, handPaint);  // Index MCP → Middle MCP
    line(5, 7, handPaint);  // Middle MCP → Ring MCP
    line(7, 9, handPaint);  // Ring MCP → Pinky MCP
    line(9, 0, handPaint);  // Pinky MCP → Wrist
    // 5 Fingertips
    line(1, 2, handPaint);  // Thumb
    line(3, 4, handPaint);  // Index
    line(5, 6, handPaint);  // Middle
    line(7, 8, handPaint);  // Ring
    line(9, 10, handPaint); // Pinky

    // ── Left Hand (5 articulated fingers) ────────────────────────────────────
    // Palm contour
    line(11, 12, handPaint); // Wrist → Thumb MCP
    line(12, 14, handPaint); // Thumb MCP → Index MCP
    line(14, 16, handPaint); // Index MCP → Middle MCP
    line(16, 18, handPaint); // Middle MCP → Ring MCP
    line(18, 20, handPaint); // Ring MCP → Pinky MCP
    line(20, 11, handPaint); // Pinky MCP → Wrist
    // 5 Fingertips
    line(12, 13, handPaint); // Thumb
    line(14, 15, handPaint); // Index
    line(16, 17, handPaint); // Middle
    line(18, 19, handPaint); // Ring
    line(20, 21, handPaint); // Pinky

    // ── Glowing Nodes & Joints ───────────────────────────────────────────────
    for (int i = 0; i < pts.length; i++) {
      final pt = pts[i];
      if (i == 0 || i == 11) {
        // Wrists: large emerald glow
        canvas.drawCircle(pt, 8.0, Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.40));
        canvas.drawCircle(pt, 5.0, Paint()..color = const Color(0xFF10B981));
        canvas.drawCircle(pt, 2.5, Paint()..color = Colors.white);
      } else if (i == 2 || i == 4 || i == 6 || i == 8 || i == 10 ||
                 i == 13 || i == 15 || i == 17 || i == 19 || i == 21) {
        // 10 Fingertips: cyan/emerald glowing beacons
        canvas.drawCircle(pt, 5.0, Paint()..color = const Color(0xFF34D399).withValues(alpha: 0.45));
        canvas.drawCircle(pt, 3.5, Paint()..color = const Color(0xFF34D399));
        canvas.drawCircle(pt, 1.8, Paint()..color = Colors.white);
      } else if (i == 1 || i == 3 || i == 5 || i == 7 || i == 9 ||
                 i == 12 || i == 14 || i == 16 || i == 18 || i == 20) {
        // 10 Knuckles (MCP joints): cyan dots
        canvas.drawCircle(pt, 3.5, Paint()..color = const Color(0xFF06B6D4));
        canvas.drawCircle(pt, 1.5, Paint()..color = Colors.white);
      } else if (i >= 22 && i <= 25) {
        // Arm joints (elbows & shoulders): electric blue
        canvas.drawCircle(pt, 4.5, Paint()..color = const Color(0xFF38BDF8));
        canvas.drawCircle(pt, 2.0, Paint()..color = Colors.white);
      } else if (i >= 26 && i <= 32) {
        // Head landmarks & neck: glowing amber
        canvas.drawCircle(pt, 4.0, Paint()..color = const Color(0xFFFBBF24));
        canvas.drawCircle(pt, 2.0, Paint()..color = Colors.white);
      } else if (i >= 33) {
        // Lower body: subtle white
        canvas.drawCircle(pt, 3.5, Paint()..color = Colors.white.withValues(alpha: 0.50));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter old) => true;
}

