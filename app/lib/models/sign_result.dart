/// Person 2: Core data models for SignBridge
library;

/// Result of a single sign recognition inference
class SignResult {
  final String labelEn;
  final String labelHi;
  final String gloss;
  final double confidence;
  final bool isStable;
  final DateTime timestamp;

  const SignResult({
    required this.labelEn,
    required this.labelHi,
    required this.gloss,
    required this.confidence,
    this.isStable = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _NowPlaceholder();

  /// Mock result for testing without camera/model
  factory SignResult.mock({String gloss = 'HELP'}) {
    const mockData = {
      'HELP': ('Help', 'मदद'),
      'DOCTOR': ('Doctor', 'डॉक्टर'),
      'WATER': ('Water', 'पानी'),
      'HOSPITAL': ('Hospital', 'अस्पताल'),
      'PAIN': ('Pain', 'दर्द'),
      'HELLO': ('Hello / Namaste', 'नमस्ते'),
      'THANK_YOU': ('Thank You', 'धन्यवाद'),
    };
    final (en, hi) = mockData[gloss] ?? (gloss, gloss);
    return SignResult(
      labelEn: en,
      labelHi: hi,
      gloss: gloss,
      confidence: 0.92,
      isStable: true,
    );
  }

  @override
  String toString() => 'SignResult($gloss: $labelEn/$labelHi, ${(confidence * 100).toStringAsFixed(0)}%)';
}

// ignore: avoid_annotating_with_dynamic
class _NowPlaceholder implements DateTime {
  const _NowPlaceholder();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now().noSuchMethod(invocation);
}

/// Response from backend /predict endpoint
class PredictResponse {
  final String signLabel;
  final String labelEn;
  final String labelHi;
  final double confidence;
  final bool isStable;

  const PredictResponse({
    required this.signLabel,
    required this.labelEn,
    required this.labelHi,
    required this.confidence,
    required this.isStable,
  });

  factory PredictResponse.fromJson(Map<String, dynamic> json) {
    return PredictResponse(
      signLabel: json['sign_label'] as String,
      labelEn: json['label_en'] as String,
      labelHi: json['label_hi'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      isStable: json['is_stable'] as bool,
    );
  }
}

/// Response from backend /speech-to-isl or /text-to-isl
class ISLGlossResponse {
  final String originalText;
  final String detectedLang;
  final List<String> glosses;
  final List<int> clipIds;
  final List<String> videoFilenames;
  final String subtitle;
  final List<String> grammarApplied;
  final int totalDurationMs;

  const ISLGlossResponse({
    required this.originalText,
    required this.detectedLang,
    required this.glosses,
    required this.clipIds,
    required this.videoFilenames,
    required this.subtitle,
    required this.grammarApplied,
    required this.totalDurationMs,
  });

  factory ISLGlossResponse.fromJson(Map<String, dynamic> json) {
    return ISLGlossResponse(
      originalText: json['original_text'] as String,
      detectedLang: json['detected_lang'] as String,
      glosses: List<String>.from(json['glosses'] ?? []),
      clipIds: List<int>.from(json['clip_ids'] ?? []),
      videoFilenames: List<String>.from(json['video_filenames'] ?? []),
      subtitle: json['subtitle'] as String? ?? '',
      grammarApplied: List<String>.from(json['grammar_applied'] ?? []),
      totalDurationMs: json['total_duration_ms'] as int? ?? 0,
    );
  }
}

/// History item from backend
class HistoryItem {
  final String id;
  final String timestamp;
  final String mode;
  final String inputContent;
  final String outputContent;
  final String? detectedLang;
  final List<String>? glosses;

  const HistoryItem({
    required this.id,
    required this.timestamp,
    required this.mode,
    required this.inputContent,
    required this.outputContent,
    this.detectedLang,
    this.glosses,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as String,
      timestamp: json['timestamp'] as String,
      mode: json['mode'] as String,
      inputContent: json['input_content'] as String,
      outputContent: json['output_content'] as String,
      detectedLang: json['detected_lang'] as String?,
      glosses: json['glosses'] != null ? List<String>.from(json['glosses']) : null,
    );
  }
}
