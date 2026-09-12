import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sign_result.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import 'sign_provider.dart';

/// Person 2: Mode B avatar state
/// Manages speech input → API gloss mapping → avatar animation sequence.
class AvatarState {
  final bool isListening;
  final bool isProcessing;
  final ISLGlossResponse? glossResponse;
  final List<String> glosses;
  final List<int> clipIds;
  final String subtitle;
  final int totalDurationMs;
  final String? errorMessage;
  final String inputText;

  const AvatarState({
    this.isListening = false,
    this.isProcessing = false,
    this.glossResponse,
    this.glosses = const [],
    this.clipIds = const [],
    this.subtitle = '',
    this.totalDurationMs = 0,
    this.errorMessage,
    this.inputText = '',
  });

  AvatarState copyWith({
    bool? isListening,
    bool? isProcessing,
    ISLGlossResponse? glossResponse,
    bool clearGlossResponse = false,
    List<String>? glosses,
    List<int>? clipIds,
    String? subtitle,
    int? totalDurationMs,
    String? errorMessage,
    bool clearError = false,
    String? inputText,
  }) {
    return AvatarState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      glossResponse:
          clearGlossResponse ? null : (glossResponse ?? this.glossResponse),
      glosses: glosses ?? this.glosses,
      clipIds: clipIds ?? this.clipIds,
      subtitle: subtitle ?? this.subtitle,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      inputText: inputText ?? this.inputText,
    );
  }
}

/// Notifier for Mode B avatar animation pipeline
class AvatarNotifier extends StateNotifier<AvatarState> {
  final ApiService _apiService;
  final TtsService _ttsService;

  AvatarNotifier({
    required ApiService apiService,
    required TtsService ttsService,
  })  : _apiService = apiService,
        _ttsService = ttsService,
        super(const AvatarState());

  /// Process text input through /text-to-isl API
  Future<void> processText(String text, {String? lang}) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      isProcessing: true,
      inputText: text,
      clearError: true,
    );

    try {
      final response = await _apiService.textToISL(
        text: text,
        lang: lang,
      );

      if (response == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Failed to process text',
        );
        return;
      }

      state = state.copyWith(
        isProcessing: false,
        glossResponse: response,
        glosses: response.glosses,
        clipIds: response.clipIds,
        subtitle: response.subtitle,
        totalDurationMs: response.totalDurationMs,
      );

      // Speak the subtitle text
      await _ttsService.speakSentence(
        sentenceEn: response.originalText,
        sentenceHi: response.originalText,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Process audio file through /speech-to-isl API
  Future<void> processAudio(String audioPath) async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
    );

    try {
      final audioFile = File(audioPath);
      final response = await _apiService.speechToISL(
        audioFile: audioFile,
      );

      if (response == null) {
        state = state.copyWith(
          isProcessing: false,
          errorMessage: 'Failed to process audio',
        );
        return;
      }

      state = state.copyWith(
        isProcessing: false,
        glossResponse: response,
        glosses: response.glosses,
        clipIds: response.clipIds,
        subtitle: response.subtitle,
        totalDurationMs: response.totalDurationMs,
        inputText: response.originalText,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Error processing audio: $e',
      );
    }
  }

  /// Reset the avatar state
  void reset() {
    state = const AvatarState();
  }
}

/// Provider for the Mode B avatar state
final avatarProvider =
    StateNotifierProvider<AvatarNotifier, AvatarState>((ref) {
  return AvatarNotifier(
    apiService: ref.watch(apiServiceProvider),
    ttsService: ref.watch(ttsServiceProvider),
  );
});
