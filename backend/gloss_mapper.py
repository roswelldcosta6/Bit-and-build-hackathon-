"""
SignBridge Bilingual Gloss Mapper (English & Hindi -> ISL SOV Gloss)
Applies real ISL linguistics:
1. Article & copula removal
2. Reordering to Subject-Object-Verb (SOV)
3. WH-question words moved to sentence-final position
4. Negation markers moved to the end
5. Bilingual synonym normalization
"""

import re
from typing import List, Tuple, Dict, Any, Optional
from vocabulary import lookup_gloss, get_sign_metadata

# Grammatical classifications for reordering
WH_GLOSSES = {"WHERE", "WHAT", "WHEN", "WHY", "HOW", "WHO", "HOW_MUCH"}
NEGATION_GLOSSES = {"NOT", "NO"}
PRONOUN_GLOSSES = {"ME", "YOU", "WE", "HE_SHE"}
VERB_GLOSSES = {
    "WANT", "COME", "GO", "WAIT", "UNDERSTAND", "STOP", "SIT", "CALL",
    "SLEEP", "HELP", "DEPOSIT", "WITHDRAW", "SIGN"
}
GREETING_GLOSSES = {"HELLO", "THANK_YOU", "PLEASE", "SORRY", "GOODBYE", "YES"}

# English stop words and copulas to drop
ENGLISH_DROPS = {
    "a", "an", "the", "is", "are", "am", "was", "were", "be", "been", "being",
    "to", "of", "for", "at", "by", "with", "from", "in", "on", "into", "onto",
    "do", "does", "did", "have", "has", "had", "will", "shall", "would", "should",
    "can", "could", "may", "might", "must", "please"
}

# Hindi stop words and copulas to drop
HINDI_DROPS = {
    "है", "हैं", "था", "थी", "थे", "हो", "हूँ", "हुं",
    "का", "के", "की", "को", "में", "से", "पर", "ने", "तक", "द्वारा",
    "एक", "भी", "तो", "ही", "कृपया"
}


def detect_language(text: str) -> str:
    """
    Detects whether text is Hindi (Devanagari script) or English.
    Returns 'hi' or 'en'.
    """
    hindi_chars = len(re.findall(r'[\u0900-\u097F]', text))
    latin_chars = len(re.findall(r'[a-zA-Z]', text))
    if hindi_chars > latin_chars:
        return "hi"
    return "en"


def tokenize_text(text: str, lang: str) -> List[str]:
    """Cleans and tokenizes text into distinct word tokens."""
    cleaned = re.sub(r'[^\w\s\u0900-\u097F]', ' ', text)
    tokens = [t.strip() for t in cleaned.split() if t.strip()]
    return tokens


def apply_isl_grammar_reordering(gloss_sequence: List[str]) -> Tuple[List[str], List[str]]:
    """
    Transforms a sequence of ISL glosses into proper ISL grammatical order:
    1. Greetings remain at beginning.
    2. Subjects / Pronouns come next.
    3. Direct/Indirect Objects (Nouns) come next.
    4. Verbs follow Objects (SOV).
    5. Negation marker (NOT) follows the Verb.
    6. Interrogative WH-words placed at the very end.
    
    Returns (reordered_glosses, grammar_rules_applied).
    """
    if not gloss_sequence:
        return [], []

    rules_applied = []
    
    greetings = []
    subjects = []
    objects = []
    verbs = []
    negations = []
    questions = []

    for gloss in gloss_sequence:
        if gloss in GREETING_GLOSSES:
            greetings.append(gloss)
        elif gloss in WH_GLOSSES:
            questions.append(gloss)
        elif gloss in NEGATION_GLOSSES:
            negations.append(gloss)
        elif gloss in PRONOUN_GLOSSES:
            subjects.append(gloss)
        elif gloss in VERB_GLOSSES:
            verbs.append(gloss)
        else:
            objects.append(gloss)

    reordered = []
    
    # 1. Greetings first
    if greetings:
        reordered.extend(greetings)
        rules_applied.append("GREETING_INITIAL")

    # 2. Subjects next
    if subjects:
        reordered.extend(subjects)

    # 3. Objects (Topic/Theme)
    if objects:
        reordered.extend(objects)

    # 4. Verbs (SOV: Object before Verb)
    if verbs:
        reordered.extend(verbs)
        if objects and subjects:
            rules_applied.append("SOV_ORDER_APPLIED")

    # 5. Negation (placed after verb/action)
    if negations:
        reordered.extend(negations)
        rules_applied.append("NEGATION_FINAL")

    # 6. WH questions at the very end
    if questions:
        reordered.extend(questions)
        rules_applied.append("WH_QUESTION_FINAL")

    # Deduplicate consecutive identical glosses
    deduped = []
    for g in reordered:
        if not deduped or deduped[-1] != g:
            deduped.append(g)

    return deduped, rules_applied


