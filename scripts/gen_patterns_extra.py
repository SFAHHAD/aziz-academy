"""Generate 60 new Patterns brain-boost items."""
import json, sys, io

# Force UTF-8 stdout for Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

WESTERN = '0123456789'
ARABIC = '٠١٢٣٤٥٦٧٨٩'
TR = str.maketrans(WESTERN, ARABIC)

def ar_num(s):
    """Convert any digits in s to Arabic-Indic digits."""
    return str(s).translate(TR)

# Arabic letter sequence (for letter patterns) - alphabetical order:
# Latin: A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
# Arabic: أ ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن هـ و ي
# Aziz Academy uses simplified mapping per existing data:
# A->أ B->ب C->ج D->د E->هـ F->و G->ز H->ح I->ط J->ي K->ك L->ل M->م N->ن O->س P->ع
# Existing items show: A=أ, C=ج, E=هـ, G=ز, I=ط (m_001), M=م (e_011), Z=ز? wait z is end
# Let's use abjad order from existing: A=أ B=ب C=ج D=د E=هـ F=و G=ز H=ح I=ط J=ي K=ك L=ل M=م N=ن O=س P=ع Q=ف R=ص S=ق T=ر U=ش V=ت W=ث X=خ Y=ذ Z=ض
# But we should keep it simple — use only common arabic letters where existing items showed mappings
# From existing: M->م, N->ن, O->س, P->ع (e_011), X->خ Y->ذ Z->ض (e_016 likely)
# Actually e_016 says X,Y,Z next — we'll see what the existing answer shows. Skip ambiguity by avoiding rare letter sequences.

# We'll avoid X-Z and obscure Arabic letter sequences. Letter items will use simple ordering.
LETTER_MAP = {
    'A': 'أ', 'B': 'ب', 'C': 'ج', 'D': 'د', 'E': 'هـ', 'F': 'و',
    'G': 'ز', 'H': 'ح', 'I': 'ط', 'J': 'ي', 'K': 'ك', 'L': 'ل',
    'M': 'م', 'N': 'ن', 'O': 'س', 'P': 'ع', 'Q': 'ف', 'R': 'ص',
    'S': 'ق', 'T': 'ر', 'U': 'ش', 'V': 'ت', 'W': 'ث', 'X': 'خ',
    'Y': 'ذ', 'Z': 'ض',
}

def L(letter):
    return LETTER_MAP[letter]

def make(id_, diff, q, q_ar, opts, opts_ar, fact, fact_ar):
    assert len(opts) == 4 and len(opts_ar) == 4
    return {
        "id": id_,
        "category": "Patterns",
        "category_ar": "الأنماط",
        "difficulty": diff,
        "question": q,
        "question_ar": q_ar,
        "options": opts,
        "options_ar": opts_ar,
        "correct_answer": opts[0],
        "correct_answer_ar": opts_ar[0],
        "fun_fact": fact,
        "fun_fact_ar": fact_ar,
    }

def num_q_en(seq, missing_pos=None):
    """Build 'What number comes next? a, b, c, ?' (if missing_pos None)."""
    parts = [str(s) for s in seq]
    return "What number comes next?  " + ", ".join(parts) + ", ?"

def num_q_ar(seq):
    parts = [ar_num(s) for s in seq]
    return "ما العدد التالي؟  " + "، ".join(parts) + "، ؟"

def num_q_missing_en(seq_with_blank):
    """seq_with_blank: list with one element being None for blank."""
    parts = ["?" if s is None else str(s) for s in seq_with_blank]
    return "What number is missing?  " + ", ".join(parts)

def num_q_missing_ar(seq_with_blank):
    parts = ["؟" if s is None else ar_num(s) for s in seq_with_blank]
    return "ما العدد الناقص؟  " + "، ".join(parts)

def num_opts_en(correct, distractors):
    return [str(correct)] + [str(d) for d in distractors]

def num_opts_ar(correct, distractors):
    return [ar_num(correct)] + [ar_num(d) for d in distractors]

items = []

# ============== EASY (diff 1) — 20 items ==============
# Fresh patterns: count by 6, 7, 8, 9; down by 2, 3, 4; letter sequences fresh starts;
# fruit/animal/word patterns, days/months, count to 50

