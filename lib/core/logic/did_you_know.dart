/// Bilingual "Did you know?" facts for the home banner. Daily-seeded so
/// every kid sees the same fact today, and tomorrow's fact rotates.
///
/// All entries are kid-safe, religion-neutral where possible, and sourced
/// from public-domain general knowledge — no citations or attribution
/// required. Keep entries short (one or two sentences).
class DidYouKnow {
  const DidYouKnow({required this.en, required this.ar, required this.emoji});

  final String en;
  final String ar;
  final String emoji;
}

const List<DidYouKnow> kDidYouKnow = [
  DidYouKnow(
    emoji: '🌊',
    en: "The Pacific Ocean is bigger than all the world's land combined.",
    ar: 'المحيط الهادئ أكبر مساحةً من كل اليابسة على الأرض مجتمعةً.',
  ),
  DidYouKnow(
    emoji: '🐝',
    en: 'A honeybee visits about 2,000 flowers in a single day.',
    ar: 'تزور النحلة الواحدة نحو ٢٠٠٠ زهرة في اليوم.',
  ),
  DidYouKnow(
    emoji: '🌙',
    en: 'The Moon is moving away from Earth by about 4 cm every year.',
    ar: 'يبتعد القمر عن الأرض ٤ سنتيمترات كل عام.',
  ),
  DidYouKnow(
    emoji: '🦒',
    en: 'A giraffe has the same number of neck bones as you do — seven.',
    ar: 'للزرافة عدد فقرات الرقبة نفسه عندك — سبع فقرات.',
  ),
  DidYouKnow(
    emoji: '⚡',
    en: 'Lightning is hotter than the surface of the Sun.',
    ar: 'البرق أشد حرارةً من سطح الشمس.',
  ),
  DidYouKnow(
    emoji: '🐙',
    en: 'An octopus has three hearts and blue blood.',
    ar: 'للأخطبوط ثلاثة قلوب ودمه أزرق اللون.',
  ),
  DidYouKnow(
    emoji: '🌍',
    en: "Earth's atmosphere is 78% nitrogen, only 21% oxygen.",
    ar: 'يتكوَّن الغلاف الجوي للأرض من ٧٨٪ نيتروجين و٢١٪ فقط أكسجين.',
  ),
  DidYouKnow(
    emoji: '📚',
    en: 'Arabic is written from right to left, but its numbers were borrowed by everyone.',
    ar: 'الكتابة العربية من اليمين إلى اليسار، لكن العالم كله استعار منها الأرقام.',
  ),
  DidYouKnow(
    emoji: '🏜️',
    en: 'Saudi Arabia is home to the largest sand desert in the world — the Empty Quarter.',
    ar: 'تضم المملكة العربية السعودية أكبر صحراء رملية في العالم — الربع الخالي.',
  ),
  DidYouKnow(
    emoji: '🦋',
    en: 'A butterfly tastes with its feet.',
    ar: 'الفراشة تتذوَّق بأقدامها.',
  ),
  DidYouKnow(
    emoji: '🚀',
    en: 'A day on Venus is longer than its year.',
    ar: 'يوم في كوكب الزهرة أطول من سنته.',
  ),
  DidYouKnow(
    emoji: '🐢',
    en: 'Some sea turtles can live more than 100 years.',
    ar: 'بعض السلاحف البحرية تعيش أكثر من ١٠٠ سنة.',
  ),
  DidYouKnow(
    emoji: '🏯',
    en: 'The Great Wall of China is over 21,000 km long.',
    ar: 'يبلغ طول سور الصين العظيم أكثر من ٢١٠٠٠ كيلومتر.',
  ),
  DidYouKnow(
    emoji: '💧',
    en: 'About 60% of your body is water.',
    ar: 'حوالي ٦٠٪ من جسمك ماء.',
  ),
  DidYouKnow(
    emoji: '🦊',
    en: 'A group of foxes is called a "skulk".',
    ar: 'تُسمَّى مجموعة الثعالب باسمٍ خاص في الإنجليزية يعني تجمُّعًا متخفيًا.',
  ),
  DidYouKnow(
    emoji: '🧠',
    en: 'Your brain uses about 20% of all the energy your body burns.',
    ar: 'يستهلك دماغك حوالي ٢٠٪ من طاقة جسمك.',
  ),
  DidYouKnow(
    emoji: '🌋',
    en: 'There are over 1,500 active volcanoes on Earth.',
    ar: 'يوجد على الأرض أكثر من ١٥٠٠ بركان نشط.',
  ),
  DidYouKnow(
    emoji: '🦅',
    en: 'A peregrine falcon can dive at 320 km/h — faster than a Formula 1 car.',
    ar: 'يستطيع الصقر الجوَّال الانقضاض بسرعة ٣٢٠ كم/س — أسرع من سيارة فورمولا ١.',
  ),
  DidYouKnow(
    emoji: '🌌',
    en: 'There are more stars in the universe than grains of sand on every beach on Earth.',
    ar: 'عدد النجوم في الكون أكبر من حبات الرمل على كل شواطئ الأرض مجتمعةً.',
  ),
  DidYouKnow(
    emoji: '🐧',
    en: 'Penguins propose to their mates with a pebble.',
    ar: 'تقدِّم البطاريق حصاةً صغيرة لشريك حياتها كنوع من الخطبة.',
  ),
];

/// Returns today's fact, deterministic per local calendar day.
DidYouKnow factForToday([DateTime? now]) {
  final d = now ?? DateTime.now();
  final daySeed = d.year * 1000 + d.month * 32 + d.day;
  return kDidYouKnow[daySeed % kDidYouKnow.length];
}
