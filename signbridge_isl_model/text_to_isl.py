"""
text_to_isl.py — SignBridge: English/Hindi text (or transcribed speech) -> ISL gloss
sequence -> real ISL video sequence.

Design decisions (per project spec):
- No neural translation model. Phrase matching + word-level normalization +
  a fixed, verified vocabulary.
- Every gloss this module can ever emit is guaranteed to exist in
  isl_dictionary.json, which was generated directly from the filenames in the
  supplied dataset (see build_from_dataset.py). Nothing here invents a sign.
- Unknown words are always reported, never silently dropped or replaced.

Hindi support lives in hindi_lexicon.json (single source of truth), not inline
here, so the word map, Hindi phrase rules and Hindi labels can never drift
apart. Unmapped Hindi words are reported as 'unknown' — the pipeline never
guesses a translation to force a match.
"""

import json
import re
import string
import unicodedata
from pathlib import Path

BASE_DIR = Path(__file__).parent

# ---------------------------------------------------------------------------
# Load data (the dataset is the source of truth — this module never
# hand-lists signs, it only reads what build_from_dataset.py already verified)
# ---------------------------------------------------------------------------


def _normalize_key(text: str) -> str:
    """NFKC + strip, so nukta forms (क़ ज़ फ़) compare equal either way."""
    return unicodedata.normalize("NFKC", text).strip()


with open(BASE_DIR / "isl_dictionary.json", encoding="utf-8") as f:
    ISL_DICTIONARY = json.load(f)

with open(BASE_DIR / "hindi_lexicon.json", encoding="utf-8") as f:
    _HINDI_LEXICON = json.load(f)

with open(BASE_DIR / "phrase_rules.json", encoding="utf-8") as f:
    _raw_phrase_rules = json.load(f)
    PHRASE_RULES = {k: v for k, v in _raw_phrase_rules.items() if not k.startswith("_")}

AVAILABLE_GLOSSES = set(ISL_DICTIONARY.keys())

# Hindi lexicon (imported from hindi_lexicon.json). Keys are normalized so they
# match tokens coming out of normalize_text(), which NFKC-normalizes input too.
HINDI_WORD_MAP = {
    _normalize_key(k): v for k, v in _HINDI_LEXICON.get("words", {}).items()
}
HINDI_LABELS = dict(_HINDI_LEXICON.get("labels", {}))

# Hindi phrase rules are folded into the same PHRASE_RULES table as the English
# ones so Level 1 phrase matching works identically in both languages.
for _hi_phrase, _hi_seq in _HINDI_LEXICON.get("phrases", {}).items():
    PHRASE_RULES.setdefault(_normalize_key(_hi_phrase), _hi_seq)

# Sanity check at import time: fail loudly rather than silently serve a
# broken rule if the dictionary and phrase_rules ever drift apart.
for _phrase, _seq in PHRASE_RULES.items():
    for _g in _seq:
        if _g not in AVAILABLE_GLOSSES:
            raise ValueError(
                f"phrase rule '{_phrase}' references gloss '{_g}' which is not "
                f"in isl_dictionary.json. Fix the rule or add the video — never "
                f"ship a dangling reference."
            )

# Every Hindi word must resolve to a real sign, else the lexicon is lying about
# coverage and the word would silently become a dead end at match time.
for _word, _g in HINDI_WORD_MAP.items():
    if _g not in AVAILABLE_GLOSSES:
        raise ValueError(
            f"hindi_lexicon.json maps '{_word}' -> '{_g}', which has no video in "
            f"isl_dictionary.json. Fix the mapping or remove it — never point "
            f"Hindi at a sign that cannot be shown."
        )

# ---------------------------------------------------------------------------
# Word-level synonym map: variant/informal English words -> a gloss that is
# CONFIRMED present in the dataset. This is a normalization convenience
# layer, not a claim about the dataset — every target here is checked above.
# ---------------------------------------------------------------------------

WORD_SYNONYMS = {
    "hi": "HELLO", "hey": "HELLO", "hola": "HELLO",
    "bye": "BYE", "goodbye": "BYE", "cya": "BYE",
    "thanks": "THANK_YOU", "thankyou": "THANK_YOU", "thx": "THANK_YOU",
    "u": "YOU", "ur": "YOUR",
    "im": "I",  # "I'm" after apostrophe-stripping becomes "im"
}