# e_031: count by 6 (new AP, not in existing easy)
items.append(make(
    "bb_pat_e_031", 1,
    num_q_en([0, 6, 12, 18]), num_q_ar([0, 6, 12, 18]),
    num_opts_en(24, [22, 26, 30]), num_opts_ar(24, [22, 26, 30]),
    "Each number adds 6 — counting in sixes.",
    "كل عدد يزيد بمقدار ٦ — العدّ بالستات."
))
# e_032: count by 7 (new AP, not in existing easy)
items.append(make(
    "bb_pat_e_032", 1,
    num_q_en([1, 8, 15, 22]), num_q_ar([1, 8, 15, 22]),
    num_opts_en(29, [28, 30, 27]), num_opts_ar(29, [28, 30, 27]),
    "Each number adds 7 — the gap stays the same.",
    "كل عدد يزيد بمقدار ٧ — الفجوة ثابتة."
))
# e_033: month sequence
items.append(make(
    "bb_pat_e_033", 1,
    "What month comes next?  January, February, March, April, ?",
    "ما الشهر التالي؟  يناير، فبراير، مارس، أبريل، ؟",
    ["May", "June", "July", "March"],
    ["مايو", "يونيو", "يوليو", "مارس"],
    "These are the months of the year in order.",
    "هذه أشهر السنة بالترتيب."
))
# e_034: 3-cycle shape pattern
items.append(make(
    "bb_pat_e_034", 1,
    "What shape comes next?  Circle, Square, Triangle, Circle, Square, ?",
    "ما الشكل التالي؟  دائرة، مربع، مثلث، دائرة، مربع، ؟",
    ["Triangle", "Circle", "Square", "Star"],
    ["مثلث", "دائرة", "مربع", "نجمة"],
    "Three shapes repeat in the same order each time.",
    "ثلاثة أشكال تتكرر بنفس الترتيب كل مرة."
))
# e_035: count down by 2 from 20
items.append(make(
    "bb_pat_e_035", 1,
    num_q_en([20, 18, 16, 14]), num_q_ar([20, 18, 16, 14]),
    num_opts_en(12, [10, 13, 15]), num_opts_ar(12, [10, 13, 15]),
    "Each number takes away 2 — counting backward by twos.",
    "كل عدد ينقص بمقدار ٢ — العدّ التنازلي بالاثنينات."
))
# Wait, that's same as e_010. Replace.
# e_035: count down by 4
items[-1] = make(
    "bb_pat_e_035", 1,
    num_q_en([24, 20, 16, 12]), num_q_ar([24, 20, 16, 12]),
    num_opts_en(8, [10, 6, 14]), num_opts_ar(8, [10, 6, 14]),
    "Each number takes away 4 — counting backward by fours.",
    "كل عدد ينقص بمقدار ٤ — العدّ التنازلي بالأربعات."
)
# e_036: count down by 3
items.append(make(
    "bb_pat_e_036", 1,
    num_q_en([30, 27, 24, 21]), num_q_ar([30, 27, 24, 21]),
    num_opts_en(18, [19, 17, 20]), num_opts_ar(18, [19, 17, 20]),
    "Each number takes away 3 — counting backward by threes.",
    "كل عدد ينقص بمقدار ٣ — العدّ التنازلي بالثلاثات."
))
# e_037: count down by 5
items.append(make(
    "bb_pat_e_037", 1,
    num_q_en([40, 35, 30, 25]), num_q_ar([40, 35, 30, 25]),
    num_opts_en(20, [22, 15, 24]), num_opts_ar(20, [22, 15, 24]),
    "Each number takes away 5 — counting backward by fives.",
    "كل عدد ينقص بمقدار ٥ — العدّ التنازلي بالخمسات."
))
# e_038: count down by 1 from 30
items.append(make(
    "bb_pat_e_038", 1,
    num_q_en([30, 29, 28, 27]), num_q_ar([30, 29, 28, 27]),
    num_opts_en(26, [25, 28, 24]), num_opts_ar(26, [25, 28, 24]),
    "Each number takes away 1 — counting backward.",
    "كل عدد ينقص بمقدار ١ — العدّ التنازلي."
))
# e_039: 1,2,3 then repeat sequence
items.append(make(
    "bb_pat_e_039", 1,
    num_q_en([1, 2, 3, 1, 2]), num_q_ar([1, 2, 3, 1, 2]),
    num_opts_en(3, [4, 1, 5]), num_opts_ar(3, [4, 1, 5]),
    "The numbers 1, 2, 3 keep repeating in order.",
    "الأعداد ١ و٢ و٣ تتكرر بالترتيب."
))
# e_040: F G H I -> J
items.append(make(
    "bb_pat_e_040", 1,
    f"What letter comes next?  F, G, H, I, ?",
    f"ما الحرف التالي؟  {L('F')}، {L('G')}، {L('H')}، {L('I')}، ؟",
    [L('J'), L('K'), L('H'), L('L')],
    [L('J'), L('K'), L('H'), L('L')],
    "Each letter is the next one in the alphabet.",
    "كل حرف هو التالي في الأبجدية."
))
# Fix: options should be English letters, options_ar are Arabic letters
items[-1] = make(
    "bb_pat_e_040", 1,
    f"What letter comes next?  F, G, H, I, ?",
    f"ما الحرف التالي؟  {L('F')}، {L('G')}، {L('H')}، {L('I')}، ؟",
    ["J", "K", "H", "L"],
    [L('J'), L('K'), L('H'), L('L')],
    "Each letter is the next one in the alphabet.",
    "كل حرف هو التالي في الأبجدية."
)
# e_041: J K L M -> N
items.append(make(
    "bb_pat_e_041", 1,
    "What letter comes next?  J, K, L, M, ?",
    f"ما الحرف التالي؟  {L('J')}، {L('K')}، {L('L')}، {L('M')}، ؟",
    ["N", "O", "P", "L"],
    [L('N'), L('O'), L('P'), L('L')],
    "Each letter is the next one in the alphabet.",
    "كل حرف هو التالي في الأبجدية."
))
# e_042: P Q R S -> T
items.append(make(
    "bb_pat_e_042", 1,
    "What letter comes next?  P, Q, R, S, ?",
    f"ما الحرف التالي؟  {L('P')}، {L('Q')}، {L('R')}، {L('S')}، ؟",
    ["T", "U", "V", "Q"],
    [L('T'), L('U'), L('V'), L('Q')],
    "Each letter is the next one in the alphabet.",
    "كل حرف هو التالي في الأبجدية."
))
# e_043: pattern Cat, Dog, Cat, Dog, ? -> Cat
items.append(make(
    "bb_pat_e_043", 1,
    "What comes next?  Cat, Dog, Cat, Dog, ?",
    "ما التالي؟  قطة، كلب، قطة، كلب، ؟",
    ["Cat", "Dog", "Bird", "Fish"],
    ["قطة", "كلب", "طائر", "سمكة"],
    "The pattern alternates between cat and dog.",
    "النمط يتبادل بين القطة والكلب."
))
# e_044: Sun, Cloud, Sun, Cloud -> Sun
items.append(make(
    "bb_pat_e_044", 1,
    "What comes next?  Sun, Cloud, Sun, Cloud, ?",
    "ما التالي؟  شمس، سحابة، شمس، سحابة، ؟",
    ["Sun", "Cloud", "Rain", "Moon"],
    ["شمس", "سحابة", "مطر", "قمر"],
    "The pattern alternates between sun and cloud.",
    "النمط يتبادل بين الشمس والسحابة."
))
# e_045: Up, Down, Up, Down -> Up
items.append(make(
    "bb_pat_e_045", 1,
    "What comes next?  Up, Down, Up, Down, ?",
    "ما التالي؟  فوق، تحت، فوق، تحت، ؟",
    ["Up", "Down", "Left", "Right"],
    ["فوق", "تحت", "يسار", "يمين"],
    "The pattern flips between up and down.",
    "النمط يتبادل بين فوق وتحت."
))
# e_046: Triangle, Square, Pentagon -> Hexagon (but kid friendly) -- skip; use simple shapes
# e_046: Hot, Cold, Hot, Cold -> Hot
items.append(make(
    "bb_pat_e_046", 1,
    "What comes next?  Hot, Cold, Hot, Cold, ?",
    "ما التالي؟  حار، بارد، حار، بارد، ؟",
    ["Hot", "Cold", "Warm", "Cool"],
    ["حار", "بارد", "دافئ", "منعش"],
    "The pattern switches between hot and cold each time.",
    "النمط يتبدل بين الحار والبارد كل مرة."
))
# e_047: Mon, Tue, Wed, Thu -> Fri
items.append(make(
    "bb_pat_e_047", 1,
    "What day comes next?  Monday, Tuesday, Wednesday, Thursday, ?",
    "ما اليوم التالي؟  الإثنين، الثلاثاء، الأربعاء، الخميس، ؟",
    ["Friday", "Saturday", "Sunday", "Thursday"],
    ["الجمعة", "السبت", "الأحد", "الخميس"],
    "These are the days of the week in order.",
    "هذه أيام الأسبوع بالترتيب."
))
# e_048: 1,2,1,2,1 -> 2 (simple alternating numbers)
items.append(make(
    "bb_pat_e_048", 1,
    num_q_en([1, 2, 1, 2, 1]), num_q_ar([1, 2, 1, 2, 1]),
    num_opts_en(2, [1, 3, 0]), num_opts_ar(2, [1, 3, 0]),
    "The numbers 1 and 2 take turns over and over.",
    "العددان ١ و٢ يتبادلان مرارًا."
))
# e_049: smile-frown words alternating
items.append(make(
    "bb_pat_e_049", 1,
    "What comes next?  Yes, No, Yes, No, ?",
    "ما التالي؟  نعم، لا، نعم، لا، ؟",
    ["Yes", "No", "Maybe", "Sure"],
    ["نعم", "لا", "ربما", "أكيد"],
    "The pattern flips between yes and no each time.",
    "النمط يتبادل بين نعم ولا كل مرة."
))
# e_050: 4-step letter cycle A B C D A B C -> D
items.append(make(
    "bb_pat_e_050", 1,
    "What letter comes next?  A, B, C, D, A, B, C, ?",
    f"ما الحرف التالي؟  {L('A')}، {L('B')}، {L('C')}، {L('D')}، {L('A')}، {L('B')}، {L('C')}، ؟",
    ["D", "A", "E", "B"],
    [L('D'), L('A'), L('E'), L('B')],
    "Four letters keep repeating — A, B, C, D over and over.",
    "أربعة حروف تتكرر — أ ب ج د مرارًا."
))

