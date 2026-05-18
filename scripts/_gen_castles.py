#!/usr/bin/env python3
"""Generate famous_castles_world.json — strict spec by user.

Schema:
- 60 items, ids cas_001..cas_060
- type: multiple_choice; category: history; difficulty: easy|medium|hard
- options[0] == correct_answer; same _ar
- Arabic strings use ٠-٩ ONLY (no Western digits anywhere in *_ar)
- image: ""
"""
from __future__ import annotations
import json, re, sys
from pathlib import Path

OUT = Path(r"C:/Users/sfahh/Desktop/Project/Aziz Academy/assets/data/famous_castles_world.json")

# Helper to convert Western digits to Arabic-Indic in *_ar strings.
W2A = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")
def ar(s: str) -> str:
    return s.translate(W2A)

# Build 60 items. Difficulty mix: 22 easy, 24 medium, 14 hard.
items: list[dict] = []

def add(diff: str, q: str, opts: list[str], q_ar: str, opts_ar: list[str], expl: str, expl_ar: str):
    assert len(opts) == 4 and len(set(opts)) == 4, f"bad opts: {opts}"
    assert len(opts_ar) == 4 and len(set(opts_ar)) == 4, f"bad opts_ar: {opts_ar}"
    items.append({
        "_diff": diff,
        "question": q,
        "options": opts,
        "correct_answer": opts[0],
        "question_ar": ar(q_ar),
        "options_ar": [ar(o) for o in opts_ar],
        "correct_answer_ar": ar(opts_ar[0]),
        "explanation": expl,
        "explanation_ar": ar(expl_ar),
    })

# ---------- EASY (22) ----------
add("easy",
    "Which fairy-tale castle in Bavaria, Germany inspired the Disney castle?",
    ["Neuschwanstein Castle", "Bran Castle", "Edinburgh Castle", "Tower of London"],
    "أيُّ قلعة خرافية في بافاريا بألمانيا ألهمت قلعة ديزني؟",
    ["قلعة نويشفانشتاين", "قلعة بران", "قلعة إدنبرة", "برج لندن"],
    "King Ludwig II of Bavaria began building Neuschwanstein in 1869; Walt Disney later used it as inspiration.",
    "بدأ الملك لودفيغ الثاني ملك بافاريا بناء قلعة نويشفانشتاين عام 1869، واستلهم منها والت ديزني لاحقًا.")

add("easy",
    "Which famous castle in London is home to the Crown Jewels and is guarded by ravens?",
    ["Tower of London", "Windsor Castle", "Buckingham Palace", "Edinburgh Castle"],
    "أيُّ قلعة شهيرة في لندن تحتفظ بجواهر التاج وتحرسها الغربان؟",
    ["برج لندن", "قلعة وندسور", "قصر باكنغهام", "قلعة إدنبرة"],
    "The Tower of London was begun by William the Conqueror around 1078 and still houses the Crown Jewels.",
    "بدأ ويليام الفاتح بناء برج لندن نحو عام 1078، وما زال يحتفظ بجواهر التاج.")

add("easy",
    "Which is the oldest and largest occupied castle in the world?",
    ["Windsor Castle", "Prague Castle", "Malbork Castle", "Buda Castle"],
    "ما هي أقدم وأكبر قلعة لا تزال مأهولة في العالم؟",
    ["قلعة وندسور", "قلعة براغ", "قلعة مالبورك", "قلعة بودا"],
    "Windsor Castle in England has been a royal home since around 1070 and is still used by the British royal family.",
    "قلعة وندسور في إنجلترا مَقَرٌّ ملكي منذ نحو عام 1070، ولا تزال تستخدمها العائلة المالكة البريطانية.")

add("easy",
    "Bran Castle in Romania is famously linked to which fictional character?",
    ["Dracula", "Robin Hood", "King Arthur", "Sherlock Holmes"],
    "ترتبط قلعة بران في رومانيا شهرةً بأيِّ شخصية خيالية؟",
    ["دراكولا", "روبن هود", "الملك آرثر", "شيرلوك هولمز"],
    "Bran Castle is popularly called 'Dracula's Castle' because of its links to the legend in Bram Stoker's novel.",
    "تُعرف قلعة بران شعبيًّا باسم «قلعة دراكولا» بسبب ارتباطها بأسطورة رواية برام ستوكر.")

add("easy",
    "On which famous rocky hill does Edinburgh Castle stand?",
    ["Castle Rock", "Arthur's Seat", "Ben Nevis", "Calton Hill"],
    "على أيِّ تلّ صخري شهير تقع قلعة إدنبرة؟",
    ["صخرة القلعة", "مقعد آرثر", "بن نيفيس", "تلّ كالتون"],
    "Edinburgh Castle sits on Castle Rock, an ancient volcanic plug overlooking Scotland's capital.",
    "تقع قلعة إدنبرة على «صخرة القلعة»، وهي عُنُق بركاني قديم يطلّ على عاصمة اسكتلندا.")

add("easy",
    "Which Japanese castle is nicknamed the 'White Heron Castle'?",
    ["Himeji Castle", "Osaka Castle", "Matsumoto Castle", "Edo Castle"],
    "أيُّ قلعة يابانية تُلقَّب بـ«قلعة البلشون الأبيض»؟",
    ["قلعة هيميجي", "قلعة أوساكا", "قلعة ماتسوموتو", "قلعة إيدو"],
    "Himeji Castle's bright white walls and graceful shape earned it the nickname 'White Heron Castle'.",
    "اكتسبت قلعة هيميجي لقب «قلعة البلشون الأبيض» بسبب جدرانها البيضاء الناصعة وشكلها الرشيق.")

add("easy",
    "Which Japanese castle is nicknamed the 'Crow Castle' for its black walls?",
    ["Matsumoto Castle", "Himeji Castle", "Nijo Castle", "Kumamoto Castle"],
    "أيُّ قلعة يابانية تُلقَّب بـ«قلعة الغراب» لجدرانها السوداء؟",
    ["قلعة ماتسوموتو", "قلعة هيميجي", "قلعة نيجو", "قلعة كوماموتو"],
    "Matsumoto Castle's black wooden exterior earned it the nickname 'Crow Castle'.",
    "اكتسبت قلعة ماتسوموتو لقب «قلعة الغراب» بسبب واجهتها الخشبية السوداء.")

