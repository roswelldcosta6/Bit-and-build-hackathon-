"""
Lightweight smoke tests. Run: python3 test_text_to_isl.py
No pytest dependency — plain asserts so it runs anywhere.
"""

from text_to_isl import (
    translate,
    ISL_DICTIONARY,
    AVAILABLE_GLOSSES,
    HINDI_WORD_MAP,
    HINDI_LABELS,
    hindi_label,
)


def check(text, lang, expected_status, expected_glosses=None):
    result = translate(text, lang)
    assert result["status"] == expected_status, (
        f"{text!r}: expected status {expected_status}, got {result['status']} -> {result}"
    )
    if expected_glosses is not None:
        got = [g["gloss"] for g in result["gloss_sequence"]]
        assert got == expected_glosses, f"{text!r}: expected {expected_glosses}, got {got}"
    return result


def test_full_phrase_match():
    check("Thank you", "en", "complete", ["THANK_YOU"])
    check("thanks", "en", "complete", ["THANK_YOU"])
    check("Hello", "en", "complete", ["HELLO"])
    check("Come here", "en", "complete", ["COME", "HERE"])


def test_word_level_match():
    check("Where is home", "en", "complete", ["WHERE", "HOME"])
    check("who are you", "en", "complete", ["WHO", "YOU"])


def test_never_hallucinates_missing_signs():
    # WATER / NEED / WANT / DOCTOR do not exist in the supplied dataset —
    # the pipeline must report them as unknown, never invent or substitute.
    result = check("I need water", "en", "partial")
    assert result["gloss_sequence"] == [{"gloss": "I", "video": ISL_DICTIONARY["I"]["video"]}]
    assert set(result["unknown"]) == {"need", "water"}

    result = check("Where is the doctor?", "en", "partial")
    assert "doctor" in result["unknown"]


def test_totally_unknown_input():
    result = check("xyzzy plugh", "en", "unknown")
    assert result["gloss_sequence"] == []


def test_hindi_pronoun_mapping():
    result = translate("मुझे पानी चाहिए", "hi")
    # "मुझे" (I) maps; पानी (water) and चाहिए (need/want) are not in the
    # dataset and must surface as unknown, not be dropped or guessed.
    assert result["status"] == "partial"
    assert result["gloss_sequence"] == [{"gloss": "I", "video": ISL_DICTIONARY["I"]["video"]}]


def test_hindi_phrase_rules_resolve():
    check("घर कहाँ है", "hi", "complete", ["WHERE", "HOME"])
    check("यहाँ आओ", "hi", "complete", ["COME", "HERE"])
    check("मत जाओ", "hi", "complete", ["DO_NOT", "GO"])
    check("मैं व्यस्त हूँ", "hi", "complete", ["I", "BUSY"])
    check("आपका नाम क्या है", "hi", "complete", ["WHAT", "YOUR", "NAME"])
    check("मुझे मदद", "hi", "complete", ["I", "HELP"])


def test_hindi_word_lexicon_resolves():
    # No phrase rule covers these, so they exercise the word-level Hindi map.
    check("मुझे घर", "hi", "complete", ["I", "HOME"])
    check("तुम्हारा काम", "hi", "complete", ["YOUR", "WORK"])
    check("सुंदर घर", "hi", "complete", ["BEAUTIFUL", "HOME"])
    check("खुश हाथ", "hi", "complete", ["HAPPY", "HAND"])


def test_hindi_copulas_are_dropped_not_reported_unknown():
    # "है" is a copula with no sign of its own — dropping it keeps a normal
    # spoken sentence from drowning in spurious unknowns.
    result = translate("यह घर है", "hi")
    assert result["status"] == "complete", result
    assert [g["gloss"] for g in result["gloss_sequence"]] == ["THIS", "HOME"]


def test_hindi_content_words_are_never_dropped():
    # "फिर" (again) and "भी" (also) DO have signs — they must survive, not be
    # mistaken for filler and silently discarded.
    check("फिर", "hi", "complete", ["AGAIN"])
    check("भी", "hi", "complete", ["ALSO"])
    check("बाहर", "hi", "complete", ["OUT"])


def test_hindi_multiword_signs_are_reachable():
    # Negated / multi-word dataset signs must be reachable from Hindi too,
    # not only from English.
    check("मत करो", "hi", "complete", ["DO_NOT"])
    check("नहीं करता", "hi", "complete", ["DOES_NOT"])
    check("नहीं सकना", "hi", "complete", ["CANNOT"])
    check("सबसे अच्छा", "hi", "complete", ["BEST"])
    check("कौन सा", "hi", "complete", ["WHICH"])
    check("करेंगे", "hi", "complete", ["WILL"])
    check("पढ़ाई", "hi", "complete", ["STUDY"])


def test_hindi_punctuation_and_autodetect():
    # The danda "।" is not ASCII punctuation; it must still be stripped, and
    # Devanagari must auto-detect as Hindi without passing language="hi".
    result = translate("घर कहाँ है।", "auto")
    assert result["status"] == "complete", result
    assert [g["gloss"] for g in result["gloss_sequence"]] == ["WHERE", "HOME"]


def test_hindi_never_guesses_missing_signs():
    result = translate("मुझे पानी चाहिए", "hi")
    assert result["status"] == "partial"
    assert set(result["unknown"]) == {"पानी", "चाहिए"}


def test_hindi_lexicon_only_points_at_real_videos():
    for word, gloss in HINDI_WORD_MAP.items():
        assert gloss in AVAILABLE_GLOSSES, f"Hindi '{word}' -> '{gloss}' has no video"
    for gloss in HINDI_LABELS:
        assert gloss in AVAILABLE_GLOSSES, f"Hindi label for '{gloss}' has no video"


def test_hindi_coverage_is_reported_honestly():
    # Guard against the lexicon silently shrinking back to a token list.
    assert len(HINDI_WORD_MAP) >= 100, f"only {len(HINDI_WORD_MAP)} Hindi words mapped"
    labelled = sum(1 for g in ISL_DICTIONARY if hindi_label(g))
    assert labelled >= 110, f"only {labelled} signs carry a Hindi label"
    # Abstract/loan words are deliberately left untranslated rather than guessed.
    assert hindi_label("GLITTER") is None
    assert hindi_label("HOMEPAGE") is None


def test_please_is_not_silently_dropped():
    # "please" has real meaning and no sign exists for it — must be reported.
    result = check("Please help me", "en", "partial")
    assert "please" in result["unknown"]


def test_multiword_dataset_phrases_collapse():
    check("do not go", "en", "complete", ["DO_NOT", "GO"])
    check("does not work", "en", "complete", ["DOES_NOT", "WORK"])


def test_empty_input():
    check("", "en", "unknown")
    check("   ", "en", "unknown")


def test_every_dictionary_video_reference_is_consistent():
    # Every gloss's video path must be internally consistent (sanity check,
    # not a claim the files exist on this machine at test time).
    for gloss, entry in ISL_DICTIONARY.items():
        assert entry["video"].startswith("assets/isl/")
        assert entry["video"].endswith(".mp4")


if __name__ == "__main__":
    tests = [v for k, v in list(globals().items()) if k.startswith("test_")]
    passed = 0
    for t in tests:
        t()
        passed += 1
        print(f"PASS: {t.__name__}")
    print(f"\n{passed}/{len(tests)} tests passed.")