# ============== MEDIUM (diff 2) — 20 items ==============
# Fresh: alternating add/subtract, +1/+2/+3 increasing gap, doubling+1, half pattern, etc.

# m_031: alternating +2, +3 (1,3,6,8,11,?) -> next +3 = 13? wait pattern: +2,+3,+2,+3 -> 1,3,6,8,11,13
items.append(make(
    "bb_pat_m_031", 2,
    num_q_en([1, 3, 6, 8, 11]), num_q_ar([1, 3, 6, 8, 11]),
    num_opts_en(13, [14, 12, 15]), num_opts_ar(13, [14, 12, 15]),
    "The pattern adds 2, then 3, then 2, then 3 — switching each step.",
    "النمط يضيف ٢ ثم ٣ ثم ٢ ثم ٣ — يتبدل في كل خطوة."
))
# m_032: alternating +1, +4 (2,3,7,8,12,?) -> +1 next? sequence: +1,+4,+1,+4 -> 2,3,7,8,12,13
items.append(make(
    "bb_pat_m_032", 2,
    num_q_en([2, 3, 7, 8, 12]), num_q_ar([2, 3, 7, 8, 12]),
    num_opts_en(13, [16, 14, 17]), num_opts_ar(13, [16, 14, 17]),
    "Add 1, then add 4, and repeat — the gap keeps switching.",
    "نضيف ١ ثم نضيف ٤ ونكرر — الفجوة تتبدل."
))
# m_033: +3, +5, +3, +5 (5, 8, 13, 16, 21, ?) -> 24
items.append(make(
    "bb_pat_m_033", 2,
    num_q_en([5, 8, 13, 16, 21]), num_q_ar([5, 8, 13, 16, 21]),
    num_opts_en(24, [25, 26, 23]), num_opts_ar(24, [25, 26, 23]),
    "Add 3, then add 5 — the pattern alternates between two jumps.",
    "نضيف ٣ ثم ٥ — النمط يتبدل بين قفزتين."
))
# m_034: doubling + 1 (1, 3, 7, 15, 31, ?) -> 63
items.append(make(
    "bb_pat_m_034", 2,
    num_q_en([1, 3, 7, 15, 31]), num_q_ar([1, 3, 7, 15, 31]),
    num_opts_en(63, [62, 47, 64]), num_opts_ar(63, [62, 47, 64]),
    "Each number doubles and then adds 1.",
    "كل عدد يتضاعف ثم نضيف ١."
))
# Wait — bb_pat_h_019 has 1,3,7,15,31 already. Replace.
items[-1] = make(
    "bb_pat_m_034", 2,
    num_q_en([1, 3, 7, 15]), num_q_ar([1, 3, 7, 15]),
    num_opts_en(31, [30, 23, 32]), num_opts_ar(31, [30, 23, 32]),
    "Each number doubles and then adds 1.",
    "كل عدد يتضاعف ثم نضيف ١."
)
# Hmm still overlaps. Replace with different rule.
items[-1] = make(
    "bb_pat_m_034", 2,
    num_q_en([2, 5, 11, 23]), num_q_ar([2, 5, 11, 23]),
    num_opts_en(47, [46, 35, 45]), num_opts_ar(47, [46, 35, 45]),
    "Each number doubles and then adds 1.",
    "كل عدد يتضاعف ثم نضيف ١."
)
# Hmm, h_005 is 2,5,11,23. Let me change the rule.
# Use: doubling minus 1 (2, 3, 5, 9, 17, ?) -> 33
items[-1] = make(
    "bb_pat_m_034", 2,
    num_q_en([2, 3, 5, 9, 17]), num_q_ar([2, 3, 5, 9, 17]),
    num_opts_en(33, [34, 25, 32]), num_opts_ar(33, [34, 25, 32]),
    "Each number doubles and then takes 1 away.",
    "كل عدد يتضاعف ثم نطرح ١."
)

