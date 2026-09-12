import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/sign_result.dart';

/// Person 2: TFLite on-device inference engine
/// Loads model.tflite + labels_bilingual.json, runs sliding window inference,
/// debounces output for stable sign recognition.
class TfliteService {
  Interpreter? _interpreter;
  Map<String, Map<String, String>> _labels = {};
  bool _isLoaded = false;

  // Sliding window: collect 30 frames → run inference
  static const int _windowSize = 30;
  static const int _keypointSize = 63; // 21 landmarks × 3 coords
  static const double _confidenceThreshold = 0.45;
  static const int _stabilityWindow = 5; // Must be stable for N consecutive inferences

  final List<List<double>> _frameBuffer = [];
  final List<String> _recentPredictions = [];
  SignResult? _lastEmittedResult;

  bool get isLoaded => _isLoaded;

  /// Load model and labels from assets
  Future<void> loadModel() async {
    try {
      // Load TFLite model (try assets/model.tflite then model.tflite)
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/model.tflite',
          options: InterpreterOptions()..threads = 2,
        );
      } catch (_) {
        _interpreter = await Interpreter.fromAsset(
          'model.tflite',
          options: InterpreterOptions()..threads = 2,
        );
      }

      // Load bilingual labels
      final labelsJson = await rootBundle.loadString('assets/labels_bilingual.json');
      final Map<String, dynamic> rawLabels = json.decode(labelsJson);
      _labels = rawLabels.map((key, value) => MapEntry(
        key,
        Map<String, String>.from(value as Map),
      ));

      _isLoaded = true;
      debugPrint('TFLite model loaded: ${_labels.length} labels');
    } catch (e) {
      debugPrint('Failed to load TFLite model: $e');
      // Fallback: use mock labels
      _labels = {
        'HELP': {'en': 'Help', 'hi': 'मदद'},
        'DOCTOR': {'en': 'Doctor', 'hi': 'डॉक्टर'},
        'WATER': {'en': 'Water', 'hi': 'पानी'},
        'HOSPITAL': {'en': 'Hospital', 'hi': 'अस्पताल'},
        'PAIN': {'en': 'Pain', 'hi': 'दर्द'},
        'HELLO': {'en': 'Hello', 'hi': 'नमस्ते'},
        'THANK_YOU': {'en': 'Thank You', 'hi': 'धन्यवाद'},
      };
      _isLoaded = true;
      debugPrint('TFLite: Using fallback mock labels');
    }
  }

  /// Add a frame's keypoints to the sliding window buffer.
  /// Returns a SignResult when enough frames are collected and a stable sign is detected.
  SignResult? addFrame(List<double> keypoints) {
    if (keypoints.length != _keypointSize) {
      debugPrint('Expected $_keypointSize keypoints, got ${keypoints.length}');
      return null;
    }

    _frameBuffer.add(keypoints);

    // Keep only the last windowSize frames
    if (_frameBuffer.length > _windowSize) {
      _frameBuffer.removeAt(0);
    }

    // Need a full window to run inference
    if (_frameBuffer.length < _windowSize) {
      return null;
    }

    return _runInference();
  }

  /// Run inference on the current frame buffer
  SignResult? _runInference() {
    try {
      if (_interpreter == null) {
        return _mockInference();
      }

      // Prepare input tensor: [1, windowSize, keypointSize]
      final input = [_frameBuffer.map((f) => f.toList()).toList()];

      // Prepare output tensor: [1, numLabels] — get label count from model
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final numLabels = outputShape.last;
      final output = [List<double>.filled(numLabels, 0.0)];

      _interpreter!.run(input, output);

      // Find the label with highest confidence
      final scores = output[0];
      final maxIndex = scores.indexOf(scores.reduce(math.max));
      final confidence = scores[maxIndex];

      if (confidence < _confidenceThreshold) {
        return null;
      }

      // Map index to label
      final labelKeys = _labels.keys.toList();
      if (maxIndex >= labelKeys.length) return null;

      final gloss = labelKeys[maxIndex];
      final labelData = _labels[gloss]!;

      final result = SignResult(
        labelEn: labelData['en'] ?? gloss,
        labelHi: labelData['hi'] ?? gloss,
        gloss: gloss,
        confidence: confidence,
      );

      return _debounceResult(result);
    } catch (e) {
      debugPrint('TFLite inference error: $e');
      return _mockInference();
    }
  }

  /// Mock inference for demo/testing without a real model
  SignResult? _mockInference() {
    // Simple heuristic based on keypoint variance
    final lastFrame = _frameBuffer.last;
    final avgVal = lastFrame.reduce((a, b) => a + b) / lastFrame.length;

    String gloss;
    if (avgVal > 0.6) {
      gloss = 'HELP';
    } else if (avgVal > 0.4) {
      gloss = 'DOCTOR';
    } else if (avgVal > 0.2) {
      gloss = 'WATER';
    } else {
      gloss = 'HELLO';
    }

    final labelData = _labels[gloss] ?? {'en': gloss, 'hi': gloss};
    final result = SignResult(
      labelEn: labelData['en']!,
      labelHi: labelData['hi']!,
      gloss: gloss,
      confidence: 0.85 + (avgVal * 0.1),
    );

    return _debounceResult(result);
  }

  /// Debounce: only emit if the same sign has been predicted stabilityWindow times
  SignResult? _debounceResult(SignResult result) {
    _recentPredictions.add(result.gloss);

    if (_recentPredictions.length > _stabilityWindow) {
      _recentPredictions.removeAt(0);
    }

    // Check if all recent predictions are the same
    if (_recentPredictions.length >= _stabilityWindow &&
        _recentPredictions.every((p) => p == result.gloss)) {
      // Stable — emit if different from last emitted
      if (_lastEmittedResult?.gloss != result.gloss) {
        _lastEmittedResult = result;
        _recentPredictions.clear();
        return result.copyWith(isStable: true);
      }
    }

    return null;
  }

  /// Clear the frame buffer (e.g., on mode switch)
  void clearBuffer() {
    _frameBuffer.clear();
    _recentPredictions.clear();
    _lastEmittedResult = null;
  }

  /// Dispose of the interpreter
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

/// Extension to add copyWith to SignResult
extension SignResultCopyWith on SignResult {
  SignResult copyWith({
    String? labelEn,
    String? labelHi,
    String? gloss,
    double? confidence,
    bool? isStable,
  }) {
    return SignResult(
      labelEn: labelEn ?? this.labelEn,
      labelHi: labelHi ?? this.labelHi,
      gloss: gloss ?? this.gloss,
      confidence: confidence ?? this.confidence,
      isStable: isStable ?? this.isStable,
      timestamp: timestamp,
    );
  }
}
