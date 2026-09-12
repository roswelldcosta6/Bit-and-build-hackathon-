import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sign_recognition_state.dart';

/// Shared surface of the Mode A recognition notifier across platforms.
/// The concrete implementations are chosen via conditional imports in
/// `sign_recognition_provider.dart`.
abstract base class SignRecognitionNotifierBase
    extends Notifier<SignRecognitionState> {
  /// Initialize camera + model, then start processing frames.
  Future<void> startProcessing();

  /// Stop processing and release platform resources.
  Future<void> stopProcessing();

  /// Clear the accumulated sentence and recognition window.
  void clearSentence();

  /// Native camera controller when the camera is running; null otherwise.
  Object? get cameraController;

  /// Whether the camera preview is ready to render.
  bool get cameraReady;
}