# m_035: half pattern (80, 40, 20, 10, ?) -> 5
items.append(make(
    "bb_pat_m_035", 2,
    num_q_en([80, 40, 20, 10]), num_q_ar([80, 40, 20, 10]),
    num_opts_en(5, [6, 8, 4]), num_opts_ar(5, [6, 8, 4]),
    "Each number is half of the one before it.",
    "كل عدد هو نصف العدد الذي قبله."
))
# m_036: triangular numbers continuing (15, 21, 28, 36, ?) -> 45
items.append(make(
    "bb_pat_m_036", 2,
    num_q_en([15, 21, 28, 36]), num_q_ar([15, 21, 28, 36]),
    num_opts_en(45, [44, 46, 48]), num_opts_ar(45, [44, 46, 48]),
    "The gap grows by 1 each time — triangular numbers.",
    "تكبر الفجوة بمقدار ١ في كل مرة — الأعداد المثلثية."
))
# m_037: alternating *2, +1 (1, 2, 3, 6, 7, 14, ?) -> 15
items.append(make(
    "bb_pat_m_037", 2,
    num_q_en([1, 2, 3, 6, 7, 14]), num_q_ar([1, 2, 3, 6, 7, 14]),
    num_opts_en(15, [28, 16, 21]), num_opts_ar(15, [28, 16, 21]),
    "Add 1, then double, and repeat — two rules taking turns.",
    "نضيف ١ ثم نضاعف ونكرر — قاعدتان تتبادلان."
))
# m_038: subtract increasing (50, 49, 47, 44, 40, ?) -> 35
items.append(make(
    "bb_pat_m_038", 2,
    num_q_en([50, 49, 47, 44, 40]), num_q_ar([50, 49, 47, 44, 40]),
    num_opts_en(35, [34, 36, 38]), num_opts_ar(35, [34, 36, 38]),
    "We subtract 1, then 2, then 3, then 4 — the gap keeps growing.",
    "نطرح ١ ثم ٢ ثم ٣ ثم ٤ — الفجوة تكبر."
))
# m_039: 3,5,4,6,5,7 -> 6 (alt +2,-1)
items.append(make(
    "bb_pat_m_039", 2,
    num_q_en([3, 5, 4, 6, 5, 7]), num_q_ar([3, 5, 4, 6, 5, 7]),
    num_opts_en(6, [8, 5, 9]), num_opts_ar(6, [8, 5, 9]),
    "Add 2, then take 1 away — repeat both steps.",
    "نضيف ٢ ثم نطرح ١ — نكرر الخطوتين."
))
# m_040: missing in middle: 7, 14, ?, 28, 35 -> 21
items.append(make(
    "bb_pat_m_040", 2,
    num_q_missing_en([7, 14, None, 28, 35]),
    num_q_missing_ar([7, 14, None, 28, 35]),
    num_opts_en(21, [20, 22, 24]), num_opts_ar(21, [20, 22, 24]),
    "Counting by sevens — the missing number is between 14 and 28.",
    "العدّ بالسبعات — العدد الناقص بين ١٤ و٢٨."
))
# m_041: missing: 6, 12, 24, ?, 96 -> 48
items.append(make(
    "bb_pat_m_041", 2,
    num_q_missing_en([6, 12, 24, None, 96]),
    num_q_missing_ar([6, 12, 24, None, 96]),
    num_opts_en(48, [36, 50, 72]), num_opts_ar(48, [36, 50, 72]),
    "Each number doubles — twice 24 is 48.",
    "كل عدد يتضاعف — ضِعف ٢٤ هو ٤٨."
))
# m_042: alternating letters G I K M -> O
items.append(make(
    "bb_pat_m_042", 2,
    "What letter comes next?  G, I, K, M, ?",
    f"ما الحرف التالي؟  {L('G')}، {L('I')}، {L('K')}، {L('M')}، ؟",
    ["O", "N", "P", "Q"],
    [L('O'), L('N'), L('P'), L('Q')],
    "Skip one letter each time — every other letter of the alphabet.",
    "نتجاوز حرفًا كل مرة — كل حرف ثانٍ من الأبجدية."
))
# m_043: Y W U S -> Q (skip back by 2)
items.append(make(
    "bb_pat_m_043", 2,
    "What letter comes next?  Y, W, U, S, ?",
    f"ما الحرف التالي؟  {L('Y')}، {L('W')}، {L('U')}، {L('S')}، ؟",
    ["Q", "R", "P", "T"],
    [L('Q'), L('R'), L('P'), L('T')],
    "Skip one letter each time — going backward through the alphabet.",
    "نتجاوز حرفًا كل مرة — نسير للخلف في الأبجدية."
))
# m_044: pattern of 3-step shapes
items.append(make(
    "bb_pat_m_044", 2,
    "What shape comes next?  Circle, Triangle, Star, Circle, Triangle, ?",
    "ما الشكل التالي؟  دائرة، مثلث، نجمة، دائرة، مثلث، ؟",
    ["Star", "Circle", "Triangle", "Square"],
    ["نجمة", "دائرة", "مثلث", "مربع"],
    "Three shapes repeat in the same order — circle, triangle, star.",
    "ثلاثة أشكال تتكرر بنفس الترتيب — دائرة ومثلث ونجمة."
))
# m_045: 100 to 200 by 20 (100, 120, 140, 160, ?) -> 180
items.append(make(
    "bb_pat_m_045", 2,
    num_q_en([100, 120, 140, 160]), num_q_ar([100, 120, 140, 160]),
    num_opts_en(180, [170, 200, 175]), num_opts_ar(180, [170, 200, 175]),
    "Each number adds 20 — counting in twenties.",
    "كل عدد يزيد بمقدار ٢٠ — العدّ بالعشرينات."
))
# m_046: 144, 121, 100, 81 -> 64 (descending squares)
items.append(make(
    "bb_pat_m_046", 2,
    num_q_en([144, 121, 100, 81]), num_q_ar([144, 121, 100, 81]),
    num_opts_en(64, [60, 72, 49]), num_opts_ar(64, [60, 72, 49]),
    "These are square numbers going down — 12, 11, 10, 9, then 8 squared.",
    "هذه أعداد مربعة تنازليًا — ١٢ و١١ و١٠ و٩ ثم ٨ تربيع."
))
# m_047: 1, 2, 4, 7, 11, 16 -> 22 — wait existing (h_006 is 1,2,4,7,11,16)
# Use 2, 3, 5, 8, 12 -> 17 (gap +1,+2,+3,+4 then +5)
items.append(make(
    "bb_pat_m_047", 2,
    num_q_en([2, 3, 5, 8, 12]), num_q_ar([2, 3, 5, 8, 12]),
    num_opts_en(17, [16, 18, 20]), num_opts_ar(17, [16, 18, 20]),
    "The gap grows by 1 each time — add 1, then 2, then 3, then 4, then 5.",
    "تكبر الفجوة بمقدار ١ كل مرة — نضيف ١ ثم ٢ ثم ٣ ثم ٤ ثم ٥."
))
# m_048: 2, 4, 7, 14, 17, 34 -> 37 (alt +2, *2, +3, *2, +3)
# Cleaner: alt *2, +3 (2, 4, 7, 14, 17, 34) -> next *2 = 68? Pattern: 2->*2=4->+3=7->*2=14->+3=17->*2=34->+3=37
items.append(make(
    "bb_pat_m_048", 2,
    num_q_en([2, 4, 7, 14, 17, 34]), num_q_ar([2, 4, 7, 14, 17, 34]),
    num_opts_en(37, [68, 38, 36]), num_opts_ar(37, [68, 38, 36]),
    "Double, then add 3, and repeat — two rules take turns.",
    "نضاعف ثم نضيف ٣ ونكرر — قاعدتان تتبادلان."
))
# m_049: counting by 11 (11, 22, 33, 44 already exists m_023). Use by 12: 12,24,36,48 -> 60
items.append(make(
    "bb_pat_m_049", 2,
    num_q_en([12, 24, 36, 48]), num_q_ar([12, 24, 36, 48]),
    num_opts_en(60, [56, 64, 50]), num_opts_ar(60, [56, 64, 50]),
    "Each number adds 12 — counting in dozens.",
    "كل عدد يزيد بمقدار ١٢ — العدّ بالاثنتي عشرة."
))
# m_050: missing in pattern with offset: 5, 10, 16, ?, 31, 40 -> 23 (gap +5,+6,+7,+8,+9)
items.append(make(
    "bb_pat_m_050", 2,
    num_q_missing_en([5, 10, 16, None, 31, 40]),
    num_q_missing_ar([5, 10, 16, None, 31, 40]),
    num_opts_en(23, [22, 24, 25]), num_opts_ar(23, [22, 24, 25]),
    "The gap grows by 1 each step — add 5, 6, 7, then 8.",
    "تكبر الفجوة بمقدار ١ كل خطوة — نضيف ٥ ثم ٦ ثم ٧ ثم ٨."
))

