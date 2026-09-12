import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_recognition_base.dart';
import 'sign_recognition_state.dart';

export 'sign_recognition_state.dart';

/// Mode A sign-recognition state (web stub).
///
/// The real ISL ML pipeline (tflite_flutter) requires dart:ffi, which the
/// browser cannot run — so the web build ships the full UI with a clear
/// "camera recognition is device-only" notice instead of native inference.
/// No camera code is imported here, keeping the web bundle clean.
base class WebSignRecognitionNotifier extends SignRecognitionNotifierBase {
  @override
  SignRecognitionState build() => const SignRecognitionState();

  @override
  Future<void> startProcessing() async {
    state = state.copyWith(
      isProcessing: false,
      errorMessage:
          'Live sign recognition runs on the Android/iOS app — the browser '
          'cannot host the on-device ISL model.',
    );
  }

  @override
  Future<void> stopProcessing() async {
    state = state.copyWith(isProcessing: false, clearCurrentResult: true);
  }

  @override
  void clearSentence() {
    state = state.copyWith(
      clearCurrentResult: true,
      sentence: [],
      sentenceEn: '',
      sentenceHi: '',
      confidence: 0.0,
    );
  }

  @override
  dynamic get cameraController => null;

  @override
  bool get cameraReady => false;
}

final signRecognitionProvider = NotifierProvider<SignRecognitionNotifierBase,
    SignRecognitionState>(WebSignRecognitionNotifier.new);
