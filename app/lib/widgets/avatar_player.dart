import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

/// Controller to drive gesture playback on the 3D Avatar.
class AvatarController extends ChangeNotifier {
  AvatarController({List<String>? initialTokens}) {
    if (initialTokens != null && initialTokens.isNotEmpty) {
      _queue = List<String>.from(initialTokens);
    }
  }

  List<String> _queue = ['HELLO'];
  int _currentIndex = 0;
  bool _isPlaying = true;
  double _speed = 1.0;
  String _currentGloss = 'HELLO';
  String _currentSubtitle = 'Hello';
  String _currentHindiSubtitle = 'नमस्ते';

  List<String> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  double get speed => _speed;
  String get currentGloss => _currentGloss;
  String get currentSubtitle => _currentSubtitle;
  String get currentHindiSubtitle => _currentHindiSubtitle;

  void playSequence(List<String> tokens) {
    if (tokens.isEmpty) return;
    _queue = List<String>.from(tokens);
    _currentIndex = 0;
    _isPlaying = true;
    _currentGloss = _queue[0];
    _updateSubtitles(_currentGloss);
    notifyListeners();
  }

  void playToken(String token) {
    playSequence([token]);
  }

  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _isPlaying = true;
    notifyListeners();
  }

  void replay() {
    _currentIndex = 0;
    _isPlaying = true;
    if (_queue.isNotEmpty) {
      _currentGloss = _queue[0];
      _updateSubtitles(_currentGloss);
    }
    notifyListeners();
  }

  void setSpeed(double newSpeed) {
    _speed = newSpeed;
    notifyListeners();
  }

  void advanceNext() {
    if (_currentIndex + 1 < _queue.length) {
      _currentIndex++;
      _currentGloss = _queue[_currentIndex];
      _updateSubtitles(_currentGloss);
      notifyListeners();
    } else {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void _updateSubtitles(String gloss) {
    final meta = _signDictionary[gloss.toUpperCase()] ?? _signDictionary['HELLO']!;
    _currentSubtitle = meta.en;
    _currentHindiSubtitle = meta.hi;
  }
}

/// Metadata for a sign language gesture.
class SignMetadata {
  const SignMetadata({
    required this.gloss,
    required this.en,
    required this.hi,
    required this.durationMs,
    required this.rightWrist,
    required this.rightElbow,
    required this.leftWrist,
    required this.leftElbow,
    this.headTilt = const [0, 0, 0],
    this.rightHandOpen = true,
    this.leftHandOpen = false,
  });

  final String gloss;
  final String en;
  final String hi;
  final int durationMs;
  final List<double> rightWrist;
  final List<double> rightElbow;
  final List<double> leftWrist;
  final List<double> leftElbow;
  final List<double> headTilt;
  final bool rightHandOpen;
  final bool leftHandOpen;
}

/// Master dictionary of core ISL signs with 3D joint coordinates.
final Map<String, SignMetadata> _signDictionary = {
  'HELLO': const SignMetadata(
    gloss: 'HELLO',
    en: 'Hello',
    hi: 'नमस्ते',
    durationMs: 1600,
    // Right arm raised at shoulder level, open palm facing camera in greeting wave
    rightWrist: [0.30, 1.62, 0.22],
    rightElbow: [0.38, 1.34, 0.12],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.03, 0.02, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'HELP': const SignMetadata(
    gloss: 'HELP',
    en: 'Help',
    hi: 'मदद',
    durationMs: 1400,
    // Left palm flat facing up in front of chest; Right hand rests on top and lifts
    rightWrist: [0.00, 1.32, 0.35],
    rightElbow: [0.18, 1.20, 0.20],
    leftWrist: [-0.05, 1.25, 0.35],
    leftElbow: [-0.18, 1.20, 0.20],
    headTilt: [0.0, -0.04, 0.0],
    rightHandOpen: false,
    leftHandOpen: true,
  ),
  'DOCTOR': const SignMetadata(
    gloss: 'DOCTOR',
    en: 'Doctor',
    hi: 'डॉक्टर',
    durationMs: 1400,
    // Right fingers tap left wrist
    rightWrist: [-0.08, 1.24, 0.34],
    rightElbow: [0.15, 1.18, 0.24],
    leftWrist: [-0.10, 1.20, 0.32],
    leftElbow: [-0.20, 1.15, 0.22],
    headTilt: [0.04, -0.02, 0.0],
    rightHandOpen: true,
    leftHandOpen: true,
  ),
  'HOSPITAL': const SignMetadata(
    gloss: 'HOSPITAL',
    en: 'Hospital',
    hi: 'अस्पताल',
    durationMs: 1500,
    // Draw cross on shoulder
    rightWrist: [-0.14, 1.44, 0.12],
    rightElbow: [0.12, 1.32, 0.18],
    leftWrist: [-0.22, 0.90, 0.05],
    leftElbow: [-0.26, 1.16, -0.02],
    headTilt: [-0.02, 0.03, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'WATER': const SignMetadata(
    gloss: 'WATER',
    en: 'Water',
    hi: 'पानी',
    durationMs: 1300,
    // Hand near chin / drinking motion
    rightWrist: [0.04, 1.56, 0.24],
    rightElbow: [0.16, 1.32, 0.16],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.0, 0.04, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'WHERE': const SignMetadata(
    gloss: 'WHERE',
    en: 'Where',
    hi: 'कहाँ',
    durationMs: 1400,
    // Both hands open, palms up, questioning sway
    rightWrist: [0.28, 1.25, 0.34],
    rightElbow: [0.24, 1.20, 0.18],
    leftWrist: [-0.28, 1.25, 0.34],
    leftElbow: [-0.24, 1.20, 0.18],
    headTilt: [0.0, -0.02, 0.0],
    rightHandOpen: true,
    leftHandOpen: true,
  ),
  'PAIN': const SignMetadata(
    gloss: 'PAIN',
    en: 'Pain',
    hi: 'दर्द',
    durationMs: 1300,
    // Two index fingers twisting towards each other
    rightWrist: [0.08, 1.35, 0.30],
    rightElbow: [0.20, 1.22, 0.18],
    leftWrist: [-0.08, 1.35, 0.30],
    leftElbow: [-0.20, 1.22, 0.18],
    headTilt: [0.0, -0.06, 0.0],
    rightHandOpen: false,
    leftHandOpen: false,
  ),
  'MEDICINE': const SignMetadata(
    gloss: 'MEDICINE',
    en: 'Medicine',
    hi: 'दवा',
    durationMs: 1300,
    // Grinding pill on palm
    rightWrist: [-0.02, 1.28, 0.32],
    rightElbow: [0.16, 1.18, 0.20],
    leftWrist: [-0.06, 1.22, 0.32],
    leftElbow: [-0.18, 1.16, 0.18],
    headTilt: [0.02, -0.02, 0.0],
    rightHandOpen: false,
    leftHandOpen: true,
  ),
  'FOOD': const SignMetadata(
    gloss: 'FOOD',
    en: 'Food',
    hi: 'खाना',
    durationMs: 1300,
    // Hand brought to mouth repeatedly
    rightWrist: [0.02, 1.54, 0.22],
    rightElbow: [0.15, 1.30, 0.16],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.0, 0.02, 0.0],
    rightHandOpen: false,
    leftHandOpen: false,
  ),
  'THANK_YOU': const SignMetadata(
    gloss: 'THANK_YOU',
    en: 'Thank You',
    hi: 'धन्यवाद',
    durationMs: 1300,
    // Right fingertips from chin forward
    rightWrist: [0.04, 1.48, 0.36],
    rightElbow: [0.14, 1.28, 0.22],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.0, 0.05, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'PLEASE': const SignMetadata(
    gloss: 'PLEASE',
    en: 'Please',
    hi: 'कृपया',
    durationMs: 1300,
    // Circular rubbing motion over chest
    rightWrist: [0.02, 1.34, 0.20],
    rightElbow: [0.18, 1.24, 0.16],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.02, 0.03, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'YES': const SignMetadata(
    gloss: 'YES',
    en: 'Yes',
    hi: 'हाँ',
    durationMs: 1200,
    // Fist nodding like head
    rightWrist: [0.18, 1.38, 0.28],
    rightElbow: [0.22, 1.22, 0.15],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [0.0, 0.06, 0.0],
    rightHandOpen: false,
    leftHandOpen: false,
  ),
  'NO': const SignMetadata(
    gloss: 'NO',
    en: 'No',
    hi: 'नहीं',
    durationMs: 1200,
    // Index and middle finger tap thumb
    rightWrist: [0.16, 1.42, 0.26],
    rightElbow: [0.24, 1.26, 0.16],
    leftWrist: [-0.22, 0.88, 0.05],
    leftElbow: [-0.28, 1.15, -0.04],
    headTilt: [-0.05, 0.0, 0.0],
    rightHandOpen: true,
    leftHandOpen: false,
  ),
  'EMERGENCY': const SignMetadata(
    gloss: 'EMERGENCY',
    en: 'Emergency',
    hi: 'आपातकाल',
    durationMs: 1500,
    // Urgent waving both hands
    rightWrist: [0.24, 1.48, 0.30],
    rightElbow: [0.28, 1.28, 0.18],
    leftWrist: [-0.24, 1.48, 0.30],
    leftElbow: [-0.28, 1.28, 0.18],
    headTilt: [0.0, -0.04, 0.0],
    rightHandOpen: true,
    leftHandOpen: true,
  ),
};

/// 3D Sign Language Avatar Component.
///
/// Meets Visual & Functional Requirements:
/// 1. Male 3D avatar with short brown hair.
/// 2. Attire: Rust-red/terracotta crew-neck short-sleeve t-shirt, dark brown belt, navy blue jeans.
/// 3. Clean neutral white studio background with soft studio ambient lighting.
/// 4. Front-facing camera view displaying avatar from head to lower legs.
/// 5. Initial gesture: Right arm raised at shoulder level with open palm in "Hello" wave gesture.
/// 6. Synchronized clean, bold subtitle text below avatar in dark charcoal typography.
/// 7. Sequential animation across multiple gloss tokens.
class AvatarPlayer extends StatefulWidget {
  const AvatarPlayer({
    this.actions = const [],
    this.tokens,
    this.api,
    this.controller,
    super.key,
  });

  final List<AvatarAction> actions;
  final List<String>? tokens;
  final ApiService? api;
  final AvatarController? controller;

  @override
  State<AvatarPlayer> createState() => _AvatarPlayerState();
}

class _AvatarPlayerState extends State<AvatarPlayer>
    with SingleTickerProviderStateMixin {
  late final AvatarController _controller;
  bool _ownsController = false;

  late final AnimationController _anim;
  double _phase = 0.0;
  double _idleTime = 0.0;
  Timer? _ticker;

  SignMetadata _prevPose = _signDictionary['HELLO']!;
  SignMetadata _targetPose = _signDictionary['HELLO']!;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      final initial = widget.tokens ??
          (widget.actions.isNotEmpty
              ? widget.actions.map((a) => a.gloss).toList()
              : ['HELLO']);
      _controller = AvatarController(initialTokens: initial);
    }

    _controller.addListener(_onControllerUpdate);
    _targetPose = _getMetadataFor(_controller.currentGloss);
    _prevPose = _targetPose;

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _startAnimationLoop();
  }

  SignMetadata _getMetadataFor(String gloss) {
    final clean = gloss.toUpperCase().replaceAll(' ', '_');
    return _signDictionary[clean] ??
        _signDictionary['HELLO']!;
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    final newMeta = _getMetadataFor(_controller.currentGloss);
    if (newMeta.gloss != _targetPose.gloss) {
      setState(() {
        _prevPose = _targetPose;
        _targetPose = newMeta;
        _phase = 0.0;
      });
    }
  }

  void _startAnimationLoop() {
    const frameMs = 33; // ~30 FPS
    _ticker = Timer.periodic(const Duration(milliseconds: frameMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      setState(() {
        _idleTime += 0.033;

        if (_controller.isPlaying) {
          final duration = _targetPose.durationMs / _controller.speed;
          final step = (frameMs / duration);
          _phase += step;

          if (_phase >= 1.0) {
            _phase = 0.0;
            _prevPose = _targetPose;
            _controller.advanceNext();
          }
        }
      });
    });
  }

  @override
  void didUpdateWidget(AvatarPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actions != oldWidget.actions && widget.actions.isNotEmpty) {
      final tokens = widget.actions.map((a) => a.gloss).toList();
      _controller.playSequence(tokens);
    } else if (widget.tokens != oldWidget.tokens && widget.tokens != null) {
      _controller.playSequence(widget.tokens!);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _anim.dispose();
    if (_ownsController) {
      _controller.removeListener(_onControllerUpdate);
      _controller.dispose();
    } else {
      widget.controller?.removeListener(_onControllerUpdate);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Current interpolated joint coordinates
    final t = _smoothEase(_phase);
    final waveFlutter = math.sin(_idleTime * 6.0) * 0.03;
    final breathing = math.sin(_idleTime * 2.2) * 0.012;

    // Interpolate right arm
    final rw = _lerp3(_prevPose.rightWrist, _targetPose.rightWrist, t);
    final re = _lerp3(_prevPose.rightElbow, _targetPose.rightElbow, t);
    // If currently waving Hello, add subtle hand flutter
    if (_targetPose.gloss == 'HELLO') {
      rw[0] += waveFlutter;
    }

    // Interpolate left arm
    final lw = _lerp3(_prevPose.leftWrist, _targetPose.leftWrist, t);
    final le = _lerp3(_prevPose.leftElbow, _targetPose.leftElbow, t);

    // Head tilt
    final headTilt = _lerp3(_prevPose.headTilt, _targetPose.headTilt, t);
    headTilt[1] += math.sin(_idleTime * 1.5) * 0.015;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.black.withValues(alpha: .06), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 3D Avatar Viewport
          Expanded(
            child: Stack(
              children: [
                // Clean neutral studio white background
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFB),
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.2,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF1F3F5),
                      ],
                    ),
                  ),
                ),

                // 3D Humanoid Avatar Canvas
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Humanoid3DAvatarPainter(
                      rightWrist: rw,
                      rightElbow: re,
                      leftWrist: lw,
                      leftElbow: le,
                      headTilt: headTilt,
                      breathing: breathing,
                      rightHandOpen: _targetPose.rightHandOpen,
                      leftHandOpen: _targetPose.leftHandOpen,
                    ),
                  ),
                ),

                // Studio Lighting & Model Badge
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _controller.isPlaying
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFFACC15),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _controller.isPlaying ? '3D Signer' : 'Paused',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Playback & Speed Controls overlay
                Positioned(
                  top: 10,
                  right: 12,
                  child: Row(
                    children: [
                      _SpeedChip(
                        current: _controller.speed,
                        onSelect: (s) => _controller.setSpeed(s),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filledTonal(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (_controller.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.resume();
                          }
                        },
                        icon: Icon(
                          _controller.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                      IconButton.filledTonal(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _controller.replay(),
                        icon: const Icon(Icons.replay_rounded),
                      ),
                    ],
                  ),
                ),

                // Sequence Token Progress Bar (when multiple words)
                if (_controller.queue.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: List.generate(_controller.queue.length, (idx) {
                        final isDone = idx < _controller.currentIndex;
                        final isCur = idx == _controller.currentIndex;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: isCur
                                  ? const Color(0xFFC85A32)
                                  : isDone
                                      ? const Color(0xFF1E2D4A)
                                      : Colors.black12,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),

          // Subtitle Bar (Clean, bold dark charcoal typography)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bold Charcoal English Subtitle
                Text(
                  _controller.currentSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                // Hindi Meaning & Sign Gloss
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _controller.currentHindiSubtitle,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFEF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _controller.currentGloss,
                        style: const TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _smoothEase(double x) {
    final clamped = x.clamp(0.0, 1.0);
    return (1.0 - math.cos(clamped * math.pi)) / 2.0;
  }

  List<double> _lerp3(List<double> a, List<double> b, double t) => [
        a[0] + (b[0] - a[0]) * t,
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
      ];
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.current, required this.onSelect});
  final double current;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    final speeds = [0.75, 1.0, 1.25];
    return PopupMenuButton<double>(
      initialValue: current,
      tooltip: 'Playback Speed',
      onSelected: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${current}x',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF333333),
          ),
        ),
      ),
      itemBuilder: (_) => speeds
          .map(
            (s) => PopupMenuItem(
              value: s,
              child: Text('${s}x speed',
                  style: TextStyle(
                      fontWeight: s == current ? FontWeight.bold : null)),
            ),
          )
          .toList(),
    );
  }
}

