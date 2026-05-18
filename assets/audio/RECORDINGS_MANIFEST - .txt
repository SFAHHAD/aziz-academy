# Real-audio recordings manifest — Aziz Academy

This document is the **single source of truth** for the MP3 recordings needed
to replace AI TTS across the Islamic content suite (policy from v1.1.96 —
real recitation only, never synthetic).

Drop each file at the exact path below, with the exact filename listed.
Then run:

```powershell
python scripts/audit_islamic_audio.py
```

That script will scan the folders, regenerate `lib/core/services/islamic_audio_registry.dart`,
and print a coverage report. The app will start playing real audio for any
clip that appears in the registry — partial coverage is fine, the
`RealAudioButton` widget falls back to TTS for missing entries (and hides
itself entirely when TTS is off).

## Folder layout

```
assets/audio/
├── hadith/          25 clips — short hadith recitations
├── azkar/           15 clips — morning + evening adhkar
├── names/           99 clips — the 99 Names of Allah
├── dua/             60 clips — du'a memorization pack
├── tajweed/         10 clips — tajweed rule examples
└── recitations/     (existing — Quran via EveryAyah CDN, no local files needed)
```

## File format

| Property | Value |
|---|---|
| Codec | MP3 |
| Bitrate | 96–128 kbps (mono is fine for spoken word) |
| Sample rate | 22 050 or 44 100 Hz |
| Channels | Mono (smaller; matches voice content) |
| Loudness | Normalize to **-16 LUFS** (matches the EveryAyah Quran stream) |
| Trim | ≤ 250 ms of silence at head/tail; no fade-in/out |
| Naming | Lowercase, snake_case, exact match to the IDs below |

> Note: clips are bundled into the app build. Aim for an average ≤ 12 KB/sec
> (i.e. a 20-second clip ≈ 240 KB). The full 209-clip pack at this rate is
> ~30 MB — acceptable for an offline-first educational app. Drop the bitrate
> to 64 kbps mono if you need to halve that.

---

## 1. Hadith (25 clips)

**Path:** `assets/audio/hadith/`
**Source JSON:** `assets/data/hadith_memorization.json`
**Recite:** the `ar` field of each entry. No translation, no narrator name.

| File | Hadith |
|---|---|
| `hdt_001.mp3` | Smile is charity — التبسم صدقة |
| `hdt_002.mp3` | Love for your brother — حب لأخيك |
| `hdt_003.mp3` | Cleanliness is half of faith — الطهور شطر الإيمان |
| `hdt_004.mp3` | Mercy — الرحمة |
| `hdt_005.mp3` | Best of you — خيركم |
| `hdt_006.mp3` | Truthfulness — الصدق |
| `hdt_007.mp3` | Seeking knowledge — طلب العلم |
| `hdt_008.mp3` | Good word is charity — الكلمة الطيبة |
| `hdt_009.mp3` | Be in the world like a stranger — كن في الدنيا كأنك غريب |
| `hdt_010.mp3` | Anger — الغضب |
| `hdt_011.mp3` | Neighbours — الجار |
| `hdt_012.mp3` | Allah loves consistency — أحب العمل إلى الله أدومه |
| `hdt_013.mp3` | Allah is beautiful — إن الله جميل يحب الجمال |
| `hdt_014.mp3` | Religion is sincerity — الدين النصيحة |
| `hdt_015.mp3` | The strong believer — المؤمن القوي |
| `hdt_016.mp3` | Saying salam — إفشاء السلام |
| `hdt_017.mp3` | Helping a Muslim — قضاء حاجة المسلم |
| `hdt_018.mp3` | Mother's right — حق الأم |
| `hdt_019.mp3` | Best of speech — خير الكلام |
| `hdt_020.mp3` | Allah loves cleanliness — إن الله نظيف يحب النظافة |
| `hdt_021.mp3` | Eating with right hand — الأكل باليمين |
| `hdt_022.mp3` | Du'a is worship — الدعاء هو العبادة |
| `hdt_023.mp3` | Modesty — الحياء |
| `hdt_024.mp3` | Removing harm — إماطة الأذى |
| `hdt_025.mp3` | Best people — خير الناس |

