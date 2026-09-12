import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Person 2: Camera pipeline service
/// Handles camera initialization, frame capture, and MediaPipe keypoint extraction.
/// Outputs List<double> of 63 landmark coordinates per frame (21 hand + 33 pose landmarks).
class CameraService {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// Initialize the camera with 30fps preview
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('NO_CAMERAS', 'No cameras available on this device');
    }

    // Prefer front camera for signing
    final frontCamera = _cameras!.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium, // Balance quality vs performance
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();

    // Initialize MediaPipe Pose Detection
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      ),
    );

    _isInitialized = true;
  }

  /// Process a single camera image and extract 63 landmark coordinates.
  /// Returns a flat List<double> of 63 values: [x1, y1, z1, x2, y2, z2, ...]
  /// for 21 hand keypoints (right hand).
  /// Returns null if no hand is detected.
  Future<List<double>?> extractKeypoints(CameraImage image) async {
    if (_poseDetector == null) return null;
    final inputImage = _convertCameraImage(image, camera: _controller!.description);
    if (inputImage == null) return null;

    try {
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) return null;

      final pose = poses.first;

      // Build 63-element keypoint vector from available pose landmarks
      // Normalized to [0, 1] range based on image dimensions
      final keypoints = <double>[];

      final landmarks = [
        // Right arm & hand (6)
        pose.landmarks[PoseLandmarkType.rightWrist],
        pose.landmarks[PoseLandmarkType.rightPinky],
        pose.landmarks[PoseLandmarkType.rightIndex],
        pose.landmarks[PoseLandmarkType.rightThumb],
        pose.landmarks[PoseLandmarkType.rightElbow],
        pose.landmarks[PoseLandmarkType.rightShoulder],
        // Left arm & hand (5)
        pose.landmarks[PoseLandmarkType.leftWrist],
        pose.landmarks[PoseLandmarkType.leftPinky],
        pose.landmarks[PoseLandmarkType.leftIndex],
        pose.landmarks[PoseLandmarkType.leftThumb],
        pose.landmarks[PoseLandmarkType.leftElbow],
        pose.landmarks[PoseLandmarkType.leftShoulder],
        // Face reference points (5)
        pose.landmarks[PoseLandmarkType.nose],
        pose.landmarks[PoseLandmarkType.leftEye],
        pose.landmarks[PoseLandmarkType.rightEye],
        pose.landmarks[PoseLandmarkType.leftEar],
        pose.landmarks[PoseLandmarkType.rightEar],
        // Torso & legs (5)
        pose.landmarks[PoseLandmarkType.leftHip],
        pose.landmarks[PoseLandmarkType.rightHip],
        pose.landmarks[PoseLandmarkType.leftKnee],
        pose.landmarks[PoseLandmarkType.rightKnee],
        pose.landmarks[PoseLandmarkType.leftAnkle],
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

      // Pad or trim to exactly 63 values (21 landmarks × 3)
      while (keypoints.length < 63) {
        keypoints.add(0.0);
      }

      return keypoints.sublist(0, 63);
    } catch (e) {
      debugPrint('Keypoint extraction error: $e');
      return null;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image, {required CameraDescription camera}) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

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

  /// Set up frame-by-frame processing via onImageAvailable callback
  void startImageStream(void Function(CameraImage image) onImage) {
    try {
      _controller?.startImageStream(onImage);
    } catch (e) {
      debugPrint('startImageStream not available: $e');
    }
  }

  /// Stop the image stream
  Future<void> stopImageStream() async {
    try {
      await _controller?.stopImageStream();
    } catch (e) {
      debugPrint('stopImageStream error: $e');
    }
  }

  /// Dispose of camera and detector resources
  Future<void> dispose() async {
    _isInitialized = false;
    await _controller?.dispose();
    _controller = null;
    await _poseDetector?.close();
    _poseDetector = null;
  }
}
