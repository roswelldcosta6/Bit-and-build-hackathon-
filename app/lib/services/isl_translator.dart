// lib/services/isl_translator.dart
// Dart port of text_to_isl.py — exact same logic, loaded from Flutter assets.

import "dart:convert";
import "package:flutter/services.dart";

class GlossItem {
  final String gloss;
  final String video;
  const GlossItem({required this.gloss, required this.video});
}

enum TranslateStatus { complete, partial, unknown }

class TranslateResult {
  final TranslateStatus status;
  final List<GlossItem> glossSequence;
  final List<String> unknownWords;
  const TranslateResult({required this.status, required this.glossSequence, required this.unknownWords});
}

class IslTranslator {
  IslTranslator._();
  static final IslTranslator instance = IslTranslator._();

  bool _loaded = false;
  Map<String, dynamic> _dict = {};
  Map<String, List<String>> _phraseRulesMap = {};
  Map<String, String> _hindiWordMap = {};
  Set<String> _hindiDropWords = {};

  static const _wordSynonyms = <String, String>{
    "hi": "HELLO", "hey": "HELLO", "hola": "HELLO",
    "bye": "BYE", "goodbye": "BYE", "cya": "BYE",
    "thanks": "THANK_YOU", "thankyou": "THANK_YOU", "thx": "THANK_YOU",
    "u": "YOU", "ur": "YOUR", "im": "I",
  };

  static const _dropWords = {"a", "an", "the", "is", "am", "are", "was", "were"};

  Future<void> load() async {
    if (_loaded) return;

    final dictJson = await rootBundle.loadString("assets/data/isl_dictionary.json");
    _dict = Map<String, dynamic>.from(json.decode(dictJson));

    final hindiJson = await rootBundle.loadString("assets/data/hindi_lexicon.json");
    final hindiLex = Map<String, dynamic>.from(json.decode(hindiJson));
    final rawWords = Map<String, dynamic>.from(hindiLex["words"] ?? {});
    _hindiWordMap = rawWords.map((k, v) => MapEntry(k.trim().toLowerCase(), v as String));
    final rawDrop = List<dynamic>.from(hindiLex["drop_words"] ?? []);
    _hindiDropWords = rawDrop.map((w) => w.toString().trim().toLowerCase()).toSet();

    final phraseJson = await rootBundle.loadString("assets/data/phrase_rules.json");
    final rawPhrases = Map<String, dynamic>.from(json.decode(phraseJson));
    _phraseRulesMap = {};
    for (final entry in rawPhrases.entries) {
      if (entry.key.startsWith("_")) continue;
      _phraseRulesMap[_norm(entry.key)] = List<String>.from(entry.value as List);
    }
    final rawHindiPhrases = Map<String, dynamic>.from(hindiLex["phrases"] ?? {});
    for (final entry in rawHindiPhrases.entries) {
      _phraseRulesMap.putIfAbsent(_norm(entry.key), () => List<String>.from(entry.value as List));
    }

    _loaded = true;
  }

  TranslateResult translate(String text, {String language = "auto"}) {
    if (!_loaded) throw StateError("IslTranslator not loaded. Call load() first.");
    if (text.trim().isEmpty) {
      return const TranslateResult(status: TranslateStatus.unknown, glossSequence: [], unknownWords: []);
    }

    final detected = language == "auto" ? (_isHindi(text) ? "hi" : "en") : language;
    final normalized = _normText(text);
    final tokens = _tokenize(normalized, detected);

    final phraseGlosses = _phraseRulesMap[normalized];
    if (phraseGlosses != null) {
      final seq = phraseGlosses.where((g) => _dict.containsKey(g))
          .map((g) => GlossItem(gloss: g, video: _dict[g]["video"] as String)).toList();
      return TranslateResult(status: TranslateStatus.complete, glossSequence: seq, unknownWords: []);
    }

    final collapsed = _collapseBigrams(tokens);
    final (known, unknown) = _matchWords(collapsed);
    final seq = known.where((g) => _dict.containsKey(g))
        .map((g) => GlossItem(gloss: g, video: _dict[g]["video"] as String)).toList();

    if (known.isEmpty) return TranslateResult(status: TranslateStatus.unknown, glossSequence: [], unknownWords: unknown);
    if (unknown.isNotEmpty) return TranslateResult(status: TranslateStatus.partial, glossSequence: seq, unknownWords: unknown);
    return TranslateResult(status: TranslateStatus.complete, glossSequence: seq, unknownWords: []);
  }

  String _norm(String s) => s.trim().toLowerCase();

  bool _isHindi(String text) => text.runes.any((cp) => cp >= 0x0900 && cp <= 0x097F);

  String _normText(String text) {
    var t = text.trim().toLowerCase();
    // Strip common punctuation (danda, quotes, dashes, ellipsis, etc.)
    t = t.replaceAll(RegExp('[।॥\u201c\u201d\u2018\u2019\u2014\u2013\u2026\u00b7.,!?;:()\'"\\[\\]{}]'), '');
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _tokenize(String normalized, String lang) {
    final raw = normalized.split(" ").where((t) => t.isNotEmpty).toList();
    if (lang == "hi") {
      final out = <String>[];
      for (final tok in raw) {
        final nk = _norm(tok);
        if (_hindiDropWords.contains(nk)) continue;
        out.add(_hindiWordMap[nk] ?? tok);
      }
      return out;
    }
    return raw.where((t) => !_dropWords.contains(t)).toList();
  }

  List<String> _collapseBigrams(List<String> tokens) {
    final bigramMap = <String, String>{};
    for (final entry in _dict.entries) {
      final eng = (entry.value["english"] as String? ?? "").toLowerCase();
      final words = eng.split(" ");
      if (words.length == 2) bigramMap["${words[0]} ${words[1]}"] = entry.key;
    }
    final result = <String>[];
    var i = 0;
    while (i < tokens.length) {
      if (i + 1 < tokens.length) {
        final bigram = "${tokens[i].toLowerCase()} ${tokens[i + 1].toLowerCase()}";
        final gloss = bigramMap[bigram];
        if (gloss != null) { result.add(gloss); i += 2; continue; }
      }
      result.add(tokens[i]);
      i++;
    }
    return result;
  }

  (List<String>, List<String>) _matchWords(List<String> tokens) {
    final known = <String>[], unknown = <String>[];
    for (final tok in tokens) {
      if (tok.isEmpty) continue;
      final upper = tok.toUpperCase();
      if (_dict.containsKey(upper)) { known.add(upper); continue; }
      final syn = _wordSynonyms[tok.toLowerCase()];
      if (syn != null && _dict.containsKey(syn)) { known.add(syn); continue; }
      unknown.add(tok);
    }
    return (known, unknown);
  }
}
