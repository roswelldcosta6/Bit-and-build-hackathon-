import '../models/sign_result.dart';

/// Mode A sign-recognition state: camera -> keypoint -> inference -> result.
class SignRecognitionState {
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

  final bool isInitialized;
  final bool isProcessing;
  final SignResult? currentResult;
  final List<SignResult> sentence;
  final String sentenceEn;
  final String sentenceHi;
  final double confidence;
  final String? errorMessage;

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
  }) => SignRecognitionState(
    isInitialized: isInitialized ?? this.isInitialized,
    isProcessing: isProcessing ?? this.isProcessing,
    currentResult: clearCurrentResult
        ? null
        : (currentResult ?? this.currentResult),
    sentence: sentence ?? this.sentence,
    sentenceEn: sentenceEn ?? this.sentenceEn,
    sentenceHi: sentenceHi ?? this.sentenceHi,
    confidence: confidence ?? this.confidence,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}