# ============== HARD (diff 3) — 20 items ==============

# h_031: Lucas numbers (2, 1, 3, 4, 7, 11, ?) -> 18
items.append(make(
    "bb_pat_h_031", 3,
    num_q_en([2, 1, 3, 4, 7, 11]), num_q_ar([2, 1, 3, 4, 7, 11]),
    num_opts_en(18, [17, 19, 22]), num_opts_ar(18, [17, 19, 22]),
    "Each number is the sum of the two before it — these are the Lucas numbers.",
    "كل عدد هو مجموع العددين قبله — هذه أعداد لوكاس."
))
# h_032: factorial 1, 1, 2, 6, 24 -> 120
items.append(make(
    "bb_pat_h_032", 3,
    num_q_en([1, 1, 2, 6, 24]), num_q_ar([1, 1, 2, 6, 24]),
    num_opts_en(120, [96, 48, 100]), num_opts_ar(120, [96, 48, 100]),
    "Multiply by 1, then 2, then 3, then 4, then 5 — these are factorials.",
    "نضرب في ١ ثم ٢ ثم ٣ ثم ٤ ثم ٥ — هذه أعداد المضروب."
))
# h_033: prime gaps: 11, 13, 17, 19, 23 -> 29
items.append(make(
    "bb_pat_h_033", 3,
    num_q_en([11, 13, 17, 19, 23]), num_q_ar([11, 13, 17, 19, 23]),
    num_opts_en(29, [27, 25, 31]), num_opts_ar(29, [27, 25, 31]),
    "These are prime numbers in order — 29 is the next prime after 23.",
    "هذه أعداد أولية بالترتيب — ٢٩ هو الأولي التالي بعد ٢٣."
))
# h_034: n^2 + 1: 2, 5, 10, 17, 26 (existing h_028!). Use n^2 - 1: 0, 3, 8, 15, 24 -> 35
items.append(make(
    "bb_pat_h_034", 3,
    num_q_en([0, 3, 8, 15, 24]), num_q_ar([0, 3, 8, 15, 24]),
    num_opts_en(35, [33, 36, 34]), num_opts_ar(35, [33, 36, 34]),
    "Each number is a square minus 1 — 1, 4, 9, 16, 25, 36 take away 1.",
    "كل عدد هو مربع مطروح منه ١ — ١ و٤ و٩ و١٦ و٢٥ و٣٦ ناقص ١."
))
# h_035: half each time with decimal continued: 200, 100, 50, 25 -> 12.5
items.append(make(
    "bb_pat_h_035", 3,
    num_q_en([200, 100, 50, 25]), num_q_ar([200, 100, 50, 25]),
    num_opts_en("12.5", ["13", "10", "20"]), num_opts_ar("12.5", ["13", "10", "20"]),
    "Each number is half of the one before — halving keeps shrinking it.",
    "كل عدد هو نصف ما قبله — التنصيف يصغّره باستمرار."
))
# Wait — Arabic uses '٫' as decimal separator. Use that.
items[-1] = make(
    "bb_pat_h_035", 3,
    num_q_en([200, 100, 50, 25]), num_q_ar([200, 100, 50, 25]),
    ["12.5", "13", "10", "20"], ["١٢٫٥", "١٣", "١٠", "٢٠"],
    "Each number is half of the one before — halving keeps shrinking it.",
    "كل عدد هو نصف ما قبله — التنصيف يصغّره باستمرار."
)