add("easy",
    "Which Spanish palace-fortress in Granada was built by the Moorish Nasrid dynasty?",
    ["The Alhambra", "El Escorial", "Alcazar of Segovia", "Palace of Aranjuez"],
    "أيُّ قصر-حصن إسباني في غرناطة بناه المسلمون من بني الأحمر (الناصريون)؟",
    ["قصر الحمراء", "دير الإسكوريال", "قصر سيغوبيا", "قصر أرانخويز"],
    "The Alhambra in Granada was begun by the Nasrid dynasty in 1238 and is famous for its Islamic art and gardens.",
    "بدأ بنو الأحمر بناء قصر الحمراء في غرناطة عام 1238، ويشتهر بفنّه الإسلامي وحدائقه.")

add("easy",
    "Which French royal palace, built by Louis XIV, has the famous Hall of Mirrors?",
    ["Palace of Versailles", "Château de Chambord", "Mont Saint-Michel", "Château de Chenonceau"],
    "أيُّ قصر ملكي فرنسي بناه لويس الرابع عشر ويضمّ «قاعة المرايا» الشهيرة؟",
    ["قصر فرساي", "قصر شامبور", "جبل القديس ميشيل", "قصر شينونسو"],
    "King Louis XIV expanded Versailles into a vast royal palace; its Hall of Mirrors has hundreds of mirrored arches.",
    "وسّع الملك لويس الرابع عشر قصر فرساي ليصبح قصرًا ملكيًّا ضخمًا، وتضمّ «قاعة المرايا» فيه مئات الأقواس المرآويّة.")

add("easy",
    "What do we call the deep ditch, often filled with water, that surrounds many castles?",
    ["Moat", "Bailey", "Keep", "Battlement"],
    "ما الاسم الذي يُطلق على الخندق العميق الذي يحيط بكثير من القلاع ويُملأ غالبًا بالماء؟",
    ["الخندق المائي", "الفناء (البَيلي)", "البرج الرئيس", "الشُّرَف"],
    "A moat is a deep, often water-filled ditch around a castle that makes attacks much harder.",
    "الخندق المائي هو حفرة عميقة تحيط بالقلعة وتُملأ غالبًا بالماء، تُصعِّب على المهاجمين اقتحامها.")

add("easy",
    "What is the name of the strong central tower of a medieval castle?",
    ["Keep", "Moat", "Bailey", "Drawbridge"],
    "ما اسم البرج المركزي القوي في القلعة في العصور الوسطى؟",
    ["البرج الرئيس (الكِيب)", "الخندق المائي", "الفناء (البَيلي)", "الجسر المتحرّك"],
    "The keep, sometimes called the donjon, was the strongest tower of a castle and the last refuge in a siege.",
    "البرج الرئيس (ويُسمَّى أحيانًا الدُّنجون) أقوى أبراج القلعة، وهو الملجأ الأخير عند الحصار.")

add("easy",
    "Which heavy gate slides up and down to seal a castle's entrance?",
    ["Portcullis", "Drawbridge", "Barbican", "Bailey"],
    "أيُّ بوابة ثقيلة تنزلق لأعلى ولأسفل لإغلاق مدخل القلعة؟",
    ["البوابة المنزلقة (البُرتُكلِّس)", "الجسر المتحرّك", "البَربَكان", "الفناء"],
    "A portcullis is a heavy iron-and-wood grille that drops down at the gate to block attackers.",
    "البُرتُكلِّس بوابة ثقيلة من خشب وحديد تنزل عند المدخل لتحجب المهاجمين.")

add("easy",
    "Which French abbey-fortress sits on a tidal island in Normandy?",
    ["Mont Saint-Michel", "Carcassonne", "Château de Chambord", "Palace of Versailles"],
    "أيُّ دير-حصن فرنسي يقع على جزيرة مدّ وجزر في نورماندي؟",
    ["جبل القديس ميشيل (مون سان ميشيل)", "كاركاسون", "قصر شامبور", "قصر فرساي"],
    "Mont Saint-Michel is a famous abbey-fortress in Normandy that becomes an island when the tide comes in.",
    "جبل القديس ميشيل دير-حصن شهير في نورماندي يتحوّل إلى جزيرة عند ارتفاع المدّ.")

add("easy",
    "Carcassonne is a famous fortified medieval city in which country?",
    ["France", "Italy", "Spain", "Germany"],
    "كاركاسون مدينة محصَّنة شهيرة من العصور الوسطى، تقع في أيِّ بلد؟",
    ["فرنسا", "إيطاليا", "إسبانيا", "ألمانيا"],
    "Carcassonne in southern France is a UNESCO World Heritage Site famous for its double walls and 52 towers.",
    "كاركاسون في جنوب فرنسا موقع تراث عالمي لليونسكو، تشتهر بأسوارها المزدوجة وأبراجها الـ52.")

add("easy",
    "Krak des Chevaliers is a famous Crusader castle located in which country today?",
    ["Syria", "Egypt", "Lebanon", "Jordan"],
    "قلعة الحصن (كراك دي شوفالييه) قلعة صليبية شهيرة، تقع اليوم في أيِّ بلد؟",
    ["سوريا", "مصر", "لبنان", "الأردن"],
    "Krak des Chevaliers in Syria is one of the best-preserved medieval Crusader castles in the world.",
    "قلعة الحصن في سوريا من أفضل القلاع الصليبية المحفوظة في العالم من العصور الوسطى.")

add("easy",
    "Which Disney park castle is named for Cinderella?",
    ["Cinderella Castle", "Sleeping Beauty Castle", "Beast's Castle", "Snow White's Castle"],
    "أيُّ قلعة في حديقة ديزني سُمِّيت باسم سندريلا؟",
    ["قلعة سندريلا", "قلعة الجميلة النائمة", "قلعة الوحش", "قلعة بياض الثلج"],
    "Cinderella Castle is the icon of Walt Disney World in Florida and was inspired by real European castles.",
    "قلعة سندريلا أيقونة عالم والت ديزني في فلوريدا، وقد استُلهمت من قلاع أوروبية حقيقية.")

