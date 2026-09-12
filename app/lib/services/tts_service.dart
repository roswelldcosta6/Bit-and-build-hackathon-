import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Person 2: Text-to-Speech service
/// Supports Hindi (hi-IN) and English (en-IN) voices.
/// User can configure: speak in English, Hindi, or both sequentially.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  String _selectedLanguage = 'both'; // 'en', 'hi', or 'both'
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;
  String get selectedLanguage => _selectedLanguage;

  /// Initialize TTS engine with bilingual voice support
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure general settings
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.45); // Slightly slower for clarity
    await _tts.setPitch(1.0);

    // Set up language completion handler
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      _isSpeaking = false;
    });

    // Check available voices
    final voices = await _tts.getVoices;
    debugPrint('Available TTS voices: ${voices.length}');

    _isInitialized = true;
  }

  /// Set the TTS language preference
  void setLanguage(String language) {
    assert(['en', 'hi', 'both'].contains(language));
    _selectedLanguage = language;
  }

  /// Speak the recognized sign in the configured language(s)
  Future<void> speakSign({
    required String textEn,
    required String textHi,
  }) async {
    if (!_isInitialized) await initialize();
    await stop(); // Stop any current speech

    switch (_selectedLanguage) {
      case 'en':
        await _speakInLanguage(textEn, 'en-IN');
        break;
      case 'hi':
        await _speakInLanguage(textHi, 'hi-IN');
        break;
      case 'both':
        // Speak English first, then Hindi
        await _speakInLanguage(textEn, 'en-IN');
        await Future.delayed(const Duration(milliseconds: 300));
        await _speakInLanguage(textHi, 'hi-IN');
        break;
    }
  }

  /// Speak text in a specific language
  Future<void> _speakInLanguage(String text, String languageCode) async {
    if (text.isEmpty) return;

    try {
      await _tts.setLanguage(languageCode);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error ($languageCode): $e');
      // Fallback: try without specific language
      try {
        await _tts.speak(text);
      } catch (e2) {
        debugPrint('TTS fallback error: $e2');
      }
    }
  }

  /// Speak a full sentence (accumulated signs)
  Future<void> speakSentence({
    required String sentenceEn,
    required String sentenceHi,
  }) async {
    if (!_isInitialized) await initialize();
    await stop();

    if (sentenceEn.isNotEmpty) {
      await _speakInLanguage(sentenceEn, 'en-IN');
    }
    if (_selectedLanguage == 'both' || _selectedLanguage == 'hi') {
      await Future.delayed(const Duration(milliseconds: 500));
      if (sentenceHi.isNotEmpty) {
        await _speakInLanguage(sentenceHi, 'hi-IN');
      }
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }

  /// Pause speech
  Future<void> pause() async {
    await _tts.pause();
  }

  /// Dispose TTS resources
  Future<void> dispose() async {
    await _tts.stop();
    _isInitialized = false;
  }
}