---

## 2. Azkar (15 clips)

**Path:** `assets/audio/azkar/`
**Source:** in-file constants in `lib/features/athkar/athkar_screen.dart`
(constants `_morning` and `_evening`).
**Recite:** the `ar` field. Where `repeat` > 1 (tasbih-style), record the
phrase **once** — the app handles the count visually.

### Morning (8 clips)
| File | Dhikr (titleAr) |
|---|---|
| `morning_01.mp3` | آية الكرسي — Ayat al-Kursi |
| `morning_02.mp3` | تسبيح الصباح — Morning glorification |
| `morning_03.mp3` | سيد الاستغفار — Master supplication for forgiveness |
| `morning_04.mp3` | سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ×100 |
| `morning_05.mp3` | لَا إِلَٰهَ إِلَّا اللَّهُ … وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ ×10 |
| `morning_06.mp3` | بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ ×3 |
| `morning_07.mp3` | رَضِيتُ بِاللَّهِ رَبًّا ×3 |
| `morning_08.mp3` | اللَّهُمَّ عَافِنِي فِي بَدَنِي ×3 |

### Evening (7 clips)
| File | Dhikr (titleAr) |
|---|---|
| `evening_01.mp3` | آية الكرسي — Ayat al-Kursi |
| `evening_02.mp3` | تسبيح المساء — Evening glorification |
| `evening_03.mp3` | أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ ×3 |
| `evening_04.mp3` | سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ×100 |
| `evening_05.mp3` | بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ ×3 |
| `evening_06.mp3` | اللَّهُمَّ بِكَ أَمْسَيْنَا |
| `evening_07.mp3` | اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ |

---

## 3. 99 Names of Allah (99 clips)

**Path:** `assets/audio/names/`
**Source JSON:** `assets/data/asma_ul_husna_memorization.json`
**Recite:** the `name_ar` field — vocalised Arabic, one name per file.
Length target: 2–4 seconds.