add("easy",
    "Which Disneyland park castle is named for Sleeping Beauty?",
    ["Sleeping Beauty Castle", "Cinderella Castle", "Snow White Castle", "Beast's Castle"],
    "أيُّ قلعة في حديقة ديزني لاند سُمِّيت باسم الجميلة النائمة؟",
    ["قلعة الجميلة النائمة", "قلعة سندريلا", "قلعة بياض الثلج", "قلعة الوحش"],
    "Sleeping Beauty Castle is the icon of the original Disneyland in California, inspired by Neuschwanstein.",
    "قلعة الجميلة النائمة أيقونة ديزني لاند الأصلية في كاليفورنيا، وقد استُلهمت من قلعة نويشفانشتاين.")

add("easy",
    "What is the name of the bridge that can be raised to block a castle's gate?",
    ["Drawbridge", "Portcullis", "Barbican", "Battlement"],
    "ما اسم الجسر الذي يمكن رفعه لمنع الدخول إلى بوابة القلعة؟",
    ["الجسر المتحرّك", "البوابة المنزلقة (البُرتُكلِّس)", "البَربَكان", "الشُّرَف"],
    "A drawbridge is a hinged bridge that can be lifted to stop attackers crossing the moat.",
    "الجسر المتحرّك جسر ذو مفصلة يمكن رفعه لمنع المهاجمين من عبور الخندق المائي.")

add("easy",
    "Buckingham Palace, the home of the British monarch, is technically a what?",
    ["Palace", "Castle", "Fortress", "Citadel"],
    "قصر باكنغهام، مقر الملك البريطاني، هو من الناحية التقنية ماذا؟",
    ["قصر", "قلعة", "حصن", "قلعة محصَّنة (سيتاديل)"],
    "Buckingham Palace is a royal palace, not a fortified castle; it became the British monarch's main home in 1837.",
    "قصر باكنغهام قصر ملكي وليس قلعة محصَّنة، وأصبح المقر الرئيس للملك البريطاني عام 1837.")

add("easy",
    "Which structure in Beijing was the Chinese imperial palace from 1420 to 1912?",
    ["The Forbidden City", "The Summer Palace", "The Potala Palace", "Topkapi Palace"],
    "أيُّ بناء في بكين كان القصر الإمبراطوري الصيني من عام 1420 إلى عام 1912؟",
    ["المدينة المحرَّمة", "القصر الصيفي", "قصر بوتالا", "قصر توبكابي"],
    "The Forbidden City in Beijing was built between 1406 and 1420 and served as the home of Ming and Qing emperors.",
    "بُنيت المدينة المحرَّمة في بكين بين عامَي 1406 و1420، واتُّخذت مقرًّا لأباطرة أسرتَي مينغ وتشينغ.")

add("easy",
    "Which Indian fort built by Shah Jahan is famous for its red sandstone walls?",
    ["Red Fort (Lal Qila)", "Agra Fort", "Mehrangarh Fort", "Amber Fort"],
    "أيُّ حصن هندي بناه شاه جهان ويشتهر بجدرانه من الحجر الرملي الأحمر؟",
    ["القلعة الحمراء (لال قلعة)", "حصن أغرا", "حصن مهرانگاره", "حصن آمر"],
    "The Red Fort in Delhi was completed by Mughal emperor Shah Jahan in 1648 and is famous for its red sandstone.",
    "اكتمل بناء القلعة الحمراء في دلهي على يد الإمبراطور المغولي شاه جهان عام 1648، وتشتهر بحجرها الرملي الأحمر.")

add("easy",
    "Which Ottoman sultans' palace in Istanbul served as their main home for almost 400 years?",
    ["Topkapi Palace", "Dolmabahçe Palace", "Buda Castle", "Hofburg Palace"],
    "أيُّ قصر للسلاطين العثمانيين في إسطنبول كان مقرّهم الرئيس قرابة 400 عام؟",
    ["قصر توبكابي", "قصر دولمة بهجة", "قلعة بودا", "قصر هوفبورغ"],
    "Topkapi Palace was the main residence of the Ottoman sultans from 1465 to 1856.",
    "كان قصر توبكابي المقر الرئيس للسلاطين العثمانيين من عام 1465 إلى عام 1856.")

# ---------- MEDIUM (24) ----------
add("medium",
    "Which Scottish castle on a tidal island is one of the most photographed in the world?",
    ["Eilean Donan Castle", "Stirling Castle", "Edinburgh Castle", "Urquhart Castle"],
    "أيُّ قلعة اسكتلندية تقع على جزيرة مدّ وجزر وتُعدّ من أكثر القلاع تصويرًا في العالم؟",
    ["قلعة أيلين دونان", "قلعة ستيرلنغ", "قلعة إدنبرة", "قلعة أوركهارت"],
    "Eilean Donan Castle sits on a small tidal island where three Scottish lochs meet, reached by a stone bridge.",
    "تقع قلعة أيلين دونان على جزيرة صغيرة من جزر المدّ والجزر عند ملتقى ثلاث بحيرات اسكتلندية، ويُوصَل إليها بجسر حجري.")

add("medium",
    "At which Scottish castle was Mary, Queen of Scots crowned in 1543?",
    ["Stirling Castle", "Edinburgh Castle", "Eilean Donan Castle", "Balmoral Castle"],
    "في أيِّ قلعة اسكتلندية تُوِّجت ماري ملكة الاسكتلنديين عام 1543؟",
    ["قلعة ستيرلنغ", "قلعة إدنبرة", "قلعة أيلين دونان", "قلعة بالمورال"],
    "Mary, Queen of Scots was crowned at Stirling Castle's Chapel Royal in 1543 when she was just nine months old.",
    "تُوِّجت ماري ملكة الاسكتلنديين في الكنيسة الملكية بقلعة ستيرلنغ عام 1543، وكانت تبلغ تسعة أشهر فقط.")