/// Custom 3D Humanoid Avatar Painter.
///
/// Renders:
/// - Male character with short brown hair
/// - Rust-red / terracotta crew-neck short-sleeve t-shirt
/// - Dark brown leather belt with metal buckle
/// - Navy blue denim trousers / jeans
/// - Articulated arms, elbows, wrists, hands, and fingers
/// - Soft studio drop shadow and contact lighting
class _Humanoid3DAvatarPainter extends CustomPainter {
  _Humanoid3DAvatarPainter({
    required this.rightWrist,
    required this.rightElbow,
    required this.leftWrist,
    required this.leftElbow,
    required this.headTilt,
    required this.breathing,
    required this.rightHandOpen,
    required this.leftHandOpen,
  });

  final List<double> rightWrist;
  final List<double> rightElbow;
  final List<double> leftWrist;
  final List<double> leftElbow;
  final List<double> headTilt;
  final double breathing;
  final bool rightHandOpen;
  final bool leftHandOpen;

  // Visual Palette
  static const skinTone = Color(0xFFF3C7A8);
  static const skinShadow = Color(0xFFDEAA87);
  static const hairBrown = Color(0xFF442614);
  static const hairHighlight = Color(0xFF6B3E22);
  static const shirtTerracotta = Color(0xFFC85A32);
  static const shirtShadow = Color(0xFFA6431E);
  static const shirtHighlight = Color(0xFFDB6E46);
  static const beltDarkBrown = Color(0xFF351C0E);
  static const buckleSilver = Color(0xFFE2E8F0);
  static const jeansNavy = Color(0xFF1E2D4A);
  static const jeansShadow = Color(0xFF141F34);
  static const shoesCharcoal = Color(0xFF262626);