| File | Name (transliteration) | Meaning |
|---|---|---|
| `name_001.mp3` | Ar-Rahman | The Most Compassionate |
| `name_002.mp3` | Ar-Raheem | The Most Merciful |
| `name_003.mp3` | Al-Malik | The King |
| `name_004.mp3` | Al-Quddus | The Most Holy |
| `name_005.mp3` | As-Salam | The Source of Peace |
| `name_006.mp3` | Al-Mu'min | The Granter of Security |
| `name_007.mp3` | Al-Muhaymin | The Guardian |
| `name_008.mp3` | Al-Aziz | The All-Mighty |
| `name_009.mp3` | Al-Jabbar | The Compeller |
| `name_010.mp3` | Al-Mutakabbir | The Supreme |
| `name_011.mp3` | Al-Khaliq | The Creator |
| `name_012.mp3` | Al-Bari | The Maker |
| `name_013.mp3` | Al-Musawwir | The Fashioner |
| `name_014.mp3` | Al-Ghaffar | The Ever-Forgiving |
| `name_015.mp3` | Al-Qahhar | The Subduer |
| `name_016.mp3` | Al-Wahhab | The Bestower |
| `name_017.mp3` | Ar-Razzaq | The Provider |
| `name_018.mp3` | Al-Fattah | The Opener |
| `name_019.mp3` | Al-Aleem | The All-Knowing |
| `name_020.mp3` | Al-Qabid | The Withholder |
| `name_021.mp3` | Al-Basit | The Expander |
| `name_022.mp3` | Al-Khafid | The Abaser |
| `name_023.mp3` | Ar-Rafi | The Exalter |
| `name_024.mp3` | Al-Mu'izz | The Bestower of Honour |
| `name_025.mp3` | Al-Mudhill | The Humiliator |
| `name_026.mp3` | As-Sami | The All-Hearing |
| `name_027.mp3` | Al-Basir | The All-Seeing |
| `name_028.mp3` | Al-Hakam | The Judge |
| `name_029.mp3` | Al-Adl | The Utterly Just |
| `name_030.mp3` | Al-Latif | The Most Subtle |
| `name_031.mp3` | Al-Khabir | The All-Aware |
| `name_032.mp3` | Al-Haleem | The Most Forbearing |
| `name_033.mp3` | Al-Azeem | The Magnificent |
| `name_034.mp3` | Al-Ghafur | The All-Forgiving |
| `name_035.mp3` | Ash-Shakur | The Most Appreciative |
| `name_036.mp3` | Al-Aliyy | The Most High |
| `name_037.mp3` | Al-Kabir | The Most Great |
| `name_038.mp3` | Al-Hafiz | The Preserver |
| `name_039.mp3` | Al-Muqit | The Sustainer |
| `name_040.mp3` | Al-Hasib | The Reckoner |
| `name_041.mp3` | Al-Jaleel | The Most Majestic |
| `name_042.mp3` | Al-Kareem | The Most Generous |
| `name_043.mp3` | Ar-Raqib | The Watchful |
| `name_044.mp3` | Al-Mujib | The Responder |
| `name_045.mp3` | Al-Wasi | The All-Embracing |
| `name_046.mp3` | Al-Hakeem | The All-Wise |
| `name_047.mp3` | Al-Wadud | The Most Loving |
| `name_048.mp3` | Al-Majeed | The Most Glorious |
| `name_049.mp3` | Al-Ba'ith | The Resurrector |
| `name_050.mp3` | Ash-Shaheed | The Witness |
| `name_051.mp3` | Al-Haqq | The Truth |
| `name_052.mp3` | Al-Wakeel | The Trustee |
| `name_053.mp3` | Al-Qawiyy | The Most Strong |
| `name_054.mp3` | Al-Mateen | The Firm |
| `name_055.mp3` | Al-Waliyy | The Protector |
| `name_056.mp3` | Al-Hameed | The Praiseworthy |
| `name_057.mp3` | Al-Muhsi | The Recorder |
| `name_058.mp3` | Al-Mubdi | The Originator |
| `name_059.mp3` | Al-Mu'eed | The Restorer |
| `name_060.mp3` | Al-Muhyi | The Giver of Life |
| `name_061.mp3` | Al-Mumit | The Taker of Life |
| `name_062.mp3` | Al-Hayy | The Ever-Living |
| `name_063.mp3` | Al-Qayyum | The Sustainer |
| `name_064.mp3` | Al-Wajid | The Self-Sufficient |
| `name_065.mp3` | Al-Majid | The Most Noble |
| `name_066.mp3` | Al-Wahid | The One |
| `name_067.mp3` | Al-Ahad | The Unique |
| `name_068.mp3` | As-Samad | The Eternal |
| `name_069.mp3` | Al-Qadir | The Capable |
| `name_070.mp3` | Al-Muqtadir | The All-Powerful |
| `name_071.mp3` | Al-Muqaddim | The Promoter |
| `name_072.mp3` | Al-Mu'akhkhir | The Delayer |
| `name_073.mp3` | Al-Awwal | The First |
| `name_074.mp3` | Al-Akhir | The Last |
| `name_075.mp3` | Az-Zahir | The Manifest |
| `name_076.mp3` | Al-Batin | The Hidden |
| `name_077.mp3` | Al-Wali | The Governor |
| `name_078.mp3` | Al-Muta'ali | The Most Exalted |
| `name_079.mp3` | Al-Barr | The Source of Goodness |
| `name_080.mp3` | At-Tawwab | The Acceptor of Repentance |
| `name_081.mp3` | Al-Muntaqim | The Avenger |
| `name_082.mp3` | Al-Afuww | The Pardoner |
| `name_083.mp3` | Ar-Ra'uf | The Most Kind |
| `name_084.mp3` | Malik-ul-Mulk | Master of the Kingdom |
| `name_085.mp3` | Dhul-Jalali wal-Ikram | Lord of Majesty and Honour |
| `name_086.mp3` | Al-Muqsit | The Just |
| `name_087.mp3` | Al-Jami | The Gatherer |
| `name_088.mp3` | Al-Ghaniyy | The Self-Sufficient |
| `name_089.mp3` | Al-Mughni | The Enricher |
| `name_090.mp3` | Al-Mani | The Withholder |
| `name_091.mp3` | Ad-Darr | The Distresser |
| `name_092.mp3` | An-Nafi | The Beneficial |
| `name_093.mp3` | An-Nur | The Light |
| `name_094.mp3` | Al-Hadi | The Guide |
| `name_095.mp3` | Al-Badi | The Originator |
| `name_096.mp3` | Al-Baqi | The Everlasting |
| `name_097.mp3` | Al-Warith | The Inheritor |
| `name_098.mp3` | Ar-Rashid | The Guide to Right |
| `name_099.mp3` | As-Sabur | The Most Patient |

