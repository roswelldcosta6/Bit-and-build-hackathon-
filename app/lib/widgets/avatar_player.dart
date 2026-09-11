import 'dart:async';

import 'package:flutter/material.dart';

import '../models/api_models.dart';
import '../services/api_service.dart';

class AvatarPlayer extends StatefulWidget {
  const AvatarPlayer({required this.actions, required this.api, super.key});
  final List<AvatarAction> actions;
  final ApiService api;
  @override
  State<AvatarPlayer> createState() => _AvatarPlayerState();
}

class _AvatarPlayerState extends State<AvatarPlayer> {
  Timer? _timer;
  Map<String, List<double>> _joints = _restPose;
  String _label = 'Ready';
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didUpdateWidget(AvatarPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions) _play();
  }

  Future<void> _play() async {
    _timer?.cancel();
    if (widget.actions.isEmpty) return;
    setState(() => _loading = true);
    for (final action in widget.actions) {
      if (!mounted) return;
      try {
        final pose = await widget.api.getPose(action.poseEndpoint);
        if (!mounted) return;
        setState(() {
          _label = pose.gloss.replaceAll('_', ' ');
          _loading = false;
        });
        await _playFrames(pose.frames);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _label = action.gloss.replaceAll('_', ' ');
          _joints = _demoPose(action.gloss);
          _loading = false;
        });
        await Future<void>.delayed(Duration(milliseconds: action.durationMs));
      }
    }
  }

  Future<void> _playFrames(List<Map<String, List<double>>> frames) async {
    if (frames.isEmpty) return;
    final done = Completer<void>();
    var index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!mounted || index >= frames.length) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      setState(() => _joints = frames[index++]);
    });
    await done.future;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Theme.of(context).colorScheme.primaryContainer,
          Theme.of(context).colorScheme.surface,
        ],
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _AvatarPainter(
              _joints,
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .48),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _loading
                      ? const SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.motion_photos_on_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                  const SizedBox(width: 6),
                  Text(
                    _loading ? 'Loading motion' : _label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          bottom: 12,
          right: 16,
          child: Text(
            '3D skeletal avatar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

const _restPose = <String, List<double>>{
  'head': [0, 1.70, 0],
  'neck': [0, 1.50, 0],
  'chest': [0, 1.30, 0],
  'left_shoulder': [-.20, 1.45, 0],
  'left_elbow': [-.30, 1.15, -.05],
  'left_wrist': [-.25, .85, .05],
  'left_hand_index': [-.27, .75, .08],
  'right_shoulder': [.20, 1.45, 0],
  'right_elbow': [.30, 1.15, -.05],
  'right_wrist': [.25, .85, .05],
  'right_hand_index': [.27, .75, .08],
};
Map<String, List<double>> _demoPose(String gloss) {
  final pose = Map<String, List<double>>.from(_restPose);
  if (gloss == 'HELP') {
    pose['left_wrist'] = [-.05, 1.25, .35];
    pose['right_wrist'] = [0, 1.32, .35];
  } else if (gloss == 'HELLO') {
    pose['right_wrist'] = [.20, 1.68, .18];
  } else {
    pose['right_wrist'] = [.08, 1.38, .3];
    pose['left_wrist'] = [-.08, 1.32, .28];
  }
  return pose;
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.joints, this.color);
  final Map<String, List<double>> joints;
  final Color color;
  Offset _point(String name, Size size) {
    final value = joints[name] ?? _restPose[name]!;
    return Offset(
      size.width * (.5 + value[0] * .9),
      size.height * (1.05 - value[1] * .52),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final thin = Paint()
      ..color = color.withValues(alpha: .72)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    void segment(String a, String b, Paint paint) =>
        canvas.drawLine(_point(a, size), _point(b, size), paint);
    segment('head', 'neck', line);
    segment('neck', 'chest', line);
    segment('left_shoulder', 'left_elbow', line);
    segment('left_elbow', 'left_wrist', line);
    segment('right_shoulder', 'right_elbow', line);
    segment('right_elbow', 'right_wrist', line);
    segment('left_wrist', 'left_hand_index', thin);
    segment('right_wrist', 'right_hand_index', thin);
    canvas.drawLine(
      _point('left_shoulder', size),
      _point('right_shoulder', size),
      line,
    );
    canvas.drawCircle(
      _point('head', size),
      27,
      Paint()..color = color.withValues(alpha: .9),
    );
    for (final name in [
      'left_wrist',
      'right_wrist',
      'left_hand_index',
      'right_hand_index',
    ]) {
      canvas.drawCircle(_point(name, size), 8, Paint()..color = Colors.white);
      canvas.drawCircle(_point(name, size), 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) =>
      oldDelegate.joints != joints || oldDelegate.color != color;
}
