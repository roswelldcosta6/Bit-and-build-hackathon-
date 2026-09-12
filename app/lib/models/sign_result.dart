/// Result of a single ISL sign recognition inference (from the ML feature).
class SignResult {
  const SignResult({
    required this.labelEn,
    required this.labelHi,
    required this.gloss,
    required this.confidence,
    this.isStable = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const _EpochZero();

  final String labelEn;
  final String labelHi;
  final String gloss;
  final double confidence;
  final bool isStable;
  final DateTime timestamp;

  SignResult copyWith({
    String? labelEn,
    String? labelHi,
    String? gloss,
    double? confidence,
    bool? isStable,
  }) => SignResult(
    labelEn: labelEn ?? this.labelEn,
    labelHi: labelHi ?? this.labelHi,
    gloss: gloss ?? this.gloss,
    confidence: confidence ?? this.confidence,
    isStable: isStable ?? this.isStable,
    timestamp: timestamp,
  );

  @override
  String toString() =>
      'SignResult($gloss: $labelEn/$labelHi, ${(confidence * 100).toStringAsFixed(0)}%)';
}

/// Const-safe stand-in so [SignResult] can stay const-constructible.
class _EpochZero implements DateTime {
  const _EpochZero();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      DateTime.fromMillisecondsSinceEpoch(0).noSuchMethod(invocation);
}