---

## 4. Du'a (60 clips)

**Path:** `assets/audio/dua/`
**Source JSON:** `assets/data/dua_memorization.json`
**Recite:** the `ar` field. Filename matches the `id` field exactly.

### Daily life (13)
| File | Occasion |
|---|---|
| `dua_eat_before.mp3` | Before Eating |
| `dua_eat_forgot.mp3` | If Forgot Bismillah |
| `dua_eat_after.mp3` | After Eating |
| `dua_drink_milk.mp3` | After Drinking Milk |
| `dua_sleep.mp3` | Before Sleeping |
| `dua_wake.mp3` | Upon Waking |
| `dua_dress.mp3` | Wearing Clothes |
| `dua_enter_bathroom.mp3` | Entering Bathroom |
| `dua_leave_bathroom.mp3` | Leaving Bathroom |
| `dua_wudu_before.mp3` | Before Wudu |
| `dua_wudu_after.mp3` | After Wudu |
| `dua_leave_home.mp3` | Leaving Home |
| `dua_enter_home.mp3` | Entering Home |

### Morning/evening + sneezing (3)
| File | Occasion |
|---|---|
| `dua_morning.mp3` | Morning Remembrance |
| `dua_evening.mp3` | Evening Remembrance |
| `dua_sneeze_self.mp3` | When Sneezing |

### Travel (7)
| File | Occasion |
|---|---|
| `dua_travel_start.mp3` | Starting a Journey |
| `dua_travel_uphill.mp3` | Going Uphill |
| `dua_travel_downhill.mp3` | Going Downhill |
| `dua_travel_return.mp3` | Returning from Travel |
| `dua_travel_rest.mp3` | Stopping at a Place |
| `dua_travel_farewell.mp3` | Farewell to Traveler |
| `dua_travel_vehicle.mp3` | Mounting a Vehicle |

### Weather (5)
| File | Occasion |
|---|---|
| `dua_rain.mp3` | When It Rains |
| `dua_rain_after.mp3` | After the Rain |
| `dua_wind.mp3` | When the Wind Blows |
| `dua_thunder.mp3` | Hearing Thunder |
| `dua_storm.mp3` | During a Storm |
| `dua_clouds.mp3` | When Seeing Clouds |

### Anxiety / hardship (6)
| File | Occasion |
|---|---|
| `dua_anxiety_yunus.mp3` | Dua of Yunus |
| `dua_anxiety_relief.mp3` | Removing Distress |
| `dua_anxiety_hardship.mp3` | When Things Are Hard |
| `dua_anxiety_fear.mp3` | When Afraid |
| `dua_anxiety_strong.mp3` | Powerful Dua of Distress |
| `dua_anxiety_sadness.mp3` | When Sad |

