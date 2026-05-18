import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/widgets/tts_speaker_icon.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: TtsSpeakerIcon(text: 'بِسْمِ اللَّهِ', tooltip: 'Listen'),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('hides itself when ttsEnabled is false (default policy)',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester);
    // With the new default + migration, ttsEnabled is false → no button.
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('renders an IconButton when ttsEnabled is true',
      (tester) async {
    // Bypass the migration by pre-setting the flag, then store
    // tts=true so the user setting is respected.
    SharedPreferences.setMockInitialValues({
      'real_audio_only_migrated_v1': true,
      'app_settings_v1': jsonEncode({'tts': true}),
    });
    await _pump(tester);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('hides when text is empty even if tts is on', (tester) async {
    SharedPreferences.setMockInitialValues({
      'real_audio_only_migrated_v1': true,
      'app_settings_v1': jsonEncode({'tts': true}),
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: TtsSpeakerIcon(text: '')),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
  });
}
