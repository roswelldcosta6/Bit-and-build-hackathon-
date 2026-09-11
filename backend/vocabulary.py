"""
SignBridge ISL Vocabulary Registry
Comprehensive mapping for 60+ core Indian Sign Language signs.
Includes humanoid 3D animation triggers, skeletal rig targets, and facial expressions.
"""

from typing import Dict, Any, List, Optional

# Master Vocabulary with 3D Humanoid Avatar metadata
ISL_VOCABULARY: List[Dict[str, Any]] = [
    # 1. Emergency & Medical (Critical for Hospitals)
    {"clip_id": 1, "gloss": "HELP", "en": "Help", "hi": "मदद", "category": "Emergency", "video_file": "HELP.mp4",
     "animation_trigger": "sign_help", "hand_target": "BOTH_HANDS", "facial_expression": "CONCERNED", "duration_ms": 1400},
    {"clip_id": 2, "gloss": "DOCTOR", "en": "Doctor", "hi": "डॉक्टर", "category": "Hospital", "video_file": "DOCTOR.mp4",
     "animation_trigger": "sign_doctor", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 3, "gloss": "HOSPITAL", "en": "Hospital", "hi": "अस्पताल", "category": "Hospital", "video_file": "HOSPITAL.mp4",
     "animation_trigger": "sign_hospital", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1500},
    {"clip_id": 4, "gloss": "PAIN", "en": "Pain", "hi": "दर्द", "category": "Hospital", "video_file": "PAIN.mp4",
     "animation_trigger": "sign_pain", "hand_target": "BOTH_HANDS", "facial_expression": "CONCERNED", "duration_ms": 1300},
    {"clip_id": 5, "gloss": "MEDICINE", "en": "Medicine", "hi": "दवा", "category": "Hospital", "video_file": "MEDICINE.mp4",
     "animation_trigger": "sign_medicine", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 6, "gloss": "EMERGENCY", "en": "Emergency", "hi": "आपातकाल", "category": "Emergency", "video_file": "EMERGENCY.mp4",
     "animation_trigger": "sign_emergency", "hand_target": "BOTH_HANDS", "facial_expression": "CONCERNED", "duration_ms": 1500},
    {"clip_id": 7, "gloss": "BLOOD", "en": "Blood", "hi": "खून", "category": "Hospital", "video_file": "BLOOD.mp4",
     "animation_trigger": "sign_blood", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 8, "gloss": "NURSE", "en": "Nurse", "hi": "नर्स", "category": "Hospital", "video_file": "NURSE.mp4",
     "animation_trigger": "sign_nurse", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 9, "gloss": "SICK", "en": "Sick", "hi": "बीमार", "category": "Hospital", "video_file": "SICK.mp4",
     "animation_trigger": "sign_sick", "hand_target": "RIGHT_HAND", "facial_expression": "CONCERNED", "duration_ms": 1400},
    {"clip_id": 10, "gloss": "FEVER", "en": "Fever", "hi": "बुखार", "category": "Hospital", "video_file": "FEVER.mp4",
     "animation_trigger": "sign_fever", "hand_target": "RIGHT_HAND", "facial_expression": "CONCERNED", "duration_ms": 1300},
    {"clip_id": 11, "gloss": "AMBULANCE", "en": "Ambulance", "hi": "एम्बुलेंस", "category": "Emergency", "video_file": "AMBULANCE.mp4",
     "animation_trigger": "sign_ambulance", "hand_target": "BOTH_HANDS", "facial_expression": "CONCERNED", "duration_ms": 1600},

    # 2. Banking & Administration
    {"clip_id": 12, "gloss": "BANK", "en": "Bank", "hi": "बैंक", "category": "Banking", "video_file": "BANK.mp4",
     "animation_trigger": "sign_bank", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1400},
    {"clip_id": 13, "gloss": "MONEY", "en": "Money", "hi": "पैसे", "category": "Banking", "video_file": "MONEY.mp4",
     "animation_trigger": "sign_money", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 14, "gloss": "ACCOUNT", "en": "Account", "hi": "खाता", "category": "Banking", "video_file": "ACCOUNT.mp4",
     "animation_trigger": "sign_account", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 15, "gloss": "DEPOSIT", "en": "Deposit", "hi": "जमा", "category": "Banking", "video_file": "DEPOSIT.mp4",
     "animation_trigger": "sign_deposit", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 16, "gloss": "WITHDRAW", "en": "Withdraw", "hi": "निकालना", "category": "Banking", "video_file": "WITHDRAW.mp4",
     "animation_trigger": "sign_withdraw", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 17, "gloss": "SIGN", "en": "Sign / Signature", "hi": "हस्ताक्षर", "category": "Banking", "video_file": "SIGN.mp4",
     "animation_trigger": "sign_signature", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1400},
    {"clip_id": 18, "gloss": "CARD", "en": "Card", "hi": "कार्ड", "category": "Banking", "video_file": "CARD.mp4",
     "animation_trigger": "sign_card", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 19, "gloss": "LOAN", "en": "Loan", "hi": "ऋण", "category": "Banking", "video_file": "LOAN.mp4",
     "animation_trigger": "sign_loan", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},

    # 3. Essential Needs & Items
    {"clip_id": 20, "gloss": "WATER", "en": "Water", "hi": "पानी", "category": "Needs", "video_file": "WATER.mp4",
     "animation_trigger": "sign_water", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 21, "gloss": "FOOD", "en": "Food", "hi": "खाना", "category": "Needs", "video_file": "FOOD.mp4",
     "animation_trigger": "sign_food", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 22, "gloss": "TOILET", "en": "Washroom / Toilet", "hi": "शौचालय", "category": "Needs", "video_file": "TOILET.mp4",
     "animation_trigger": "sign_toilet", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 23, "gloss": "SLEEP", "en": "Sleep", "hi": "सोना", "category": "Needs", "video_file": "SLEEP.mp4",
     "animation_trigger": "sign_sleep", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1400},
    {"clip_id": 24, "gloss": "PHONE", "en": "Phone", "hi": "फोन", "category": "Needs", "video_file": "PHONE.mp4",
     "animation_trigger": "sign_phone", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},

    # 4. People & Pronouns
    {"clip_id": 25, "gloss": "ME", "en": "I / Me", "hi": "मैं / मुझे", "category": "Pronouns", "video_file": "ME.mp4",
     "animation_trigger": "sign_me", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1100},
    {"clip_id": 26, "gloss": "YOU", "en": "You", "hi": "आप / तुम", "category": "Pronouns", "video_file": "YOU.mp4",
     "animation_trigger": "sign_you", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1100},
    {"clip_id": 27, "gloss": "WE", "en": "We", "hi": "हम", "category": "Pronouns", "video_file": "WE.mp4",
     "animation_trigger": "sign_we", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 28, "gloss": "HE_SHE", "en": "He / She", "hi": "वह", "category": "Pronouns", "video_file": "HE_SHE.mp4",
     "animation_trigger": "sign_heshe", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1100},
    {"clip_id": 29, "gloss": "FAMILY", "en": "Family", "hi": "परिवार", "category": "People", "video_file": "FAMILY.mp4",
     "animation_trigger": "sign_family", "hand_target": "BOTH_HANDS", "facial_expression": "SMILE", "duration_ms": 1400},
    {"clip_id": 30, "gloss": "MOTHER", "en": "Mother", "hi": "माँ", "category": "People", "video_file": "MOTHER.mp4",
     "animation_trigger": "sign_mother", "hand_target": "RIGHT_HAND", "facial_expression": "SMILE", "duration_ms": 1300},
    {"clip_id": 31, "gloss": "FATHER", "en": "Father", "hi": "पिता", "category": "People", "video_file": "FATHER.mp4",
     "animation_trigger": "sign_father", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 32, "gloss": "CHILD", "en": "Child", "hi": "बच्चा", "category": "People", "video_file": "CHILD.mp4",
     "animation_trigger": "sign_child", "hand_target": "RIGHT_HAND", "facial_expression": "SMILE", "duration_ms": 1200},

    # 5. Question Words (WH-Words - Positioned at end in ISL grammar)
    {"clip_id": 33, "gloss": "WHERE", "en": "Where", "hi": "कहाँ", "category": "Questions", "video_file": "WHERE.mp4",
     "animation_trigger": "sign_where", "hand_target": "BOTH_HANDS", "facial_expression": "QUESTIONING", "duration_ms": 1400},
    {"clip_id": 34, "gloss": "WHAT", "en": "What", "hi": "क्या", "category": "Questions", "video_file": "WHAT.mp4",
     "animation_trigger": "sign_what", "hand_target": "BOTH_HANDS", "facial_expression": "QUESTIONING", "duration_ms": 1300},
    {"clip_id": 35, "gloss": "WHEN", "en": "When", "hi": "कब", "category": "Questions", "video_file": "WHEN.mp4",
     "animation_trigger": "sign_when", "hand_target": "BOTH_HANDS", "facial_expression": "QUESTIONING", "duration_ms": 1300},
    {"clip_id": 36, "gloss": "WHY", "en": "Why", "hi": "क्यों", "category": "Questions", "video_file": "WHY.mp4",
     "animation_trigger": "sign_why", "hand_target": "RIGHT_HAND", "facial_expression": "QUESTIONING", "duration_ms": 1300},
    {"clip_id": 37, "gloss": "HOW", "en": "How", "hi": "कैसे", "category": "Questions", "video_file": "HOW.mp4",
     "animation_trigger": "sign_how", "hand_target": "BOTH_HANDS", "facial_expression": "QUESTIONING", "duration_ms": 1400},
    {"clip_id": 38, "gloss": "WHO", "en": "Who", "hi": "कौन", "category": "Questions", "video_file": "WHO.mp4",
     "animation_trigger": "sign_who", "hand_target": "RIGHT_HAND", "facial_expression": "QUESTIONING", "duration_ms": 1300},
    {"clip_id": 39, "gloss": "HOW_MUCH", "en": "How Much / Price", "hi": "कितना / दाम", "category": "Questions", "video_file": "HOW_MUCH.mp4",
     "animation_trigger": "sign_howmuch", "hand_target": "RIGHT_HAND", "facial_expression": "QUESTIONING", "duration_ms": 1400},

    # 6. Common Actions / Verbs
    {"clip_id": 40, "gloss": "WANT", "en": "Want / Need", "hi": "चाहिए", "category": "Verbs", "video_file": "WANT.mp4",
     "animation_trigger": "sign_want", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 41, "gloss": "COME", "en": "Come", "hi": "आना", "category": "Verbs", "video_file": "COME.mp4",
     "animation_trigger": "sign_come", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 42, "gloss": "GO", "en": "Go", "hi": "जाना", "category": "Verbs", "video_file": "GO.mp4",
     "animation_trigger": "sign_go", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 43, "gloss": "WAIT", "en": "Wait", "hi": "इंतजार", "category": "Verbs", "video_file": "WAIT.mp4",
     "animation_trigger": "sign_wait", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 44, "gloss": "UNDERSTAND", "en": "Understand", "hi": "समझना", "category": "Verbs", "video_file": "UNDERSTAND.mp4",
     "animation_trigger": "sign_understand", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 45, "gloss": "STOP", "en": "Stop", "hi": "रुकना", "category": "Verbs", "video_file": "STOP.mp4",
     "animation_trigger": "sign_stop", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 46, "gloss": "SIT", "en": "Sit", "hi": "बैठना", "category": "Verbs", "video_file": "SIT.mp4",
     "animation_trigger": "sign_sit", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 47, "gloss": "CALL", "en": "Call", "hi": "बुलाना", "category": "Verbs", "video_file": "CALL.mp4",
     "animation_trigger": "sign_call", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},

    # 7. Greetings & Courtesy
    {"clip_id": 48, "gloss": "HELLO", "en": "Hello / Namaste", "hi": "नमस्ते", "category": "Greetings", "video_file": "HELLO.mp4",
     "animation_trigger": "sign_hello", "hand_target": "BOTH_HANDS", "facial_expression": "SMILE", "duration_ms": 1300},
    {"clip_id": 49, "gloss": "THANK_YOU", "en": "Thank You", "hi": "धन्यवाद", "category": "Greetings", "video_file": "THANK_YOU.mp4",
     "animation_trigger": "sign_thankyou", "hand_target": "RIGHT_HAND", "facial_expression": "SMILE", "duration_ms": 1200},
    {"clip_id": 50, "gloss": "PLEASE", "en": "Please", "hi": "कृपया", "category": "Greetings", "video_file": "PLEASE.mp4",
     "animation_trigger": "sign_please", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 51, "gloss": "SORRY", "en": "Sorry", "hi": "माफ कीजिए", "category": "Greetings", "video_file": "SORRY.mp4",
     "animation_trigger": "sign_sorry", "hand_target": "RIGHT_HAND", "facial_expression": "CONCERNED", "duration_ms": 1300},
    {"clip_id": 52, "gloss": "YES", "en": "Yes", "hi": "हाँ", "category": "Greetings", "video_file": "YES.mp4",
     "animation_trigger": "sign_yes", "hand_target": "RIGHT_HAND", "facial_expression": "SMILE", "duration_ms": 1100},
    {"clip_id": 53, "gloss": "NO", "en": "No", "hi": "नहीं", "category": "Greetings", "video_file": "NO.mp4",
     "animation_trigger": "sign_no", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1100},
    {"clip_id": 54, "gloss": "GOODBYE", "en": "Goodbye", "hi": "अलविदा", "category": "Greetings", "video_file": "GOODBYE.mp4",
     "animation_trigger": "sign_goodbye", "hand_target": "RIGHT_HAND", "facial_expression": "SMILE", "duration_ms": 1300},
    {"clip_id": 55, "gloss": "NAME", "en": "Name", "hi": "नाम", "category": "Greetings", "video_file": "NAME.mp4",
     "animation_trigger": "sign_name", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1200},

    # 8. Time & Education / Direction
    {"clip_id": 56, "gloss": "TIME", "en": "Time", "hi": "समय", "category": "Time", "video_file": "TIME.mp4",
     "animation_trigger": "sign_time", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 57, "gloss": "TODAY", "en": "Today", "hi": "आज", "category": "Time", "video_file": "TODAY.mp4",
     "animation_trigger": "sign_today", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1200},
    {"clip_id": 58, "gloss": "TOMORROW", "en": "Tomorrow", "hi": "कल", "category": "Time", "video_file": "TOMORROW.mp4",
     "animation_trigger": "sign_tomorrow", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 59, "gloss": "SCHOOL", "en": "School / Classroom", "hi": "स्कूल", "category": "Education", "video_file": "SCHOOL.mp4",
     "animation_trigger": "sign_school", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1400},
    {"clip_id": 60, "gloss": "TEACHER", "en": "Teacher", "hi": "अध्यापक", "category": "Education", "video_file": "TEACHER.mp4",
     "animation_trigger": "sign_teacher", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1400},
    {"clip_id": 61, "gloss": "BOOK", "en": "Book", "hi": "किताब", "category": "Education", "video_file": "BOOK.mp4",
     "animation_trigger": "sign_book", "hand_target": "BOTH_HANDS", "facial_expression": "NEUTRAL", "duration_ms": 1300},
    {"clip_id": 62, "gloss": "NOT", "en": "Not / Don't", "hi": "नहीं", "category": "Grammar", "video_file": "NOT.mp4",
     "animation_trigger": "sign_not", "hand_target": "RIGHT_HAND", "facial_expression": "NEUTRAL", "duration_ms": 1200},
]

