import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';

/// A small arithmetic challenge that stands between a child and any
/// account / external / purchase action.
///
/// Why: the App Store Kids Category (and good practice for any under-13
/// app) requires a "parental gate" — a deliberate barrier a young child
/// cannot pass by accident. A two-digit multiplication is the App Store
/// norm: trivial for an adult, a real speed-bump for a 6-year-old.
class ParentalChallenge {
  const ParentalChallenge(this.a, this.b);

  final int a;
  final int b;

  int get answer => a * b;

  /// The prompt shown to the parent, e.g. `13 × 7`.
  String get question => '$a × $b';

  /// Whether [input] (raw text) is the correct answer.
  bool accepts(String input) => int.tryParse(input.trim()) == answer;

  /// Generates a fresh challenge — a two-digit number times a single
  /// digit. Pure given [random]; exposed for tests.
  static ParentalChallenge generate([Random? random]) {
    final r = random ?? Random();
    return ParentalChallenge(11 + r.nextInt(9), 3 + r.nextInt(7));
  }
}

/// Shows the parental gate. Resolves `true` when the parent solves the
/// challenge, `false` if they cancel or dismiss it.
Future<bool> showParentalGate(
  BuildContext context, {
  required bool arabic,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ParentalGateDialog(arabic: arabic),
  );
  return ok ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog({required this.arabic});

  final bool arabic;

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog> {
  final _controller = TextEditingController();
  ParentalChallenge _challenge = ParentalChallenge.generate();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _verify() {
    if (_challenge.accepts(_controller.text)) {
      Navigator.of(context).pop(true);
      return;
    }
    // Wrong — regenerate so a child can't brute-force one fixed answer.
    setState(() {
      _wrong = true;
      _challenge = ParentalChallenge.generate();
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.arabic;
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: Row(
        children: [
          const Text('🧑‍🦰', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ar ? 'اسأل شخصاً بالغاً' : 'Ask a grown-up',
              style: AppTextStyles.headingSmall,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar
                ? 'هذه الخطوة للكبار. لإكمالها، احسب:'
                : 'This step is for grown-ups. To continue, solve:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _challenge.question,
              style: AppTextStyles.headingMedium.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              hintText: ar ? 'الإجابة' : 'Answer',
              filled: true,
              fillColor: AppColors.background,
              errorText: _wrong
                  ? (ar ? 'حاول مرة أخرى' : 'Try again')
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(ar ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _verify,
          child: Text(ar ? 'تأكيد' : 'Confirm'),
        ),
      ],
    );
  }
}