# h_036: powers of 4: 1, 4, 16, 64 -> 256
items.append(make(
    "bb_pat_h_036", 3,
    num_q_en([1, 4, 16, 64]), num_q_ar([1, 4, 16, 64]),
    num_opts_en(256, [128, 196, 144]), num_opts_ar(256, [128, 196, 144]),
    "Each number is multiplied by 4 — these are powers of four.",
    "كل عدد يضرب في ٤ — هذه قوى الأربعة."
))
# h_037: n^3 - 1: 0, 7, 26, 63, 124 -> 215
items.append(make(
    "bb_pat_h_037", 3,
    num_q_en([0, 7, 26, 63, 124]), num_q_ar([0, 7, 26, 63, 124]),
    num_opts_en(215, [216, 200, 224]), num_opts_ar(215, [216, 200, 224]),
    "Each number is a cube minus 1 — 1, 8, 27, 64, 125, 216 take away 1.",
    "كل عدد هو مكعب مطروح منه ١ — ١ و٨ و٢٧ و٦٤ و١٢٥ و٢١٦ ناقص ١."
))
# h_038: alternating subtract pattern 100, 95, 85, 80, 70, ? (-5,-10,-5,-10) -> 65
items.append(make(
    "bb_pat_h_038", 3,
    num_q_en([100, 95, 85, 80, 70]), num_q_ar([100, 95, 85, 80, 70]),
    num_opts_en(65, [60, 64, 75]), num_opts_ar(65, [60, 64, 75]),
    "Take away 5, then 10, and repeat both jumps.",
    "نطرح ٥ ثم ٧ ثم نكرر — لا، نطرح ٥ ثم ١٠ ونكرر الخطوتين."
))
# Cleaner Arabic
items[-1] = make(
    "bb_pat_h_038", 3,
    num_q_en([100, 95, 85, 80, 70]), num_q_ar([100, 95, 85, 80, 70]),
    num_opts_en(65, [60, 64, 75]), num_opts_ar(65, [60, 64, 75]),
    "Take away 5, then take away 10 — keep alternating both jumps.",
    "نطرح ٥ ثم نطرح ١٠ — نكرر الخطوتين بالتناوب."
)
# h_039: pattern n*(n+1): 2, 6, 12, 20, 30 (h_017 has this!). Use n*(n+2): 3, 8, 15, 24, 35 -> 48
items.append(make(
    "bb_pat_h_039", 3,
    num_q_en([3, 8, 15, 24, 35]), num_q_ar([3, 8, 15, 24, 35]),
    num_opts_en(48, [46, 49, 50]), num_opts_ar(48, [46, 49, 50]),
    "Multiply each whole number by itself plus 2 — like 1*3, 2*4, 3*5.",
    "نضرب كل عدد صحيح في نفسه زائد ٢ — مثل ١×٣ و٢×٤ و٣×٥."
))
# h_040: difference of squares like 7, 12, 19, 28, 39 -> 52 (gap +5,+7,+9,+11,+13)
items.append(make(
    "bb_pat_h_040", 3,
    num_q_en([7, 12, 19, 28, 39]), num_q_ar([7, 12, 19, 28, 39]),
    num_opts_en(52, [50, 51, 53]), num_opts_ar(52, [50, 51, 53]),
    "The gap grows by 2 each step — odd numbers added in order.",
    "تكبر الفجوة بمقدار ٢ كل خطوة — نضيف الأعداد الفردية بالترتيب."
))
# h_041: pattern times 3 minus 1: 1, 2, 5, 14, 41 -> 122
items.append(make(
    "bb_pat_h_041", 3,
    num_q_en([1, 2, 5, 14, 41]), num_q_ar([1, 2, 5, 14, 41]),
    num_opts_en(122, [123, 120, 100]), num_opts_ar(122, [123, 120, 100]),
    "Multiply by 3 then take 1 away — repeat that rule each step.",
    "نضرب في ٣ ثم نطرح ١ — نكرر القاعدة كل خطوة."
))
# h_042: Padovan-ish: 1, 1, 1, 2, 2, 3, 4, 5 -> 7
items.append(make(
    "bb_pat_h_042", 3,
    num_q_en([1, 1, 1, 2, 2, 3, 4, 5]), num_q_ar([1, 1, 1, 2, 2, 3, 4, 5]),
    num_opts_en(7, [6, 8, 9]), num_opts_ar(7, [6, 8, 9]),
    "Each number is the sum of the two from earlier in the sequence — Padovan numbers.",
    "كل عدد هو مجموع عددين أقدم في المتتالية — أعداد بادوفان."
))
# h_043: Fibonacci doubled positions or sum of two before with start: 0, 1, 1, 2, 3, 5, 8, 13 -> 21
# Existing h_001: 1,1,2,3,5,8 and h_018 has Fib missing too. Use 0-start variant: 0, 1, 1, 2, 3, 5 -> 8
# Actually let's do a different rule: each = sum of all previous: 1, 1, 2, 4, 8, 16 -> 32
items.append(make(
    "bb_pat_h_043", 3,
    num_q_en([1, 1, 2, 4, 8, 16]), num_q_ar([1, 1, 2, 4, 8, 16]),
    num_opts_en(32, [24, 30, 34]), num_opts_ar(32, [24, 30, 34]),
    "Each number is the sum of all the numbers before it.",
    "كل عدد هو مجموع كل الأعداد التي قبله."
))
# h_044: 1*2, 2*3, 3*4, 4*5, 5*6 = 2,6,12,20,30 (exists h_017). Use n^2 + n + 1 hard: 3, 7, 13, 21, 31 -> 43 (gap +4,+6,+8,+10,+12)
items.append(make(
    "bb_pat_h_044", 3,
    num_q_en([3, 7, 13, 21, 31]), num_q_ar([3, 7, 13, 21, 31]),
    num_opts_en(43, [41, 45, 42]), num_opts_ar(43, [41, 45, 42]),
    "The gap grows by 2 each step — add 4, then 6, then 8, then 10, then 12.",
    "تكبر الفجوة بمقدار ٢ كل خطوة — نضيف ٤ ثم ٦ ثم ٨ ثم ١٠ ثم ١٢."
))
# h_045: alternating two sequences interleaved: 1, 10, 2, 20, 3, 30, 4 -> 40
items.append(make(
    "bb_pat_h_045", 3,
    num_q_en([1, 10, 2, 20, 3, 30, 4]), num_q_ar([1, 10, 2, 20, 3, 30, 4]),
    num_opts_en(40, [5, 50, 14]), num_opts_ar(40, [5, 50, 14]),
    "Two sequences are mixed — counting up and counting by tens take turns.",
    "متتاليتان متشابكتان — العدّ للأمام والعدّ بالعشرات يتبادلان."
))
# h_046: pyramid sums: 1, 5, 14, 30, 55 (h_027). Use pentagonal numbers: 1, 5, 12, 22, 35 -> 51
items.append(make(
    "bb_pat_h_046", 3,
    num_q_en([1, 5, 12, 22, 35]), num_q_ar([1, 5, 12, 22, 35]),
    num_opts_en(51, [49, 50, 52]), num_opts_ar(51, [49, 50, 52]),
    "The gap grows by 3 each step — add 4, 7, 10, 13, 16 — pentagonal numbers.",
    "تكبر الفجوة بمقدار ٣ كل خطوة — نضيف ٤ ثم ٧ ثم ١٠ ثم ١٣ ثم ١٦ — الأعداد الخماسية."
))
# h_047: hexagonal: 1, 6, 15, 28, 45 -> 66
items.append(make(
    "bb_pat_h_047", 3,
    num_q_en([1, 6, 15, 28, 45]), num_q_ar([1, 6, 15, 28, 45]),
    num_opts_en(66, [64, 70, 60]), num_opts_ar(66, [64, 70, 60]),
    "The gap grows by 4 each step — these are hexagonal numbers.",
    "تكبر الفجوة بمقدار ٤ كل خطوة — هذه الأعداد السداسية."
))
# h_048: 81, 27, 9, 3 -> 1 (divide by 3)
items.append(make(
    "bb_pat_h_048", 3,
    num_q_en([81, 27, 9, 3]), num_q_ar([81, 27, 9, 3]),
    num_opts_en(1, [0, 2, 6]), num_opts_ar(1, [0, 2, 6]),
    "Each number is divided by 3 — going down the powers of three.",
    "كل عدد يقسم على ٣ — نعود في قوى الثلاثة."
))
# h_049: digit sum game: 12, 14, 17, 21, 26 -> 32 (gap = digit sum? 12->1+2=3 no)
# Use centered triangular: 1, 4, 10, 19, 31 -> 46 (gap +3,+6,+9,+12,+15)
items.append(make(
    "bb_pat_h_049", 3,
    num_q_en([1, 4, 10, 19, 31]), num_q_ar([1, 4, 10, 19, 31]),
    num_opts_en(46, [43, 47, 48]), num_opts_ar(46, [43, 47, 48]),
    "The gap grows by 3 each step — add 3, then 6, then 9, then 12, then 15.",
    "تكبر الفجوة بمقدار ٣ كل خطوة — نضيف ٣ ثم ٦ ثم ٩ ثم ١٢ ثم ١٥."
))
# h_050: 2, 3, 5, 8, 13, 21 (Fib-ish from 2,3) -> 34
items.append(make(
    "bb_pat_h_050", 3,
    num_q_en([2, 3, 5, 8, 13, 21]), num_q_ar([2, 3, 5, 8, 13, 21]),
    num_opts_en(34, [33, 35, 32]), num_opts_ar(34, [33, 35, 32]),
    "Each number is the sum of the two before it — like Fibonacci, starting from 2 and 3.",
    "كل عدد هو مجموع العددين قبله — مثل فيبوناتشي، بدءًا من ٢ و٣."
))