add("medium",
    "Which legendary stone, used in coronations of Scottish kings, was kept at Edinburgh Castle?",
    ["The Stone of Destiny", "The Coronation Stone of Wales", "The Black Stone", "The Standing Stone"],
    "أيُّ حجر أسطوري كان يُستخدم في تتويج ملوك اسكتلندا وحُفظ في قلعة إدنبرة؟",
    ["حجر القدر", "حجر تتويج ويلز", "الحجر الأسود", "الحجر القائم"],
    "The Stone of Destiny is an ancient symbol of Scottish kingship and is now displayed at Edinburgh Castle.",
    "حجر القدر رمز قديم للملكية الاسكتلندية، ويُعرض اليوم في قلعة إدنبرة.")

add("medium",
    "Caernarfon Castle, often used for the investiture of the Prince of Wales, is in which country?",
    ["Wales", "Scotland", "Ireland", "England"],
    "قلعة كارنارفون، التي تُستخدم غالبًا لتنصيب أمير ويلز، في أيِّ بلد تقع؟",
    ["ويلز", "اسكتلندا", "أيرلندا", "إنجلترا"],
    "Caernarfon Castle in Wales was begun in 1283 by King Edward I and is used to invest the Prince of Wales.",
    "بدأ الملك إدوارد الأول بناء قلعة كارنارفون في ويلز عام 1283، وتُستخدم لتنصيب أمير ويلز.")

add("medium",
    "Which Welsh castle, built in 1283, is on the UNESCO World Heritage list with three other castles of Edward I?",
    ["Conwy Castle", "Caernarfon Castle (alone)", "Cardiff Castle", "Pembroke Castle"],
    "أيُّ قلعة ويلزية بُنيت عام 1283 ومُدرَجة في قائمة اليونسكو للتراث العالمي مع ثلاث قلاع أخرى لإدوارد الأول؟",
    ["قلعة كونوي", "قلعة كارنارفون (وحدها)", "قلعة كارديف", "قلعة بمبروك"],
    "Conwy Castle in Wales is part of a UNESCO group of four 'castles and town walls of King Edward in Gwynedd'.",
    "قلعة كونوي في ويلز جزء من مجموعة اليونسكو لـ«قلاع وأسوار مدن الملك إدوارد في غوينيد».")

add("medium",
    "The Château de Chambord in France is famous for a special staircase often attributed to which genius?",
    ["Leonardo da Vinci", "Michelangelo", "Galileo", "Eiffel"],
    "يشتهر قصر شامبور في فرنسا بدَرَج خاصّ يُنسَب غالبًا إلى أيِّ عبقري؟",
    ["ليوناردو دا فينشي", "مايكل أنجلو", "غاليليو", "إيفل"],
    "Chambord's famous double-helix staircase is often attributed to ideas of Leonardo da Vinci.",
    "يُنسَب الدَّرَج اللَّولبي المزدوج الشهير في شامبور غالبًا إلى أفكار ليوناردو دا فينشي.")

add("medium",
    "Which French Loire Valley château is nicknamed the 'Ladies' Castle' because of the women who shaped it?",
    ["Château de Chenonceau", "Château de Chambord", "Château d'Amboise", "Château de Blois"],
    "أيُّ قصر فرنسي في وادي اللوار يُلقَّب «قصر السيّدات» بسبب النساء اللواتي شكّلنه؟",
    ["قصر شينونسو", "قصر شامبور", "قصر أمبواز", "قصر بلوا"],
    "Chenonceau is called 'Le Château des Dames' because women like Diane de Poitiers and Catherine de Medici designed and ruled it.",
    "يُسمَّى شينونسو «قصر السيّدات» لأن نساء مثل ديان دو بواتييه وكاترين دي ميديتشي صمّمنه وحكمن فيه.")

add("medium",
    "Which Romanian royal castle, built for King Carol I, is famous for Neo-Renaissance style?",
    ["Peleș Castle", "Bran Castle", "Hunyad Castle", "Corvin Castle"],
    "أيُّ قلعة ملكية رومانية بُنيت للملك كارول الأول وتشتهر بطرازها النيو-نَهضوي؟",
    ["قلعة بيليش", "قلعة بران", "قلعة هونياد", "قلعة كورفين"],
    "Peleș Castle in the Carpathians was built for King Carol I of Romania between 1873 and 1914.",
    "بُنيت قلعة بيليش في جبال الكاربات للملك كارول الأول ملك رومانيا بين عامَي 1873 و1914.")

add("medium",
    "Prague Castle is often called the largest of which kind in the world?",
    ["Largest ancient castle complex", "Largest royal palace", "Largest fortress in Asia", "Largest abbey"],
    "كثيرًا ما تُوصف قلعة براغ بأنها الأكبر من أيِّ نوع في العالم؟",
    ["أكبر مجمَّع قلعة قديمة", "أكبر قصر ملكي", "أكبر حصن في آسيا", "أكبر دير"],
    "Prague Castle is often called the largest ancient castle complex in the world, covering nearly 70,000 square metres.",
    "كثيرًا ما تُوصف قلعة براغ بأنها أكبر مجمَّع قلعة قديمة في العالم، إذ تمتدّ على نحو 70 ألف متر مربّع.")

add("medium",
    "Which German castle in Thuringia is famous because Martin Luther translated the New Testament into German there?",
    ["Wartburg Castle", "Hohenzollern Castle", "Heidelberg Castle", "Neuschwanstein Castle"],
    "أيُّ قلعة ألمانية في تورينغن تشتهر بأن مارتن لوثر ترجم فيها العهد الجديد إلى الألمانية؟",
    ["قلعة فارتبورغ", "قلعة هوهنتسولرن", "قلعة هايدلبرغ", "قلعة نويشفانشتاين"],
    "At Wartburg Castle, Martin Luther translated the New Testament into German in 1521–1522 while in hiding.",
    "في قلعة فارتبورغ، ترجم مارتن لوثر العهد الجديد إلى الألمانية بين عامَي 1521 و1522 أثناء اختبائه.")