# Pure grammatical function words (articles, copula) that ISL grammar does
# not require and that carry no independent meaning of their own — safe to
# drop rather than report as "unknown". "please" is deliberately NOT in this
# list: it's a real content word with no sign in this dataset, so it must be
# reported as unknown rather than silently discarded (per spec section 5:
# never silently drop meaningful unknown words).
DROP_WORDS = {
    "a", "an", "the", "is", "am", "are", "was", "were",
}

# Same rationale, in Hindi: copulas ("है/हैं/था/थे/हो") and the ergative
# postposition "ने" carry no sign of their own in this dataset, so dropping
# them keeps a normal spoken sentence from drowning in spurious unknowns.
# Content words are never listed here — e.g. "फिर" (again) and "भी" (also)
# have real signs and must surface, not vanish.
HINDI_DROP_WORDS = {
    _normalize_key(w) for w in _HINDI_LEXICON.get("drop_words", [])
}

# Extra punctuation that string.punctuation misses but that real Hindi text
# actually contains — the danda, double danda, and common typographic marks.
_EXTRA_PUNCT = "।॥“”‘’—–…·"

# Detection range for Devanagari. Hindi input is auto-detected from this.
_DEVANAGARI_RANGE = ("\u0900", "\u097F")


def _is_hindi(text: str) -> bool:
    """Detect Devanagari script by unicode codepoint range."""
    return any(_DEVANAGARI_RANGE[0] <= ch <= _DEVANAGARI_RANGE[1] for ch in text)


def _strip_punct(text: str) -> str:
    text = unicodedata.normalize("NFKC", text)
    return text.translate(str.maketrans("", "", string.punctuation + _EXTRA_PUNCT))


def normalize_text(text: str, language: str = "auto"):
    """
    Returns (normalized_text: str, tokens: list[str], detected_lang: str)
    """
    if language == "auto":
        language = "hi" if _is_hindi(text) else "en"

    text = text.strip().lower()
    text = _strip_punct(text)
    text = re.sub(r"\s+", " ", text).strip()

    raw_tokens = text.split(" ")

    if language == "hi":
        tokens = []
        for tok in raw_tokens:
            if not tok or tok in HINDI_DROP_WORDS:
                continue
            gloss = HINDI_WORD_MAP.get(tok)
            tokens.append(gloss if gloss else tok)  # unmapped Hindi stays as-is -> unknown
        return text, tokens, "hi"

    # English path
    tokens = [t for t in raw_tokens if t and t not in DROP_WORDS]
    return text, tokens, "en"


def _match_phrase_rules(normalized_text: str):
    """Level 1: exact phrase match. Returns gloss list or None."""
    return PHRASE_RULES.get(normalized_text)


def _match_words(tokens):
    """
    Level 2: word-by-word / semantic matching against the vocabulary.
    Returns (known_glosses: list[str], unknown_words: list[str])
    Never guesses — a token becomes 'known' only if it (or its synonym, or
    its Hindi mapping) is an exact, verified gloss.
    """
    known, unknown = [], []
    for tok in tokens:
        if not tok:
            continue
        upper = tok.upper()

        if upper in AVAILABLE_GLOSSES:
            known.append(upper)
            continue

        syn = WORD_SYNONYMS.get(tok)
        if syn and syn in AVAILABLE_GLOSSES:
            known.append(syn)
            continue

        unknown.append(tok)

    return known, unknown


