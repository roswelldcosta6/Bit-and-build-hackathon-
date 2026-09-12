import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/tflite_service.dart';
import '../services/tts_service.dart';
import 'settings_controller.dart';
import 'sign_recognition_base.dart';
import 'sign_recognition_state.dart';

export 'sign_recognition_state.dart';

/// Orchestrates the full Mode A pipeline: camera frames -> MediaPipe
/// keypoints -> TFLite sliding-window inference -> stable sign -> TTS +
/// backend history log. (Mobile implementation — tflite_flutter needs dart:ffi.)
base class SignRecognitionNotifier extends SignRecognitionNotifierBase {
  CameraService? _cameraService;
  final TfliteService _tfliteService = TfliteService();
  TtsService? _ttsService;
  bool _frameBusy = false;
  bool _disposed = false;

  @override
  SignRecognitionState build() {
    // Release native resources when the provider is disposed.
    ref.onDispose(() {
      _disposed = true;
      _cameraService?.stopImageStream();
      unawaited(_cameraService?.dispose());
      _tfliteService.dispose();
      _ttsService?.dispose();
    });
    return const SignRecognitionState();
  }

  /// Exposed for the camera preview widget; null until the camera is up.
  @override
  CameraController? get cameraController => _cameraService?.controller;

  @override
  bool get cameraReady =>
      _cameraService?.isInitialized == true &&
      cameraController?.value.isInitialized == true;

  /// Initialize camera + model, then start processing frames.
  @override
  Future<void> startProcessing() async {
    if (state.isProcessing || _disposed) return;
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      _cameraService ??= CameraService();
      await _cameraService!.initialize();

      await _tfliteService.loadModel();

      _ttsService ??= TtsService();
      await _ttsService!.initialize();
      _applyLanguagePreference();

      if (_disposed) return;
      state = state.copyWith(isInitialized: true, isProcessing: true);

      _cameraService!.startImageStream(_onCameraFrame);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isProcessing: false,
        isInitialized: false,
        errorMessage: 'Failed to initialize: $e',
      );
    }
  }

  /// Stop processing and release the camera (kept for a later restart).
  @override
  Future<void> stopProcessing() async {
    await _cameraService?.stopImageStream();
    _tfliteService.clearBuffer();
    await _cameraService?.pause();
    if (_disposed) return;
    state = state.copyWith(
      isInitialized: false,
      isProcessing: false,
      clearCurrentResult: true,
    );
  }

  /// Process one camera frame through the pipeline.
  Future<void> _onCameraFrame(CameraImage image) async {
    // Skip frames while the previous one is still in flight — ML Kit cannot
    // process concurrent images.
    if (_frameBusy || !state.isProcessing || _disposed) return;
    _frameBusy = true;

    try {
      final keypoints = await _cameraService?.extractKeypoints(image);
      if (keypoints == null || _disposed) return;

      final result = _tfliteService.addFrame(keypoints);
      if (result == null || _disposed) return;

      final newSentence = [...state.sentence, result];
      final sentenceEn = newSentence.map((r) => r.labelEn).join(' ');
      final sentenceHi = newSentence.map((r) => r.labelHi).join(' ');

      state = state.copyWith(
        currentResult: result,
        sentence: newSentence,
        sentenceEn: sentenceEn,
        sentenceHi: sentenceHi,
        confidence: result.confidence,
      );

      // Speak the recognized sign aloud (best-effort, never blocks frames).
      unawaited(
        _ttsService?.speakSign(
          textEn: result.labelEn,
          textHi: result.labelHi,
        ),
      );

      // Log to backend history (fire-and-forget; guests/offline are fine).
      ApiService? api;
      try {
        api = ref.read(apiServiceProvider);
      } catch (_) {}
      if (api != null) {
        unawaited(
          api
              .addHistoryEntry(
                mode: 'MODE_A',
                inputContent: 'Sign: ${result.gloss}',
                outputContent: '${result.labelEn} / ${result.labelHi}',
                detectedLang: 'isl',
                glosses: [result.gloss],
              )
              .catchError((_) {}),
        );
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    } finally {
      _frameBusy = false;
    }
  }

  /// Clear the sentence and start a fresh recognition window.
  @override
  void clearSentence() {
    _tfliteService.clearBuffer();
    state = state.copyWith(
      clearCurrentResult: true,
      sentence: [],
      sentenceEn: '',
      sentenceHi: '',
      confidence: 0.0,
    );
  }

  void _applyLanguagePreference() {
    final tts = _ttsService;
    if (tts == null) return;
    try {
      final settings = ref.read(settingsProvider);
      tts.setLanguage(switch (settings.speechLanguage) {
        SpeechLanguage.english => 'en',
        SpeechLanguage.hindi => 'hi',
        SpeechLanguage.both => 'both',
      });
    } catch (_) {
      // Settings unavailable — keep the default.
    }
  }
}

/// Mode A sign recognition state provider (mobile implementation).
final signRecognitionProvider = NotifierProvider<SignRecognitionNotifierBase,
    SignRecognitionState>(SignRecognitionNotifier.new);
