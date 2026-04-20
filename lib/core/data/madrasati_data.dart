import 'package:flutter/material.dart';
import 'package:aziz_academy/core/models/school_models.dart';

// =============================================================================
// Saudi MOE curriculum — stages, grades, subjects, chapters, questions
// =============================================================================

final List<SchoolStage> madrasatiStages = [
  // ── رياض الأطفال ──────────────────────────────────────────────────────────
  const SchoolStage(
    id: 'kindergarten',
    name: 'رياض الأطفال',
    emoji: '🌱',
    color: Color(0xFF43A047),
    grades: [],
  ),

  // ── المرحلة الابتدائية ────────────────────────────────────────────────────
  SchoolStage(
    id: 'primary',
    name: 'المرحلة الابتدائية',
    emoji: '📚',
    color: const Color(0xFF1565C0),
    grades: [
      _primaryGrade1,
      _primaryGrade2,
      _primaryGrade3,
      _primaryGrade4,
      _primaryGrade5,
    ],
  ),

  // ── المرحلة المتوسطة ──────────────────────────────────────────────────────
  SchoolStage(
    id: 'middle',
    name: 'المرحلة المتوسطة',
    emoji: '🔬',
    color: const Color(0xFFE65100),
    grades: [
      _middleGrade6,
      _middleGrade7,
      _middleGrade8,
      _middleGrade9,
    ],
  ),

  // ── المرحلة الثانوية ──────────────────────────────────────────────────────
  SchoolStage(
    id: 'secondary',
    name: 'المرحلة الثانوية',
    emoji: '🎓',
    color: const Color(0xFF6A1B9A),
    grades: [
      _secondaryGrade10,
      _secondaryGrade11,
      _secondaryGrade12,
    ],
  ),
];

// =============================================================================
// Shared subject stubs (قريباً placeholder — no chapters)
// =============================================================================

SchoolSubject _subjectStub(String id, String name, String emoji, Color color) =>
    SchoolSubject(id: id, name: name, emoji: emoji, color: color);

// =============================================================================
// PRIMARY — Grade 1
// =============================================================================