add("medium",
    "Malbork Castle in Poland was the headquarters of which medieval order?",
    ["The Teutonic Order", "The Knights Templar", "The Knights Hospitaller", "The Order of Saint John"],
    "كانت قلعة مالبورك في بولندا مقرًّا لأيِّ نظام عسكري في العصور الوسطى؟",
    ["النظام التيوتوني", "فرسان الهيكل", "فرسان الإسبتارية", "نظام القديس يوحنا"],
    "Malbork Castle in Poland was built in the 13th century as the headquarters of the Teutonic Order.",
    "بُنيت قلعة مالبورك في بولندا في القرن الثالث عشر مقرًّا للنظام التيوتوني.")

add("medium",
    "Malbork Castle is often described as the largest castle in the world by what measure?",
    ["Land area", "Height of towers", "Number of windows", "Length of moat"],
    "كثيرًا ما تُوصف قلعة مالبورك بأنها أكبر قلعة في العالم وفق أيِّ مقياس؟",
    ["مساحة الأرض", "ارتفاع الأبراج", "عدد النوافذ", "طول الخندق المائي"],
    "Malbork Castle covers about 21 hectares of land area, often making it the largest castle in the world by that measure.",
    "تمتدّ قلعة مالبورك على نحو 21 هكتارًا، ما يجعلها غالبًا أكبر قلعة في العالم من حيث المساحة.")

add("medium",
    "Which Spanish castle in Segovia is often said to have inspired Walt Disney's castle designs?",
    ["Alcázar of Segovia", "The Alhambra", "Castillo de Coca", "El Escorial"],
    "أيُّ قلعة إسبانية في سيغوبيا يُقال إنها ألهمت تصاميم قلاع والت ديزني؟",
    ["قصر سيغوبيا (الألكاثار)", "قصر الحمراء", "قلعة كوكا", "دير الإسكوريال"],
    "The Alcázar of Segovia, with its ship-shape and tall towers, is often said to have inspired Disney's Cinderella Castle.",
    "يُقال إن قصر سيغوبيا (الألكاثار)، بشكله الذي يشبه السفينة وأبراجه العالية، ألهم قلعة سندريلا في ديزني.")

add("medium",
    "Which Slovenian castle is famous for being built into the mouth of a cliff cave?",
    ["Predjama Castle", "Bled Castle", "Ljubljana Castle", "Ptuj Castle"],
    "أيُّ قلعة سلوفينية تشتهر ببنائها في فم كهف صخري؟",
    ["قلعة بريدْياما", "قلعة بليد", "قلعة ليوبليانا", "قلعة بتوي"],
    "Predjama Castle in Slovenia is dramatically built into the mouth of a 123-metre cliff cave.",
    "بُنيت قلعة بريدْياما في سلوفينيا بصورة مذهلة داخل فم كهف صخري ارتفاعه نحو 123 مترًا.")

add("medium",
    "Trakai Island Castle stands on an island in a lake in which country?",
    ["Lithuania", "Latvia", "Estonia", "Poland"],
    "تقع قلعة جزيرة تراكاي على جزيرة في بحيرة في أيِّ بلد؟",
    ["ليتوانيا", "لاتفيا", "إستونيا", "بولندا"],
    "Trakai Island Castle is on a small island in Lake Galvė in Lithuania and was a residence of grand dukes.",
    "تقع قلعة جزيرة تراكاي على جزيرة صغيرة في بحيرة غالڤيه في ليتوانيا، وكانت مقرًّا للدوقات العظام.")

add("medium",
    "Osaka Castle in Japan was originally built by which famous warlord in 1583?",
    ["Toyotomi Hideyoshi", "Oda Nobunaga", "Tokugawa Ieyasu", "Date Masamune"],
    "بنى قلعة أوساكا في اليابان أصلًا أيُّ زعيم عسكري شهير عام 1583؟",
    ["تويوتومي هيديوشي", "أودا نوبوناغا", "توكوغاوا إيياسو", "داته ماساموني"],
    "Osaka Castle was begun in 1583 by warlord Toyotomi Hideyoshi as a symbol of his power over Japan.",
    "بدأ الزعيم العسكري تويوتومي هيديوشي بناء قلعة أوساكا عام 1583 رمزًا لسلطته على اليابان.")

add("medium",
    "The Potala Palace, a fortress-palace at over 3,700 m elevation, is in which region?",
    ["Tibet", "Nepal", "Bhutan", "Mongolia"],
    "قصر بوتالا، القصر-الحصن الذي يقع على ارتفاع يزيد على 3700 متر، يقع في أيِّ منطقة؟",
    ["التبت", "نيبال", "بوتان", "منغوليا"],
    "The Potala Palace in Lhasa, Tibet was the winter home of the Dalai Lamas and sits on a mountain over 3,700 metres high.",
    "كان قصر بوتالا في لهاسا بالتبت المقر الشتوي لـ«الدالاي لاما»، وهو على جبل يزيد ارتفاعه على 3700 متر.")

add("medium",
    "Which Indian fort in Jaipur is famous for elephant rides up to its main gate?",
    ["Amber Fort", "Mehrangarh Fort", "Agra Fort", "Red Fort"],
    "أيُّ حصن هندي في جايبور يشتهر بركوب الفيلة إلى بوّابته الرئيسة؟",
    ["حصن آمر", "حصن مهرانگاره", "حصن أغرا", "القلعة الحمراء"],
    "Amber Fort near Jaipur, India, was begun in 1592 and is famous for visitors climbing to its gate on elephants.",
    "بدأ بناء حصن آمر قرب جايبور في الهند عام 1592، ويشتهر بصعود الزوّار إلى بوّابته على ظهور الفيلة.")

