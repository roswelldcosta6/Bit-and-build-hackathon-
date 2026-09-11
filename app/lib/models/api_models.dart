class AvatarAction {
  const AvatarAction({
    required this.gloss,
    required this.durationMs,
    required this.poseEndpoint,
    this.expression = 'NEUTRAL',
  });
  final String gloss;
  final int durationMs;
  final String poseEndpoint;
  final String expression;
  factory AvatarAction.fromJson(Map<String, dynamic> json) => AvatarAction(
    gloss: json['gloss'] as String,
    durationMs: json['duration_ms'] as int? ?? 1200,
    poseEndpoint: json['pose_endpoint'] as String,
    expression: json['facial_expression'] as String? ?? 'NEUTRAL',
  );
}

class TranslationResult {
  const TranslationResult({
    required this.originalText,
    required this.subtitle,
    required this.language,
    required this.glosses,
    required this.actions,
  });
  final String originalText;
  final String subtitle;
  final String language;
  final List<String> glosses;
  final List<AvatarAction> actions;
  factory TranslationResult.fromJson(Map<String, dynamic> json) =>
      TranslationResult(
        originalText: json['original_text'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        language: json['detected_lang'] as String? ?? 'en',
        glosses: (json['glosses'] as List<dynamic>? ?? []).cast<String>(),
        actions: (json['animation_sequence'] as List<dynamic>? ?? [])
            .map((item) => AvatarAction.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
}

class SkeletalPose {
  const SkeletalPose({
    required this.gloss,
    required this.durationMs,
    required this.frames,
  });
  final String gloss;
  final int durationMs;
  final List<Map<String, List<double>>> frames;
  factory SkeletalPose.fromJson(Map<String, dynamic> json) => SkeletalPose(
    gloss: json['gloss'] as String,
    durationMs: json['duration_ms'] as int? ?? 1200,
    frames: (json['frames'] as List<dynamic>? ?? []).map((frame) {
      final raw =
          (frame as Map<String, dynamic>)['joints'] as Map<String, dynamic>;
      return raw.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((n) => (n as num).toDouble()).toList(),
        ),
      );
    }).toList(),
  );
}