def translate(text: str, language: str = "auto") -> dict:
    """
    Main entry point. Mirrors the Flutter <-> ML API contract described in
    FLUTTER_INTEGRATION.md.

    Input:  text (str), language ("en" | "hi" | "auto")
    Output: {
        "status": "complete" | "partial" | "unknown",
        "gloss_sequence": [{"gloss": str, "video": str}, ...],
        "unknown": [str, ...]   # present when status != "complete"
    }
    """
    if not text or not text.strip():
        return {"status": "unknown", "gloss_sequence": [], "unknown": []}

    normalized, tokens, detected_lang = normalize_text(text, language)

    # Level 1: try exact phrase match first (English or Hindi)
    phrase_glosses = _match_phrase_rules(normalized)
    if phrase_glosses is not None:
        gloss_sequence = [
            {"gloss": g, "video": ISL_DICTIONARY[g]["video"]} for g in phrase_glosses
        ]
        return {"status": "complete", "gloss_sequence": gloss_sequence}

    # Also try phrase rules against multi-word gloss collapsing, e.g. handle
    # dataset phrase-signs like "do not" / "does not" inside longer sentences
    # by checking bigrams before falling back to single-word matching.
    tokens = _collapse_known_bigrams(tokens)

    # Level 2: word/semantic matching
    known, unknown = _match_words(tokens)

    gloss_sequence = [
        {"gloss": g, "video": ISL_DICTIONARY[g]["video"]} for g in known
    ]

    if not known:
        return {"status": "unknown", "gloss_sequence": [], "unknown": unknown}

    if unknown:
        return {"status": "partial", "gloss_sequence": gloss_sequence, "unknown": unknown}

    return {"status": "complete", "gloss_sequence": gloss_sequence}


def _collapse_known_bigrams(tokens):
    """
    The dataset contains a few multi-word signs as single videos
    (e.g. 'Thank You' -> THANK_YOU, 'Do Not' -> DO_NOT, 'Does Not' -> DOES_NOT).
    Before word-level matching, greedily collapse adjacent token pairs that
    match one of these into a single gloss token.
    """
    # Build bigram -> gloss map from the dictionary's english field (e.g.
    # {"thank", "you"} -> "THANK_YOU")
    bigram_map = {}
    for gloss, entry in ISL_DICTIONARY.items():
        words = entry["english"].split(" ")
        if len(words) == 2:
            bigram_map[(words[0], words[1])] = gloss

    result = []
    i = 0
    while i < len(tokens):
        if i + 1 < len(tokens) and (tokens[i], tokens[i + 1]) in bigram_map:
            result.append(bigram_map[(tokens[i], tokens[i + 1])])
            i += 2
        else:
            result.append(tokens[i])
            i += 1
    return result


def hindi_label(gloss: str):
    """Canonical Hindi label for a gloss, or None if we have not mapped one."""
    return HINDI_LABELS.get(gloss)


def vocabulary_with_hindi():
    """
    The full 151-sign vocabulary with its Hindi label where one exists.
    Used for coverage reporting — this is the honest count of how much of the
    dataset is reachable from Hindi, not a claim that everything is.
    """
    return {
        gloss: {"english": entry["english"], "hindi": HINDI_LABELS.get(gloss)}
        for gloss, entry in ISL_DICTIONARY.items()
    }


if __name__ == "__main__":
    demo_inputs = [
        ("I need water", "en"),          # dataset gap — expect 'partial'
        ("Thank you", "en"),
        ("Please help me", "en"),
        ("Where is home", "en"),
        ("Do not go", "en"),
        ("मुझे पानी चाहिए", "hi"),        # पानी/चाहिए still a dataset gap — partial
        ("घर कहाँ है", "hi"),
        ("आपका नाम क्या है", "hi"),
        ("मेरा नाम क्या है", "hi"),
        ("मत जाओ", "hi"),
        ("यहाँ आओ", "hi"),
        ("मैं व्यस्त हूँ", "hi"),          # copula "हूँ" is dropped, not unknown
        ("मुझे मदद", "hi"),
    ]
    for text, lang in demo_inputs:
        result = translate(text, lang)
        print(f"\nINPUT: {text!r} (lang={lang})")
        print(json.dumps(result, ensure_ascii=False, indent=2))

    labelled = sum(1 for v in vocabulary_with_hindi().values() if v["hindi"])
    total = len(ISL_DICTIONARY)
    print(f"\nHindi labels: {labelled}/{total} signs")
    print(f"Hindi word forms mapped: {len(HINDI_WORD_MAP)}")
    print(f"Hindi phrase rules: {len(_HINDI_LEXICON.get('phrases', {}))}")