add("medium",
    "Mehrangarh Fort towers over which 'Blue City' in Rajasthan, India?",
    ["Jodhpur", "Jaipur", "Udaipur", "Bikaner"],
    "يطلّ حصن مهرانگاره على أيِّ «مدينة زرقاء» في راجستان بالهند؟",
    ["جودبور", "جايبور", "أودايبور", "بيكانير"],
    "Mehrangarh Fort sits on a 122-metre cliff above Jodhpur, Rajasthan's famous 'Blue City'.",
    "يقع حصن مهرانگاره على جرف ارتفاعه 122 مترًا فوق مدينة جودبور، «المدينة الزرقاء» الشهيرة في راجستان.")

add("medium",
    "The Castle of Good Hope, a star-shaped 17th-century fortress, is in which African city?",
    ["Cape Town", "Cairo", "Mombasa", "Lagos"],
    "حصن الرجاء الصالح، الحصن النجمي الذي بُني في القرن السابع عشر، في أيِّ مدينة أفريقية؟",
    ["كيب تاون", "القاهرة", "مومباسا", "لاغوس"],
    "The Castle of Good Hope was built by the Dutch East India Company in Cape Town between 1666 and 1679.",
    "بنت شركة الهند الشرقية الهولندية حصن الرجاء الصالح في كيب تاون بين عامَي 1666 و1679.")

add("medium",
    "Hearst Castle in California was built for which famous newspaper publisher?",
    ["William Randolph Hearst", "Joseph Pulitzer", "Henry Ford", "John D. Rockefeller"],
    "بُني «قصر هيرست» في كاليفورنيا لأيِّ ناشر صحف شهير؟",
    ["ويليام راندولف هيرست", "جوزيف بوليتزر", "هنري فورد", "جون د. روكفلر"],
    "Hearst Castle on California's coast was built for newspaper magnate William Randolph Hearst and finished in 1947.",
    "بُني قصر هيرست على ساحل كاليفورنيا لقطب الصحافة ويليام راندولف هيرست، واكتمل عام 1947.")

add("medium",
    "Biltmore Estate in North Carolina is the largest privately owned home in the United States. Who had it built?",
    ["George Vanderbilt", "John D. Rockefeller", "Andrew Carnegie", "Henry Ford"],
    "ضيعة بيلتمور في كارولاينا الشمالية أكبر منزل مملوك ملكية خاصة في الولايات المتحدة. مَن بناه؟",
    ["جورج فاندربيلت", "جون د. روكفلر", "أندرو كارنيغي", "هنري فورد"],
    "Biltmore Estate was built by George Vanderbilt and finished in 1895; it has 250 rooms over 16,000 square metres.",
    "بنى جورج فاندربيلت ضيعة بيلتمور واكتمل بناؤها عام 1895، وفيها 250 غرفة على مساحة 16 ألف متر مربّع.")

add("medium",
    "Castillo de San Marcos, the oldest masonry fort in the continental US, is in which city?",
    ["St. Augustine, Florida", "Charleston, South Carolina", "Savannah, Georgia", "New Orleans, Louisiana"],
    "حصن سان ماركوس، أقدم حصن من الحجر في الأراضي الأمريكية المتّصلة، في أيِّ مدينة يقع؟",
    ["سانت أوغسطين، فلوريدا", "تشارلستون، كارولاينا الجنوبية", "سافانا، جورجيا", "نيو أورلينز، لويزيانا"],
    "Castillo de San Marcos in St. Augustine, Florida was begun by Spain in 1672 and is the oldest masonry fort in the continental US.",
    "بدأت إسبانيا بناء حصن سان ماركوس في سانت أوغسطين بفلوريدا عام 1672، وهو أقدم حصن من الحجر في الأراضي الأمريكية المتّصلة.")

add("medium",
    "What is the open courtyard area inside the outer walls of a medieval castle called?",
    ["Bailey", "Keep", "Battlement", "Barbican"],
    "ما اسم المساحة المفتوحة بين الأسوار الخارجية للقلعة في العصور الوسطى؟",
    ["الفناء (البَيلي)", "البرج الرئيس (الكِيب)", "الشُّرَف", "البَربَكان"],
    "The bailey is the open courtyard inside a castle's walls, where stables, kitchens and other buildings stood.",
    "الفناء (البَيلي) ساحة مفتوحة داخل أسوار القلعة، تحوي الإسطبلات والمطابخ والمباني الأخرى.")

# ---------- HARD (14) ----------
add("hard",
    "What is the artificial earthen mound on which a Norman 'motte-and-bailey' keep was built?",
    ["The motte", "The bailey", "The barbican", "The donjon"],
    "ما اسم التلّ الترابي الاصطناعي الذي بُني عليه برج النورمان من نوع «الموتّ والبَيلي»؟",
    ["الموتّ (التل)", "البَيلي (الفناء)", "البَربَكان", "الدُّنجون"],
    "In a motte-and-bailey castle, the motte is a high earth mound topped with a wooden or stone keep; popular with Normans after 1066.",
    "في قلاع «الموتّ والبَيلي»، يكون الموتّ تلًّا عاليًا من التراب يعلوه برج خشبي أو حجري، وقد انتشرت هذه القلاع عند النورمان بعد عام 1066.")

add("hard",
    "What name is given to the fortified gatehouse extension that protects a castle's main gate?",
    ["Barbican", "Battlement", "Donjon", "Bailey"],
    "ما الاسم الذي يُطلق على البناء المحصَّن الممتدّ أمام البوابة الرئيسة للقلعة لحمايتها؟",
    ["البَربَكان", "الشُّرَف", "الدُّنجون", "الفناء (البَيلي)"],
    "A barbican is an outer fortified gatehouse that forces attackers into a narrow killing zone before they reach the main gate.",
    "البَربَكان بناءٌ محصَّن خارجي يُجبر المهاجمين على المرور في ممرٍّ ضيق قاتل قبل أن يبلغوا البوابة الرئيسة.")

