import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera pipeline service (from the ML feature branch): camera
/// initialization, frame capture and MediaPipe pose-landmark extraction.
/// Emits one 63-value vector per frame (21 landmarks x 3 coords).
class CameraService {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// Request camera permission if needed, then initialize the camera with a
  /// live frame stream. Throws with a readable message on failure.
  Future<void> initialize() async {
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

    // Prefer the front camera — it faces the signer.
    final frontCamera = _cameras!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // balance quality vs performance
      enableAudio: false,
      // Let the plugin pick the latest raw format this ML Kit build supports.
      imageFormatGroup: ImageFormatGroup.unknown,
    );

    await _controller!.initialize();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      ),
    );

    _isInitialized = true;
  }

  /// Process a single camera image and extract 63 landmark coordinates:
  /// [x1, y1, z1, x2, y2, z2, ...] for the 21 tracked landmarks, normalized
  /// to [0, 1] (z in [-1, 1]). Returns null when nothing usable is detected.
  Future<List<double>?> extractKeypoints(CameraImage image) async {
    if (_poseDetector == null || _controller == null) return null;
    final inputImage = _convertCameraImage(
      image,
      camera: _controller!.description,
    );
    if (inputImage == null) return null;

    try {
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isEmpty) return null;
      final pose = poses.first;

      final keypoints = <double>[];
      final landmarks = <PoseLandmark?>[
        // Right arm & hand
        pose.landmarks[PoseLandmarkType.rightWrist],
        pose.landmarks[PoseLandmarkType.rightPinky],
        pose.landmarks[PoseLandmarkType.rightIndex],
        pose.landmarks[PoseLandmarkType.rightThumb],
        pose.landmarks[PoseLandmarkType.rightElbow],
        pose.landmarks[PoseLandmarkType.rightShoulder],
        // Left arm & hand
        pose.landmarks[PoseLandmarkType.leftWrist],
        pose.landmarks[PoseLandmarkType.leftPinky],
        pose.landmarks[PoseLandmarkType.leftIndex],
        pose.landmarks[PoseLandmarkType.leftThumb],
        pose.landmarks[PoseLandmarkType.leftElbow],
        pose.landmarks[PoseLandmarkType.leftShoulder],
        // Face reference points
        pose.landmarks[PoseLandmarkType.nose],
        pose.landmarks[PoseLandmarkType.leftEye],
        pose.landmarks[PoseLandmarkType.rightEye],
        pose.landmarks[PoseLandmarkType.leftEar],
        pose.landmarks[PoseLandmarkType.rightEar],
        // Torso
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.rightKnee],
      ];

      for (final landmark in landmarks) {
        if (landmark != null) {
          keypoints.addAll([
            landmark.x.clamp(0.0, 1.0),
            landmark.y.clamp(0.0, 1.0),
            landmark.z.clamp(-1.0, 1.0),
          ]);
        } else {
          keypoints.addAll([0.0, 0.0, 0.0]);
        }
      }

      // Pad/trim to exactly 63 values (21 landmarks x 3).
      while (keypoints.length < 63) {
        keypoints.add(0.0);
      }
      return keypoints.sublist(0, 63);
    } catch (e) {
      debugPrint('Keypoint extraction error: $e');
      return null;
    }
  }

  InputImage? _convertCameraImage(
    CameraImage image, {
    required CameraDescription camera,
  }) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      // With ImageFormatGroup.unknown the camera plugin reports the native
      // format (YUV_420_888 on Android, kCVPixelFormat420YpCbCr8BiPlanar
      // video range on iOS); resolve it dynamically for ML Kit compatibility.
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) {
        debugPrint('Unsupported image format: ${image.format.raw}');
        return null;
      }

      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      debugPrint('Camera image conversion error: $e');
      return null;
    }
  }

  /// Frame-by-frame processing via onImageAvailable.
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

  /// Release the preview surface while keeping the session (app pause).
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

  /// Dispose of camera and detector resources.
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
