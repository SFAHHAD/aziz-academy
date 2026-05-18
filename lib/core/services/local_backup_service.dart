import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/l10n/context_ext.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/services/local_backup_platform.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';

/// Validates exported JSON shape. Returns a localized error message or null if OK.
String? validateBackupPayload(Map<String, dynamic> j, AppLocalizations l10n) {
  if (j['app'] != 'aziz_academy') {
    return l10n.backupInvalidFile;
  }
  final v = j['v'];
  if (v != 2 && v != 1) {
    return l10n.backupUnsupportedVersion;
  }
  if (j['achievements'] is! Map) {
    return l10n.backupMissingAchievements;
  }
  if (j['recapQueue'] is! List) {
    return l10n.backupMissingRecap;
  }
  return null;
}

/// Builds the same JSON as export (for tests / reuse).
Future<String> buildLocalProgressJsonString(WidgetRef ref) async {
  final ach = await ref.read(achievementProvider.future);
  final recap = await ref.read(recapQueueProvider.future);

  final payload = <String, dynamic>{
    'v': 2,
    'app': 'aziz_academy',
    'exported': DateTime.now().toIso8601String(),
    'achievements': {
      'capitalsStars': ach.capitalsStars,
      'logosStars': ach.logosStars,
      'mathStars': ach.mathStars,
      'sciencesStars': ach.sciencesStars,
      'capitalsCompleted': ach.capitalsCompleted,
      'logosCompleted': ach.logosCompleted,
      'mathCompleted': ach.mathCompleted,
      'sciencesCompleted': ach.sciencesCompleted,
      'totalCorrect': ach.totalCorrect,
      'streakCount': ach.streakCount,
      'lastVisitDate': ach.lastVisitDate,
      'continentsTapped': ach.continentsTapped.toList(),
      'unlockedBadges': ach.unlockedBadges.map((b) => b.name).toList(),
    },
    'recapQueue': recap.map((e) => e.toJson()).toList(),
  };

  return const JsonEncoder.withIndent('  ').convert(payload);
}

/// Exports on-device progress as JSON (no cloud — local backup / support).
Future<void> shareLocalProgressJson(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final text = await buildLocalProgressJsonString(ref);
  await shareBackupText(text, l10n.backupShareSubject);
}

/// Picks a JSON file and merges into local storage after parent confirmation.
Future<void> importLocalProgressFromFile(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;

  final bytes = await readPickedFileBytes(result.files.single);
  if (bytes == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupReadFileError)),
      );
    }
    return;
  }

  final text = utf8.decode(bytes);
  late final Map<String, dynamic> map;
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('root');
    }
    map = decoded;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.backupInvalidJson)),
      );
    }
    return;
  }

  final err = validateBackupPayload(map, l10n);
  if (err != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
    return;
  }

  if (!context.mounted) return;
  final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final d = ctx.l10n;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(d.backupImportTitle),
            content: Text(d.backupImportBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(d.backupCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(d.backupConfirm),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!ok) return;

  await ref.read(achievementProvider.notifier).restoreFromBackup(
        Map<String, dynamic>.from(map['achievements'] as Map),
      );
  await ref.read(recapQueueProvider.notifier).replaceQueueFromBackup(
        List<dynamic>.from(map['recapQueue'] as List),
      );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.backupSnackSuccess)),
    );
  }
}
