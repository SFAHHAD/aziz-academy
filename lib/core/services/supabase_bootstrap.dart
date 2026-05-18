import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aziz Academy's Supabase backend (project `aziz-academy`, Q8VISION org,
/// region eu-central-1).
///
/// The anon key below is **public by design** — it is meant to ship in
/// client code. What actually protects data is row-level security: every
/// table has policies so an account can only ever read/write its own row.
/// See the `account_sync` migration.
const String kSupabaseUrl = 'https://pwdhwhpnwrlzrerrdqvg.supabase.co';
const String kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB3ZGh3aHBud3JsenJlcnJkcXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NTcwMTAsImV4cCI6MjA5NDUzMzAxMH0.pNYm7_yFjYaqDr-BPFhWt1f6HyU5mC5Ynzaq3tYTszQ';

/// True once [initSupabase] has finished successfully.
///
/// Every auth code path checks this first. When it is false — a backend
/// outage, or a widget test that pumps the app without running `main()` —
/// the app degrades cleanly to guest-only mode instead of crashing.
bool supabaseReady = false;

/// Initialises the Supabase SDK. Call once, early in `main()`, before
/// `runApp`. Never throws: a backend hiccup must not block app start, the
/// app is fully playable as a guest without it.
Future<void> initSupabase() async {
  try {
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
    );
    supabaseReady = true;
  } catch (e) {
    supabaseReady = false;
    debugPrint('Supabase init failed — running guest-only: $e');
  }
}