# Fast Lookup Maps
GLOSS_BY_ID: Dict[int, Dict[str, Any]] = {item["clip_id"]: item for item in ISL_VOCABULARY}
GLOSS_BY_NAME: Dict[str, Dict[str, Any]] = {item["gloss"]: item for item in ISL_VOCABULARY}

# Extended Bilingual Synonym Mapping
SYNONYM_MAP: Dict[str, str] = {
    # English synonyms
    "help": "HELP", "assist": "HELP", "aid": "HELP", "support": "HELP",
    "doctor": "DOCTOR", "physician": "DOCTOR", "dr": "DOCTOR", "medic": "DOCTOR",
    "hospital": "HOSPITAL", "clinic": "HOSPITAL", "dispensary": "HOSPITAL",
    "pain": "PAIN", "hurt": "PAIN", "ache": "PAIN", "hurting": "PAIN", "sore": "PAIN",
    "medicine": "MEDICINE", "medication": "MEDICINE", "pills": "MEDICINE", "tablet": "MEDICINE", "drugs": "MEDICINE",
    "emergency": "EMERGENCY", "urgent": "EMERGENCY", "crisis": "EMERGENCY",
    "blood": "BLOOD", "bleeding": "BLOOD",
    "nurse": "NURSE", "sister": "NURSE",
    "sick": "SICK", "ill": "SICK", "unwell": "SICK",
    "fever": "FEVER", "temperature": "FEVER",
    "ambulance": "AMBULANCE",
    
    # Banking
    "bank": "BANK", "branch": "BANK",
    "money": "MONEY", "cash": "MONEY", "rupees": "MONEY", "funds": "MONEY",
    "account": "ACCOUNT", "a/c": "ACCOUNT", "ac": "ACCOUNT",
    "deposit": "DEPOSIT", "credit": "DEPOSIT", "submit": "DEPOSIT",
    "withdraw": "WITHDRAW", "withdrawal": "WITHDRAW",
    "signature": "SIGN", "sign": "SIGN",
    "card": "CARD", "debit": "CARD", "credit card": "CARD", "atm": "CARD",
    "loan": "LOAN",
    
    # Needs
    "water": "WATER", "drink": "WATER", "thirsty": "WATER",
    "food": "FOOD", "eat": "FOOD", "meal": "FOOD", "hungry": "FOOD", "lunch": "FOOD", "dinner": "FOOD",
    "toilet": "TOILET", "washroom": "TOILET", "restroom": "TOILET", "bathroom": "TOILET", "latrine": "TOILET",
    "sleep": "SLEEP", "rest": "SLEEP", "tired": "SLEEP",
    "phone": "PHONE", "mobile": "PHONE", "telephone": "PHONE", "cellphone": "PHONE",
    
    # People & Pronouns
    "i": "ME", "me": "ME", "my": "ME", "myself": "ME", "mine": "ME",
    "you": "YOU", "your": "YOU", "yours": "YOU",
    "we": "WE", "us": "WE", "our": "WE",
    "he": "HE_SHE", "she": "HE_SHE", "him": "HE_SHE", "her": "HE_SHE", "they": "HE_SHE",
    "family": "FAMILY",
    "mother": "MOTHER", "mom": "MOTHER", "mummy": "MOTHER", "ma": "MOTHER",
    "father": "FATHER", "dad": "FATHER", "papa": "FATHER",
    "child": "CHILD", "kid": "CHILD", "baby": "CHILD", "boy": "CHILD", "girl": "CHILD",
    
    # Questions
    "where": "WHERE", "wherein": "WHERE",
    "what": "WHAT",
    "when": "WHEN",
    "why": "WHY",
    "how": "HOW",
    "who": "WHO", "whom": "WHO",
    "much": "HOW_MUCH", "many": "HOW_MUCH", "price": "HOW_MUCH", "cost": "HOW_MUCH",
    
    # Verbs
    "want": "WANT", "need": "WANT", "require": "WANT", "wish": "WANT", "demand": "WANT",
    "come": "COME", "came": "COME", "arrive": "COME",
    "go": "GO", "went": "GO", "leave": "GO",
    "wait": "WAIT", "waiting": "WAIT", "hold": "WAIT",
    "understand": "UNDERSTAND", "understood": "UNDERSTAND", "know": "UNDERSTAND",
    "stop": "STOP", "halt": "STOP",
    "sit": "SIT", "seated": "SIT",
    "call": "CALL", "calling": "CALL",
    
    # Greetings
    "hello": "HELLO", "hi": "HELLO", "namaste": "HELLO", "hey": "HELLO", "greetings": "HELLO",
    "thank": "THANK_YOU", "thanks": "THANK_YOU",
    "please": "PLEASE", "kindly": "PLEASE",
    "sorry": "SORRY", "apologize": "SORRY", "excuse": "SORRY",
    "yes": "YES", "yeah": "YES", "yep": "YES", "correct": "YES", "true": "YES",
    "no": "NO", "nope": "NO", "never": "NO",
    "goodbye": "GOODBYE", "bye": "GOODBYE",
    "name": "NAME",
    
    # Time / School / Negation
    "time": "TIME", "clock": "TIME", "hour": "TIME",
    "today": "TODAY", "now": "TODAY",
    "tomorrow": "TOMORROW", "yesterday": "TOMORROW",
    "school": "SCHOOL", "college": "SCHOOL", "class": "SCHOOL", "classroom": "SCHOOL",
    "teacher": "TEACHER", "sir": "TEACHER", "madam": "TEACHER", "professor": "TEACHER",
    "book": "BOOK", "notebook": "BOOK", "paper": "BOOK",
    "not": "NOT", "dont": "NOT", "don't": "NOT", "cannot": "NOT", "cant": "NOT", "can't": "NOT",

    # ================= Hindi Words =================
    "मदद": "HELP", "सहायता": "HELP",
    "डॉक्टर": "DOCTOR", "डाक्टर": "DOCTOR", "वैद्य": "DOCTOR",
    "अस्पताल": "HOSPITAL", "दवाखाना": "HOSPITAL",
    "दर्द": "PAIN", "तकलीफ": "PAIN", "पीड़ा": "PAIN",
    "दवा": "MEDICINE", "दवाई": "MEDICINE", "गोली": "MEDICINE",
    "आपातकाल": "EMERGENCY", "ज़रूरी": "EMERGENCY", "जरूरी": "EMERGENCY",
    "खून": "BLOOD", "रक्त": "BLOOD",
    "नर्स": "NURSE", "सिस्टर": "NURSE",
    "बीमार": "SICK", "तबीयत": "SICK",
    "बुखार": "FEVER",
    "एम्बुलेंस": "AMBULANCE",
    
    "बैंक": "BANK",
    "पैसे": "MONEY", "रुपये": "MONEY", "रुपया": "MONEY", "धन": "MONEY", "कैश": "MONEY",
    "खाता": "ACCOUNT", "अकाउंट": "ACCOUNT",
    "जमा": "DEPOSIT",
    "निकालना": "WITHDRAW", "निकासी": "WITHDRAW",
    "हस्ताक्षर": "SIGN", "दस्तखत": "SIGN", "साइन": "SIGN",
    "कार्ड": "CARD", "एटीएम": "CARD",
    "ऋण": "LOAN", "कर्ज": "LOAN", "लोन": "LOAN",
    
    "पानी": "WATER", "जल": "WATER", "नीर": "WATER",
    "खाना": "FOOD", "भोजन": "FOOD", "रोटी": "FOOD", "भूख": "FOOD",
    "शौचालय": "TOILET", "बाथरूम": "TOILET", "टॉयलेट": "TOILET",
    "सोना": "SLEEP", "आराम": "SLEEP", "नींद": "SLEEP",
    "फोन": "PHONE", "मोबाइल": "PHONE",
    
    "मैं": "ME", "मुझे": "ME", "मेरा": "ME", "मेरी": "ME", "मेरे": "ME", "मुझको": "ME",
    "आप": "YOU", "तुम": "YOU", "तुम्हारा": "YOU", "आपका": "YOU", "तुम्हें": "YOU", "आपको": "YOU",
    "हम": "WE", "हमें": "WE", "हमारा": "WE",
    "वह": "HE_SHE", "वो": "HE_SHE", "उसका": "HE_SHE", "उसने": "HE_SHE", "उसे": "HE_SHE",
    "परिवार": "FAMILY",
    "माँ": "MOTHER", "माता": "MOTHER", "मम्मी": "MOTHER",
    "पिता": "FATHER", "बाप": "FATHER", "पापा": "FATHER",
    "बच्चा": "CHILD", "बच्चे": "CHILD", "लड़का": "CHILD", "लड़की": "CHILD",
    
    "कहाँ": "WHERE", "किधर": "WHERE",
    "क्या": "WHAT",
    "कब": "WHEN",
    "क्यों": "WHY",
    "कैसे": "HOW",
    "कौन": "WHO",
    "कितना": "HOW_MUCH", "कितने": "HOW_MUCH", "दाम": "HOW_MUCH", "कीमत": "HOW_MUCH",
    
    "चाहिए": "WANT", "मांगना": "WANT", "जरूरत": "WANT", "ज़रूरत": "WANT",
    "आना": "COME", "आओ": "COME", "आइए": "COME",
    "जाना": "GO", "जाओ": "GO", "जाइए": "GO",
    "रुकना": "WAIT", "इंतजार": "WAIT", "ठहरो": "WAIT",
    "समझना": "UNDERSTAND", "समझा": "UNDERSTAND", "समझे": "UNDERSTAND",
    "बंद": "STOP", "रुको": "STOP",
    "बैठना": "SIT", "बैठो": "SIT", "बैठिए": "SIT",
    "बुलाना": "CALL", "बुलाओ": "CALL",
    
    "नमस्ते": "HELLO", "प्रणाम": "HELLO", "नमस्कार": "HELLO",
    "धन्यवाद": "THANK_YOU", "शुक्रिया": "THANK_YOU",
    "कृपया": "PLEASE", "मेहरबानी": "PLEASE",
    "माफ": "SORRY", "क्षमा": "SORRY",
    "हाँ": "YES", "हां": "YES", "जी": "YES",
    "नहीं": "NO", "ना": "NO", "मत": "NO",
    "अलविदा": "GOODBYE",
    "नाम": "NAME",
    
    "समय": "TIME", "वक्त": "TIME", "बजे": "TIME",
    "आज": "TODAY", "अभी": "TODAY",
    "कल": "TOMORROW",
    "स्कूल": "SCHOOL", "विद्यालय": "SCHOOL", "पाठशाला": "SCHOOL",
    "अध्यापक": "TEACHER", "शिक्षक": "TEACHER", "गुरु": "TEACHER",
    "किताब": "BOOK", "पुस्तक": "BOOK",
}


def get_all_vocabulary() -> List[Dict[str, Any]]:
    return ISL_VOCABULARY


def lookup_gloss(word: str) -> Optional[str]:
    cleaned = word.strip().lower()
    return SYNONYM_MAP.get(cleaned)


def get_sign_metadata(gloss: str) -> Optional[Dict[str, Any]]:
    return GLOSS_BY_NAME.get(gloss)
