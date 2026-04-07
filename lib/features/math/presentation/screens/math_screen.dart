import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/features/math/providers/math_quiz_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MathScreen extends ConsumerWidget {
  const MathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Unlike Capitals or Flags, we always show the intro first 
    // unless they specifically launch a quiz session. For simplicity
    // we use a boolean flag or rely on routing explicitly `/math/quiz`.
    
    return const _MathIntroScreen();
  }
}

class _MathIntroScreen extends ConsumerWidget {
  const _MathIntroScreen();

  static const _operations = {
    MathOperation.addition: 'الجمع (+)',
    MathOperation.subtraction: 'الطرح (-)',
    MathOperation.multiplication: 'الضرب (×)',
    MathOperation.division: 'القسمة (÷)',
  };

  static const _opColors = {
    MathOperation.addition: Color(0xFF67B99A),
    MathOperation.subtraction: Color(0xFFF5C77E),
    MathOperation.multiplication: Color(0xFFFF9E7D),
    MathOperation.division: Color(0xFF78B0D1),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IntroHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroCard(),
                        const SizedBox(height: 28),
                        Text(
                          'أو اختر نوع العمليات',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280,
                            mainAxisExtent: 140,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: MathOperation.values.length,
                          itemBuilder: (context, index) {
                            final op = MathOperation.values[index];
                            return _OperationCard(
                              operation: op,
                              title: _operations[op]!,
                              color: _opColors[op]!,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.secondary),
            onPressed: () => context.go(AppRoutes.home),
          ),
          Text(
            'تحدي الرياضيات',
            style: AppTextStyles.headingMedium.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: 48), // Balance spacing
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4E4376).withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(mathOperationProvider.notifier).setFilter(null); // Mixed
            context.push(AppRoutes.mathQuiz);
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختبار الذكاء الشامل',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.surface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أسئلة متنوعة لا نهائية!',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.surface.withAlpha(200),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withAlpha(80),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔢', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationCard extends ConsumerWidget {
  const _OperationCard({
    required this.operation,
    required this.title,
    required this.color,
  });

  final MathOperation operation;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ref.read(mathOperationProvider.notifier).setFilter(operation);
            context.push(AppRoutes.mathQuiz);
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    title.split(' ').last, // Extacts (+), (-), (x)
                    style: TextStyle(fontSize: 24, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title.split(' ').first, // Extracts "الجمع"
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