def text_to_isl_gloss(text: str, explicit_lang: Optional[str] = None) -> Dict[str, Any]:
    """
    End-to-end NLP pipeline:
    Input: "Where is the doctor?" or "मुझे डॉक्टर चाहिए"
    Output: {
        "original_text": "...",
        "detected_lang": "en" | "hi",
        "glosses": ["DOCTOR", "WHERE"],
        "clip_ids": [2, 33],
        "video_filenames": ["DOCTOR.mp4", "WHERE.mp4"],
        "subtitle": "Doctor Where",
        "grammar_applied": ["WH_QUESTION_FINAL"]
    }
    """
    lang = explicit_lang if explicit_lang in ["en", "hi"] else detect_language(text)
    tokens = tokenize_text(text, lang)
    drops = HINDI_DROPS if lang == "hi" else ENGLISH_DROPS

    raw_glosses = []
    
    # 2-gram / 1-gram sliding window for phrases (e.g. "thank you", "credit card")
    i = 0
    while i < len(tokens):
        # Try bigram first
        if i + 1 < len(tokens):
            bigram = f"{tokens[i]} {tokens[i+1]}".lower()
            bigram_gloss = lookup_gloss(bigram)
            if bigram_gloss:
                raw_glosses.append(bigram_gloss)
                i += 2
                continue

        single = tokens[i].lower()
        if single in drops:
            i += 1
            continue

        single_gloss = lookup_gloss(single)
        if single_gloss:
            raw_glosses.append(single_gloss)
        else:
            # Check if it's a number or simple known word
            pass

        i += 1

    # Fallback if no specific keywords matched
    if not raw_glosses:
        # Check for generic HELP or UNDERSTAND
        if any(w in text.lower() for w in ["help", "मदद", "assist", "emergency"]):
            raw_glosses.append("HELP")
        else:
            raw_glosses.append("HELLO")

    # Apply linguistic ISL grammar transformation
    reordered_glosses, grammar_rules = apply_isl_grammar_reordering(raw_glosses)

    clip_ids = []
    video_filenames = []
    subtitle_parts = []
    animation_sequence = []
    total_duration_ms = 0

    for gloss in reordered_glosses:
        meta = get_sign_metadata(gloss)
        if meta:
            clip_ids.append(meta["clip_id"])
            video_filenames.append(meta["video_file"])
            subtitle_parts.append(meta["en"])
            
            dur = meta.get("duration_ms", 1300)
            total_duration_ms += dur
            animation_sequence.append({
                "gloss": gloss,
                "animation_trigger": meta.get("animation_trigger", f"sign_{gloss.lower()}"),
                "duration_ms": dur,
                "blend_transition_ms": 250,
                "hand_target": meta.get("hand_target", "BOTH_HANDS"),
                "facial_expression": meta.get("facial_expression", "NEUTRAL"),
                "pose_endpoint": f"/avatar/poses/{gloss}",
            })
        else:
            clip_ids.append(1)
            video_filenames.append("HELP.mp4")
            subtitle_parts.append(gloss.capitalize())
            total_duration_ms += 1200
            animation_sequence.append({
                "gloss": gloss,
                "animation_trigger": f"sign_{gloss.lower()}",
                "duration_ms": 1200,
                "blend_transition_ms": 250,
                "hand_target": "BOTH_HANDS",
                "facial_expression": "NEUTRAL",
                "pose_endpoint": f"/avatar/poses/{gloss}",
            })

    subtitle = " ".join(subtitle_parts)

    return {
        "original_text": text,
        "detected_lang": lang,
        "glosses": reordered_glosses,
        "animation_sequence": animation_sequence,
        "total_duration_ms": total_duration_ms,
        "clip_ids": clip_ids,
        "video_filenames": video_filenames,
        "subtitle": subtitle,
        "grammar_applied": grammar_rules,
    }