final _primaryGrade1 = SchoolGrade(
  id: 'p1',
  name: 'الأول الابتدائي',
  subjects: [
    SchoolSubject(
      id: 'p1_arabic',
      name: 'لغتي الجميلة',
      emoji: '📖',
      color: const Color(0xFF00838F),
      chapters: [
        SchoolChapter(
          id: 'p1_ar_ch1',
          name: 'الحروف الهجائية',
          questions: [
            const SchoolQuestion(
              id: 'p1_ar_1_1',
              question: 'ما هو الحرف الأول في الأبجدية العربية؟',
              options: ['الألف', 'الباء', 'الجيم', 'الدال'],
              correctAnswer: 'الألف',
              funFact: 'الألف هو أقدم حرف في الأبجدية السامية.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_1_2',
              question: 'كم عدد حروف اللغة العربية؟',
              options: ['28', '26', '24', '30'],
              correctAnswer: '28',
              funFact: 'اللغة العربية إحدى أكثر لغات العالم انتشاراً.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_1_3',
              question: 'أي الكلمات التالية تبدأ بحرف الباء؟',
              options: ['بيت', 'كتاب', 'مدرسة', 'قلم'],
              correctAnswer: 'بيت',
              funFact: 'الباء هي الحرف الثاني في الأبجدية العربية.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_1_4',
              question: 'ما الحرف الأخير في كلمة "كتاب"؟',
              options: ['الباء', 'الكاف', 'التاء', 'الألف'],
              correctAnswer: 'الباء',
              funFact: 'الباء تأتي في نهاية كثير من الكلمات العربية.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_1_5',
              question: 'أي الحروف التالية حرف شمسي؟',
              options: ['الشين', 'الباء', 'الكاف', 'الميم'],
              correctAnswer: 'الشين',
              funFact: 'الحروف الشمسية 14 حرفاً تندغم فيها لام التعريف.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'p1_ar_ch2',
          name: 'حركات الحروف',
          questions: [
            const SchoolQuestion(
              id: 'p1_ar_2_1',
              question: 'ما اسم الحركة التي تجعل الحرف يُنطق بصوت "أَ"؟',
              options: ['الفتحة', 'الضمة', 'الكسرة', 'السكون'],
              correctAnswer: 'الفتحة',
              funFact: 'الفتحة هي أخف الحركات في العربية.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_2_2',
              question: 'ما اسم الحركة التي تجعل الحرف يُنطق بصوت "أُ"؟',
              options: ['الضمة', 'الفتحة', 'الكسرة', 'التنوين'],
              correctAnswer: 'الضمة',
              funFact: 'الضمة تدل على رفع الكلمة في الجملة.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_2_3',
              question: 'ما اسم الحركة التي تجعل الحرف يُنطق بصوت "إِ"؟',
              options: ['الكسرة', 'الفتحة', 'الضمة', 'الشدة'],
              correctAnswer: 'الكسرة',
              funFact: 'الكسرة توضع تحت الحرف وتشبه الفتحة الصغيرة.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_2_4',
              question: 'ما الحركة التي تعني سكون الحرف؟',
              options: ['السكون', 'الفتحة', 'الضمة', 'الكسرة'],
              correctAnswer: 'السكون',
              funFact: 'السكون يُرمز له بدائرة صغيرة فوق الحرف.',
            ),
            const SchoolQuestion(
              id: 'p1_ar_2_5',
              question: 'ما الحرف المشدّد في كلمة "مُحَمَّد"؟',
              options: ['الميم', 'الحاء', 'الدال', 'الألف'],
              correctAnswer: 'الميم',
              funFact: 'الشدة تعني أن الحرف يُنطق مرتين متتاليتين.',
            ),
          ],
        ),
      ],
    ),
    SchoolSubject(
      id: 'p1_math',
      name: 'الرياضيات',
      emoji: '🔢',
      color: const Color(0xFF1565C0),
      chapters: [
        SchoolChapter(
          id: 'p1_math_ch1',
          name: 'الأعداد من ١ إلى ١٠',
          questions: [
            const SchoolQuestion(
              id: 'p1_m_1_1',
              question: 'ما الرقم الذي يأتي بعد العدد 5؟',
              options: ['6', '7', '4', '8'],
              correctAnswer: '6',
              funFact: 'الأعداد الطبيعية تبدأ من الصفر وتمتد إلى ما لا نهاية.',
            ),
            const SchoolQuestion(
              id: 'p1_m_1_2',
              question: 'كم عدد أصابع اليد الواحدة؟',
              options: ['5', '4', '6', '10'],
              correctAnswer: '5',
              funFact: 'استخدم الإنسان قديماً أصابعه للعد.',
            ),
            const SchoolQuestion(
              id: 'p1_m_1_3',
              question: 'أي الأعداد التالية أكبر من 7؟',
              options: ['9', '5', '3', '6'],
              correctAnswer: '9',
              funFact: 'الأعداد الأكبر تقع على يمين الأعداد الأصغر في خط الأعداد.',
            ),
            const SchoolQuestion(
              id: 'p1_m_1_4',
              question: 'ما أصغر عدد بين 3 و 7 و 1 و 9؟',
              options: ['1', '3', '7', '9'],
              correctAnswer: '1',
              funFact: 'الصفر هو أصغر عدد طبيعي عند كثير من العلماء.',
            ),
            const SchoolQuestion(
              id: 'p1_m_1_5',
              question: 'كم ناتج 3 + 4؟',
              options: ['7', '6', '8', '5'],
              correctAnswer: '7',
              funFact: 'الجمع هو من أولى العمليات الحسابية التي تعلمها الإنسان.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'p1_math_ch2',
          name: 'الجمع والطرح البسيط',
          questions: [
            const SchoolQuestion(
              id: 'p1_m_2_1',
              question: 'كم ناتج 5 + 3؟',
              options: ['8', '7', '9', '6'],
              correctAnswer: '8',
              funFact: 'الجمع عملية تجميع الكميات معاً.',
            ),
            const SchoolQuestion(
              id: 'p1_m_2_2',
              question: 'كم ناتج 9 - 4؟',
              options: ['5', '4', '6', '3'],
              correctAnswer: '5',
              funFact: 'الطرح هو عملية إيجاد الفرق بين عددين.',
            ),
            const SchoolQuestion(
              id: 'p1_m_2_3',
              question: 'كم ناتج 6 + 4؟',
              options: ['10', '9', '11', '8'],
              correctAnswer: '10',
              funFact: 'العدد 10 هو أساس نظام العد العشري.',
            ),
            const SchoolQuestion(
              id: 'p1_m_2_4',
              question: 'كم ناتج 8 - 3؟',
              options: ['5', '4', '6', '11'],
              correctAnswer: '5',
              funFact: 'رمز الطرح "-" استُخدم أول مرة في القرن الخامس عشر.',
            ),
            const SchoolQuestion(
              id: 'p1_m_2_5',
              question: 'كم ناتج 7 + 2؟',
              options: ['9', '8', '10', '7'],
              correctAnswer: '9',
              funFact: 'الأعداد الفردية لا تقبل القسمة على 2.',
            ),
          ],
        ),
      ],
    ),
    SchoolSubject(
      id: 'p1_islam',
      name: 'التربية الإسلامية',
      emoji: '🕌',
      color: const Color(0xFF2E7D32),
      chapters: [
        SchoolChapter(
          id: 'p1_isl_ch1',
          name: 'أركان الإسلام',
          questions: [
            const SchoolQuestion(
              id: 'p1_i_1_1',
              question: 'كم عدد أركان الإسلام؟',
              options: ['5', '4', '6', '3'],
              correctAnswer: '5',
              funFact: 'أركان الإسلام الخمسة هي الأساس الذي يقوم عليه الإسلام.',
            ),
            const SchoolQuestion(
              id: 'p1_i_1_2',
              question: 'ما أول ركن من أركان الإسلام؟',
              options: ['الشهادتان', 'الصلاة', 'الزكاة', 'الصوم'],
              correctAnswer: 'الشهادتان',
              funFact: 'الشهادتان هما: شهادة أن لا إله إلا الله وأن محمداً رسول الله.',
            ),
            const SchoolQuestion(
              id: 'p1_i_1_3',
              question: 'من هو آخر الأنبياء والمرسلين؟',
              options: ['محمد ﷺ', 'عيسى', 'موسى', 'إبراهيم'],
              correctAnswer: 'محمد ﷺ',
              funFact: 'النبي محمد ﷺ وُلد في مكة المكرمة عام 570م.',
            ),
            const SchoolQuestion(
              id: 'p1_i_1_4',
              question: 'ما اسم الكتاب المقدس للمسلمين؟',
              options: ['القرآن الكريم', 'التوراة', 'الإنجيل', 'الزبور'],
              correctAnswer: 'القرآن الكريم',
              funFact: 'القرآن الكريم أُنزل على سيدنا محمد ﷺ على مدى 23 عاماً.',
            ),
            const SchoolQuestion(
              id: 'p1_i_1_5',
              question: 'في أي شهر يصوم المسلمون؟',
              options: ['رمضان', 'شعبان', 'محرم', 'ذو الحجة'],
              correctAnswer: 'رمضان',
              funFact: 'شهر رمضان هو الشهر الذي أُنزل فيه القرآن الكريم.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'p1_isl_ch2',
          name: 'الصلاة وأوقاتها',
          questions: [
            const SchoolQuestion(
              id: 'p1_i_2_1',
              question: 'كم عدد الصلوات المفروضة في اليوم والليلة؟',
              options: ['5', '3', '4', '6'],
              correctAnswer: '5',
              funFact: 'فُرضت الصلاة في ليلة الإسراء والمعراج.',
            ),
            const SchoolQuestion(
              id: 'p1_i_2_2',
              question: 'ما أول صلاة في اليوم؟',
              options: ['الفجر', 'الظهر', 'العصر', 'المغرب'],
              correctAnswer: 'الفجر',
              funFact: 'تُصلى صلاة الفجر قبل طلوع الشمس.',
            ),
            const SchoolQuestion(
              id: 'p1_i_2_3',
              question: 'كم ركعة في صلاة الظهر؟',
              options: ['4', '2', '3', '5'],
              correctAnswer: '4',
              funFact: 'صلاة الظهر تُصلى بعد زوال الشمس عن كبد السماء.',
            ),
            const SchoolQuestion(
              id: 'p1_i_2_4',
              question: 'ما آخر صلاة في اليوم؟',
              options: ['العشاء', 'المغرب', 'العصر', 'الفجر'],
              correctAnswer: 'العشاء',
              funFact: 'صلاة العشاء تُصلى بعد اختفاء الشفق الأحمر.',
            ),
            const SchoolQuestion(
              id: 'p1_i_2_5',
              question: 'بماذا يبدأ المصلي صلاته؟',
              options: ['الله أكبر', 'بسم الله', 'الحمد لله', 'سبحان الله'],
              correctAnswer: 'الله أكبر',
              funFact: 'تكبيرة الإحرام هي الدخول الرسمي في الصلاة.',
            ),
          ],
        ),
      ],
    ),
  ],
);

// =============================================================================
// PRIMARY — Grade 2, 3, 5 (structure only)
// =============================================================================

final _primaryGrade2 = SchoolGrade(
  id: 'p2',
  name: 'الثاني الابتدائي',
  subjects: [
    _subjectStub('p2_arabic', 'لغتي الجميلة', '📖', const Color(0xFF00838F)),
    _subjectStub('p2_math', 'الرياضيات', '🔢', const Color(0xFF1565C0)),
    _subjectStub('p2_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('p2_sci', 'العلوم', '🔬', const Color(0xFF00695C)),
  ],
);

final _primaryGrade3 = SchoolGrade(
  id: 'p3',
  name: 'الثالث الابتدائي',
  subjects: [
    _subjectStub('p3_arabic', 'لغتي الجميلة', '📖', const Color(0xFF00838F)),
    _subjectStub('p3_math', 'الرياضيات', '🔢', const Color(0xFF1565C0)),
    _subjectStub('p3_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('p3_sci', 'العلوم', '🔬', const Color(0xFF00695C)),
    _subjectStub('p3_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
  ],
);

// =============================================================================
// PRIMARY — Grade 4
// =============================================================================

final _primaryGrade4 = SchoolGrade(
  id: 'p4',
  name: 'الرابع الابتدائي',
  subjects: [
    _subjectStub('p4_arabic', 'لغتي الجميلة', '📖', const Color(0xFF00838F)),
    SchoolSubject(
      id: 'p4_math',
      name: 'الرياضيات',
      emoji: '🔢',
      color: const Color(0xFF1565C0),
      chapters: [
        SchoolChapter(
          id: 'p4_m_ch1',
          name: 'الضرب',
          questions: [
            const SchoolQuestion(
              id: 'p4_m_1_1',
              question: 'ما ناتج 7 × 8؟',
              options: ['56', '54', '58', '62'],
              correctAnswer: '56',
              funFact: 'جدول الضرب اخترعه علماء الرياضيات قبل آلاف السنين.',
            ),
            const SchoolQuestion(
              id: 'p4_m_1_2',
              question: 'ما ناتج 9 × 6؟',
              options: ['54', '56', '48', '63'],
              correctAnswer: '54',
              funFact: 'الضرب هو جمع متكرر لعدد مُعيَّن.',
            ),
            const SchoolQuestion(
              id: 'p4_m_1_3',
              question: 'ما ناتج 12 × 5؟',
              options: ['60', '50', '70', '55'],
              correctAnswer: '60',
              funFact: 'العدد 60 له أهمية تاريخية في قياس الزمن.',
            ),
            const SchoolQuestion(
              id: 'p4_m_1_4',
              question: 'ما ناتج 8 × 8؟',
              options: ['64', '72', '56', '60'],
              correctAnswer: '64',
              funFact: 'العدد 64 هو 2 مرفوعاً للقوة 6.',
            ),
            const SchoolQuestion(
              id: 'p4_m_1_5',
              question: 'ما ناتج 11 × 9؟',
              options: ['99', '90', '100', '108'],
              correctAnswer: '99',
              funFact: 'العدد 99 يمثل الأسماء الحسنى لله سبحانه وتعالى.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'p4_m_ch2',
          name: 'القسمة',
          questions: [
            const SchoolQuestion(
              id: 'p4_m_2_1',
              question: 'ما ناتج 48 ÷ 6؟',
              options: ['8', '7', '9', '6'],
              correctAnswer: '8',
              funFact: 'القسمة هي عملية توزيع كمية على أجزاء متساوية.',
            ),
            const SchoolQuestion(
              id: 'p4_m_2_2',
              question: 'ما ناتج 72 ÷ 8؟',
              options: ['9', '8', '7', '10'],
              correctAnswer: '9',
              funFact: 'رمز القسمة ÷ اخترعه يوهان رهان عام 1659م.',
            ),
            const SchoolQuestion(
              id: 'p4_m_2_3',
              question: 'ما ناتج 45 ÷ 9؟',
              options: ['5', '6', '4', '7'],
              correctAnswer: '5',
              funFact: 'القسمة والضرب عمليتان عكسيتان.',
            ),
            const SchoolQuestion(
              id: 'p4_m_2_4',
              question: 'ما ناتج 100 ÷ 4؟',
              options: ['25', '20', '30', '10'],
              correctAnswer: '25',
              funFact: 'العدد 25 هو ربع المئة في المئوية.',
            ),
            const SchoolQuestion(
              id: 'p4_m_2_5',
              question: 'ما ناتج 63 ÷ 7؟',
              options: ['9', '8', '7', '10'],
              correctAnswer: '9',
              funFact: '63 = 7 × 9، والتحقق من القسمة يكون بالضرب.',
            ),
          ],
        ),
      ],
    ),
    SchoolSubject(
      id: 'p4_sci',
      name: 'العلوم',
      emoji: '🔬',
      color: const Color(0xFF00695C),
      chapters: [
        SchoolChapter(
          id: 'p4_sci_ch1',
          name: 'المادة وخصائصها',
          questions: [
            const SchoolQuestion(
              id: 'p4_s_1_1',
              question: 'ما حالات المادة الثلاث؟',
              options: [
                'صلبة وسائلة وغازية',
                'ساخنة وباردة ومتجمدة',
                'كبيرة وصغيرة ومتوسطة',
                'ناعمة وخشنة وصلبة',
              ],
              correctAnswer: 'صلبة وسائلة وغازية',
              funFact: 'هناك حالة رابعة للمادة تُسمى البلازما موجودة في الشمس.',
            ),
            const SchoolQuestion(
              id: 'p4_s_1_2',
              question: 'عند تسخين الماء يتحول إلى...',
              options: ['بخار ماء', 'ثلج', 'تراب', 'رمل'],
              correctAnswer: 'بخار ماء',
              funFact: 'يغلي الماء عند درجة 100 مئوية على مستوى سطح البحر.',
            ),
            const SchoolQuestion(
              id: 'p4_s_1_3',
              question: 'أي المواد التالية في الحالة الغازية؟',
              options: ['الهواء', 'الماء', 'الملح', 'الحديد'],
              correctAnswer: 'الهواء',
              funFact: 'الهواء خليط من الغازات أكثرها النيتروجين بنسبة 78%.',
            ),
            const SchoolQuestion(
              id: 'p4_s_1_4',
              question: 'ما مثال على مادة في الحالة الصلبة؟',
              options: ['الحجر', 'الماء', 'البخار', 'الهواء'],
              correctAnswer: 'الحجر',
              funFact: 'المواد الصلبة لها شكل وحجم ثابتان.',
            ),
            const SchoolQuestion(
              id: 'p4_s_1_5',
              question: 'ماذا يحدث للماء عند تجميده؟',
              options: ['يتحول إلى ثلج', 'يتبخر', 'يختفي', 'يصبح غازاً'],
              correctAnswer: 'يتحول إلى ثلج',
              funFact: 'يتجمد الماء عند صفر درجة مئوية.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'p4_sci_ch2',
          name: 'الطاقة وأشكالها',
          questions: [
            const SchoolQuestion(
              id: 'p4_s_2_1',
              question: 'من أين تحصل النباتات على طاقتها؟',
              options: ['ضوء الشمس', 'الماء فقط', 'التربة فقط', 'الهواء فقط'],
              correctAnswer: 'ضوء الشمس',
              funFact: 'عملية البناء الضوئي تحوّل ضوء الشمس إلى طاقة كيميائية.',
            ),
            const SchoolQuestion(
              id: 'p4_s_2_2',
              question: 'ما وحدة قياس الطاقة في النظام الدولي؟',
              options: ['الجول', 'المتر', 'الكيلوغرام', 'الثانية'],
              correctAnswer: 'الجول',
              funFact: 'سُميت وحدة الطاقة (جول) تكريماً للعالم جيمس جول.',
            ),
            const SchoolQuestion(
              id: 'p4_s_2_3',
              question: 'أي النشاطات يستهلك طاقة ميكانيكية؟',
              options: ['الجري', 'النوم', 'التنفس أثناء الراحة', 'القراءة'],
              correctAnswer: 'الجري',
              funFact: 'الطاقة الميكانيكية هي مجموع الطاقة الحركية والكامنة.',
            ),
            const SchoolQuestion(
              id: 'p4_s_2_4',
              question: 'ما مصدر الطاقة الضوئية الطبيعية؟',
              options: ['الشمس', 'القمر', 'النجوم', 'الأرض'],
              correctAnswer: 'الشمس',
              funFact: 'تصل إلى الأرض في ساعة واحدة طاقة شمسية تكفي العالم سنة كاملة.',
            ),
            const SchoolQuestion(
              id: 'p4_s_2_5',
              question: 'أي الطاقات التالية مثال على الطاقة الحرارية؟',
              options: ['اللهب', 'الريح', 'الصوت', 'الضوء'],
              correctAnswer: 'اللهب',
              funFact: 'الطاقة الحرارية تنتقل بثلاث طرق: التوصيل والحمل والإشعاع.',
            ),
          ],
        ),
      ],
    ),
    _subjectStub('p4_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('p4_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
    _subjectStub('p4_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
  ],
);

final _primaryGrade5 = SchoolGrade(
  id: 'p5',
  name: 'الخامس الابتدائي',
  subjects: [
    _subjectStub('p5_arabic', 'لغتي الجميلة', '📖', const Color(0xFF00838F)),
    _subjectStub('p5_math', 'الرياضيات', '🔢', const Color(0xFF1565C0)),
    _subjectStub('p5_sci', 'العلوم', '🔬', const Color(0xFF00695C)),
    _subjectStub('p5_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('p5_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
    _subjectStub('p5_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
  ],
);

// =============================================================================
// MIDDLE — Grade 6
// =============================================================================

final _middleGrade6 = SchoolGrade(
  id: 'm6',
  name: 'السادس المتوسط',
  subjects: [
    _subjectStub('m6_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    _subjectStub('m6_math', 'الرياضيات', '📐', const Color(0xFF283593)),
    _subjectStub('m6_sci', 'العلوم', '⚗️', const Color(0xFFBF360C)),
    _subjectStub('m6_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('m6_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
    _subjectStub('m6_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
  ],
);

// =============================================================================
// MIDDLE — Grade 7
// =============================================================================

final _middleGrade7 = SchoolGrade(
  id: 'm7',
  name: 'السابع المتوسط',
  subjects: [
    _subjectStub('m7_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    SchoolSubject(
      id: 'm7_math',
      name: 'الرياضيات',
      emoji: '📐',
      color: const Color(0xFF283593),
      chapters: [
        SchoolChapter(
          id: 'm7_m_ch1',
          name: 'الأعداد الصحيحة',
          questions: [
            const SchoolQuestion(
              id: 'm7_m_1_1',
              question: 'ما ناتج (-5) + (-3)؟',
              options: ['-8', '8', '-2', '2'],
              correctAnswer: '-8',
              funFact: 'الأعداد السالبة أُدخلت في الرياضيات لحل معادلات لا حل لها بالأعداد الطبيعية.',
            ),
            const SchoolQuestion(
              id: 'm7_m_1_2',
              question: 'ما ناتج (-6) × 4؟',
              options: ['-24', '24', '-10', '10'],
              correctAnswer: '-24',
              funFact: 'سالب × موجب = سالب، وسالب × سالب = موجب.',
            ),
            const SchoolQuestion(
              id: 'm7_m_1_3',
              question: 'ما ناتج (-12) ÷ (-3)؟',
              options: ['4', '-4', '3', '-3'],
              correctAnswer: '4',
              funFact: 'قسمة عددين بنفس الإشارة ينتج عنها عدد موجب.',
            ),
            const SchoolQuestion(
              id: 'm7_m_1_4',
              question: 'ما ناتج 7 + (-10)؟',
              options: ['-3', '3', '17', '-17'],
              correctAnswer: '-3',
              funFact: 'لجمع عددين مختلفين في الإشارة نأخذ الفرق ونضع إشارة الأكبر.',
            ),
            const SchoolQuestion(
              id: 'm7_m_1_5',
              question: 'أي الأعداد التالية أصغر من (-2)؟',
              options: ['-5', '0', '1', '3'],
              correctAnswer: '-5',
              funFact: 'كلما تحركنا يساراً في خط الأعداد، كلما صغرت القيمة.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'm7_m_ch2',
          name: 'النسب المئوية والكسور',
          questions: [
            const SchoolQuestion(
              id: 'm7_m_2_1',
              question: 'ما النسبة المئوية لـ ¾؟',
              options: ['75%', '25%', '50%', '80%'],
              correctAnswer: '75%',
              funFact: 'النسبة المئوية تعني عدداً من كل مئة.',
            ),
            const SchoolQuestion(
              id: 'm7_m_2_2',
              question: 'ما الكسر العادي المكافئ لـ 0.25؟',
              options: ['¼', '½', '¾', '⅕'],
              correctAnswer: '¼',
              funFact: 'الكسور العشرية والعادية طريقتان لتمثيل الأجزاء.',
            ),
            const SchoolQuestion(
              id: 'm7_m_2_3',
              question: 'كم ناتج ½ + ¼؟',
              options: ['¾', '⅔', '⅓', '¼'],
              correctAnswer: '¾',
              funFact: 'لجمع الكسور يجب توحيد المقام أولاً.',
            ),
            const SchoolQuestion(
              id: 'm7_m_2_4',
              question: 'ما ناتج 0.5 × 0.4؟',
              options: ['0.2', '0.02', '2', '20'],
              correctAnswer: '0.2',
              funFact: 'في ضرب الكسور العشرية، نضرب ثم نضع الفاصلة.',
            ),
            const SchoolQuestion(
              id: 'm7_m_2_5',
              question: 'ما نسبة 15 من 60؟',
              options: ['25%', '15%', '30%', '60%'],
              correctAnswer: '25%',
              funFact: '15/60 = 1/4 = 25%، النسبة المئوية مفيدة في الحياة اليومية.',
            ),
          ],
        ),
      ],
    ),
    SchoolSubject(
      id: 'm7_sci',
      name: 'العلوم',
      emoji: '⚗️',
      color: const Color(0xFFBF360C),
      chapters: [
        SchoolChapter(
          id: 'm7_sci_ch1',
          name: 'المادة والتغيرات الكيميائية',
          questions: [
            const SchoolQuestion(
              id: 'm7_s_1_1',
              question: 'ما الصيغة الكيميائية للماء؟',
              options: ['H₂O', 'CO₂', 'NaCl', 'O₂'],
              correctAnswer: 'H₂O',
              funFact: 'H₂O تعني جزيئاً يحتوي على ذرتي هيدروجين وذرة أكسجين.',
            ),
            const SchoolQuestion(
              id: 'm7_s_1_2',
              question: 'أي التغيرات التالية تغيُّر فيزيائي؟',
              options: [
                'ذوبان السكر في الماء',
                'احتراق الخشب',
                'صدأ الحديد',
                'تخمُّر العصير',
              ],
              correctAnswer: 'ذوبان السكر في الماء',
              funFact: 'في التغيير الفيزيائي لا تتغير التركيبة الكيميائية للمادة.',
            ),
            const SchoolQuestion(
              id: 'm7_s_1_3',
              question: 'ما الصيغة الكيميائية لثاني أكسيد الكربون؟',
              options: ['CO₂', 'H₂O', 'O₂', 'CO'],
              correctAnswer: 'CO₂',
              funFact: 'ثاني أكسيد الكربون ينتج عن عمليتي التنفس والاحتراق.',
            ),
            const SchoolQuestion(
              id: 'm7_s_1_4',
              question: 'أي العناصر التالية معدن؟',
              options: ['الحديد', 'الكبريت', 'الكربون', 'الهيدروجين'],
              correctAnswer: 'الحديد',
              funFact: 'المعادن موصلة للكهرباء والحرارة وبريقها معدني.',
            ),
            const SchoolQuestion(
              id: 'm7_s_1_5',
              question: 'ما الوحدة الأساسية للمادة الحية؟',
              options: ['الخلية', 'الذرة', 'الجزيء', 'النواة'],
              correctAnswer: 'الخلية',
              funFact: 'اكتشف العالم روبرت هوك الخلية عام 1665م.',
            ),
          ],
        ),
        SchoolChapter(
          id: 'm7_sci_ch2',
          name: 'الحركة والقوى',
          questions: [
            const SchoolQuestion(
              id: 'm7_s_2_1',
              question: 'ما وحدة قياس القوة في النظام الدولي؟',
              options: ['النيوتن', 'الجول', 'الواط', 'الأمبير'],
              correctAnswer: 'النيوتن',
              funFact: 'سُميت وحدة القوة نيوتن تكريماً للعالم إسحاق نيوتن.',
            ),
            const SchoolQuestion(
              id: 'm7_s_2_2',
              question: 'ما الصيغة الرياضية لقانون نيوتن الثاني؟',
              options: ['F = ma', 'F = mv', 'F = m/a', 'P = mv'],
              correctAnswer: 'F = ma',
              funFact: 'F هي القوة، m الكتلة، a التسارع في قانون نيوتن.',
            ),
            const SchoolQuestion(
              id: 'm7_s_2_3',
              question: 'ما مقدار تسارع الجاذبية الأرضية تقريباً؟',
              options: ['9.8 م/ث²', '6.4 م/ث²', '12 م/ث²', '3.2 م/ث²'],
              correctAnswer: '9.8 م/ث²',
              funFact: 'يختلف تسارع الجاذبية قليلاً من مكان لآخر على سطح الأرض.',
            ),
            const SchoolQuestion(
              id: 'm7_s_2_4',
              question: 'ما وحدة قياس الشغل (العمل)؟',
              options: ['الجول', 'النيوتن', 'الواط', 'الباسكال'],
              correctAnswer: 'الجول',
              funFact: 'الشغل = القوة × المسافة في اتجاه القوة.',
            ),
            const SchoolQuestion(
              id: 'm7_s_2_5',
              question: 'قانون نيوتن الأول يُعرف بـ...',
              options: [
                'قانون القصور الذاتي',
                'قانون الزخم',
                'قانون الجاذبية',
                'قانون الطاقة',
              ],
              correctAnswer: 'قانون القصور الذاتي',
              funFact: 'الجسم الساكن يظل ساكناً والمتحرك يظل متحركاً ما لم تؤثر عليه قوة.',
            ),
          ],
        ),
      ],
    ),
    _subjectStub('m7_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('m7_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
    _subjectStub('m7_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
  ],
);

final _middleGrade8 = SchoolGrade(
  id: 'm8',
  name: 'الثامن المتوسط',
  subjects: [
    _subjectStub('m8_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    _subjectStub('m8_math', 'الرياضيات', '📐', const Color(0xFF283593)),
    _subjectStub('m8_sci', 'العلوم', '⚗️', const Color(0xFFBF360C)),
    _subjectStub('m8_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('m8_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
    _subjectStub('m8_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
    _subjectStub('m8_cs', 'الحاسب وتقنية المعلومات', '💻', const Color(0xFF37474F)),
  ],
);

final _middleGrade9 = SchoolGrade(
  id: 'm9',
  name: 'التاسع المتوسط',
  subjects: [
    _subjectStub('m9_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    _subjectStub('m9_math', 'الرياضيات', '📐', const Color(0xFF283593)),
    _subjectStub('m9_sci', 'العلوم', '⚗️', const Color(0xFFBF360C)),
    _subjectStub('m9_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('m9_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
    _subjectStub('m9_social', 'الدراسات الاجتماعية', '🌍', const Color(0xFF5D4037)),
    _subjectStub('m9_cs', 'الحاسب وتقنية المعلومات', '💻', const Color(0xFF37474F)),
  ],
);

// =============================================================================
// SECONDARY — Grade 10
// =============================================================================

final _secondaryGrade10 = SchoolGrade(
  id: 's10',
  name: 'العاشر الثانوي',
  subjects: [
    _subjectStub('s10_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    SchoolSubject(
      id: 's10_math',
      name: 'الرياضيات',
      emoji: '📊',
      color: const Color(0xFF4A148C),
      chapters: [
        SchoolChapter(
          id: 's10_m_ch1',
          name: 'الدوال والعلاقات',
          questions: [
            const SchoolQuestion(
              id: 's10_m_1_1',
              question: 'ما قيمة f(x) = 2x + 3 عندما x = 5؟',
              options: ['13', '10', '15', '8'],
              correctAnswer: '13',
              funFact: 'الدوال الخطية تمثّل علاقات مستقيمة على المستوى الإحداثي.',
            ),
            const SchoolQuestion(
              id: 's10_m_1_2',
              question: 'ما الجذر التربيعي للعدد 144؟',
              options: ['12', '14', '10', '16'],
              correctAnswer: '12',
              funFact: '12² = 144، والجذر التربيعي هو العدد الذي يُضرب في نفسه.',
            ),
            const SchoolQuestion(
              id: 's10_m_1_3',
              question: 'ما ناتج 2³؟',
              options: ['8', '6', '9', '16'],
              correctAnswer: '8',
              funFact: '2³ = 2 × 2 × 2 = 8، والأس يعني الضرب المتكرر.',
            ),
            const SchoolQuestion(
              id: 's10_m_1_4',
              question: 'إذا كان f(x) = x² فما قيمة f(4)؟',
              options: ['16', '8', '12', '4'],
              correctAnswer: '16',
              funFact: 'الدوال التربيعية تعطي منحنى يُسمى القطع المكافئ.',
            ),
            const SchoolQuestion(
              id: 's10_m_1_5',
              question: 'ما قيمة sin(90°)؟',
              options: ['1', '0', '½', '√2/2'],
              correctAnswer: '1',
              funFact: 'sin(90°) = 1 هي قيمة الجيب عند الزاوية القائمة.',
            ),
          ],
        ),
        SchoolChapter(
          id: 's10_m_ch2',
          name: 'الجبر والمعادلات',
          questions: [
            const SchoolQuestion(
              id: 's10_m_2_1',
              question: 'ما قيمة x في المعادلة 3x = 15؟',
              options: ['5', '3', '12', '45'],
              correctAnswer: '5',
              funFact: 'الجبر سمّاه العالم العربي الخوارزمي وأسس قواعده.',
            ),
            const SchoolQuestion(
              id: 's10_m_2_2',
              question: 'ما قيمة x في المعادلة x² = 25؟',
              options: ['±5', '5', '25', '±25'],
              correctAnswer: '±5',
              funFact: 'المعادلات التربيعية لها حلان في معظم الحالات.',
            ),
            const SchoolQuestion(
              id: 's10_m_2_3',
              question: 'ما ناتج (x+2)(x-2)؟',
              options: ['x²-4', 'x²+4', 'x²-2', 'x²+2x-4'],
              correctAnswer: 'x²-4',
              funFact: '(a+b)(a-b) = a²-b² هي قاعدة فرق التربيعين.',
            ),
            const SchoolQuestion(
              id: 's10_m_2_4',
              question: 'ما قيمة x في 2x + 4 = 10؟',
              options: ['3', '2', '4', '7'],
              correctAnswer: '3',
              funFact: 'لحل المعادلات ننقل المجهولات لجهة والأرقام للجهة الأخرى.',
            ),
            const SchoolQuestion(
              id: 's10_m_2_5',
              question: 'ما قيمة x في x/3 = 6؟',
              options: ['18', '3', '9', '2'],
              correctAnswer: '18',
              funFact: 'نضرب طرفي المعادلة في 3 للحصول على x.',
            ),
          ],
        ),
      ],
    ),
    SchoolSubject(
      id: 's10_physics',
      name: 'الفيزياء',
      emoji: '⚡',
      color: const Color(0xFFFF6F00),
      chapters: [
        SchoolChapter(
          id: 's10_ph_ch1',
          name: 'الحركة والديناميكا',
          questions: [
            const SchoolQuestion(
              id: 's10_ph_1_1',
              question: 'ما وحدة قياس السرعة في النظام الدولي؟',
              options: ['م/ث', 'كم/ث', 'نيوتن', 'جول'],
              correctAnswer: 'م/ث',
              funFact: 'سرعة الضوء حوالي 300,000 كم/ث وهي أسرع شيء في الكون.',
            ),
            const SchoolQuestion(
              id: 's10_ph_1_2',
              question: 'ما الصيغة الرياضية للسرعة المتوسطة؟',
              options: ['v = d/t', 'v = dt', 'v = t/d', 'v = d+t'],
              correctAnswer: 'v = d/t',
              funFact: 'v: السرعة، d: المسافة، t: الزمن في معادلة السرعة.',
            ),
            const SchoolQuestion(
              id: 's10_ph_1_3',
              question: 'ما مقدار تسارع الجاذبية الأرضية؟',
              options: ['9.8 م/ث²', '6.67 م/ث²', '3.8 م/ث²', '12 م/ث²'],
              correctAnswer: '9.8 م/ث²',
              funFact: 'يختلف مقدار الجاذبية على سطح القمر: 1.6 م/ث².',
            ),
            const SchoolQuestion(
              id: 's10_ph_1_4',
              question: 'قانون نيوتن الثالث ينص على...',
              options: [
                'لكل فعل رد فعل مساوٍ ومعاكس',
                'القوة = الكتلة × التسارع',
                'الجسم يبقى ساكناً ما لم تؤثر قوة',
                'الطاقة لا تُفنى ولا تُخلق',
              ],
              correctAnswer: 'لكل فعل رد فعل مساوٍ ومعاكس',
              funFact: 'نيوتن الثالث يفسر لماذا ترتد المدفع للخلف عند إطلاق القذيفة.',
            ),
            const SchoolQuestion(
              id: 's10_ph_1_5',
              question: 'ما وحدة قياس الضغط؟',
              options: ['الباسكال', 'النيوتن', 'الجول', 'الواط'],
              correctAnswer: 'الباسكال',
              funFact: 'سُميت وحدة الضغط باسكال تكريماً للعالم الفرنسي بليز باسكال.',
            ),
          ],
        ),
        SchoolChapter(
          id: 's10_ph_ch2',
          name: 'الكهرباء والمغناطيسية',
          questions: [
            const SchoolQuestion(
              id: 's10_ph_2_1',
              question: 'ما قانون أوم؟',
              options: ['V = IR', 'V = I+R', 'V = I/R', 'I = VR'],
              correctAnswer: 'V = IR',
              funFact: 'V: الجهد، I: شدة التيار، R: المقاومة في قانون أوم.',
            ),
            const SchoolQuestion(
              id: 's10_ph_2_2',
              question: 'ما وحدة قياس شدة التيار الكهربائي؟',
              options: ['الأمبير', 'الفولت', 'الأوم', 'الواط'],
              correctAnswer: 'الأمبير',
              funFact: 'سُميت وحدة التيار أمبير تكريماً للعالم أندريه ماري أمبير.',
            ),
            const SchoolQuestion(
              id: 's10_ph_2_3',
              question: 'ما وحدة قياس المقاومة الكهربائية؟',
              options: ['الأوم', 'الأمبير', 'الفولت', 'الهرتز'],
              correctAnswer: 'الأوم',
              funFact: 'سُميت وحدة المقاومة أوم تكريماً للعالم جورج سيمون أوم.',
            ),
            const SchoolQuestion(
              id: 's10_ph_2_4',
              question: 'ما وحدة قياس الجهد الكهربائي؟',
              options: ['الفولت', 'الأمبير', 'الأوم', 'الواط'],
              correctAnswer: 'الفولت',
              funFact: 'سُميت وحدة الجهد فولت تكريماً للعالم أليساندرو فولتا.',
            ),
            const SchoolQuestion(
              id: 's10_ph_2_5',
              question: 'ما العلاقة بين القدرة الكهربائية والجهد والتيار؟',
              options: ['P = VI', 'P = V/I', 'P = V+I', 'P = V²I'],
              correctAnswer: 'P = VI',
              funFact: 'القدرة الكهربائية تُقاس بالواط: 1W = 1V × 1A.',
            ),
          ],
        ),
      ],
    ),
    _subjectStub('s10_chem', 'الكيمياء', '🧪', const Color(0xFF1B5E20)),
    _subjectStub('s10_bio', 'الأحياء', '🌿', const Color(0xFF33691E)),
    _subjectStub('s10_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('s10_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
  ],
);

final _secondaryGrade11 = SchoolGrade(
  id: 's11',
  name: 'الحادي عشر الثانوي',
  subjects: [
    _subjectStub('s11_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    _subjectStub('s11_math', 'الرياضيات', '📊', const Color(0xFF4A148C)),
    _subjectStub('s11_physics', 'الفيزياء', '⚡', const Color(0xFFFF6F00)),
    _subjectStub('s11_chem', 'الكيمياء', '🧪', const Color(0xFF1B5E20)),
    _subjectStub('s11_bio', 'الأحياء', '🌿', const Color(0xFF33691E)),
    _subjectStub('s11_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('s11_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
  ],
);

final _secondaryGrade12 = SchoolGrade(
  id: 's12',
  name: 'الثاني عشر الثانوي',
  subjects: [
    _subjectStub('s12_arabic', 'اللغة العربية', '📖', const Color(0xFF00838F)),
    _subjectStub('s12_math', 'الرياضيات', '📊', const Color(0xFF4A148C)),
    _subjectStub('s12_physics', 'الفيزياء', '⚡', const Color(0xFFFF6F00)),
    _subjectStub('s12_chem', 'الكيمياء', '🧪', const Color(0xFF1B5E20)),
    _subjectStub('s12_bio', 'الأحياء', '🌿', const Color(0xFF33691E)),
    _subjectStub('s12_islam', 'التربية الإسلامية', '🕌', const Color(0xFF2E7D32)),
    _subjectStub('s12_eng', 'اللغة الإنجليزية', '🇬🇧', const Color(0xFFC62828)),
    _subjectStub('s12_cs', 'الحاسب وتقنية المعلومات', '💻', const Color(0xFF37474F)),
  ],
);

