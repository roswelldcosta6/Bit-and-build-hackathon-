import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/sign_result.dart';

/// On-device ISL inference engine (from the ML feature branch).
/// Loads model.tflite + labels_bilingual.json, runs sliding-window inference
/// over 30-frame keypoint sequences and debounces output for stable signs.
class TfliteService {
  Interpreter? _interpreter;
  List<Map<String, String>> _labels = const [];
  bool _isLoaded = false;

  // Sliding window: collect 30 frames, then run inference over buffered keypoints.
  static const int _windowSize = 30;
  static const int _keypointSize = 63; // 21 landmarks x 3 coords
  static const double _confidenceThreshold = 0.35; // Filter low confidence noise (prevents 20% random triggers)
  static const double _stableConfidenceThreshold = 0.50; // Threshold to lock in sign
  static const int _stabilityWindow = 4; // Stable across recent window

  final List<List<double>> _frameBuffer = [];
  final List<String> _recentPredictions = [];

  bool get isLoaded => _isLoaded;

  /// Load the TFLite model and bilingual labels from assets.
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      try {
        final ByteData modelByteData = await rootBundle.load('assets/model.tflite');
        final Uint8List modelBytes = modelByteData.buffer.asUint8List(
          modelByteData.offsetInBytes,
          modelByteData.lengthInBytes,
        );

        _interpreter = Interpreter.fromBuffer(
          modelBytes,
          options: InterpreterOptions()..threads = 2,
        );
      } catch (e1) {
        debugPrint('Interpreter.fromBuffer failed: $e1. Trying Interpreter.fromAsset(assets/model.tflite)...');
        try {
          _interpreter = await Interpreter.fromAsset(
            'assets/model.tflite',
            options: InterpreterOptions()..threads = 2,
          );
        } catch (e2) {
          debugPrint('Interpreter.fromAsset(assets/model.tflite) failed: $e2. Trying Interpreter.fromAsset(model.tflite)...');
          _interpreter = await Interpreter.fromAsset(
            'model.tflite',
            options: InterpreterOptions()..threads = 2,
          );
        }
      }

      final labelsJson = await rootBundle.loadString(
        'assets/labels_bilingual.json',
      );
      final Map<String, dynamic> rawLabels = json.decode(labelsJson);
      // Preserve exact JSON key insertion order which matches the 163 model output classes
      _labels = rawLabels.entries
          .map((e) {
            final val = e.value as Map<String, dynamic>;
            return {
              'key': e.key,
              'en': val['en']?.toString() ?? e.key,
              'hi': val['hi']?.toString() ?? e.key,
            };
          })
          .toList();

      _isLoaded = true;
      debugPrint(
        'TFLite model loaded: ${_labels.length} labels '
        '(input: ${_interpreter!.getInputTensor(0).shape}, '
        'output: ${_interpreter!.getOutputTensor(0).shape})',
      );
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  /// Add one frame's 63 keypoints to the sliding window. Returns the live
  /// [SignResult] for real-time visual feedback, and marks [isStable] when consistent.
  SignResult? addFrame(List<double> keypoints) {
    if (keypoints.length != _keypointSize) {
      return null;
    }

    _frameBuffer.add(keypoints);
    if (_frameBuffer.length > _windowSize) {
      _frameBuffer.removeAt(0);
    }
    // Need at least 6 frames before evaluating sequence
    if (_frameBuffer.length < 6) return null;

    return _runInference();
  }

  SignResult? _runInference() {
    final interpreter = _interpreter;
    if (interpreter == null) return null;

    try {
      final List<List<double>> modelFrames = List.from(_frameBuffer);
      while (modelFrames.length < _windowSize) {
        modelFrames.insert(0, modelFrames.first);
      }
      final input = [modelFrames.sublist(modelFrames.length - _windowSize).map((f) => f.toList()).toList()];
      final numLabels = interpreter.getOutputTensor(0).shape.last;
      final output = [List<double>.filled(numLabels, 0.0)];

      interpreter.run(input, output);

      final scores = output[0];
      final maxIndex = scores.indexOf(scores.reduce(math.max));
      final confidence = scores[maxIndex];

      // Ignore low confidence noise
      if (confidence < _confidenceThreshold) return null;
      if (maxIndex >= _labels.length) return null;

      final labelData = _labels[maxIndex];
      final labelEn = labelData['en'] ?? maxIndex.toString();
      final labelHi = labelData['hi'] ?? maxIndex.toString();
      final gloss = labelData['key'] ?? labelEn.toUpperCase().replaceAll(' ', '_');

      final result = SignResult(
        labelEn: labelEn,
        labelHi: labelHi,
        gloss: gloss,
        confidence: confidence.clamp(0.0, 1.0),
      );

      return _debounceResult(result);
    } catch (e) {
      debugPrint('TFLite inference error: $e');
      return null;
    }
  }

  SignResult? _debounceResult(SignResult result) {
    _recentPredictions.add(result.gloss);
    if (_recentPredictions.length > _stabilityWindow) {
      _recentPredictions.removeAt(0);
    }

    // A sign is stable if confidence is high and it dominates the recent window
    final matchCount = _recentPredictions.where((p) => p == result.gloss).length;
    final isStable = result.confidence >= _stableConfidenceThreshold &&
        _recentPredictions.length >= _stabilityWindow &&
        matchCount >= (_stabilityWindow - 1);

    return result.copyWith(isStable: isStable);
  }

  /// Reset the sliding window and debounce state (e.g. on clear).
  void clearBuffer() {
    _frameBuffer.clear();
    _recentPredictions.clear();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