### Family (5)
| File | Occasion |
|---|---|
| `dua_parents.mp3` | For Parents |
| `dua_family_offspring.mp3` | For Righteous Children |
| `dua_family_unity.mp3` | For Family Unity |
| `dua_family_protect.mp3` | Protecting Children |
| `dua_parents_forgive.mp3` | Forgive Parents |

### Knowledge / study (5)
| File | Occasion |
|---|---|
| `dua_knowledge.mp3` | For More Knowledge |
| `dua_knowledge_understanding.mp3` | For Understanding |
| `dua_knowledge_useful.mp3` | For Useful Knowledge |
| `dua_knowledge_exam.mp3` | Before an Exam |
| `dua_knowledge_memory.mp3` | For Strong Memory |

### Mosque + adhan (5)
| File | Occasion |
|---|---|
| `dua_enter_mosque.mp3` | Entering the Mosque |
| `dua_leave_mosque.mp3` | Leaving the Mosque |
| `dua_mosque_adhan.mp3` | Hearing the Adhan |
| `dua_mosque_after_adhan.mp3` | After the Adhan |
| `dua_mosque_walk.mp3` | Walking to Mosque |

### Quran (5)
| File | Occasion |
|---|---|
| `dua_quran_understanding.mp3` | Understanding the Quran |
| `dua_quran_heart.mp3` | Quran in the Heart |
| `dua_quran_guide.mp3` | Guidance from Quran |
| `dua_quran_recite.mp3` | Beginning to Recite |
| `dua_quran_finish.mp3` | After Reciting |

### Forgiveness (5)
| File | Occasion |
|---|---|
| `dua_forgive_general.mp3` | Asking Forgiveness |
| `dua_forgive_master.mp3` | Master of Forgiveness |
| `dua_forgive_adam.mp3` | Dua of Adam |
| `dua_forgive_short.mp3` | Short Forgiveness |
| `dua_forgive_world_next.mp3` | Goodness in Both Worlds |

---

## 5. Tajweed (10 clips)

**Path:** `assets/audio/tajweed/`
**Source JSON:** `assets/data/tajweed_basics.json`
**Recite:** the `example_ar` field — a short Qur'anic example demonstrating
the rule. Not the rule name itself.

| File | Rule | Example basis |
|---|---|---|
| `tj_madd.mp3` | Madd — vowel lengthening | example_ar field |
| `tj_ghunnah.mp3` | Ghunnah — nasalization | example_ar field |
| `tj_ikhfa.mp3` | Ikhfa — hiding noon | example_ar field |
| `tj_idgham.mp3` | Idgham — merging | example_ar field |
| `tj_iqlab.mp3` | Iqlab — converting to mim | example_ar field |
| `tj_qalqalah.mp3` | Qalqalah — echoing | example_ar field |
| `tj_lam_shamsiyah.mp3` | Sun letters | example_ar field |
| `tj_lam_qamariyyah.mp3` | Moon letters | example_ar field |
| `tj_idhar.mp3` | Idhar — clear pronunciation | example_ar field |
| `tj_waqf.mp3` | Waqf — stopping | example_ar field |

---

## Workflow when you ship new clips

1. Drop the MP3s into the correct folder under `assets/audio/`.
2. Run `python scripts/audit_islamic_audio.py`.
3. The script regenerates `lib/core/services/islamic_audio_registry.dart`
   so the app knows which clips are now real.
4. Run `flutter analyze` to confirm nothing broke.
5. Deploy: `.\scripts\deploy_web.ps1 --prod`.
6. After deploy, sanity-check by tapping the 🔊 button on the corresponding
   screen — should hear the real recording, no TTS fallback.

## Coverage today

The registry currently lists **0 / 209** clips. Every 🔊 button on the
Islamic screens still falls back to TTS — which is muted by default per the
real-audio-only policy. As soon as the first batch ships, those buttons
start playing real audio without code changes anywhere else.
