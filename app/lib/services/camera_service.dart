import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

/// The 2D visual landmarks (for skeleton overlay) and 63-value model input vector.
class KeypointsResult {
  final List<double> modelInput;
  final List<Offset> visualLandmarks;
  final bool handsDetected;

  const KeypointsResult({
    required this.modelInput,
    required this.visualLandmarks,
    required this.handsDetected,
  });
}

/// Camera pipeline service:
/// - Supports front / back camera toggle via [switchCamera].
/// - Uses ML Kit Pose Detection for body + wrist/elbow/head landmarks.
/// - Full 5-finger biomechanical model per hand with articulated MCP knuckles and fingertips.
/// - Full head contour with neck, eyes, ears, nose and cranial apex.
/// - Accurately aligns coordinates to `ml/dataset.py` specifications.
class CameraService {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _useFrontCamera = true;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;
  bool get usingFrontCamera => _useFrontCamera;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize({bool useFrontCamera = true}) async {
    _useFrontCamera = useFrontCamera;
    if (_isInitialized) return;

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw CameraException(
        'CAMERA_PERMISSION_DENIED',
        'Camera permission was not granted',
      );
    }

    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('NO_CAMERAS', 'No cameras available on this device');
    }

    await _initController();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      ),
    );

    _isInitialized = true;
  }

  Future<void> _initController() async {
    final cameras = _cameras!;
    final CameraDescription selected;

    if (_useFrontCamera) {
      selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
    } else {
      selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
    }

    _controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup:
          Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
  }

  // ── Camera toggle ──────────────────────────────────────────────────────────

  /// Switch between front and back camera mid-stream.
  /// Returns `true` on success.
  Future<bool> switchCamera({required void Function(CameraImage) onImage}) async {
    if (_cameras == null || _cameras!.isEmpty) return false;

    try {
      await _controller?.stopImageStream();
      await _controller?.dispose();
      _controller = null;

      _useFrontCamera = !_useFrontCamera;
      await _initController();
      _controller!.startImageStream(onImage);
      return true;
    } catch (e) {
      debugPrint('switchCamera error: $e');
      return false;
    }
  }

  // ── Keypoint extraction ────────────────────────────────────────────────────

  /// Process one camera frame through ML Kit pose detection.
  Future<KeypointsResult?> extractKeypoints(CameraImage image) async {
    if (_poseDetector == null || _controller == null) return null;
    final cameraDesc = _controller!.description;
    final inputImage = _convertCameraImage(image, camera: cameraDesc);
    if (inputImage == null) return null;

    try {
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) return null;
      final pose = poses.first;

      final rotation = InputImageRotationValue.fromRawValue(
            cameraDesc.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final bool isRotated = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final double tW = (isRotated ? image.height : image.width).toDouble();
      final double tH = (isRotated ? image.width : image.height).toDouble();

      // Normalize raw landmark pixel → [0,1] offset
      Offset norm(double x, double y) =>
          Offset((x / tW).clamp(0.0, 1.0), (y / tH).clamp(0.0, 1.0));

      Offset? posePt(PoseLandmarkType t) {
        final lm = pose.landmarks[t];
        return lm != null ? norm(lm.x, lm.y) : null;
      }

      // ── Body landmarks ────────────────────────────────────────────────────
      final rWrist = posePt(PoseLandmarkType.rightWrist);
      final lWrist = posePt(PoseLandmarkType.leftWrist);
      final rElbow = posePt(PoseLandmarkType.rightElbow);
      final lElbow = posePt(PoseLandmarkType.leftElbow);
      final rShoulder = posePt(PoseLandmarkType.rightShoulder);
      final lShoulder = posePt(PoseLandmarkType.leftShoulder);
      final rHip = posePt(PoseLandmarkType.rightHip);
      final lHip = posePt(PoseLandmarkType.leftHip);
      final rKnee = posePt(PoseLandmarkType.rightKnee);
      final lKnee = posePt(PoseLandmarkType.leftKnee);
      final nose = posePt(PoseLandmarkType.nose);
      final lEye = posePt(PoseLandmarkType.leftEye);
      final rEye = posePt(PoseLandmarkType.rightEye);
      final lEar = posePt(PoseLandmarkType.leftEar);
      final rEar = posePt(PoseLandmarkType.rightEar);

      // Hand detection: at least one wrist is above its hip
      final rHandUp = rWrist != null && (rHip == null || rWrist.dy < rHip.dy);
      final lHandUp = lWrist != null && (lHip == null || lWrist.dy < lHip.dy);
      final handsDetected = rHandUp || lHandUp;

      // Resting-pose gate: skip inference if both wrists are clearly at sides
      if (rWrist != null && lWrist != null && rHip != null && lHip != null) {
        if (rWrist.dy > rHip.dy && lWrist.dy > lHip.dy) return null;
      }

      // ── Biomechanical 5-finger hand reconstruction ─────────────────────────
      // Forearm unit vector from elbow → wrist
      ({double ux, double uy}) forearmDir(Offset wristPt, Offset elbowPt) {
        final dx = wristPt.dx - elbowPt.dx;
        final dy = wristPt.dy - elbowPt.dy;
        final len = math.sqrt(dx * dx + dy * dy);
        return len > 0.001
            ? (ux: dx / len, uy: dy / len)
            : (ux: 0.0, uy: -1.0); // default: point upward
      }

      // Compute point along forward forearm vector (fwd) and lateral vector (lat)
      Offset offsetFromWrist(
        Offset wrist,
        double ux,
        double uy,
        double fwd,
        double lat,
      ) =>
          Offset(
            (wrist.dx + ux * fwd - uy * lat).clamp(0.0, 1.0),
            (wrist.dy + uy * fwd + ux * lat).clamp(0.0, 1.0),
          );

      Offset bestFinger(
        Offset wrist,
        double ux,
        double uy,
        PoseLandmarkType type,
        double fwd,
        double lat,
      ) {
        final lm = pose.landmarks[type];
        if (lm != null && lm.likelihood > 0.15) {
          return norm(lm.x, lm.y);
        }
        return offsetFromWrist(wrist, ux, uy, fwd, lat);
      }

      // ── Right hand (anatomical right) ──────────────────────────────────────
      final rW = rWrist ?? const Offset(0.38, 0.50);
      final rE = rElbow ?? const Offset(0.34, 0.52);
      final rDir = forearmDir(rW, rE);
      final rUx = rDir.ux;
      final rUy = rDir.uy;

      // Knuckles (MCP joints)
      final rThumbMcp = offsetFromWrist(rW, rUx, rUy, 0.035, 0.032);
      final rIndexMcp = offsetFromWrist(rW, rUx, rUy, 0.048, 0.016);
      final rMiddleMcp = offsetFromWrist(rW, rUx, rUy, 0.050, 0.000);
      final rRingMcp = offsetFromWrist(rW, rUx, rUy, 0.046, -0.016);
      final rPinkyMcp = offsetFromWrist(rW, rUx, rUy, 0.040, -0.030);

      // 5 Distinct Fingertips
      final rThumbTip = bestFinger(rW, rUx, rUy, PoseLandmarkType.rightThumb, 0.065, 0.048);
      final rIndexTip = bestFinger(rW, rUx, rUy, PoseLandmarkType.rightIndex, 0.095, 0.020);
      final rMiddleTip = offsetFromWrist(rW, rUx, rUy, 0.102, 0.000);
      final rRingTip = offsetFromWrist(rW, rUx, rUy, 0.092, -0.020);
      final rPinkyTip = bestFinger(rW, rUx, rUy, PoseLandmarkType.rightPinky, 0.078, -0.040);

      // ── Left hand (anatomical left) ────────────────────────────────────────
      final lW = lWrist ?? const Offset(0.62, 0.50);
      final lE = lElbow ?? const Offset(0.66, 0.52);
      final lDir = forearmDir(lW, lE);
      final lUx = lDir.ux;
      final lUy = lDir.uy;

      // Knuckles (MCP joints)
      final lThumbMcp = offsetFromWrist(lW, lUx, lUy, 0.035, -0.032);
      final lIndexMcp = offsetFromWrist(lW, lUx, lUy, 0.048, -0.016);
      final lMiddleMcp = offsetFromWrist(lW, lUx, lUy, 0.050, 0.000);
      final lRingMcp = offsetFromWrist(lW, lUx, lUy, 0.046, 0.016);
      final lPinkyMcp = offsetFromWrist(lW, lUx, lUy, 0.040, 0.030);

      // 5 Distinct Fingertips
      final lThumbTip = bestFinger(lW, lUx, lUy, PoseLandmarkType.leftThumb, 0.065, -0.048);
      final lIndexTip = bestFinger(lW, lUx, lUy, PoseLandmarkType.leftIndex, 0.095, -0.020);
      final lMiddleTip = offsetFromWrist(lW, lUx, lUy, 0.102, 0.000);
      final lRingTip = offsetFromWrist(lW, lUx, lUy, 0.092, 0.020);
      final lPinkyTip = bestFinger(lW, lUx, lUy, PoseLandmarkType.leftPinky, 0.078, 0.040);

      // ── Body & Head landmarks with fallbacks ──────────────────────────────
      final rShoulderPt = rShoulder ?? const Offset(0.38, 0.35);
      final lShoulderPt = lShoulder ?? const Offset(0.62, 0.35);
      final rElbowPt = rElbow ?? const Offset(0.34, 0.52);
      final lElbowPt = lElbow ?? const Offset(0.66, 0.52);
      final rHipPt = rHip ?? const Offset(0.42, 0.75);
      final lHipPt = lHip ?? const Offset(0.58, 0.75);
      final rKneePt = rKnee ?? const Offset(0.43, 0.90);
      final lKneePt = lKnee ?? const Offset(0.57, 0.90);

      final nosePt = nose ?? const Offset(0.50, 0.20);
      final lEyePt = lEye ?? const Offset(0.54, 0.18);
      final rEyePt = rEye ?? const Offset(0.46, 0.18);
      final lEarPt = lEar ?? const Offset(0.58, 0.20);
      final rEarPt = rEar ?? const Offset(0.42, 0.20);

      // Head top & neck anchors
      final neckPt = Offset(
        (rShoulderPt.dx + lShoulderPt.dx) / 2.0,
        (rShoulderPt.dy + lShoulderPt.dy) / 2.0,
      );
      final headTopPt = Offset(
        nosePt.dx,
        (nosePt.dy - (neckPt.dy - nosePt.dy) * 0.75).clamp(0.02, 0.98),
      );

      // ── Visual Landmarks (37 points in camera sensor space) ────────────────
      // Right hand: 0-10
      // 0:rWrist, 1:rThumbMcp, 2:rThumbTip, 3:rIndexMcp, 4:rIndexTip,
      // 5:rMiddleMcp, 6:rMiddleTip, 7:rRingMcp, 8:rRingTip, 9:rPinkyMcp, 10:rPinkyTip
      // Left hand: 11-21
      // 11:lWrist, 12:lThumbMcp, 13:lThumbTip, 14:lIndexMcp, 15:lIndexTip,
      // 16:lMiddleMcp, 17:lMiddleTip, 18:lRingMcp, 19:lRingTip, 20:lPinkyMcp, 21:lPinkyTip
      // Arms & Torso: 22-25
      // 22:rElbow, 23:rShoulder, 24:lElbow, 25:lShoulder
      // Head & Face: 26-32
      // 26:nose, 27:lEye, 28:rEye, 29:lEar, 30:rEar, 31:headTop, 32:neck
      // Legs & Hips: 33-36
      // 33:rHip, 34:lHip, 35:rKnee, 36:lKnee
      final visualLandmarks = <Offset>[
        // Right hand (0-10)
        rW,
        rThumbMcp, rThumbTip,
        rIndexMcp, rIndexTip,
        rMiddleMcp, rMiddleTip,
        rRingMcp, rRingTip,
        rPinkyMcp, rPinkyTip,
        // Left hand (11-21)
        lW,
        lThumbMcp, lThumbTip,
        lIndexMcp, lIndexTip,
        lMiddleMcp, lMiddleTip,
        lRingMcp, lRingTip,
        lPinkyMcp, lPinkyTip,
        // Arms (22-25)
        rElbowPt, rShoulderPt,
        lElbowPt, lShoulderPt,
        // Head (26-32)
        nosePt, lEyePt, rEyePt, lEarPt, rEarPt, headTopPt, neckPt,
        // Lower body (33-36)
        rHipPt, lHipPt, rKneePt, lKneePt,
      ];

      // ── Model input (63 floats = 21 landmarks × 3) ─────────────────────────
      // Exact alignment with ml/dataset.py:
      //  0:rWrist, 1:rPinky, 2:rIndex, 3:rThumb, 4:rElbow, 5:rShoulder
      //  6:lWrist, 7:lPinky, 8:lIndex, 9:lThumb, 10:lElbow, 11:lShoulder
      // 12:nose, 13:lEye, 14:rEye, 15:lEar, 16:rEar
      // 17:lHip, 18:rHip, 19:lKnee, 20:rKnee  <-- matches dataset.py exactly
      final modelPts = <({Offset pt, double z})>[
        // 0-3: Right hand
        (pt: rW, z: rHandUp ? -0.15 : 0.0),
        (pt: rPinkyTip, z: rHandUp ? -0.15 : 0.0),
        (pt: rIndexTip, z: rHandUp ? -0.15 : 0.0),
        (pt: rThumbTip, z: rHandUp ? -0.13 : 0.0),
        // 4-5: Right arm
        (pt: rElbowPt, z: 0.05),
        (pt: rShoulderPt, z: 0.0),
        // 6-9: Left hand
        (pt: lW, z: lHandUp ? -0.15 : 0.0),
        (pt: lPinkyTip, z: lHandUp ? -0.15 : 0.0),
        (pt: lIndexTip, z: lHandUp ? -0.15 : 0.0),
        (pt: lThumbTip, z: lHandUp ? -0.13 : 0.0),
        // 10-11: Left arm
        (pt: lElbowPt, z: 0.05),
        (pt: lShoulderPt, z: 0.0),
        // 12-16: Head
        (pt: nosePt, z: 0.0),
        (pt: lEyePt, z: 0.0),
        (pt: rEyePt, z: 0.0),
        (pt: lEarPt, z: 0.05),
        (pt: rEarPt, z: 0.05),
        // 17-20: Hips & Knees (Left first, then Right, per dataset.py)
        (pt: lHipPt, z: 0.0),
        (pt: rHipPt, z: 0.0),
        (pt: lKneePt, z: 0.0),
        (pt: rKneePt, z: 0.0),
      ];

      // Coordinate mapping to dataset.py:
      // In dataset.py, the signer's right side is at x > 0.5 (~0.62).
      // On camera sensors, a person facing the camera has their right side on the left (x < 0.5).
      // (1.0 - pt.dx) maps the camera coordinate to dataset convention.
      final keypoints = <double>[];
      for (final item in modelPts) {
        final double x = (1.0 - item.pt.dx).clamp(0.0, 1.0);
        final double y = item.pt.dy.clamp(0.0, 1.0);
        keypoints.addAll([x, y, item.z]);
      }
      while (keypoints.length < 63) {
        keypoints.add(0.0);
      }

      return KeypointsResult(
        modelInput: keypoints.sublist(0, 63),
        visualLandmarks: visualLandmarks,
        handsDetected: handsDetected,
      );
    } catch (e) {
      debugPrint('Keypoint extraction error: $e');
      return null;
    }
  }

  // ── Image conversion ───────────────────────────────────────────────────────

  InputImage? _convertCameraImage(
    CameraImage image, {
    required CameraDescription camera,
  }) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
            camera.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      if (image.planes.isEmpty) return null;

      Uint8List bytes;
      InputImageFormat effectiveFormat;

      if (Platform.isAndroid) {
        if (image.format.group == ImageFormatGroup.nv21 &&
            image.planes.isNotEmpty) {
          bytes = image.planes.first.bytes;
          effectiveFormat = InputImageFormat.nv21;
        } else if (image.planes.length == 1) {
          bytes = image.planes.first.bytes;
          effectiveFormat = InputImageFormat.nv21;
        } else if (image.planes.length == 3) {
          bytes = _yuv420ToNv21(image);
          effectiveFormat = InputImageFormat.nv21;
        } else {
          final WriteBuffer allBytes = WriteBuffer();
          for (final Plane plane in image.planes) {
            allBytes.putUint8List(plane.bytes);
          }
          bytes = allBytes.done().buffer.asUint8List();
          effectiveFormat =
              InputImageFormatValue.fromRawValue(image.format.raw) ??
                  InputImageFormat.nv21;
        }
      } else {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
        effectiveFormat =
            InputImageFormatValue.fromRawValue(image.format.raw) ??
                InputImageFormat.bgra8888;
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: effectiveFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Camera image conversion error: $e');
      return null;
    }
  }

  /// Converts YUV_420_888 3-plane image into NV21 format required by ML Kit.
  static Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    final Plane yPlane = image.planes[0];
    final Uint8List yBytes = yPlane.bytes;
    final int yRowStride = yPlane.bytesPerRow;

    if (yRowStride == width) {
      nv21.setRange(0, ySize, yBytes);
    } else {
      for (int row = 0; row < height; row++) {
        final int srcOffset = row * yRowStride;
        final int dstOffset = row * width;
        nv21.setRange(
            dstOffset, dstOffset + width, yBytes.sublist(srcOffset, srcOffset + width));
      }
    }

    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final Uint8List uBytes = uPlane.bytes;
    final Uint8List vBytes = vPlane.bytes;
    final int uRowStride = uPlane.bytesPerRow;
    final int vRowStride = vPlane.bytesPerRow;
    final int uPixelStride = uPlane.bytesPerPixel ?? 1;
    final int vPixelStride = vPlane.bytesPerPixel ?? 1;

    int uvIndex = ySize;
    final int halfWidth = width ~/ 2;
    final int halfHeight = height ~/ 2;

    for (int row = 0; row < halfHeight; row++) {
      for (int col = 0; col < halfWidth; col++) {
        final int vOffset = row * vRowStride + col * vPixelStride;
        final int uOffset = row * uRowStride + col * uPixelStride;
        if (vOffset < vBytes.length && uOffset < uBytes.length) {
          nv21[uvIndex++] = vBytes[vOffset];
          nv21[uvIndex++] = uBytes[uOffset];
        }
      }
    }
    return nv21;
  }

  // ── Stream control ─────────────────────────────────────────────────────────

  void startImageStream(void Function(CameraImage image) onImage) {
    try {
      _controller?.startImageStream(onImage);
    } catch (e) {
      debugPrint('startImageStream not available: $e');
    }
  }

  Future<void> stopImageStream() async {
    try {
      await _controller?.stopImageStream();
    } catch (e) {
      debugPrint('stopImageStream error: $e');
    }
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await stopImageStream();
    try {
      await _controller?.dispose();
    } catch (e) {
      debugPrint('pause dispose error: $e');
    }
    _controller = null;
    _isInitialized = false;
  }

  Future<void> dispose() async {
    await pause();
    try {
      await _poseDetector?.close();
    } catch (e) {
      debugPrint('pose detector close error: $e');
    }
    _poseDetector = null;
  }
}
