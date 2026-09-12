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

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.role,
    required this.preferredLang,
    required this.createdAt,
  });
  final String userId;
  final String email;
  final String fullName;
  final String role;
  final String preferredLang;
  final String createdAt;
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['user_id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String,
    role: json['role'] as String? ?? 'deaf_user',
    preferredLang: json['preferred_lang'] as String? ?? 'en',
    createdAt: json['created_at'] as String? ?? '',
  );
}

class AuthResult {
  const AuthResult({required this.token, required this.user});
  final String token;
  final UserProfile user;
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    token: json['token'] as String,
    user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
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
