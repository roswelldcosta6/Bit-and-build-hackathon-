import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech service (from the ML feature branch): bilingual
/// English/Hindi speech output for recognized signs.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  String _selectedLanguage = 'both'; // 'en', 'hi', or 'both'
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;
  String get selectedLanguage => _selectedLanguage;

  /// Initialize the TTS engine with bilingual voice support.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45); // slightly slower for clarity
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  /// Set the TTS language preference: 'en', 'hi', or 'both'.
  void setLanguage(String language) {
    assert(['en', 'hi', 'both'].contains(language));
    _selectedLanguage = language;
  }

  /// Speak the recognized sign in the configured language(s).
  Future<void> speakSign({
    required String textEn,
    required String textHi,
  }) async {
    if (!_isInitialized) await initialize();
    await stop();

    switch (_selectedLanguage) {
      case 'en':
        await _speakInLanguage(textEn, 'en-IN');
      case 'hi':
        await _speakInLanguage(textHi, 'hi-IN');
      case 'both':
        await _speakInLanguage(textEn, 'en-IN');
        await _speakInLanguage(textHi, 'hi-IN');
    }
  }

  Future<void> _speakInLanguage(String text, String languageCode) async {
    try {
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error ($languageCode): $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  void dispose() {
    stop();
  }
}
