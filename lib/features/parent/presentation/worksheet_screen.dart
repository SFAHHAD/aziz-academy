import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/providers/general_quiz_pool_provider.dart';
import 'package:aziz_academy/features/general_quiz/data/general_quiz_repository.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

/// Generates a printable 10-question worksheet (with answer key on the
/// reverse side) from any module's question pool. Renders bilingual
/// content; the parent picks topic + locale and the screen produces a PNG
/// they can share via the system sheet, AirDrop, or open-in-Print.
class WorksheetScreen extends ConsumerStatefulWidget {
  const WorksheetScreen({super.key});

  @override
  ConsumerState<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends ConsumerState<WorksheetScreen> {
  final _key = GlobalKey();
  List<GeneralQuizEntry> _entries = const [];
  String? _topic;
  bool _arabic = true;
  bool _busy = false;
  List<GeneralQuizEntry> _picked = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use the session-cached pool — avoids re-parsing the 31 JSON packs
    // on every entry into the worksheet generator.
    final all = await ref.read(generalQuizPoolProvider.future);
    if (!mounted) return;
    setState(() {
      _entries = all;
      _picked = _pick(all, null);
    });
  }

  List<GeneralQuizEntry> _pick(List<GeneralQuizEntry> all, String? topic) {
    final pool = topic == null
        ? all
        : all.where((e) => e.category == topic).toList();
    final shuffled = [...pool]..shuffle(Random());
    return shuffled.take(10).toList();
  }

  Future<void> _share() async {
    if (_picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final ts = DateTime.now().millisecondsSinceEpoch;
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                Uint8List.fromList(bytes),
                mimeType: 'image/png',
                name: 'aziz_academy_worksheet_$ts.png',
              ),
            ],
            text: 'Worksheet — Aziz Academy',
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/aziz_academy_worksheet_$ts.png';
        await File(path).writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'Worksheet — Aziz Academy'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    final categories = _entries.map((e) => e.category).toSet().toList()..sort();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLow,
        foregroundColor: AppColors.textDark,
        title: Text(isAr ? 'ورقة عمل' : 'Worksheet'),
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.parent);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(isAr ? 'كل المواضيع' : 'All topics'),
                  selected: _topic == null,
                  onSelected: (_) => setState(() {
                    _topic = null;
                    _picked = _pick(_entries, null);
                  }),
                ),
                for (final c in categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _topic == c,
                    onSelected: (_) => setState(() {
                      _topic = c;
                      _picked = _pick(_entries, c);
                    }),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(isAr ? 'أسئلة جديدة' : 'New questions'),
                    onPressed: _entries.isEmpty
                        ? null
                        : () => setState(() {
                            _picked = _pick(_entries, _topic);
                          }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    label: Text(isAr ? 'شارك / اطبع' : 'Share / print'),
                    onPressed: _busy ? null : _share,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: RepaintBoundary(
                key: _key,
                child: _Worksheet(
                  arabic: _arabic,
                  topic: _topic,
                  questions: _picked,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SwitchListTile(
                value: _arabic,
                onChanged: (v) => setState(() => _arabic = v),
                title: Text(
                  isAr ? 'العربية' : 'Arabic',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Worksheet extends StatelessWidget {
  const _Worksheet({
    required this.arabic,
    required this.topic,
    required this.questions,
  });
  final bool arabic;
  final String? topic;
  final List<GeneralQuizEntry> questions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      padding: const EdgeInsets.all(28),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              arabic ? 'أكاديمية عزيز — ورقة عمل' : 'Aziz Academy — Worksheet',
              style: AppTextStyles.headingLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              topic ?? (arabic ? 'كل المواضيع' : 'All topics'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                arabic ? 'الاسم: ____________' : 'Name: ____________',
                style: AppTextStyles.bodyMedium,
              ),
              Text(
                arabic ? 'التاريخ: ____________' : 'Date: ____________',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(questions.length, (i) {
            final q = questions[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${arabic ? q.questionAr : q.question}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...List.generate(q.options.length, (j) {
                    final opt = arabic ? q.optionsAr[j] : q.options[j];
                    final letter = String.fromCharCode(65 + j);
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 2,
                        left: 12,
                        right: 12,
                      ),
                      child: Text(
                        '○ $letter. $opt',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const Divider(height: 32, thickness: 1),
          Text(
            arabic ? 'مفتاح الإجابات' : 'Answer key',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: List.generate(questions.length, (i) {
              final q = questions[i];
              final ans = arabic ? q.correctAnswerAr : q.correctAnswer;
              return Text(
                '${i + 1}. $ans',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textMedium,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