  // 3D Perspective Projection: [X, Y, Z] -> [ScreenX, ScreenY]
  Offset _project(double x, double y, double z, Size size) {
    // Camera settings: centered at (0, 1.35, 2.6)
    const cameraZ = 2.6;
    final dist = cameraZ - z;
    final scale = 1.0 / (dist <= 0.1 ? 0.1 : dist);

    final centerX = size.width * 0.50;
    // Align view so avatar spans from head to lower legs
    final centerY = size.height * 0.52;
    final fovFactor = size.height * 1.55;

    final px = centerX + (x * fovFactor * scale * 0.52);
    final py = centerY - ((y - 1.25) * fovFactor * scale * 0.52);
    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Studio Contact Shadow on Floor
    _drawContactShadow(canvas, size);

    // 2. Lower Legs & Shoes (Navy Jeans & Charcoal Shoes)
    _drawLowerBody(canvas, size);

    // 3. Torso (Terracotta Crew-Neck Shirt & Brown Belt)
    _drawTorsoAndBelt(canvas, size);

    // 4. Left Arm (Behind / side)
    _drawArm(
      canvas,
      size,
      shoulderPos: [-0.22, 1.44 + breathing, 0.0],
      elbowPos: leftElbow,
      wristPos: leftWrist,
      isRightArm: false,
      isOpenHand: leftHandOpen,
    );

    // 5. Head & Neck (with short brown hair)
    _drawHeadAndHair(canvas, size);

    // 6. Right Arm (Active signing arm / Hello gesture)
    _drawArm(
      canvas,
      size,
      shoulderPos: [0.22, 1.44 + breathing, 0.0],
      elbowPos: rightElbow,
      wristPos: rightWrist,
      isRightArm: true,
      isOpenHand: rightHandOpen,
    );
  }