add("hard",
    "What are the alternating high and low sections along the top of a castle wall called?",
    ["Crenellations", "Arrow slits", "Barbicans", "Bastions"],
    "ما الاسم الذي يُطلق على الأجزاء المرتفعة والمنخفضة المتناوبة على قمّة سور القلعة؟",
    ["التَّنشيف (المسنَّنات)", "كوّات الرماية", "الباربكانات", "الحصون البُرجية"],
    "Crenellations are the alternating raised 'merlons' and lower 'crenels' on top of a castle wall, giving cover and firing positions.",
    "التَّنشيف (المسنَّنات) أجزاء مرتفعة (مَيرلون) ومنخفضة (كرنل) متناوبة على قمّة سور القلعة، توفّر السترة ومواقع الرماية.")

add("hard",
    "What were the narrow vertical slits in castle walls used for?",
    ["Shooting arrows", "Throwing food", "Letting in breeze for the king", "Decoration only"],
    "لماذا كانت تُصنع الفتحات العمودية الضيّقة في جدران القلاع؟",
    ["لإطلاق السهام", "لرمي الطعام", "لإدخال الهواء للملك", "للزينة فقط"],
    "Arrow slits (also called arrow loops) were narrow openings that let archers shoot out while staying protected behind the wall.",
    "كوّات الرماية (السهام) فتحاتٌ ضيقة تسمح للرماة بإطلاق السهام مع البقاء محميِّين خلف السور.")

add("hard",
    "A 'concentric castle', with rings of walls one inside the other, became common in Europe in which centuries?",
    ["12th–13th centuries", "5th–6th centuries", "16th–17th centuries", "19th–20th centuries"],
    "انتشرت «القلعة المتراكزة» (ذات الأسوار المتداخلة دائرةً داخل دائرة) في أوروبا في أيِّ قرنين؟",
    ["القرنان الثاني عشر والثالث عشر", "القرنان الخامس والسادس", "القرنان السادس عشر والسابع عشر", "القرنان التاسع عشر والعشرون"],
    "Concentric castles, with rings of walls inside each other, became common in Europe in the 12th and 13th centuries, partly inspired by Crusader fortresses.",
    "انتشرت القلعة المتراكزة ذات الأسوار المتداخلة في أوروبا في القرنين الثاني عشر والثالث عشر، متأثّرةً جزئيًّا بالحصون الصليبية.")

add("hard",
    "Which medieval siege weapon used a long counterweighted arm to fling huge stones?",
    ["Trebuchet", "Catapult (mangonel)", "Ballista", "Battering ram"],
    "أيُّ سلاح حصار في العصور الوسطى استخدم ذراعًا طويلة بوزن مقابل لإطلاق حجارة ضخمة؟",
    ["المَنجنيق ذو الوزن المقابل (تربوشيه)", "المَنجنيق ذو الالتواء (مانغونيل)", "البالستا", "كبش النَّطح"],
    "A trebuchet uses a heavy counterweight and a long arm to fling stones over castle walls — the most powerful medieval throwing weapon.",
    "يستخدم المَنجنيق ذو الوزن المقابل (تربوشيه) وزنًا ثقيلًا وذراعًا طويلة لرمي الحجارة فوق أسوار القلاع، وهو أقوى أسلحة الرمي في العصور الوسطى.")

add("hard",
    "Which medieval siege weapon was a giant crossbow that fired large bolts or stones?",
    ["Ballista", "Trebuchet", "Catapult (mangonel)", "Onager"],
    "أيُّ سلاح حصار في العصور الوسطى كان قوسًا مستعرضًا عملاقًا يُطلق سهامًا كبيرة أو حجارة؟",
    ["البالستا", "المَنجنيق ذو الوزن المقابل (تربوشيه)", "المَنجنيق ذو الالتواء (مانغونيل)", "الأوناغر"],
    "A ballista was a giant crossbow-style siege weapon that used twisted ropes to fire heavy bolts or stones over long distances.",
    "البالستا سلاح حصار يشبه قوسًا مستعرضًا عملاقًا، يستخدم حبالًا ملتوية لإطلاق سهام ثقيلة أو حجارة لمسافات بعيدة.")

add("hard",
    "Krak des Chevaliers in Syria fell in 1271. To which Muslim sultan did it surrender?",
    ["Sultan Baybars", "Saladin (Salah ad-Din)", "Suleiman the Magnificent", "Mehmed II"],
    "سقطت قلعة الحصن (كراك دي شوفالييه) في سوريا عام 1271. لأيِّ سلطان مسلم استسلمت؟",
    ["السلطان بيبرس", "صلاح الدين الأيوبي", "سليمان القانوني", "محمد الفاتح"],
    "Krak des Chevaliers held out for centuries; the Mamluk Sultan Baybars finally took it in 1271 — not Saladin, who failed to capture it earlier.",
    "صمدت قلعة الحصن قرونًا؛ ثم انتزعها السلطان المملوكي بيبرس عام 1271، لا صلاح الدين الذي فشل في فتحها من قبل.")

add("hard",
    "In 1453, which great walled city was finally taken after a long siege, ending the Byzantine Empire?",
    ["Constantinople", "Vienna", "Belgrade", "Damascus"],
    "في عام 1453، أيُّ مدينة كبيرة محصَّنة بأسوار سقطت بعد حصار طويل، فانتهت بسقوطها الإمبراطورية البيزنطية؟",
    ["القسطنطينية", "فيينّا", "بلغراد", "دمشق"],
    "Constantinople fell in 1453 to Ottoman Sultan Mehmed II after a 53-day siege, ending the Byzantine Empire.",
    "سقطت القسطنطينية عام 1453 بيد السلطان العثماني محمد الفاتح بعد حصار دام 53 يومًا، فانتهت الإمبراطورية البيزنطية.")

add("hard",
    "What is the proper distinction between a castle, a fortress and a palace?",
    ["A castle is a fortified noble home; a fortress is purely military; a palace is unfortified and for show.",
     "They all mean exactly the same building.",
     "A fortress is older than a castle; a palace is older than both.",
     "Only buildings in Europe can be called castles; everything else is a palace."],
    "ما الفرق الصحيح بين القلعة والحصن والقصر؟",
    ["القلعة بيت محصَّن للنبيل، والحصن بناء عسكري بحت، والقصر غير محصَّن وللعرض.",
     "كلّها تعني المبنى نفسه تمامًا.",
     "الحصن أقدم من القلعة، والقصر أقدم منهما.",
     "القلاع لا تكون إلّا في أوروبا، وكلّ ما عداها يُسمَّى قصرًا."],
    "A castle is a fortified residence for a noble family; a fortress is purely military; a palace is a grand but unfortified residence.",
    "القلعة بيت محصَّن لعائلة نبيلة، والحصن بناء عسكري بحت، أمّا القصر فمنزل فخم لكنه غير محصَّن.")