# ===== Verify counts =====
easy = [it for it in items if it['difficulty'] == 1]
med  = [it for it in items if it['difficulty'] == 2]
hard = [it for it in items if it['difficulty'] == 3]
print(f"Easy: {len(easy)}  Medium: {len(med)}  Hard: {len(hard)}  Total: {len(items)}")

# Write JSON
out_path = r"C:/Users/sfahh/Desktop/Project/Aziz Academy/assets/data/brain_boost_patterns_extra.json"
with open(out_path, 'w', encoding='utf-8') as f:
    json.dump(items, f, ensure_ascii=False, indent=2)

# === Self-validation ===
with open(out_path, 'r', encoding='utf-8') as f:
    loaded = json.load(f)

REQUIRED_KEYS = {
    "id","category","category_ar","difficulty","question","question_ar",
    "options","options_ar","correct_answer","correct_answer_ar","fun_fact","fun_fact_ar"
}

assert len(loaded) == 60, f"Expected 60, got {len(loaded)}"
ids = set()
diff_count = {1:0, 2:0, 3:0}
borderline = []

for it in loaded:
    keys = set(it.keys())
    missing = REQUIRED_KEYS - keys
    assert not missing, f"{it.get('id')} missing keys: {missing}"
    assert len(it['options']) == 4, f"{it['id']} options wrong len: {len(it['options'])}"
    assert len(it['options_ar']) == 4, f"{it['id']} options_ar wrong len: {len(it['options_ar'])}"
    assert it['options'][0] == it['correct_answer'], f"{it['id']} options[0] != correct_answer"
    assert it['options_ar'][0] == it['correct_answer_ar'], f"{it['id']} options_ar[0] != correct_answer_ar"
    assert it['id'] not in ids, f"duplicate id {it['id']}"
    ids.add(it['id'])
    diff_count[it['difficulty']] += 1
    # Check Arabic-Indic: question_ar should not contain 0-9 western digits (allow ٫ etc.)
    for fld in ['question_ar', 'correct_answer_ar']:
        if any(ch in it[fld] for ch in '0123456789'):
            borderline.append(f"{it['id']}: western digit in {fld}: {it[fld]}")
    for s in it['options_ar']:
        if any(ch in s for ch in '0123456789'):
            borderline.append(f"{it['id']}: western digit in options_ar: {s}")
    # Check id letter matches difficulty
    parts = it['id'].split('_')
    letter = parts[2]
    expected_diff = {'e':1,'m':2,'h':3}[letter]
    assert expected_diff == it['difficulty'], f"{it['id']} diff mismatch"

print("ALL VALIDATIONS PASSED")
print(f"By difficulty: easy={diff_count[1]} medium={diff_count[2]} hard={diff_count[3]}")
print(f"Unique IDs: {len(ids)}")
if borderline:
    print("BORDERLINE:")
    for b in borderline:
        print(" ", b)
else:
    print("No borderline items flagged.")
