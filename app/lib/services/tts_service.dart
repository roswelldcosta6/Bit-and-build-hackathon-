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

    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5); // Natural conversational rate
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true); // Crucial: wait for speech to finish!

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Set the TTS language preference: 'en', 'hi', or 'both'.
  void setLanguage(String language) {
    assert(['en', 'hi', 'both'].contains(language));
    _selectedLanguage = language;
  }

  /// Speak the recognized sign or accumulated sentence in the configured language(s).
  Future<void> speakSign({
    required String textEn,
    required String textHi,
  }) async {
    if (!_isInitialized) await initialize();
    await stop();

    final en = textEn.trim();
    final hi = textHi.trim();

    switch (_selectedLanguage) {
      case 'en':
        if (en.isNotEmpty) await _speakInLanguage(en, 'en-IN');
      case 'hi':
        if (hi.isNotEmpty) {
          await _speakInLanguage(hi, 'hi-IN');
        } else if (en.isNotEmpty) {
          await _speakInLanguage(en, 'en-IN');
        }
      case 'both':
        if (en.isNotEmpty) {
          await _speakInLanguage(en, 'en-IN');
        }
        if (hi.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 250));
          await _speakInLanguage(hi, 'hi-IN');
        }
    }
  }

  Future<void> _speakInLanguage(String text, String languageCode) async {
    try {
      // Check language availability with fallback
      dynamic isAvailable = false;
      try {
        isAvailable = await _tts.isLanguageAvailable(languageCode);
      } catch (_) {}

      final effectiveLang = (isAvailable == true || isAvailable == 1)
          ? languageCode
          : (languageCode.startsWith('hi') ? 'hi' : 'en-US');

      await _tts.setLanguage(effectiveLang);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error ($languageCode): $e');
      // Fallback attempt with default language
      try {
        await _tts.setLanguage('en-US');
        await _tts.speak(text);
      } catch (_) {}
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
