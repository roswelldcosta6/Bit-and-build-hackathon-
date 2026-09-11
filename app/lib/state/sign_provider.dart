import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../models/sign_result.dart';
import '../services/camera_service.dart';
import '../services/tflite_service.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';

/// Person 2: Mode A sign recognition state
/// Manages camera → keypoint → inference → result → TTS pipeline.
class SignRecognitionState {
  final bool isInitialized;
  final bool isProcessing;
  final SignResult? currentResult;
  final List<SignResult> sentence;
  final String sentenceEn;
  final String sentenceHi;
  final double confidence;
  final String? errorMessage;

  const SignRecognitionState({
    this.isInitialized = false,
    this.isProcessing = false,
    this.currentResult,
    this.sentence = const [],
    this.sentenceEn = '',
    this.sentenceHi = '',
    this.confidence = 0.0,
    this.errorMessage,
  });

  SignRecognitionState copyWith({
    bool? isInitialized,
    bool? isProcessing,
    SignResult? currentResult,
    bool clearCurrentResult = false,
    List<SignResult>? sentence,
    String? sentenceEn,
    String? sentenceHi,
    double? confidence,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignRecognitionState(
      isInitialized: isInitialized ?? this.isInitialized,
      isProcessing: isProcessing ?? this.isProcessing,
      currentResult: clearCurrentResult ? null : (currentResult ?? this.currentResult),
      sentence: sentence ?? this.sentence,
      sentenceEn: sentenceEn ?? this.sentenceEn,
      sentenceHi: sentenceHi ?? this.sentenceHi,
      confidence: confidence ?? this.confidence,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier that orchestrates the full Mode A pipeline
class SignRecognitionNotifier extends StateNotifier<SignRecognitionState> {
  final CameraService _cameraService;
  final TfliteService _tfliteService;
  final ApiService _apiService;
  final TtsService _ttsService;

  SignRecognitionNotifier({
    required CameraService cameraService,
    required TfliteService tfliteService,
    required ApiService apiService,
    required TtsService ttsService,
  })  : _cameraService = cameraService,
        _tfliteService = tfliteService,
        _apiService = apiService,
        _ttsService = ttsService,
        super(const SignRecognitionState());

  /// Initialize camera and TFLite model, then start processing frames
  Future<void> startProcessing() async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Initialize camera
      await _cameraService.initialize();

      // Load TFLite model
      await _tfliteService.loadModel();

      state = state.copyWith(isInitialized: true, isProcessing: false);

      // Start listening to camera frames
      _cameraService.startImageStream(_onCameraFrame);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to initialize: $e',
      );
    }
  }

  /// Process each camera frame through the pipeline
  Future<void> _onCameraFrame(CameraImage image) async {
    if (!state.isProcessing) return;

    try {
      // Step 1: Extract keypoints from camera frame
      final keypoints = await _cameraService.extractKeypoints(image);
      if (keypoints == null) return;

      // Step 2: Feed to TFLite inference engine
      final result = _tfliteService.addFrame(keypoints);

      // Step 3: If stable result, update state and trigger TTS
      if (result != null) {
        final newSentence = [...state.sentence, result];

        // Build bilingual sentences
        final sentenceEn = newSentence.map((r) => r.labelEn).join(' ');
        final sentenceHi = newSentence.map((r) => r.labelHi).join(' ');

        state = state.copyWith(
          currentResult: result,
          sentence: newSentence,
          sentenceEn: sentenceEn,
          sentenceHi: sentenceHi,
          confidence: result.confidence,
        );

        // Step 4: Trigger TTS
        await _ttsService.speakSign(
          textEn: result.labelEn,
          textHi: result.labelHi,
        );

        // Step 5: Log to backend history
        _apiService.addHistoryEntry(
          mode: 'MODE_A',
          inputContent: 'Sign: ${result.gloss}',
          outputContent: '${result.labelEn} / ${result.labelHi}',
          detectedLang: 'isl',
          glosses: [result.gloss],
        );
      }
    } catch (e) {
      debugPrint('Frame processing error: $e');
    }
  }

  /// Clear the current sentence and start fresh
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

  /// Stop processing and release camera
  Future<void> stopProcessing() async {
    await _cameraService.stopImageStream();
    _tfliteService.clearBuffer();
    await _cameraService.dispose();
    state = state.copyWith(
      isInitialized: false,
      isProcessing: false,
      clearCurrentResult: true,
    );
  }

  @override
  void dispose() {
    _cameraService.stopImageStream();
    _cameraService.dispose();
    _tfliteService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}

/// Provider for the shared service instances
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

final tfliteServiceProvider = Provider<TfliteService>((ref) {
  return TfliteService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

/// Provider for the Mode A sign recognition state
final signRecognitionProvider =
    StateNotifierProvider<SignRecognitionNotifier, SignRecognitionState>((ref) {
  return SignRecognitionNotifier(
    cameraService: ref.watch(cameraServiceProvider),
    tfliteService: ref.watch(tfliteServiceProvider),
    apiService: ref.watch(apiServiceProvider),
    ttsService: ref.watch(ttsServiceProvider),
  );
});