add("hard",
    "Hohensalzburg Fortress, one of the largest fully preserved medieval castles in Europe, looks down on which Austrian city?",
    ["Salzburg", "Vienna", "Innsbruck", "Graz"],
    "حصن هوهنسالتسبورغ، أحد أكبر القلاع المحفوظة في أوروبا من العصور الوسطى، يطلّ على أيِّ مدينة نمساوية؟",
    ["سالتسبورغ", "فيينّا", "إنسبروك", "غراتس"],
    "Hohensalzburg Fortress, begun in 1077, sits on a hill above Salzburg and is one of the largest medieval castles in Europe still mostly intact.",
    "بدأ بناء حصن هوهنسالتسبورغ عام 1077 على تلٍّ فوق مدينة سالتسبورغ، وهو من أكبر قلاع أوروبا في العصور الوسطى التي ظلّت سليمة في معظمها.")

add("hard",
    "Heidelberg Castle in Germany is famous for being a major surviving example of which architectural style north of the Alps?",
    ["Renaissance", "Gothic only", "Baroque only", "Art Deco"],
    "تشتهر قلعة هايدلبرغ في ألمانيا بأنها مثال رئيس باقٍ على أيِّ طراز معماري شمال جبال الألب؟",
    ["النهضة (الرنيسانس)", "القوطي فقط", "الباروك فقط", "آرت ديكو"],
    "Heidelberg Castle, partly ruined since the 1600s, is famous for outstanding Renaissance architecture north of the Alps.",
    "قلعة هايدلبرغ، التي تهدّم جزء منها منذ القرن السابع عشر، تشتهر بعمارتها النَّهضوية البارزة شمال جبال الألب.")

add("hard",
    "Mughal emperor Shah Jahan completed the Red Fort in Delhi in which year?",
    ["1648", "1492", "1707", "1857"],
    "أكمل الإمبراطور المغولي شاه جهان بناء القلعة الحمراء في دلهي في أيِّ عام؟",
    ["1648", "1492", "1707", "1857"],
    "Shah Jahan moved his capital to Delhi and completed the Red Fort there in 1648.",
    "نقل شاه جهان عاصمته إلى دلهي وأكمل بناء القلعة الحمراء هناك عام 1648.")

add("hard",
    "Mont Saint-Michel began as which kind of religious-military site in the 8th century?",
    ["A fortified abbey", "A pirate base", "A Roman bath", "A trading port only"],
    "بدأ جبل القديس ميشيل (مون سان ميشيل) في القرن الثامن بوصفه أيَّ نوع من المواقع الدينية-العسكرية؟",
    ["ديرًا محصَّنًا", "قاعدةً للقراصنة", "حمّامًا رومانيًّا", "ميناءً تجاريًّا فقط"],
    "Mont Saint-Michel began as a fortified abbey in the 8th century and grew into both a religious centre and a coastal stronghold.",
    "بدأ جبل القديس ميشيل ديرًا محصَّنًا في القرن الثامن، ثم نما ليصبح مركزًا دينيًّا وحصنًا ساحليًّا في آنٍ معًا.")

# Final assembly: assign IDs cas_001..cas_060 in order, set diff strings.
final = []
for i, it in enumerate(items, start=1):
    rid = f"cas_{i:03d}"
    final.append({
        "id": rid,
        "type": "multiple_choice",
        "category": "history",
        "difficulty": it["_diff"],
        "question": it["question"],
        "question_ar": it["question_ar"],
        "options": it["options"],
        "options_ar": it["options_ar"],
        "correct_answer": it["correct_answer"],
        "correct_answer_ar": it["correct_answer_ar"],
        "explanation": it["explanation"],
        "explanation_ar": it["explanation_ar"],
        "image": "",
    })

# Sanity check counts
diff_counts = {"easy": 0, "medium": 0, "hard": 0}
for it in items:
    diff_counts[it["_diff"]] += 1
print(f"counts: {diff_counts} total={len(items)}")
assert len(final) == 60, f"got {len(final)}"
assert diff_counts == {"easy": 22, "medium": 24, "hard": 14}, diff_counts

# Write UTF-8 NO BOM
text = json.dumps(final, ensure_ascii=False, indent=2)
OUT.write_text(text, encoding="utf-8")
print(f"wrote {OUT} bytes={len(text)}")

# Run the user's local-check
WESTERN = re.compile(r"[0-9]")
data = json.loads(OUT.read_text(encoding="utf-8"))
assert len(data) == 60
ids = set()
for it in data:
    assert it["id"] not in ids; ids.add(it["id"])
    assert it["id"].startswith("cas_")
    for k in ("question", "options", "correct_answer", "question_ar", "options_ar",
              "correct_answer_ar", "explanation", "explanation_ar", "image",
              "type", "category", "difficulty"):
        assert k in it, f"{it['id']} missing {k}"
    assert it["type"] == "multiple_choice"
    assert it["category"] == "history"
    assert it["difficulty"] in ("easy", "medium", "hard")
    assert len(it["options"]) == 4 and len(it["options_ar"]) == 4
    assert len(set(it["options"])) == 4 and len(set(it["options_ar"])) == 4
    assert it["options"][0] == it["correct_answer"]
    assert it["options_ar"][0] == it["correct_answer_ar"]
    for ar_str in (it["question_ar"], it["explanation_ar"], *it["options_ar"], it["correct_answer_ar"]):
        assert not WESTERN.search(ar_str), f"{it['id']}: {ar_str!r}"
print(f"local-check OK {len(data)}")