  void _drawContactShadow(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.94);
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.16),
          Colors.black.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCenter(center: center, width: 190, height: 42));

    canvas.drawOval(
      Rect.fromCenter(center: center, width: 190, height: 42),
      shadowPaint,
    );
  }

  void _drawLowerBody(Canvas canvas, Size size) {
    final hipL = _project(-0.10, 1.02, 0.0, size);
    final hipR = _project(0.10, 1.02, 0.0, size);
    final kneeL = _project(-0.11, 0.68, 0.02, size);
    final kneeR = _project(0.11, 0.68, 0.02, size);
    final ankleL = _project(-0.10, 0.36, 0.03, size);
    final ankleR = _project(0.10, 0.36, 0.03, size);

    // Navy Jeans Legs
    final jeansPaint = Paint()
      ..color = jeansNavy
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final jeansShadowPaint = Paint()
      ..color = jeansShadow
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left leg
    jeansShadowPaint.strokeWidth = 32;
    canvas.drawLine(hipL, kneeL, jeansShadowPaint);
    canvas.drawLine(kneeL, ankleL, jeansShadowPaint);
    jeansPaint.strokeWidth = 28;
    canvas.drawLine(hipL, kneeL, jeansPaint);
    canvas.drawLine(kneeL, ankleL, jeansPaint);

    // Right leg
    canvas.drawLine(hipR, kneeR, jeansShadowPaint);
    canvas.drawLine(kneeR, ankleR, jeansShadowPaint);
    canvas.drawLine(hipR, kneeR, jeansPaint);
    canvas.drawLine(kneeR, ankleR, jeansPaint);

    // Shoes
    final shoePaint = Paint()..color = shoesCharcoal;
    final shoeSolePaint = Paint()..color = Colors.white70;

    for (final ankle in [ankleL, ankleR]) {
      final shoeRect = Rect.fromCenter(
        center: Offset(ankle.dx + 4, ankle.dy + 8),
        width: 32,
        height: 16,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(shoeRect, const Radius.circular(8)),
        shoePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(shoeRect.left, shoeRect.bottom - 4, 32, 4),
          const Radius.circular(2),
        ),
        shoeSolePaint,
      );
    }
  }

  void _drawTorsoAndBelt(Canvas canvas, Size size) {
    final chest = _project(0.0, 1.30 + breathing, 0.0, size);
    final waist = _project(0.0, 1.05 + (breathing * 0.5), 0.0, size);
    final shoulderL = _project(-0.22, 1.44 + breathing, 0.0, size);
    final shoulderR = _project(0.22, 1.44 + breathing, 0.0, size);

    // Terracotta T-Shirt Body Polygon
    final shirtPath = Path()
      ..moveTo(shoulderL.dx, shoulderL.dy)
      ..quadraticBezierTo(chest.dx, chest.dy - 18, shoulderR.dx, shoulderR.dy)
      ..lineTo(waist.dx + 40, waist.dy)
      ..lineTo(waist.dx - 40, waist.dy)
      ..close();

    final shirtGrad = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: const [shirtHighlight, shirtTerracotta, shirtShadow],
      stops: const [0.0, 0.55, 1.0],
    );

    final shirtPaint = Paint()
      ..shader = shirtGrad.createShader(shirtPath.getBounds());
    canvas.drawPath(shirtPath, shirtPaint);

    // Crew Neck Collar Rim
    final collarPaint = Paint()
      ..color = const Color(0xFFA03F1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final neckCenter = _project(0.0, 1.46 + breathing, 0.05, size);
    canvas.drawArc(
      Rect.fromCenter(center: neckCenter, width: 34, height: 18),
      0.1,
      math.pi - 0.2,
      false,
      collarPaint,
    );

    // Dark Brown Belt
    final beltRect = Rect.fromCenter(
      center: Offset(waist.dx, waist.dy + 3),
      width: 82,
      height: 15,
    );
    final beltPaint = Paint()..color = beltDarkBrown;
    canvas.drawRRect(
      RRect.fromRectAndRadius(beltRect, const Radius.circular(4)),
      beltPaint,
    );

    // Silver Buckle
    final buckleRect = Rect.fromCenter(
      center: Offset(waist.dx, waist.dy + 3),
      width: 22,
      height: 17,
    );
    final bucklePaint = Paint()
      ..color = buckleSilver
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(buckleRect, const Radius.circular(3)),
      bucklePaint,
    );

    final buckleProng = Paint()
      ..color = buckleSilver
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(waist.dx - 4, waist.dy + 3),
      Offset(waist.dx + 4, waist.dy + 3),
      buckleProng,
    );
  }

  void _drawHeadAndHair(Canvas canvas, Size size) {
    final headCenter = _project(
      headTilt[0],
      1.68 + (breathing * 0.7) + headTilt[1],
      headTilt[2],
      size,
    );
    final neckBase = _project(0.0, 1.48 + breathing, 0.0, size);

    // Neck
    final neckPaint = Paint()..color = skinShadow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(headCenter.dx, (headCenter.dy + neckBase.dy) * 0.5),
          width: 22,
          height: 28,
        ),
        const Radius.circular(8),
      ),
      neckPaint,
    );

    // Face / Head base
    final faceRect = Rect.fromCenter(
      center: headCenter,
      width: 48,
      height: 58,
    );

    final skinGrad = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: const [Color(0xFFFDE8D8), skinTone, skinShadow],
    );

    final facePaint = Paint()..shader = skinGrad.createShader(faceRect);
    canvas.drawOval(faceRect, facePaint);

    // Ears
    final earPaint = Paint()..color = skinTone;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx - 24, headCenter.dy + 2),
        width: 8,
        height: 16,
      ),
      earPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx + 24, headCenter.dy + 2),
        width: 8,
        height: 16,
      ),
      earPaint,
    );

    // Short Brown Hair (sculpted volume with fringe & sides)
    final hairPath = Path()
      // Hair top curve
      ..moveTo(headCenter.dx - 25, headCenter.dy - 6)
      ..cubicTo(
        headCenter.dx - 28,
        headCenter.dy - 32,
        headCenter.dx - 12,
        headCenter.dy - 40,
        headCenter.dx,
        headCenter.dy - 38,
      )
      ..cubicTo(
        headCenter.dx + 15,
        headCenter.dy - 40,
        headCenter.dx + 28,
        headCenter.dy - 30,
        headCenter.dx + 25,
        headCenter.dy - 6,
      )
      // Front stylish fringe / bangs cut
      ..quadraticBezierTo(
        headCenter.dx + 16,
        headCenter.dy - 18,
        headCenter.dx + 6,
        headCenter.dy - 16,
      )
      ..quadraticBezierTo(
        headCenter.dx - 6,
        headCenter.dy - 22,
        headCenter.dx - 18,
        headCenter.dy - 14,
      )
      ..close();

    final hairGrad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [hairHighlight, hairBrown],
    );

    final hairPaint = Paint()..shader = hairGrad.createShader(faceRect);
    canvas.drawPath(hairPath, hairPaint);

    // Friendly Facial Features (Eyes & Smile)
    final eyePaint = Paint()..color = const Color(0xFF2C1810);
    // Left eye & eyebrow
    canvas.drawCircle(Offset(headCenter.dx - 8, headCenter.dy - 2), 2.5, eyePaint);
    // Right eye & eyebrow
    canvas.drawCircle(Offset(headCenter.dx + 8, headCenter.dy - 2), 2.5, eyePaint);

    final browPaint = Paint()
      ..color = hairBrown
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(headCenter.dx - 13, headCenter.dy - 8),
      Offset(headCenter.dx - 4, headCenter.dy - 7),
      browPaint,
    );
    canvas.drawLine(
      Offset(headCenter.dx + 4, headCenter.dy - 7),
      Offset(headCenter.dx + 13, headCenter.dy - 8),
      browPaint,
    );

    // Gentle Smile
    final smilePaint = Paint()
      ..color = const Color(0xFFBA5B3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final mouthRect = Rect.fromCenter(
      center: Offset(headCenter.dx, headCenter.dy + 12),
      width: 14,
      height: 8,
    );
    canvas.drawArc(mouthRect, 0.2, math.pi - 0.4, false, smilePaint);
  }

  void _drawArm(
    Canvas canvas,
    Size size, {
    required List<double> shoulderPos,
    required List<double> elbowPos,
    required List<double> wristPos,
    required bool isRightArm,
    required bool isOpenHand,
  }) {
    final pShoulder = _project(shoulderPos[0], shoulderPos[1], shoulderPos[2], size);
    final pElbow = _project(elbowPos[0], elbowPos[1], elbowPos[2], size);
    final pWrist = _project(wristPos[0], wristPos[1], wristPos[2], size);

    // 1. Short Sleeve on Upper Arm (Terracotta)
    final sleeveEnd = Offset.lerp(pShoulder, pElbow, 0.45)!;
    final sleevePaint = Paint()
      ..color = shirtTerracotta
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pShoulder, sleeveEnd, sleevePaint);

    // 2. Upper Arm (Bicep/Tricep) Skin
    final armSkinPaint = Paint()
      ..color = skinTone
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(sleeveEnd, pElbow, armSkinPaint);

    // Elbow Joint Sphere
    canvas.drawCircle(pElbow, 9, armSkinPaint);

    // 3. Forearm Skin
    final forearmPaint = Paint()
      ..color = skinTone
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pElbow, pWrist, forearmPaint);

    // 4. Hand & Fingers
    _drawHand(
      canvas,
      pWrist,
      pElbow,
      isRight: isRightArm,
      isOpen: isOpenHand,
    );
  }

  void _drawHand(
    Canvas canvas,
    Offset wrist,
    Offset elbow, {
    required bool isRight,
    required bool isOpen,
  }) {
    // Determine pointing vector of the hand
    final dir = (wrist - elbow);
    final length = dir.distance;
    final norm = length > 0 ? dir / length : const Offset(0, -1);
    final perp = Offset(-norm.dy, norm.dx);

    final handCenter = wrist + (norm * 14);

    final palmPaint = Paint()..color = skinTone;
    final fingerPaint = Paint()
      ..color = skinTone
      ..strokeWidth = 3.8
      ..strokeCap = StrokeCap.round;

    if (isOpen) {
      // Natural Open Palm (as in "Hello" wave gesture)
      canvas.drawOval(
        Rect.fromCenter(center: handCenter, width: 16, height: 18),
        palmPaint,
      );

      // Thumb
      final thumbBase = wrist + (perp * (isRight ? 7 : -7)) + (norm * 5);
      final thumbTip = thumbBase + (perp * (isRight ? 10 : -10)) + (norm * 7);
      canvas.drawLine(thumbBase, thumbTip, fingerPaint);

      // 4 Fingers (Index, Middle, Ring, Pinky)
      for (int i = 0; i < 4; i++) {
        final spread = (i - 1.5) * 3.2;
        final fBase = handCenter + (perp * spread) + (norm * 4);
        final fTip = fBase + (norm * (12 + (i == 1 || i == 2 ? 3 : 0)));
        canvas.drawLine(fBase, fTip, fingerPaint);
      }
    } else {
      // Relaxed fist / closed hand
      canvas.drawCircle(handCenter, 9, palmPaint);
      // Thumb tucked
      final thumbBase = handCenter + (perp * (isRight ? 6 : -6));
      canvas.drawCircle(thumbBase, 4, palmPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _Humanoid3DAvatarPainter oldDelegate) => true;
}
