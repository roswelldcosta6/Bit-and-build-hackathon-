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

  // Sliding window: collect 30 frames, then run inference on every new frame.
  static const int _windowSize = 30;
  static const int _keypointSize = 63; // 21 landmarks x 3 coords
  static const double _confidenceThreshold = 0.45;
  static const int _stabilityWindow = 5; // stable for N consecutive runs

  final List<List<double>> _frameBuffer = [];
  final List<String> _recentPredictions = [];
  SignResult? _lastEmittedResult;

  bool get isLoaded => _isLoaded;

  /// Load the TFLite model and bilingual labels from assets.
  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      final labelsJson = await rootBundle.loadString(
        'assets/labels_bilingual.json',
      );
      final Map<String, dynamic> rawLabels = json.decode(labelsJson);
      // Keys are the class indices as strings ("0".."162"); keep them ordered
      // so inference output index i maps to class i.
      final entries =
          rawLabels.entries.toList()..sort((a, b) {
            final ai = int.tryParse(a.key) ?? 0;
            final bi = int.tryParse(b.key) ?? 0;
            return ai.compareTo(bi);
          });
      _labels = entries
          .map((e) => Map<String, String>.from(e.value as Map))
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

  /// Add one frame's 63 keypoints to the sliding window. Returns a stable
  /// [SignResult] when the model has produced a consistent prediction,
  /// otherwise null.
  SignResult? addFrame(List<double> keypoints) {
    if (keypoints.length != _keypointSize) {
      debugPrint('Expected $_keypointSize keypoints, got ${keypoints.length}');
      return null;
    }

    _frameBuffer.add(keypoints);
    if (_frameBuffer.length > _windowSize) {
      _frameBuffer.removeAt(0);
    }
    if (_frameBuffer.length < _windowSize) return null;

    return _runInference();
  }

  SignResult? _runInference() {
    final interpreter = _interpreter;
    if (interpreter == null) return null;

    try {
      final input = [_frameBuffer.map((f) => f.toList()).toList()];
      final numLabels = interpreter.getOutputTensor(0).shape.last;
      final output = [List<double>.filled(numLabels, 0.0)];

      interpreter.run(input, output);

      final scores = output[0];
      final maxIndex = scores.indexOf(scores.reduce(math.max));
      final confidence = scores[maxIndex];

      if (confidence < _confidenceThreshold) return null;
      if (maxIndex >= _labels.length) return null;

      final labelData = _labels[maxIndex];
      final result = SignResult(
        labelEn: labelData['en'] ?? maxIndex.toString(),
        labelHi: labelData['hi'] ?? maxIndex.toString(),
        gloss: maxIndex.toString(),
        confidence: confidence,
      );

      return _debounceResult(result);
    } catch (e) {
      debugPrint('TFLite inference error: $e');
      return null;
    }
  }

  /// Only emit when the same sign wins [stabilityWindow] consecutive runs and
  /// differs from the last emitted sign.
  SignResult? _debounceResult(SignResult result) {
    _recentPredictions.add(result.gloss);
    if (_recentPredictions.length > _stabilityWindow) {
      _recentPredictions.removeAt(0);
    }

    if (_recentPredictions.length >= _stabilityWindow &&
        _recentPredictions.every((p) => p == result.gloss)) {
      if (_lastEmittedResult?.gloss != result.gloss) {
        _lastEmittedResult = result;
        _recentPredictions.clear();
        return result.copyWith(isStable: true);
      }
    }
    return null;
  }

  /// Reset the sliding window and debounce state (e.g. on clear).
  void clearBuffer() {
    _frameBuffer.clear();
    _recentPredictions.clear();
    _lastEmittedResult = null;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
