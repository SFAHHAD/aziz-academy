import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aziz_academy/core/agents/learner_state.dart';
import 'package:aziz_academy/core/providers/achievement_provider.dart';
import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/providers/daily_challenge_provider.dart';
import 'package:aziz_academy/core/providers/family_profiles_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/providers/mood_provider.dart';
import 'package:aziz_academy/core/providers/recap_queue_provider.dart';
import 'package:aziz_academy/core/providers/xp_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aziz_academy/features/admin/admin_assets.dart';
import 'package:aziz_academy/features/admin/admin_audit.dart';
import 'package:aziz_academy/features/admin/sections/qbank_crud_section.dart';
import 'package:aziz_academy/features/admin/sections/feature_flags_admin_section.dart';
import 'package:aziz_academy/features/admin/admin_error_log.dart';
import 'package:aziz_academy/features/admin/admin_feedback.dart';
import 'package:aziz_academy/features/admin/admin_lint.dart';
import 'package:aziz_academy/features/admin/admin_overrides.dart';
import 'package:aziz_academy/features/admin/admin_traffic.dart';
import 'package:aziz_academy/features/admin/q_bank_service.dart';
import 'package:aziz_academy/features/home/activity_catalog.dart';

// =============================================================================
// Admin Console
//
// Pro layout:
//   - Sidebar: grouped sections (Overview / Content / Users / System / Tools)
//   - Main: page header + section body
//   - Sidebar collapses to a drawer on screens < 900 px
//
// Sections:
//   Overview        — system + live counters + skill EMAs + sessions
//   Q Bank          — pool browser + question search
//   Lint            — content quality issues
//   Translate       — missing-AR workbench with override save
//   Catalog         — every home activity, deep links
//   Family          — profiles inspector
//   Economy & Mood  — coins, mood history
//   Storage         — SharedPreferences inspector
//   Errors          — in-memory error log
//   Flags           — feature flag toggles
//   Tools           — destructive actions
//
// Hidden behind a 4-digit gate. Default code: 4242.
// =============================================================================

const String _kPasscode = '4242';
const String _kAppVersion = '1.1.113+118';
const String _kBuildCommit = String.fromEnvironment(
  'GIT_COMMIT',
  defaultValue: 'dev',
);
const String _kBuildTime = String.fromEnvironment(
  'BUILD_TIME',
  defaultValue: '',
);
const String _kUnlockedAtKey = 'admin_unlocked_at';
const Duration _kSessionTtl = Duration(hours: 12);

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool? _authorized;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_kUnlockedAtKey);
    if (ts != null) {
      final unlockedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(unlockedAt) < _kSessionTtl) {
        if (mounted) setState(() => _authorized = true);
        return;
      }
    }
    if (mounted) setState(() => _authorized = false);
  }

  Future<void> _onUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUnlockedAtKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _authorized = true);
  }

  Future<void> _onLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUnlockedAtKey);
    if (mounted) setState(() => _authorized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_authorized == null) {
      return const Scaffold(
        backgroundColor: _C.canvas,
        body: Center(child: CircularProgressIndicator(color: _C.accent)),
      );
    }
    if (_authorized == false) {
      return _PasscodeGate(onUnlock: _onUnlock);
    }
    return _AdminShell(onLogout: _onLogout);
  }
}

// =============================================================================
// Design tokens — terminal/ops console.
//
// The kid-facing app is navy + gold + rounded + Cairo. The admin must be the
// *visual opposite*: pure black, terminal green, sharp corners, mono font.
// Goal: zero ambiguity — the moment the operator lands here it reads as a
// dev tool, not "the same app in a different mode".
// =============================================================================

class _C {
  static const canvas = Color(0xFF000000); // pure black canvas
  static const sidebar = Color(0xFF080808); // very-near-black sidebar
  static const card = Color(0xFF0E0E10); // panel bg
  static const cardHi = Color(0xFF161618); // hover / selected row
  static const border = Color(0xFF1F1F22); // hairline
  static const text = Color(0xFFD4D4D4); // mono off-white
  static const muted = Color(0xFF6E6E72); // captions / labels
  static const accent = Color(0xFF3FB950); // terminal green (ANSI-ish)
  static const warn = Color(0xFFE8A85F); // amber for warnings
  static const danger = Color(0xFFF85149); // red for errors
  // Strict mono font for the entire console.
  static const font = 'JetBrainsMono';
}

// =============================================================================
// Passcode gate
// =============================================================================

class _PasscodeGate extends StatefulWidget {
  const _PasscodeGate({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  State<_PasscodeGate> createState() => _PasscodeGateState();
}

class _PasscodeGateState extends State<_PasscodeGate> {
  final _ctrl = TextEditingController();
  String? _error;
  int _attempts = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _ctrl.text.trim();
    if (code == _kPasscode) {
      widget.onUnlock();
      return;
    }
    setState(() {
      _attempts++;
      _error = _attempts >= 3
          ? 'Too many tries. Go home.'
          : 'Wrong code. Try again.';
    });
    _ctrl.clear();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _C.card,
                      border: Border.all(color: _C.border),
                    ),
                    child: const Text(
                      '\$ aziz-ops --auth',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: _C.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'restricted: passcode required',
                    style: TextStyle(
                      fontFamily: _C.font,
                      color: _C.muted,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    autofocus: true,
                    enabled: _attempts < 3,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: _C.text,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      hintText: '••••',
                      hintStyle: AppTextStyles.headingMedium.copyWith(
                        color: _C.muted.withAlpha(120),
                        letterSpacing: 8,
                      ),
                      filled: true,
                      fillColor: _C.card,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      border: _border(_C.border),
                      enabledBorder: _border(_C.border),
                      focusedBorder: _border(_C.accent),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _C.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _C.accent,
                        foregroundColor: const Color(0xFF0A1628),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      onPressed: _attempts < 3 ? _submit : null,
                      child: const Text(
                        'Unlock',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(
                      'Back to home',
                      style: AppTextStyles.bodyMedium.copyWith(color: _C.muted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(2),
    borderSide: BorderSide(color: c),
  );
}

// =============================================================================
// Sections enum (sidebar + content router)
// =============================================================================

enum _Section {
  overview,
  traffic,
  engagement,
  feedback,
  audit,
  qBank,
  qBankCrud,        // NEW 2026-05-18: add/edit/delete questions (Supabase)
  lint,
  translate,
  catalog,
  assets,
  family,
  economy,
  privacy,
  storage,
  errors,
  flags,
  cloudFlags,       // NEW 2026-05-18: global section enable/disable (Supabase)
  tools,
}

/// Maps an audit area + the lint code (if present in the finding title) to
/// the section the operator should jump to. Falls back to the area's most
/// relevant tab when no code is present.
_Section _sectionForAuditFinding(AuditFinding f) {
  // Heuristics — keep simple. The title strings come from runAudit() in
  // admin_audit.dart; if you change them there, update here.
  final t = f.title.toLowerCase();
  if (t.contains('parse')) return _Section.qBank;
  if (t.contains('duplicate question id')) return _Section.qBank;
  if (t.contains('duplicate activity id')) return _Section.catalog;
  if (t.contains('catalog')) return _Section.catalog;
  if (t.contains('activity row')) return _Section.catalog;
  if (t.contains('categor') || t.contains('featured')) {
    return _Section.catalog;
  }
  if (t.contains('arabic')) return _Section.translate;
  if (t.contains('lint')) return _Section.lint;
  if (t.contains('framework error')) return _Section.errors;
  if (t.contains('recap')) return _Section.tools;
  if (t.contains('feedback')) return _Section.feedback;
  if (t.contains('cross-device')) return _Section.traffic;
  if (t.contains('app open')) return _Section.traffic;
  switch (f.area) {
    case AuditArea.content:
      return _Section.qBank;
    case AuditArea.security:
      return _Section.privacy;
    case AuditArea.performance:
      return _Section.assets;
    case AuditArea.accessibility:
      return _Section.tools;
    case AuditArea.operations:
      return _Section.errors;
  }
}

extension _SectionX on _Section {
  String get label {
    switch (this) {
      case _Section.overview:
        return 'Overview';
      case _Section.traffic:
        return 'Traffic';
      case _Section.engagement:
        return 'Engagement';
      case _Section.feedback:
        return 'Feedback';
      case _Section.audit:
        return 'Audit Report';
      case _Section.qBank:
        return 'Q Bank';
      case _Section.lint:
        return 'Lint';
      case _Section.translate:
        return 'Translate';
      case _Section.catalog:
        return 'Catalog';
      case _Section.assets:
        return 'Assets';
      case _Section.family:
        return 'Family';
      case _Section.economy:
        return 'Economy & Mood';
      case _Section.privacy:
        return 'Privacy & Data';
      case _Section.storage:
        return 'Storage';
      case _Section.errors:
        return 'Errors';
      case _Section.flags:
        return 'Activity hide list (local)';
      case _Section.qBankCrud:
        return 'Q-Bank — Edit content';
      case _Section.cloudFlags:
        return 'Feature flags (global)';
      case _Section.tools:
        return 'Tools';
    }
  }

  IconData get icon {
    switch (this) {
      case _Section.overview:
        return Icons.dashboard_rounded;
      case _Section.traffic:
        return Icons.show_chart_rounded;
      case _Section.engagement:
        return Icons.local_fire_department_rounded;
      case _Section.feedback:
        return Icons.inbox_rounded;
      case _Section.audit:
        return Icons.fact_check_rounded;
      case _Section.qBank:
        return Icons.inventory_2_outlined;
      case _Section.lint:
        return Icons.rule_rounded;
      case _Section.translate:
        return Icons.translate_rounded;
      case _Section.catalog:
        return Icons.apps_rounded;
      case _Section.assets:
        return Icons.folder_open_rounded;
      case _Section.family:
        return Icons.family_restroom_rounded;
      case _Section.economy:
        return Icons.savings_rounded;
      case _Section.privacy:
        return Icons.shield_outlined;
      case _Section.storage:
        return Icons.storage_rounded;
      case _Section.errors:
        return Icons.error_outline_rounded;
      case _Section.flags:
        return Icons.toggle_on_outlined;
            case _Section.qBankCrud:
        return Icons.edit_note_rounded;
      case _Section.cloudFlags:
        return Icons.toggle_on_rounded;

case _Section.tools:
        return Icons.build_rounded;
    }
  }

  String get group {
    switch (this) {
      case _Section.overview:
        return 'OVERVIEW';
      case _Section.traffic:
      case _Section.engagement:
      case _Section.feedback:
      case _Section.audit:
      case _Section.errors:
        return 'MONITORING';
      case _Section.qBank:
      case _Section.qBankCrud:
      case _Section.lint:
      case _Section.translate:
      case _Section.catalog:
      case _Section.assets:
        return 'CONTENT';
      case _Section.family:
      case _Section.economy:
        return 'USERS';
      case _Section.privacy:
      case _Section.storage:
      case _Section.flags:
      case _Section.cloudFlags:
        return 'SYSTEM';
      case _Section.tools:
        return 'TOOLS';
    }
  }
}

// =============================================================================
// Shell — sidebar + main pane
// =============================================================================

class _AdminShell extends ConsumerStatefulWidget {
  const _AdminShell({required this.onLogout});
  final VoidCallback onLogout;

  @override
  ConsumerState<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<_AdminShell> {
  _Section _section = _Section.overview;
  // Set when a user clicks "Open in Translate" from a lint row. Read once by
  // the translate section's initial query and then cleared.
  String? _translateInitialQuery;

  void _jumpToTranslate(String query) {
    setState(() {
      _section = _Section.translate;
      _translateInitialQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: _C.canvas,
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: _C.sidebar,
              child: SafeArea(
                child: _Sidebar(
                  section: _section,
                  onPick: (s) {
                    setState(() => _section = s);
                    Navigator.of(context).maybePop();
                  },
                  onLogout: widget.onLogout,
                ),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              SizedBox(
                width: 240,
                child: _Sidebar(
                  section: _section,
                  onPick: (s) => setState(() => _section = s),
                  onLogout: widget.onLogout,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _PageHeader(section: _section, showMenu: !wide),
                  Expanded(
                    child: _SectionRouter(
                      section: _section,
                      onJumpTranslate: _jumpToTranslate,
                      initialTranslateQuery: _translateInitialQuery,
                      onTranslateQueryConsumed: () =>
                          setState(() => _translateInitialQuery = null),
                      onJumpToSection: (s) => setState(() => _section = s),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.onPick,
    required this.onLogout,
  });

  final _Section section;
  final ValueChanged<_Section> onPick;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<_Section>>{};
    for (final s in _Section.values) {
      groups.putIfAbsent(s.group, () => []).add(s);
    }
    return Container(
      color: _C.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(
              children: [
                // Square mono terminal-style mark instead of round gold badge
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _C.canvas,
                    border: Border.all(color: _C.accent, width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '▍',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: _C.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'aziz-ops',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _C.cardHi,
                    border: Border.all(color: _C.border),
                  ),
                  child: const Text(
                    'v1',
                    style: TextStyle(
                      fontFamily: _C.font,
                      color: _C.muted,
                      fontSize: 9,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
                    child: Row(
                      children: [
                        Text(
                          '# ${entry.key.toLowerCase()}',
                          style: TextStyle(
                            fontFamily: _C.font,
                            color: _C.muted.withAlpha(180),
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 1, color: _C.border)),
                      ],
                    ),
                  ),
                  for (final s in entry.value)
                    _SidebarItem(
                      section: s,
                      selected: s == section,
                      onTap: () => onPick(s),
                    ),
                ],
                const SizedBox(height: 14),
              ],
            ),
          ),
          const Divider(height: 1, color: _C.border),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _SidebarFooterButton(
                  icon: Icons.home_rounded,
                  label: 'Back to home',
                  onTap: () => context.go(AppRoutes.home),
                ),
                _SidebarFooterButton(
                  icon: Icons.logout_rounded,
                  label: 'Lock console',
                  onTap: onLogout,
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                  child: Text(
                    'v$_kAppVersion · ${_kBuildCommit == 'dev' ? 'dev build' : _kBuildCommit}',
                    style: const TextStyle(
                      fontFamily: _C.font,
                      color: _C.muted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(2),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _C.cardHi : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
              border: Border(
                left: BorderSide(
                  color: selected ? _C.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 17,
                  color: selected ? _C.accent : _C.muted,
                ),
                const SizedBox(width: 10),
                Text(
                  section.label,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: selected ? _C.text : _C.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
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

class _SidebarFooterButton extends StatelessWidget {
  const _SidebarFooterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _C.muted),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _C.font,
                  color: _C.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageHeader extends ConsumerWidget {
  const _PageHeader({required this.section, required this.showMenu});
  final _Section section;
  final bool showMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _C.sidebar,
        border: Border(bottom: BorderSide(color: _C.border)),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: _C.text),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          // Live status dot — purely visual confirmation that the console is
          // connected (no network polling, this is a fixed indicator).
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3FB950),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3FB950).withAlpha(120),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  section.group,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '/',
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.border,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    section.label,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: _C.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Build / commit chip — operator can see at a glance which build is
          // in front of them. Hidden on narrow widths.
          if (MediaQuery.of(context).size.width >= 720)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _C.cardHi,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _C.border),
              ),
              child: Text(
                _kBuildCommit == 'dev' ? 'DEV' : '#$_kBuildCommit',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  color: _C.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh data',
            icon: const Icon(Icons.refresh_rounded, color: _C.muted, size: 20),
            onPressed: () {
              ref.invalidate(qBankProvider);
              ref.invalidate(lintReportProvider);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionRouter extends StatelessWidget {
  const _SectionRouter({
    required this.section,
    required this.onJumpTranslate,
    required this.initialTranslateQuery,
    required this.onTranslateQueryConsumed,
    required this.onJumpToSection,
  });
  final _Section section;
  final ValueChanged<String> onJumpTranslate;
  final String? initialTranslateQuery;
  final VoidCallback onTranslateQueryConsumed;
  final ValueChanged<_Section> onJumpToSection;

  @override
  Widget build(BuildContext context) {
    switch (section) {
      case _Section.overview:
        return const _OverviewSection();
      case _Section.traffic:
        return const _TrafficSection();
      case _Section.engagement:
        return const _EngagementSection();
      case _Section.feedback:
        return const _FeedbackSection();
      case _Section.audit:
        return _AuditSection(onJumpToSection: onJumpToSection);
      case _Section.qBank:
        return const _QBankSection();
      case _Section.lint:
        return _LintSection(onJumpTranslate: onJumpTranslate);
      case _Section.translate:
        return _TranslateSection(
          initialQuery: initialTranslateQuery,
          onQueryConsumed: onTranslateQueryConsumed,
        );
      case _Section.catalog:
        return const _CatalogSection();
      case _Section.assets:
        return const _AssetsSection();
      case _Section.family:
        return const _FamilySection();
      case _Section.economy:
        return const _EconomySection();
      case _Section.privacy:
        return const _PrivacySection();
      case _Section.storage:
        return const _StorageSection();
      case _Section.errors:
        return const _ErrorsSection();
      case _Section.qBankCrud:
        return const QBankCrudSection();
      case _Section.flags:
        return const _FlagsSection();
      case _Section.cloudFlags:
        return const FeatureFlagsAdminSection();
      case _Section.tools:
        return const _ToolsSection();
    }
  }
}

// =============================================================================
// Section: Overview
// =============================================================================

class _OverviewSection extends ConsumerWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievement = ref.watch(achievementProvider).value;
    final coins = ref.watch(coinProvider).value ?? 0;
    final learner = ref.watch(learnerStateProvider).value;
    final recapTotal = ref.watch(recapQueueProvider).value?.length ?? 0;
    final dailyDone =
        ref.watch(dailyChallengeProvider).value?.isCompleted ?? false;
    final locale = ref.watch(localeProvider).value;
    final media = MediaQuery.of(context);
    final lintAsync = ref.watch(lintReportProvider);
    final qBankAsync = ref.watch(qBankProvider);

    final buildMode = kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug';
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Health'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HealthCard(
                tone: dailyDone ? _Tone.ok : _Tone.warn,
                label: 'Daily challenge',
                value: dailyDone ? 'Done today' : 'Pending',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: lintAsync.when(
                loading: () => _HealthCard(
                  tone: _Tone.muted,
                  label: 'Content lint',
                  value: 'Running…',
                ),
                error: (e, st) => _HealthCard(
                  tone: _Tone.err,
                  label: 'Content lint',
                  value: 'Failed',
                ),
                data: (rep) => _HealthCard(
                  tone: rep.errors > 0
                      ? _Tone.err
                      : (rep.warnings > 0 ? _Tone.warn : _Tone.ok),
                  label: 'Content lint',
                  value: '${rep.errors}E · ${rep.warnings}W · ${rep.infos}i',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: qBankAsync.when(
                loading: () => _HealthCard(
                  tone: _Tone.muted,
                  label: 'Q Bank',
                  value: 'Loading…',
                ),
                error: (e, st) => _HealthCard(
                  tone: _Tone.err,
                  label: 'Q Bank',
                  value: 'Failed',
                ),
                data: (snap) => _HealthCard(
                  tone: snap.poolsWithErrors > 0
                      ? _Tone.err
                      : (snap.totalMissingAr > 0 ? _Tone.warn : _Tone.ok),
                  label: 'Q Bank',
                  value:
                      '${snap.totalQuestions} Q · ${(snap.bilingualRatio * 100).toStringAsFixed(0)}% AR',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Header2('System'),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Version', _kAppVersion),
            _Stat(
              'Build',
              '$buildMode${_kBuildCommit == 'dev' ? '' : ' · $_kBuildCommit'}',
            ),
            _Stat(
              'Built',
              _kBuildTime.isEmpty ? '—' : _kBuildTime.split('T').first,
            ),
            _Stat('Platform', platform),
            _Stat('Locale', locale?.languageCode ?? 'ar'),
            _Stat(
              'Direction',
              Directionality.of(context) == TextDirection.rtl ? 'RTL' : 'LTR',
            ),
            _Stat(
              'Viewport',
              '${media.size.width.toInt()}×${media.size.height.toInt()}',
            ),
            _Stat('Pixel ratio', media.devicePixelRatio.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 24),
        _Header2('This device'),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Badges', '${achievement?.unlockedBadges.length ?? 0}'),
            _Stat('Visit streak', '${achievement?.streakCount ?? 0}'),
            _Stat('Coins', '$coins'),
            _Stat('Total sessions', '${learner?.totalSessions ?? 0}'),
            _Stat('Recap queue', '$recapTotal'),
            _Stat(
              'Frustration',
              learner == null
                  ? '—'
                  : '${(learner.frustrationLevel * 100).toStringAsFixed(0)}%',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _Header2('Skill EMA per module'),
        const SizedBox(height: 12),
        _SkillTable(learner: learner),
        const SizedBox(height: 24),
        _Header2('Last 10 sessions'),
        const SizedBox(height: 12),
        _SessionList(learner: learner),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Section: Traffic
// =============================================================================

class _TrafficSection extends ConsumerWidget {
  const _TrafficSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trafficSnapshotProvider);
    return async.when(
      loading: () => const _LoadingPanel(label: 'Loading traffic…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: _render,
    );
  }

  Widget _render(TrafficSnapshot t) {
    final topRoutes = t.routeHits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('On-device traffic'),
        const SizedBox(height: 6),
        const Text(
          'These counters live in SharedPreferences on this browser only. '
          'For cross-device visitor numbers, see "Cross-device" below.',
          style: TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          stats: [
            _Stat('Total opens', '${t.totalOpens}'),
            _Stat('Active days (7d)', '${t.openDaysLast7}'),
            _Stat('Active days (30d)', '${t.openDaysLast30}'),
            _Stat('Last open', fmtAgo(t.lastOpenAt)),
            _Stat(
              'First open',
              t.firstOpenAt == null
                  ? '—'
                  : t.firstOpenAt!.toIso8601String().split('T').first,
            ),
            _Stat('Total page loads', '${t.totalRouteHits}'),
          ],
        ),
        const SizedBox(height: 24),
        _Header2('Last 14 days'),
        const SizedBox(height: 8),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < t.openHistogramByDay.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: t.openHistogramByDay[i] == 1 ? 56 : 4,
                              decoration: BoxDecoration(
                                color: t.openHistogramByDay[i] == 1
                                    ? _C.accent
                                    : _C.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${13 - i}d',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                color: _C.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Header2('Top routes (this device)'),
        const SizedBox(height: 8),
        if (topRoutes.isEmpty)
          _MutedPanel(text: 'Navigate around the app and counts will fill in.')
        else
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < topRoutes.take(20).length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _C.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            topRoutes[i].key,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              color: _C.text,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          fmtAgo(t.routeLastSeen[topRoutes[i].key]),
                          style: const TextStyle(
                            fontFamily: _C.font,
                            color: _C.muted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '${topRoutes[i].value} hit'
                            '${topRoutes[i].value == 1 ? '' : 's'}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: _C.font,
                              color: _C.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        _Header2('Cross-device traffic'),
        const SizedBox(height: 8),
        _Card(
          borderTone: _Tone.ok,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(label: 'WIRED', tone: _C.accent),
                    const SizedBox(width: 8),
                    const Text(
                      'Vercel Web Analytics + Speed Insights',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Privacy-friendly: no cookies, no fingerprinting, no PII. '
                  'Just URL + a coarse country code. Counts every visitor '
                  'across devices/browsers automatically.',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SelectableText(
                      'https://vercel.com/sfahhads-projects/aziz-academy/analytics',
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: _C.accent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _C.canvas,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: _C.border),
                  ),
                  child: const Text(
                    'View visitor counts, top pages, country breakdown, and '
                    'Core Web Vitals (LCP/FID/CLS) in the Vercel dashboard. '
                    'The link is operator-only — no auth bypass.',
                    style: TextStyle(
                      fontFamily: _C.font,
                      color: _C.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Section: Engagement
//
// Per-module breakdown drawn from LearnerState.recentSessions on this device.
// We aggregate session count, average accuracy, average duration, and last
// played, then sort to surface the strongest and weakest modules.
// =============================================================================

class _EngagementSection extends ConsumerWidget {
  const _EngagementSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learner = ref.watch(learnerStateProvider).value;
    final trafficAsync = ref.watch(trafficSnapshotProvider);
    final traffic = trafficAsync.value;
    if (learner == null || learner.recentSessions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _MutedPanel(
            text: 'No quiz sessions logged yet on this device.',
          ),
          const SizedBox(height: 24),
          if (traffic != null) _ActivityRankingCard(traffic: traffic),
        ],
      );
    }

    // Group sessions by module.
    final byModule = <String, List<SessionStat>>{};
    for (final s in learner.recentSessions) {
      byModule.putIfAbsent(s.module, () => []).add(s);
    }

    // Compute per-module rollup.
    final rows = byModule.entries.map((e) {
      final list = e.value;
      final totalAns = list.fold<int>(0, (a, b) => a + b.total);
      final totalCorr = list.fold<int>(0, (a, b) => a + b.score);
      final totalMs = list.fold<int>(0, (a, b) => a + b.durationMs);
      final last = list
          .map((s) => s.endedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      return _EngRow(
        module: e.key,
        sessionCount: list.length,
        accuracy: totalAns == 0 ? 0 : totalCorr / totalAns,
        avgDurationMs: list.isEmpty ? 0 : totalMs ~/ list.length,
        lastPlayed: last,
      );
    }).toList()..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    final strongest = [...rows]
      ..sort((a, b) => b.accuracy.compareTo(a.accuracy));
    final weakest = [...rows]..sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final totalSessions = rows.fold<int>(0, (a, b) => a + b.sessionCount);
    final totalAns = byModule.values
        .expand((l) => l)
        .fold<int>(0, (a, b) => a + b.total);
    final totalCorr = byModule.values
        .expand((l) => l)
        .fold<int>(0, (a, b) => a + b.score);
    final overallAcc = totalAns == 0 ? 0 : (totalCorr / totalAns) * 100;
    final totalMinutes =
        byModule.values
            .expand((l) => l)
            .fold<int>(0, (a, b) => a + b.durationMs) /
        60000;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Engagement (this device)'),
        const SizedBox(height: 6),
        const Text(
          'Aggregated from the last 30 sessions captured by the learner '
          'agent. For cross-device numbers, see Vercel Analytics.',
          style: TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          stats: [
            _Stat('Modules played', '${byModule.length}'),
            _Stat('Total sessions', '$totalSessions'),
            _Stat('Questions answered', '$totalAns'),
            _Stat('Overall accuracy', '${overallAcc.toStringAsFixed(0)}%'),
            _Stat('Total play time', '${totalMinutes.toStringAsFixed(0)}m'),
          ],
        ),
        const SizedBox(height: 24),
        if (strongest.isNotEmpty && strongest.first.accuracy > 0) ...[
          _Header2('Strongest module'),
          const SizedBox(height: 8),
          _Card(
            borderTone: _Tone.ok,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: _C.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strongest.first.module,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${(strongest.first.accuracy * 100).toStringAsFixed(0)}% accuracy '
                          'across ${strongest.first.sessionCount} sessions',
                          style: const TextStyle(
                            fontFamily: _C.font,
                            color: _C.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (weakest.isNotEmpty && weakest.first.accuracy < 0.6) ...[
          _Header2('Worth practicing'),
          const SizedBox(height: 8),
          _Card(
            borderTone: _Tone.warn,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(
                    Icons.fitness_center_rounded,
                    color: _C.warn,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weakest.first.module,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Only ${(weakest.first.accuracy * 100).toStringAsFixed(0)}% accurate — '
                          'rotate it through Recap.',
                          style: const TextStyle(
                            fontFamily: _C.font,
                            color: _C.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _Header2('All modules played'),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _C.border),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          rows[i].module,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.text,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: rows[i].accuracy.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rows[i].accuracy < 0.45
                                      ? _C.danger
                                      : (rows[i].accuracy > 0.78
                                            ? _C.accent
                                            : _C.warn),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${rows[i].sessionCount} sessions  ·  '
                              'avg ${fmtDuration(rows[i].avgDurationMs)}  ·  '
                              '${fmtAgo(rows[i].lastPlayed)}',
                              style: const TextStyle(
                                fontFamily: _C.font,
                                color: _C.muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${(rows[i].accuracy * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (traffic != null) _ActivityRankingCard(traffic: traffic),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _EngRow {
  const _EngRow({
    required this.module,
    required this.sessionCount,
    required this.accuracy,
    required this.avgDurationMs,
    required this.lastPlayed,
  });
  final String module;
  final int sessionCount;
  final double accuracy;
  final int avgDurationMs;
  final DateTime lastPlayed;
}

/// Cross-references the activity catalog with the traffic route hits so the
/// operator can see which catalog activities actually get used and which
/// have never been opened. The "Never opened" list is the easiest source
/// of pruning candidates.
class _ActivityRankingCard extends StatelessWidget {
  const _ActivityRankingCard({required this.traffic});
  final TrafficSnapshot traffic;

  @override
  Widget build(BuildContext context) {
    // Build a list of (activity, hits) using the catalog as the source of
    // truth and traffic.routeHits as the lookup. Activities that have never
    // been visited get hits=0.
    final ranked = kActivities.map((a) {
      return (activity: a, hits: traffic.routeHits[a.route] ?? 0);
    }).toList()..sort((a, b) => b.hits.compareTo(a.hits));

    final visited = ranked.where((r) => r.hits > 0).toList();
    final neverOpened = ranked.where((r) => r.hits == 0).toList();
    final coverage = kActivities.isEmpty
        ? 0.0
        : (visited.length / kActivities.length) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header2('Activity ranking'),
        const SizedBox(height: 6),
        Text(
          'Cross-references your catalog (${kActivities.length} activities) '
          'with the on-device route hits. ${visited.length} activities have '
          'been opened — ${coverage.toStringAsFixed(0)}% coverage.',
          style: const TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        if (visited.isNotEmpty) ...[
          const Text(
            'Top 10 most-used',
            style: TextStyle(
              fontFamily: _C.font,
              color: _C.muted,
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < visited.take(10).length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _C.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '#${i + 1}',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              color: _C.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Text(
                          visited[i].activity.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            visited[i].activity.titleEn,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: _C.font,
                              color: _C.text,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${visited[i].hits}',
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (neverOpened.isNotEmpty) ...[
          Text(
            '${neverOpened.length} never opened',
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.warn,
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'These catalog activities have zero hits on this device. If '
            'they\'re also rarely opened in Vercel Analytics, consider '
            'pruning to keep the catalog healthy.',
            style: TextStyle(
              fontFamily: _C.font,
              color: _C.muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in neverOpened.take(40))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: _C.warn.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.activity.emoji,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r.activity.titleEn,
                        style: const TextStyle(
                          fontFamily: _C.font,
                          color: _C.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (neverOpened.length > 40) ...[
            const SizedBox(height: 6),
            Text(
              '… and ${neverOpened.length - 40} more',
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.muted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// =============================================================================
// Section: Feedback inbox
// =============================================================================

class _FeedbackSection extends ConsumerStatefulWidget {
  const _FeedbackSection();

  @override
  ConsumerState<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends ConsumerState<_FeedbackSection> {
  FeedbackStatus? _statusFilter = FeedbackStatus.open;
  FeedbackKind? _kindFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(feedbackInboxProvider);
    return async.when(
      loading: () => const _LoadingPanel(label: 'Loading feedback…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: _render,
    );
  }

  Widget _render(List<FeedbackEntry> entries) {
    final byStatus = <FeedbackStatus, int>{
      for (final s in FeedbackStatus.values)
        s: entries.where((e) => e.status == s).length,
    };
    final byKind = <FeedbackKind, int>{
      for (final k in FeedbackKind.values)
        k: entries.where((e) => e.kind == k).length,
    };
    final filtered = entries
        .where(
          (e) =>
              (_statusFilter == null || e.status == _statusFilter) &&
              (_kindFilter == null || e.kind == _kindFilter) &&
              (_query.isEmpty ||
                  e.message.toLowerCase().contains(_query.toLowerCase()) ||
                  e.from.toLowerCase().contains(_query.toLowerCase()) ||
                  e.contact.toLowerCase().contains(_query.toLowerCase())),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _Header2('Inbox'),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(
                Icons.download_rounded,
                size: 14,
                color: _C.muted,
              ),
              label: const Text(
                'Export JSON',
                style: TextStyle(color: _C.muted),
              ),
              onPressed: () => _exportDialog(
                context,
                ref.read(feedbackInboxProvider.notifier).exportJson(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Submissions saved on this device. Add a Vercel function or '
          'Formspree endpoint if you want them posted to your inbox too.',
          style: TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          stats: [
            _Stat('Total received', '${entries.length}'),
            _Stat('Open', '${byStatus[FeedbackStatus.open]}'),
            _Stat('Resolved', '${byStatus[FeedbackStatus.resolved]}'),
            _Stat('Archived', '${byStatus[FeedbackStatus.archived]}'),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ToggleChip(
              label: 'All',
              selected: _statusFilter == null,
              onTap: () => setState(() => _statusFilter = null),
            ),
            for (final s in FeedbackStatus.values)
              _ToggleChip(
                label: '${s.name} (${byStatus[s]})',
                selected: _statusFilter == s,
                tone: s == FeedbackStatus.open
                    ? _C.warn
                    : (s == FeedbackStatus.resolved
                          ? _C.accent
                          : AppColors.primary),
                onTap: () => setState(
                  () => _statusFilter = _statusFilter == s ? null : s,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _ToggleChip(
              label: 'Any kind',
              selected: _kindFilter == null,
              onTap: () => setState(() => _kindFilter = null),
            ),
            for (final k in FeedbackKind.values)
              _ToggleChip(
                label: '${k.emoji} ${k.label} (${byKind[k]})',
                selected: _kindFilter == k,
                onTap: () =>
                    setState(() => _kindFilter = _kindFilter == k ? null : k),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SearchRow(
          hint: 'Search by message, name, or contact',
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        _Header2('Items (${filtered.length})'),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          _MutedPanel(
            text: entries.isEmpty
                ? 'No feedback yet. Surface a "Send feedback" entry in the '
                      'parent area or settings sheet to start collecting.'
                : 'Nothing matches your filter.',
          )
        else
          for (final e in filtered) _FeedbackRow(entry: e),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _exportDialog(BuildContext context, String json) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: const Text(
          'Feedback inbox (JSON)',
          style: TextStyle(color: _C.text),
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.canvas,
              borderRadius: BorderRadius.circular(2),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                json.isEmpty || json == '[]' ? '(empty)' : json,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: _C.text,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _FeedbackRow extends ConsumerWidget {
  const _FeedbackRow({required this.entry});
  final FeedbackEntry entry;

  Color _statusTone() {
    switch (entry.status) {
      case FeedbackStatus.open:
        return _C.warn;
      case FeedbackStatus.resolved:
        return _C.accent;
      case FeedbackStatus.archived:
        return _C.muted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts =
        '${entry.at.year}-${entry.at.month.toString().padLeft(2, '0')}-${entry.at.day.toString().padLeft(2, '0')} '
        '${entry.at.hour.toString().padLeft(2, '0')}:${entry.at.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(
                label: '${entry.kind.emoji} ${entry.kind.label}',
                tone: AppColors.primary,
              ),
              const SizedBox(width: 6),
              _Tag(label: entry.status.name, tone: _statusTone()),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${entry.from.isEmpty ? "(anon)" : entry.from} · $ts'
                  '${entry.context.isEmpty ? '' : '  ·  ${entry.context}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            entry.message,
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.text,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (entry.contact.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Contact: ${entry.contact}',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                color: _C.muted,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            children: [
              TextButton.icon(
                icon: const Icon(
                  Icons.share_outlined,
                  size: 14,
                  color: _C.accent,
                ),
                label: const Text(
                  'Forward',
                  style: TextStyle(color: _C.accent),
                ),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    subject:
                        '[Aziz Academy] ${entry.kind.label} from '
                        '${entry.from.isEmpty ? "anon" : entry.from}',
                    text: _formatEmailBody(entry),
                  ),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 14, color: _C.muted),
                label: const Text('Copy', style: TextStyle(color: _C.muted)),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: _formatEmailBody(entry)),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: _C.card,
                        content: const Text(
                          'Copied feedback to clipboard.',
                          style: TextStyle(color: _C.text),
                        ),
                      ),
                    );
                  }
                },
              ),
              if (entry.status != FeedbackStatus.resolved)
                TextButton.icon(
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: _C.accent,
                  ),
                  label: const Text(
                    'Resolve',
                    style: TextStyle(color: _C.accent),
                  ),
                  onPressed: () => ref
                      .read(feedbackInboxProvider.notifier)
                      .setStatus(entry.id, FeedbackStatus.resolved),
                ),
              if (entry.status != FeedbackStatus.archived)
                TextButton.icon(
                  icon: const Icon(
                    Icons.archive_outlined,
                    size: 14,
                    color: _C.muted,
                  ),
                  label: const Text(
                    'Archive',
                    style: TextStyle(color: _C.muted),
                  ),
                  onPressed: () => ref
                      .read(feedbackInboxProvider.notifier)
                      .setStatus(entry.id, FeedbackStatus.archived),
                ),
              TextButton.icon(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 14,
                  color: _C.danger,
                ),
                label: const Text('Delete', style: TextStyle(color: _C.danger)),
                onPressed: () =>
                    ref.read(feedbackInboxProvider.notifier).remove(entry.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section: Audit Report
// =============================================================================

class _AuditSection extends ConsumerWidget {
  const _AuditSection({required this.onJumpToSection});
  final ValueChanged<_Section> onJumpToSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditReportProvider);
    return async.when(
      loading: () => const _LoadingPanel(label: 'Running audit…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (rep) => _render(context, ref, rep),
    );
  }

  Widget _render(BuildContext context, WidgetRef ref, AuditReport rep) {
    final byArea = rep.byArea();
    final score = rep.healthScore;
    final scoreColor = score >= 90
        ? _C.accent
        : score >= 70
        ? _C.warn
        : _C.danger;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scoreColor.withAlpha(30),
                    border: Border.all(color: scoreColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: scoreColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health score',
                        style: TextStyle(
                          fontFamily: _C.font,
                          color: _C.muted,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        score >= 90
                            ? 'Looks healthy'
                            : score >= 70
                            ? 'Needs attention'
                            : 'Action required',
                        style: TextStyle(
                          fontFamily: _C.font,
                          color: scoreColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Tag(
                            label:
                                'Critical ${rep.countOf(AuditSeverity.critical)}',
                            tone: _C.danger,
                          ),
                          _Tag(
                            label: 'High ${rep.countOf(AuditSeverity.high)}',
                            tone: _C.danger,
                          ),
                          _Tag(
                            label:
                                'Medium ${rep.countOf(AuditSeverity.medium)}',
                            tone: _C.warn,
                          ),
                          _Tag(
                            label: 'Low ${rep.countOf(AuditSeverity.low)}',
                            tone: AppColors.primary,
                          ),
                          _Tag(
                            label: 'OK ${rep.countOf(AuditSeverity.ok)}',
                            tone: _C.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Copy markdown',
                  icon: const Icon(Icons.description_outlined, color: _C.muted),
                  onPressed: () async {
                    final md = rep.toMarkdown();
                    await Clipboard.setData(ClipboardData(text: md));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: _C.card,
                          content: const Text(
                            'Audit report copied as markdown.',
                            style: TextStyle(color: _C.text),
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Re-run',
                  icon: const Icon(Icons.refresh_rounded, color: _C.muted),
                  onPressed: () {
                    ref.invalidate(auditReportProvider);
                    // Re-read history after the new snapshot lands.
                    Future.delayed(
                      const Duration(milliseconds: 100),
                      () => ref.invalidate(auditHistoryProvider),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Generated ${rep.generatedAt.toIso8601String()}',
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            color: _C.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 16),
        const _AuditTrendStrip(),
        const SizedBox(height: 20),
        for (final entry in byArea.entries) ...[
          _Header2(entry.key.label),
          const SizedBox(height: 8),
          for (final f in entry.value)
            _AuditRow(
              finding: f,
              onJumpTo: () => onJumpToSection(_sectionForAuditFinding(f)),
            ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.finding, this.onJumpTo});
  final AuditFinding finding;
  final VoidCallback? onJumpTo;

  Color _toneColor() {
    switch (finding.severity) {
      case AuditSeverity.critical:
      case AuditSeverity.high:
        return _C.danger;
      case AuditSeverity.medium:
        return _C.warn;
      case AuditSeverity.low:
        return AppColors.primary;
      case AuditSeverity.info:
        return _C.muted;
      case AuditSeverity.ok:
        return _C.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: tone.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(label: finding.severity.name.toUpperCase(), tone: tone),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  finding.title,
                  style: const TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Kv(label: 'Evidence', value: finding.evidence),
          _Kv(label: 'Recommendation', value: finding.recommendation),
          if (onJumpTo != null && finding.severity != AuditSeverity.ok) ...[
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: tone,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text(
                  'Open relevant tab',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: onJumpTo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Section: Privacy & Data
// =============================================================================

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(qBankProvider);
    return async.when(
      loading: () => const _LoadingPanel(label: 'Loading…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (snap) => _render(snap),
    );
  }

  Widget _render(QBankSnapshot snap) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Data flow'),
        const SizedBox(height: 8),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(label: 'NO BACKEND', tone: _C.accent),
                    const SizedBox(width: 8),
                    const Text(
                      '100% on-device storage',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: _C.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Kv(
                  label: 'Storage',
                  value:
                      'SharedPreferences (browser localStorage on web). '
                      'No IndexedDB, no SQLite, no remote DB.',
                ),
                _Kv(
                  label: 'Network calls',
                  value:
                      'Bundled assets + 1 first-party endpoint: '
                      '/_vercel/insights for analytics + speed metrics. '
                      'No third-party domains contacted.',
                ),
                _Kv(
                  label: 'Cookies',
                  value:
                      'None set by app code. Vercel Web Analytics is '
                      'cookieless by design — no tracking cookies.',
                ),
                _Kv(
                  label: 'Third-party scripts',
                  value:
                      'Vercel Insights (privacy-first, GDPR-clean). '
                      'No Google, Meta, or ad-tech.',
                ),
                _Kv(
                  label: 'PII collected',
                  value: 'None. Optional kid name (free-text, never sent).',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Header2('Compliance posture'),
        const SizedBox(height: 8),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Kv(
                  label: 'COPPA',
                  value:
                      'Friendly stance — no PII, no tracking, no ads. '
                      'Document this in /privacy and the app store listing.',
                ),
                _Kv(
                  label: 'GDPR',
                  value:
                      'Friendly — local-only data; no consent banner '
                      'needed unless you add a third-party SDK.',
                ),
                _Kv(
                  label: 'Data deletion',
                  value:
                      'Available: Tools → Wipe ALL local storage. Add a '
                      'kid-facing "Forget me" button in /privacy.',
                ),
                _Kv(
                  label: 'Export',
                  value:
                      'Available: Settings → Export progress (JSON). Good '
                      'for portability.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _Header2('Bundled content footprint'),
        const SizedBox(height: 8),
        _StatGrid(
          stats: [
            _Stat(
              'Q Bank size',
              '${(snap.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            _Stat('Pools', '${snap.pools.length}'),
            _Stat('Questions', '${snap.totalQuestions}'),
          ],
        ),
        const SizedBox(height: 20),
        _Header2('Architectural position'),
        const SizedBox(height: 8),
        _Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(label: 'INTENTIONAL', tone: _C.accent),
                    const SizedBox(width: 8),
                    const Text(
                      'No Postgres, no Metabase, no PostHog — by design',
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'This admin is a self-audit console for an on-device app, '
                  'not a business-metrics dashboard. The standard stack '
                  '(Postgres + Metabase / Retool + PostHog) requires a backend '
                  'and a user-events table — both would break the "no backend, '
                  'no third-party SDKs, no tracking" line that ships in the '
                  'app\'s meta description, manifest.json, and JSON-LD.',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cross-device numbers come from Vercel Web Analytics — '
                  'cookieless, no SDK in the bundle, just a single defer-loaded '
                  'script. That stays. Anything else (Sentry, PostHog, '
                  'Mixpanel) requires re-auditing this section first.',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _Header2('Recommendations'),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            children: const [
              ListTile(
                dense: true,
                leading: Icon(Icons.tag_rounded, size: 16, color: _C.accent),
                title: Text(
                  'Publish a /privacy page in plain language',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  'You already have one — confirm it lists "no PII, no tracking".',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                  ),
                ),
              ),
              Divider(height: 1, color: _C.border),
              ListTile(
                dense: true,
                leading: Icon(Icons.tag_rounded, size: 16, color: _C.accent),
                title: Text(
                  'Add a kid-friendly "Erase my progress" button',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  'Currently behind admin Tools — that\'s right for parents '
                  'but a child-accessible reset is a nice trust signal.',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                  ),
                ),
              ),
              Divider(height: 1, color: _C.border),
              ListTile(
                dense: true,
                leading: Icon(Icons.tag_rounded, size: 16, color: _C.accent),
                title: Text(
                  'Re-audit when adding any third-party SDK',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 12,
                  ),
                ),
                subtitle: Text(
                  'Vercel Analytics, Sentry, Formspree — each one changes '
                  'the privacy story. Update /privacy + this section.',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Section: Q Bank
// =============================================================================

class _QBankSection extends ConsumerStatefulWidget {
  const _QBankSection();

  @override
  ConsumerState<_QBankSection> createState() => _QBankSectionState();
}

class _QBankSectionState extends ConsumerState<_QBankSection> {
  String _query = '';
  _PoolSort _sort = _PoolSort.size;
  bool _issuesOnly = false;

  @override
  Widget build(BuildContext context) {
    final asyncSnap = ref.watch(qBankProvider);
    return asyncSnap.when(
      loading: () => const _LoadingPanel(label: 'Loading 250 question pools…'),
      error: (e, _) => _ErrorPanel(message: 'Q Bank failed: $e'),
      data: _render,
    );
  }

  Widget _render(QBankSnapshot snap) {
    final pools = _filterPools(snap);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Totals'),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Pools', '${snap.pools.length}'),
            _Stat('Questions', '${snap.totalQuestions}'),
            _Stat(
              'Bilingual',
              '${(snap.bilingualRatio * 100).toStringAsFixed(1)}%',
            ),
            _Stat('Missing AR', '${snap.totalMissingAr}'),
            _Stat('Duplicate IDs', '${snap.totalDuplicateIds}'),
            _Stat(
              'Total size',
              '${(snap.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            _Stat('Pool errors', '${snap.poolsWithErrors}'),
            _Stat('Items indexed', '${snap.allItems.length}'),
          ],
        ),
        const SizedBox(height: 20),
        _SearchRow(
          hint: 'Search pools or questions',
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final s in _PoolSort.values)
              _ToggleChip(
                label: 'Sort: ${s.name}',
                selected: _sort == s,
                onTap: () => setState(() => _sort = s),
              ),
            _ToggleChip(
              label: 'Issues only',
              selected: _issuesOnly,
              tone: _C.danger,
              onTap: () => setState(() => _issuesOnly = !_issuesOnly),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_query.isNotEmpty) ...[
          _Header2('Question matches'),
          const SizedBox(height: 8),
          _QuestionMatches(snap: snap, query: _query),
          const SizedBox(height: 24),
        ],
        _Header2('Pools (${pools.length})'),
        const SizedBox(height: 8),
        for (final p in pools) ...[
          _PoolCard(pool: p),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  List<QBankPoolStats> _filterPools(QBankSnapshot snap) {
    Iterable<QBankPoolStats> base = snap.pools;
    if (_issuesOnly) {
      base = base.where(
        (p) =>
            p.parseError != null ||
            p.missingArCount > 0 ||
            p.duplicateIdCount > 0,
      );
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      base = base.where((p) => p.poolId.toLowerCase().contains(q));
    }
    final list = base.toList();
    switch (_sort) {
      case _PoolSort.size:
        list.sort((a, b) => b.byteSize.compareTo(a.byteSize));
        break;
      case _PoolSort.count:
        list.sort((a, b) => b.totalCount.compareTo(a.totalCount));
        break;
      case _PoolSort.coverage:
        list.sort((a, b) => a.bilingualRatio.compareTo(b.bilingualRatio));
        break;
      case _PoolSort.alpha:
        list.sort((a, b) => a.poolId.compareTo(b.poolId));
        break;
    }
    return list;
  }
}

enum _PoolSort { size, count, coverage, alpha }

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.pool});
  final QBankPoolStats pool;

  @override
  Widget build(BuildContext context) {
    final hasError = pool.parseError != null;
    final hasIssues =
        hasError || pool.missingArCount > 0 || pool.duplicateIdCount > 0;
    final tone = hasError ? _Tone.err : (hasIssues ? _Tone.warn : _Tone.ok);
    return _Card(
      borderTone: tone,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        childrenPadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: _C.muted,
        collapsedIconColor: _C.muted,
        title: Row(
          children: [
            _Dot(tone: tone),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pool.poolId,
                style: const TextStyle(
                  fontFamily: _C.font,
                  color: _C.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _MutedText('${pool.totalCount} Q', size: 11),
            const SizedBox(width: 14),
            _MutedText(
              '${(pool.bilingualRatio * 100).toStringAsFixed(0)}% AR',
              size: 11,
            ),
            const SizedBox(width: 14),
            _MutedText(
              '${(pool.byteSize / 1024).toStringAsFixed(0)} KB',
              size: 11,
            ),
          ],
        ),
        subtitle: hasError
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  pool.parseError!,
                  style: const TextStyle(
                    fontFamily: _C.font,
                    color: _C.danger,
                    fontSize: 11,
                  ),
                ),
              )
            : null,
        children: [
          const Divider(height: 1, color: _C.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Kv(label: 'Asset', value: pool.assetPath, mono: true),
                _Kv(
                  label: 'Bilingual / total',
                  value: '${pool.bilingualCount} / ${pool.totalCount}',
                ),
                _Kv(
                  label: 'Missing Arabic',
                  value: '${pool.missingArCount}',
                  tone: pool.missingArCount > 0 ? _Tone.warn : null,
                ),
                _Kv(
                  label: 'Duplicate IDs',
                  value: '${pool.duplicateIdCount}',
                  tone: pool.duplicateIdCount > 0 ? _Tone.err : null,
                ),
                _Kv(
                  label: 'Difficulty',
                  value: pool.difficultyHistogram.isEmpty
                      ? '—'
                      : (pool.difficultyHistogram.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key)))
                            .map((e) => 'd${e.key}=${e.value}')
                            .join(' · '),
                ),
                if (pool.categoryCounts.isNotEmpty)
                  _Kv(
                    label: 'Top categories',
                    value:
                        (pool.categoryCounts.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                            .take(4)
                            .map((e) => '${e.key} (${e.value})')
                            .join(' · '),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionMatches extends StatelessWidget {
  const _QuestionMatches({required this.snap, required this.query});
  final QBankSnapshot snap;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.toLowerCase();
    final hits = snap.allItems
        .where(
          (it) =>
              it.primaryEn.toLowerCase().contains(q) ||
              it.primaryAr.contains(query) ||
              it.id.toLowerCase().contains(q) ||
              it.category.toLowerCase().contains(q),
        )
        .take(40)
        .toList();
    if (hits.isEmpty) {
      return _MutedPanel(text: 'No matching questions.');
    }
    return _Card(
      child: Column(
        children: [
          for (var i = 0; i < hits.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: _C.border),
            ListTile(
              dense: true,
              leading: hits[i].isFullyBilingual
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: _C.accent,
                    )
                  : const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: _C.warn,
                    ),
              title: Text(
                hits[i].primaryEn.isNotEmpty ? hits[i].primaryEn : '(no EN)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: _C.font,
                  color: _C.text,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '${hits[i].poolId}  ·  ${hits[i].id}'
                '${hits[i].category.isNotEmpty ? '  ·  ${hits[i].category}' : ''}'
                '${hits[i].difficulty != null ? '  ·  d${hits[i].difficulty}' : ''}',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  color: _C.muted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          if (hits.length >= 40)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Showing first 40 — narrow your search to see more',
                style: TextStyle(
                  fontFamily: _C.font,
                  color: _C.muted,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section: Lint
// =============================================================================

class _LintSection extends ConsumerStatefulWidget {
  const _LintSection({required this.onJumpTranslate});
  final ValueChanged<String> onJumpTranslate;

  @override
  ConsumerState<_LintSection> createState() => _LintSectionState();
}

class _LintSectionState extends ConsumerState<_LintSection> {
  LintSeverity? _filter;
  String? _codeFilter;
  String _query = '';
  bool _groupByPool = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(lintReportProvider);
    return async.when(
      loading: () =>
          const _LoadingPanel(label: 'Running lint over every pool…'),
      error: (e, _) => _ErrorPanel(message: 'Lint failed: $e'),
      data: (rep) => _renderReport(rep),
    );
  }

  Widget _renderReport(LintReport rep) {
    final issues = rep.issues
        .where(
          (i) =>
              (_filter == null || i.severity == _filter) &&
              (_codeFilter == null || i.code == _codeFilter) &&
              (_query.isEmpty ||
                  i.poolId.toLowerCase().contains(_query.toLowerCase()) ||
                  i.questionId.toLowerCase().contains(_query.toLowerCase()) ||
                  i.message.toLowerCase().contains(_query.toLowerCase()) ||
                  i.code.toLowerCase().contains(_query.toLowerCase())),
        )
        .toList();

    // Top codes by count (the prevailing offenders) so the operator can fix
    // a whole class of issue with one filter click.
    final byCode = <String, int>{};
    for (final i in rep.issues) {
      byCode[i.code] = (byCode[i.code] ?? 0) + 1;
    }
    final topCodes = byCode.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _Header2('Lint summary'),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(
                Icons.download_rounded,
                size: 14,
                color: _C.muted,
              ),
              label: const Text(
                'Export JSON',
                style: TextStyle(color: _C.muted),
              ),
              onPressed: () => _exportDialog(context, rep.exportJson()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Errors', '${rep.errors}'),
            _Stat('Warnings', '${rep.warnings}'),
            _Stat('Infos', '${rep.infos}'),
            _Stat('Items checked', '${rep.totalChecked}'),
            _Stat('Elapsed', '${rep.elapsed.inMilliseconds} ms'),
            _Stat('Pools w/ issues', '${rep.byPool().length}'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ToggleChip(
              label: 'All',
              selected: _filter == null,
              onTap: () => setState(() => _filter = null),
            ),
            _ToggleChip(
              label: 'Errors (${rep.errors})',
              selected: _filter == LintSeverity.error,
              tone: _C.danger,
              onTap: () => setState(() => _filter = LintSeverity.error),
            ),
            _ToggleChip(
              label: 'Warnings (${rep.warnings})',
              selected: _filter == LintSeverity.warning,
              tone: _C.warn,
              onTap: () => setState(() => _filter = LintSeverity.warning),
            ),
            _ToggleChip(
              label: 'Infos (${rep.infos})',
              selected: _filter == LintSeverity.info,
              onTap: () => setState(() => _filter = LintSeverity.info),
            ),
            const SizedBox(width: 8),
            _ToggleChip(
              label: 'Group by pool',
              selected: _groupByPool,
              onTap: () => setState(() => _groupByPool = !_groupByPool),
            ),
          ],
        ),
        if (topCodes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Header2('Top rules'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ToggleChip(
                label: 'any rule',
                selected: _codeFilter == null,
                onTap: () => setState(() => _codeFilter = null),
              ),
              for (final c in topCodes.take(10))
                _ToggleChip(
                  label: '${c.key} (${c.value})',
                  selected: _codeFilter == c.key,
                  onTap: () => setState(
                    () => _codeFilter = _codeFilter == c.key ? null : c.key,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _SearchRow(
          hint: 'Filter by pool, id, code, or message',
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        _Header2('Issues (${issues.length})'),
        const SizedBox(height: 8),
        if (issues.isEmpty)
          _MutedPanel(text: 'No issues match your filter. 🎉')
        else if (_groupByPool)
          ..._renderGrouped(issues)
        else
          ..._renderFlat(issues),
        const SizedBox(height: 32),
      ],
    );
  }

  Iterable<Widget> _renderFlat(List<LintIssue> issues) sync* {
    for (final issue in issues.take(500)) {
      yield _LintRow(
        issue: issue,
        onJumpTranslate: _shouldOfferTranslate(issue)
            ? () => widget.onJumpTranslate(issue.questionId)
            : null,
      );
    }
    if (issues.length > 500) {
      yield Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Showing first 500 of ${issues.length}.',
          style: const TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
          ),
        ),
      );
    }
  }

  Iterable<Widget> _renderGrouped(List<LintIssue> issues) sync* {
    final byPool = <String, List<LintIssue>>{};
    for (final i in issues) {
      byPool.putIfAbsent(i.poolId, () => []).add(i);
    }
    final pools = byPool.keys.toList()
      ..sort((a, b) => byPool[b]!.length.compareTo(byPool[a]!.length));
    for (final pool in pools.take(60)) {
      final list = byPool[pool]!;
      final errs = list.where((i) => i.severity == LintSeverity.error).length;
      final warns = list
          .where((i) => i.severity == LintSeverity.warning)
          .length;
      yield Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          children: [
            _Tag(
              label: pool,
              tone: errs > 0
                  ? _C.danger
                  : (warns > 0 ? _C.warn : AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              '${list.length} issue${list.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
      for (final issue in list.take(40)) {
        yield _LintRow(
          issue: issue,
          onJumpTranslate: _shouldOfferTranslate(issue)
              ? () => widget.onJumpTranslate(issue.questionId)
              : null,
        );
      }
      if (list.length > 40) {
        yield Padding(
          padding: const EdgeInsets.only(left: 4, top: 2, bottom: 6),
          child: Text(
            '… ${list.length - 40} more in $pool',
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.muted,
              fontSize: 11,
            ),
          ),
        );
      }
    }
    if (pools.length > 60) {
      yield Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Showing first 60 of ${pools.length} pools.',
          style: const TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
          ),
        ),
      );
    }
  }

  bool _shouldOfferTranslate(LintIssue i) =>
      i.code == 'missing_ar_text' ||
      i.code == 'ar_equals_en' ||
      i.code == 'long_text_ar' ||
      i.code == 'correct_ar_not_in_options_ar' ||
      i.code == 'options_ar_length_mismatch';

  Future<void> _exportDialog(BuildContext context, String json) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: const Text(
          'Lint report (JSON)',
          style: TextStyle(color: _C.text),
        ),
        content: SizedBox(
          width: 700,
          height: 500,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.canvas,
              borderRadius: BorderRadius.circular(2),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                json,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: _C.text,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Copy all'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LintRow extends StatelessWidget {
  const _LintRow({required this.issue, this.onJumpTranslate});
  final LintIssue issue;
  final VoidCallback? onJumpTranslate;

  Color _toneColor() {
    switch (issue.severity) {
      case LintSeverity.error:
        return _C.danger;
      case LintSeverity.warning:
        return _C.warn;
      case LintSeverity.info:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 32,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Tag(label: issue.code, tone: tone),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${issue.poolId} · ${issue.questionId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue.message,
                    style: const TextStyle(
                      fontFamily: _C.font,
                      color: _C.text,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onJumpTranslate != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: _C.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.translate_rounded, size: 14),
                label: const Text(
                  'Fix in Translate',
                  style: TextStyle(fontSize: 11),
                ),
                onPressed: onJumpTranslate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section: Translate (workbench)
// =============================================================================

class _TranslateSection extends ConsumerStatefulWidget {
  const _TranslateSection({this.initialQuery, this.onQueryConsumed});
  final String? initialQuery;
  final VoidCallback? onQueryConsumed;

  @override
  ConsumerState<_TranslateSection> createState() => _TranslateSectionState();
}

class _TranslateSectionState extends ConsumerState<_TranslateSection> {
  String _query = '';
  String? _selectedPool;
  final Map<String, TextEditingController> _editors = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _query = widget.initialQuery!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onQueryConsumed?.call();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _editors.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _editorFor(QBankItem it) {
    return _editors.putIfAbsent(
      '${it.poolId}/${it.id}',
      () => TextEditingController(text: it.primaryAr),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSnap = ref.watch(qBankProvider);
    final asyncOverrides = ref.watch(overrideMapProvider);
    return asyncSnap.when(
      loading: () => const _LoadingPanel(label: 'Loading questions…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (snap) => _render(snap, asyncOverrides.value ?? const {}),
    );
  }

  Widget _render(QBankSnapshot snap, Map<String, QuestionOverride> overrides) {
    final missing = missingArItems(snap);
    final pools = (missing.map((e) => e.poolId).toSet().toList()..sort());
    final filtered = missing
        .where(
          (it) =>
              (_selectedPool == null || it.poolId == _selectedPool) &&
              (_query.isEmpty ||
                  it.primaryEn.toLowerCase().contains(_query.toLowerCase()) ||
                  it.id.toLowerCase().contains(_query.toLowerCase())),
        )
        .take(200)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Translation status'),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Missing AR (rows)', '${missing.length}'),
            _Stat('Affected pools', '${pools.length}'),
            _Stat(
              'Coverage',
              '${(snap.bilingualRatio * 100).toStringAsFixed(1)}%',
            ),
            _Stat('Saved overrides', '${overrides.length}'),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ToggleChip(
              label: 'All pools',
              selected: _selectedPool == null,
              onTap: () => setState(() => _selectedPool = null),
            ),
            for (final p in pools.take(20))
              _ToggleChip(
                label: p,
                selected: _selectedPool == p,
                onTap: () => setState(() => _selectedPool = p),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SearchRow(
          hint: 'Filter by EN text or id',
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Header2(
              'Workbench (${filtered.length}'
              '${missing.length > filtered.length ? ' of ${missing.length}' : ''})',
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Export overrides'),
              onPressed: () => _exportDialog(
                context,
                ref.read(overrideMapProvider.notifier).exportJson(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty) _MutedPanel(text: 'Nothing missing here. 🎉'),
        for (final it in filtered) _translationRow(it, overrides),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _translationRow(
    QBankItem it,
    Map<String, QuestionOverride> overrides,
  ) {
    final ctrl = _editorFor(it);
    final saved = overrides['${it.poolId}/${it.id}'];
    final savedAr = saved?.patch['question_ar'] as String?;
    if (savedAr != null && ctrl.text == it.primaryAr) {
      ctrl.text = savedAr;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Tag(label: it.poolId, tone: AppColors.primary),
              const SizedBox(width: 6),
              _Tag(label: it.id, tone: _C.muted),
              const Spacer(),
              if (saved != null) _Tag(label: 'override', tone: _C.accent),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            it.primaryEn,
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.text,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'الترجمة العربية…',
              hintStyle: const TextStyle(
                fontFamily: _C.font,
                color: _C.muted,
                fontSize: 12,
              ),
              filled: true,
              fillColor: _C.canvas,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: _C.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: _C.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: BorderSide(color: _C.accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (saved != null)
                TextButton.icon(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 14,
                    color: _C.danger,
                  ),
                  label: const Text(
                    'Drop override',
                    style: TextStyle(color: _C.danger),
                  ),
                  onPressed: () => ref
                      .read(overrideMapProvider.notifier)
                      .remove(it.poolId, it.id),
                ),
              const SizedBox(width: 4),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _C.accent,
                  foregroundColor: const Color(0xFF0A1628),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.save_outlined, size: 14),
                label: const Text('Save'),
                onPressed: () async {
                  final value = ctrl.text.trim();
                  if (value.isEmpty) return;
                  // Capture the messenger before the await so we don't reach
                  // for `context` after a possible unmount.
                  final messenger = ScaffoldMessenger.of(context);
                  await ref
                      .read(overrideMapProvider.notifier)
                      .upsert(
                        QuestionOverride(
                          poolId: it.poolId,
                          questionId: it.id,
                          patch: {'question_ar': value},
                          updatedAt: DateTime.now(),
                        ),
                      );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: _C.card,
                      content: Text(
                        'Saved override for ${it.id}',
                        style: const TextStyle(color: _C.text),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportDialog(BuildContext context, String json) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        title: const Text('Override patches', style: TextStyle(color: _C.text)),
        content: SizedBox(
          width: 600,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _C.canvas,
              borderRadius: BorderRadius.circular(2),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                json.isEmpty || json == '[]' ? '(no overrides yet)' : json,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: _C.text,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section: Catalog
// =============================================================================

class _CatalogSection extends StatelessWidget {
  const _CatalogSection();

  @override
  Widget build(BuildContext context) {
    final byCategory = <ActivityCategory, List<Activity>>{};
    for (final a in kActivities) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }
    final featuredCount = kActivities.where((a) => a.featured).length;
    final recapCount = kActivities.where((a) => a.recapModule != null).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Catalog inventory'),
        const SizedBox(height: 6),
        const Text(
          'Diagnostic listing of every entry in lib/features/home/'
          'activity_catalog.dart. Showing route, category, and flags. This is '
          'a data table — not a games library.',
          style: TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          stats: [
            _Stat('Total', '${kActivities.length}'),
            _Stat('Featured', '$featuredCount'),
            _Stat('Categories', '${byCategory.length}'),
            _Stat('Recap-linked', '$recapCount'),
          ],
        ),
        const SizedBox(height: 18),
        // Per-category data table — strict mono font, no kid emojis,
        // monochrome flags. Intentionally reads as a row in a CSV, not a
        // tile in the home grid.
        for (final entry in byCategory.entries) ...[
          _Header2(
            '${entry.key.labelEn().toUpperCase()} '
            '· ${entry.value.length}',
          ),
          const SizedBox(height: 6),
          _Card(
            child: Column(
              children: [
                // Column header row
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _C.border, width: 1),
                    ),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 40,
                        child: Text(
                          'FLAGS',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.muted,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ID',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.muted,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'ROUTE',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            color: _C.muted,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < entry.value.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _C.border),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Row(
                            children: [
                              Text(
                                entry.value[i].featured ? 'F' : '·',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  color: entry.value[i].featured
                                      ? _C.accent
                                      : _C.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.value[i].recapModule != null ? 'R' : '·',
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  color: entry.value[i].recapModule != null
                                      ? const Color(0xFF3FB950)
                                      : _C.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            entry.value[i].id,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              color: _C.text,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            entry.value[i].route,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              color: _C.muted,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open in new tab',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color: _C.muted,
                          ),
                          onPressed: () => context.push(entry.value[i].route),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        const SizedBox(height: 6),
        const Text(
          'F = featured · R = recap-linked',
          style: TextStyle(
            fontFamily: 'JetBrainsMono',
            color: _C.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Section: Assets
// =============================================================================

class _AssetsSection extends ConsumerStatefulWidget {
  const _AssetsSection();

  @override
  ConsumerState<_AssetsSection> createState() => _AssetsSectionState();
}

class _AssetsSectionState extends ConsumerState<_AssetsSection> {
  bool _fullScan = false;

  @override
  Widget build(BuildContext context) {
    final async = _fullScan
        ? ref.watch(assetInventoryFullProvider)
        : ref.watch(assetInventoryProvider);
    return async.when(
      loading: () => _LoadingPanel(
        label: _fullScan
            ? 'Probing every asset (slow)…'
            : 'Reading asset manifest…',
      ),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: _render,
    );
  }

  Widget _render(AssetInventory inv) {
    final biggest = inv.biggest(15);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _Header2('Bundle inventory'),
            const Spacer(),
            _ToggleChip(
              label: _fullScan ? 'Full sizes' : 'Quick (JSON only)',
              selected: _fullScan,
              onTap: () => setState(() => _fullScan = !_fullScan),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Quick mode reads question-pool JSON sizes (the bulk of weight) '
          'directly from rootBundle. Full mode probes every asset — slower '
          'but accurate for images / audio / fonts.',
          style: TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _StatGrid(
          stats: [
            _Stat('Total assets', '${inv.entries.length}'),
            _Stat(
              'Total size',
              '${(inv.totalBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            ),
            for (final k in AssetKind.values)
              if (inv.countOf(k) > 0)
                _Stat(
                  '${k.emoji} ${k.label}',
                  '${inv.countOf(k)} · ${(inv.sizeOf(k) / 1024).toStringAsFixed(0)} KB',
                ),
          ],
        ),
        const SizedBox(height: 24),
        _Header2('Biggest 15 files'),
        const SizedBox(height: 8),
        if (biggest.where((e) => e.bytes > 0).isEmpty)
          _MutedPanel(text: 'Sizes not probed yet — flip "Full sizes" to scan.')
        else
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < biggest.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _C.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          biggest[i].kind.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            biggest[i].path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              color: _C.text,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: Text(
                            biggest[i].bytes == 0
                                ? '—'
                                : '${(biggest[i].bytes / 1024).toStringAsFixed(1)} KB',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: _C.font,
                              color: _C.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 24),
        _Header2('Per-bucket counts'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in AssetKind.values)
              if (inv.countOf(k) > 0)
                _CountPill(
                  emoji: k.emoji,
                  label: k.label,
                  count: inv.countOf(k),
                ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// =============================================================================
// Section: Family
// =============================================================================

class _FamilySection extends ConsumerWidget {
  const _FamilySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(familyProfilesProvider);
    return async.when(
      loading: () => const _LoadingPanel(label: 'Loading profiles…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (state) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header2('Profiles on this device'),
            const SizedBox(height: 12),
            _StatGrid(
              stats: [
                _Stat('Profiles', '${state.slots.length}'),
                _Stat('Active slot', '#${state.activeSlotId}'),
                _Stat('Capacity', '4'),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              child: Column(
                children: [
                  for (var i = 0; i < state.slots.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: _C.border),
                    ListTile(
                      dense: true,
                      leading: Text(
                        state.slots[i].avatarEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Row(
                        children: [
                          Text(
                            state.slots[i].name.isEmpty
                                ? '(unnamed)'
                                : state.slots[i].name,
                            style: const TextStyle(
                              fontFamily: _C.font,
                              color: _C.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (state.slots[i].id == state.activeSlotId)
                            _Tag(label: 'active', tone: _C.accent),
                        ],
                      ),
                      subtitle: Text(
                        'slot #${state.slots[i].id} · age ${state.slots[i].ageBand}',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: _C.muted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: _C.muted,
                        ),
                        tooltip: 'Switch to this profile',
                        onPressed: () => ref
                            .read(familyProfilesProvider.notifier)
                            .switchTo(state.slots[i].id),
                      ),
                    ),
                  ],
                  if (state.slots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No profiles created yet. Add some in '
                        '/family.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _C.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ToolButton(
              icon: Icons.family_restroom_rounded,
              title: 'Open Family Profiles screen',
              subtitle: 'Edit, add, or remove profiles',
              onTap: () => context.push(AppRoutes.familyProfiles),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Section: Economy & Mood
// =============================================================================

class _EconomySection extends ConsumerWidget {
  const _EconomySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(coinProvider).value ?? 0;
    final achievement = ref.watch(achievementProvider).value;
    final xp = ref.watch(xpProvider).value?.totalXp ?? 0;
    final moodAsync = ref.watch(moodProvider);

    return moodAsync.when(
      loading: () => const _LoadingPanel(label: 'Loading mood data…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (mood) {
        // Build a 14-day mood strip from `entries`.
        final last14 = _last14Days();
        final byYmd = {for (final e in mood.entries) e.ymd: e.mood};
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header2('Coin economy'),
            const SizedBox(height: 12),
            _StatGrid(
              stats: [
                _Stat('Balance', '$coins 🪙'),
                _Stat('Visit streak', '${achievement?.streakCount ?? 0}'),
                _Stat('Badges', '${achievement?.unlockedBadges.length ?? 0}'),
                _Stat('XP', '$xp'),
              ],
            ),
            const SizedBox(height: 24),
            _Header2('Mood — last 14 days'),
            const SizedBox(height: 12),
            _Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final ymd in last14) ...[
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              byYmd[ymd]?.emoji ?? '·',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ymd.substring(8),
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                color: _C.muted,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (mood.today != null)
              _MutedPanel(text: "Today's mood: ${mood.today!.mood.emoji}"),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  List<String> _last14Days() {
    final today = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final out = <String>[];
    for (var i = 13; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      out.add('${d.year}-${two(d.month)}-${two(d.day)}');
    }
    return out;
  }
}

// =============================================================================
// Section: Storage
// =============================================================================

class _StorageSection extends ConsumerStatefulWidget {
  const _StorageSection();

  @override
  ConsumerState<_StorageSection> createState() => _StorageSectionState();
}

class _StorageSectionState extends ConsumerState<_StorageSection> {
  Map<String, _PrefValue>? _prefs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final keys = p.getKeys();
    final out = <String, _PrefValue>{};
    for (final k in keys) {
      final v = p.get(k);
      out[k] = _PrefValue.from(v);
    }
    if (!mounted) return;
    setState(() => _prefs = out);
  }

  Future<void> _deleteKey(String key) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(key);
    await _loadPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = _prefs;
    if (prefs == null) {
      return const _LoadingPanel(label: 'Reading storage…');
    }
    final entries =
        prefs.entries
            .where(
              (e) =>
                  _query.isEmpty ||
                  e.key.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    final totalBytes = prefs.values.fold<int>(0, (a, b) => a + b.approxBytes);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('SharedPreferences'),
        const SizedBox(height: 12),
        _StatGrid(
          stats: [
            _Stat('Keys', '${prefs.length}'),
            _Stat(
              'Approx size',
              '${(totalBytes / 1024).toStringAsFixed(1)} KB',
            ),
            _Stat('Showing', '${entries.length}'),
          ],
        ),
        const SizedBox(height: 12),
        _SearchRow(
          hint: 'Filter keys',
          query: _query,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: _C.border),
                ExpansionTile(
                  iconColor: _C.muted,
                  collapsedIconColor: _C.muted,
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    entries[i].key,
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: _C.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${entries[i].value.type}  ·  '
                    '${entries[i].value.approxBytes} B'
                    '${entries[i].value.preview.isEmpty ? '' : '  ·  ${entries[i].value.preview}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _C.font,
                      color: _C.muted,
                      fontSize: 11,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _C.canvas,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: _C.border),
                            ),
                            child: SelectableText(
                              entries[i].value.full,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 11,
                                color: _C.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: _C.danger,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                ),
                                label: const Text('Delete key'),
                                onPressed: () => _deleteKey(entries[i].key),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _PrefValue {
  const _PrefValue({
    required this.type,
    required this.approxBytes,
    required this.preview,
    required this.full,
  });

  factory _PrefValue.from(Object? v) {
    if (v == null) {
      return const _PrefValue(
        type: 'null',
        approxBytes: 0,
        preview: '(null)',
        full: 'null',
      );
    }
    final s = v.toString();
    final preview = s.length > 70 ? '${s.substring(0, 67)}…' : s;
    return _PrefValue(
      type: v.runtimeType.toString(),
      approxBytes: s.length,
      preview: preview,
      full: s,
    );
  }

  final String type;
  final int approxBytes;
  final String preview;
  final String full;
}

// =============================================================================
// Section: Errors
// =============================================================================

class _ErrorsSection extends StatelessWidget {
  const _ErrorsSection();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdminErrorLog.revision,
      builder: (context, _, child) => _renderList(),
    );
  }

  Widget _renderList() {
    final entries = AdminErrorLog.entries;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _Header2('In-memory error log'),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                size: 16,
                color: _C.muted,
              ),
              label: const Text('Clear', style: TextStyle(color: _C.muted)),
              onPressed: AdminErrorLog.clear,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'The last 200 framework errors captured by FlutterError.onError. '
          'Most recent 50 persist across reloads via SharedPreferences. For '
          'cross-device aggregation, layer in Sentry / Crashlytics.',
          style: const TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          _MutedPanel(text: 'No errors captured. Looking healthy. ✅')
        else
          for (final e in entries) _ErrorRow(entry: e),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ErrorRow extends StatefulWidget {
  const _ErrorRow({required this.entry});
  final AdminLogEntry entry;

  @override
  State<_ErrorRow> createState() => _ErrorRowState();
}

class _ErrorRowState extends State<_ErrorRow> {
  bool _expanded = false;

  Color _toneColor() {
    switch (widget.entry.severity) {
      case AdminLogSeverity.error:
        return _C.danger;
      case AdminLogSeverity.warning:
        return _C.warn;
      case AdminLogSeverity.info:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _toneColor();
    final ymd = widget.entry.at;
    final stamp =
        '${ymd.hour.toString().padLeft(2, '0')}:${ymd.minute.toString().padLeft(2, '0')}:${ymd.second.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                _Tag(label: widget.entry.severity.name, tone: tone),
                const SizedBox(width: 8),
                _Tag(label: widget.entry.source, tone: _C.muted),
                const Spacer(),
                Text(
                  stamp,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              widget.entry.message,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.text,
                fontSize: 12,
              ),
            ),
            if (_expanded && widget.entry.stack.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.canvas,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _C.border),
                ),
                child: SelectableText(
                  widget.entry.stack,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Section: Feature flags
// =============================================================================

class _FlagsSection extends ConsumerWidget {
  const _FlagsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFlags = ref.watch(flagMapProvider);
    return asyncFlags.when(
      loading: () => const _LoadingPanel(label: 'Loading flags…'),
      error: (e, _) => _ErrorPanel(message: '$e'),
      data: (flags) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Header2('Activity feature flags'),
            const SizedBox(height: 8),
            Text(
              'Flip an activity off to hide it from Featured + the catalog '
              'on the next launch. Stored locally — no redeploy required.',
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _StatGrid(
              stats: [
                _Stat('Total activities', '${kActivities.length}'),
                _Stat(
                  'Disabled',
                  '${flags.values.where((v) => v == false).length}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (flags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: () =>
                      ref.read(flagMapProvider.notifier).clearAll(),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: _C.muted,
                  ),
                  label: const Text(
                    'Re-enable all',
                    style: TextStyle(color: _C.muted),
                  ),
                ),
              ),
            _Card(
              child: Column(
                children: [
                  for (var i = 0; i < kActivities.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: _C.border),
                    SwitchListTile(
                      dense: true,
                      activeThumbColor: _C.accent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      secondary: Text(
                        kActivities[i].emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(
                        kActivities[i].titleEn,
                        style: const TextStyle(
                          fontFamily: _C.font,
                          color: _C.text,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${kActivities[i].id}  ·  ${kActivities[i].route}',
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: _C.muted,
                          fontSize: 10,
                        ),
                      ),
                      value: flags[kActivities[i].id] != false,
                      onChanged: (v) => ref
                          .read(flagMapProvider.notifier)
                          .set(kActivities[i].id, v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Section: Tools
// =============================================================================

class _ToolsSection extends ConsumerWidget {
  const _ToolsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header2('Jump'),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.bar_chart_rounded,
          title: 'Open Stats screen',
          subtitle: 'Per-module progress, charts, accuracy',
          onTap: () => context.push(AppRoutes.stats),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.shield_moon_rounded,
          title: 'Open Parent area',
          subtitle: 'Reports, exports, family digest',
          onTap: () => context.push(AppRoutes.parent),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.science_outlined,
          title: 'Open Widget gallery',
          subtitle: 'Internal dev preview of components',
          onTap: () => context.push(AppRoutes.devGallery),
        ),
        const SizedBox(height: 24),
        _Header2('Maintenance'),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.cleaning_services_outlined,
          title: 'Compact recap queue',
          subtitle:
              'Drop entries that point to question IDs not present in any '
              'pool — the audit flags these as orphans.',
          onTap: () async {
            try {
              final qBank = await ref.read(qBankProvider.future);
              final recap = await ref.read(recapQueueProvider.future);
              final allItemIds = qBank.allItems.map((i) => i.id).toSet();
              final orphans = recap
                  .where(
                    (e) =>
                        e.questionId.isNotEmpty &&
                        !allItemIds.contains(e.questionId),
                  )
                  .toList();
              if (orphans.isEmpty) {
                if (context.mounted) {
                  _toast(context, 'Recap queue is already clean.');
                }
                return;
              }
              await ref
                  .read(recapQueueProvider.notifier)
                  .removeEntries(orphans);
              if (context.mounted) {
                _toast(
                  context,
                  'Dropped ${orphans.length} orphan recap entries.',
                );
              }
            } catch (e) {
              if (context.mounted) _toast(context, 'Failed: $e');
            }
          },
        ),
        const SizedBox(height: 24),
        _Header2('Reset'),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.delete_outline_rounded,
          title: 'Reset learner state',
          subtitle: 'Clears EMAs, sessions, errors. Local only.',
          destructive: true,
          onTap: () => _confirm(
            context,
            'Reset learner state?',
            'Wipes recent sessions, skill data, and error history on this '
                'device. Coins, badges, and saved progress are kept.',
            () async {
              await ref.read(learnerStateProvider.notifier).reset();
              if (context.mounted) _toast(context, 'Cleared.');
            },
          ),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.delete_forever_rounded,
          title: 'Drop all override patches',
          subtitle: 'Removes every translation/edit override',
          destructive: true,
          onTap: () => _confirm(
            context,
            'Drop all overrides?',
            'Removes every saved translation patch on this device. The '
                'underlying JSON files are untouched.',
            () async {
              await ref.read(overrideMapProvider.notifier).clearAll();
              if (context.mounted) {
                _toast(context, 'Overrides cleared.');
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.cleaning_services_rounded,
          title: 'Wipe ALL local storage',
          subtitle: 'Every key — coins, streaks, progress, admin session',
          destructive: true,
          onTap: () => _confirm(
            context,
            'Wipe all local data?',
            'EVERY key on this device is deleted. The app resets to a '
                'first-launch state.',
            () async {
              final p = await SharedPreferences.getInstance();
              await p.clear();
              if (context.mounted) {
                _toast(context, 'All keys cleared. Restart the app.');
                context.go(AppRoutes.home);
              }
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String title,
    String body,
    Future<void> Function() action,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.card,
        titleTextStyle: const TextStyle(
          fontFamily: _C.font,
          color: _C.text,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: _C.font,
          color: _C.muted,
          fontSize: 13,
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _C.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await action();
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _C.card,
        content: Text(msg, style: const TextStyle(color: _C.text)),
      ),
    );
  }
}

// =============================================================================
// Reusable widgets
// =============================================================================

enum _Tone { ok, warn, err, muted }

class _Header2 extends StatelessWidget {
  const _Header2(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: _C.font,
        color: _C.text,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text, {this.size = 12});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontFamily: _C.font, color: _C.muted, fontSize: size),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.borderTone});
  final Widget child;
  final _Tone? borderTone;

  Color _border() {
    switch (borderTone) {
      case _Tone.ok:
        return _C.accent.withAlpha(80);
      case _Tone.warn:
        return _C.warn.withAlpha(110);
      case _Tone.err:
        return _C.danger.withAlpha(160);
      case _Tone.muted:
      case null:
        return _C.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _border()),
      ),
      child: child,
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cols = w >= 1100
        ? 4
        : w >= 800
        ? 3
        : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: cols,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (final s in stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _C.card,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: _C.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.label,
                  style: const TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 10,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  s.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: _C.font,
                    color: _C.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.tone,
    required this.label,
    required this.value,
  });
  final _Tone tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = _resolve(tone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: c.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Dot(tone: tone),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _C.font,
                  color: _C.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: _C.font,
              color: c,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Color _resolve(_Tone t) {
    switch (t) {
      case _Tone.ok:
        return _C.accent;
      case _Tone.warn:
        return _C.warn;
      case _Tone.err:
        return _C.danger;
      case _Tone.muted:
        return _C.muted;
    }
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.tone});
  final _Tone tone;
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _HealthCard._resolve(tone),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tone});
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withAlpha(28),
        border: Border.all(color: tone.withAlpha(110)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: _C.font,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: tone,
        ),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({
    required this.label,
    required this.value,
    this.tone,
    this.mono = false,
  });
  final String label;
  final String value;
  final _Tone? tone;
  final bool mono;

  Color _color() {
    switch (tone) {
      case _Tone.warn:
        return _C.warn;
      case _Tone.err:
        return _C.danger;
      case _Tone.ok:
        return _C.accent;
      case _Tone.muted:
      case null:
        return _C.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.muted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: mono ? 'JetBrainsMono' : 'Cairo',
                color: _color(),
                fontSize: mono ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.emoji,
    required this.label,
    required this.count,
  });
  final String emoji;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: _C.font,
              color: _C.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: _C.accent.withAlpha(40),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                color: _C.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatefulWidget {
  const _SearchRow({
    required this.hint,
    required this.query,
    required this.onChanged,
  });
  final String hint;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<_SearchRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(_SearchRow old) {
    super.didUpdateWidget(old);
    // Sync external query changes (e.g. seeded from a sibling section) into
    // the field without clobbering whatever the user is currently typing.
    if (widget.query != old.query && widget.query != _ctrl.text) {
      _ctrl.text = widget.query;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 17, color: _C.muted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChanged,
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.text,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontFamily: _C.font,
                  color: _C.muted,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (widget.query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: _C.muted),
              onPressed: () {
                _ctrl.clear();
                widget.onChanged('');
              },
            ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = tone ?? _C.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? c.withAlpha(40) : _C.card,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: selected ? c : _C.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: _C.font,
              color: selected ? c : _C.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillTable extends StatelessWidget {
  const _SkillTable({required this.learner});
  final LearnerState? learner;

  @override
  Widget build(BuildContext context) {
    if (learner == null || learner!.skillByModule.isEmpty) {
      return _MutedPanel(
        text:
            'No sessions logged yet. Skill data fills in once a quiz finishes.',
      );
    }
    final entries = learner!.skillByModule.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return _Card(
      child: Column(
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: _C.text,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          e.value < 0.45
                              ? _C.danger
                              : (e.value > 0.78 ? _C.accent : _C.warn),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${(e.value * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: _C.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({required this.learner});
  final LearnerState? learner;

  @override
  Widget build(BuildContext context) {
    if (learner == null || learner!.recentSessions.isEmpty) {
      return _MutedPanel(text: 'No recent sessions yet.');
    }
    final list = learner!.recentSessions.take(10).toList();
    return _Card(
      child: Column(
        children: [
          for (final s in list)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      s.module,
                      style: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        color: _C.text,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${s.score}/${s.total}',
                      style: const TextStyle(
                        fontFamily: _C.font,
                        color: _C.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    fmtAgo(s.endedAt),
                    style: const TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: _C.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? _C.danger : _C.accent;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: accent.withAlpha(70)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(35),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: _C.font,
                        color: destructive ? _C.danger : _C.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: _C.font,
                        color: _C.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: _C.accent),
        const SizedBox(height: 14),
        Text(
          label,
          style: const TextStyle(
            fontFamily: _C.font,
            color: _C.muted,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _C.danger.withAlpha(120)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _C.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: _C.font,
                color: _C.text,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MutedPanel extends StatelessWidget {
  const _MutedPanel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(2),
      border: Border.all(color: _C.border),
    ),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: _C.font,
          color: _C.muted,
          fontSize: 12,
        ),
      ),
    ),
  );
}

/// Score-trend strip — last 14 audit snapshots as bars, colored by score.
/// Self-hides if no history yet. Reads from [auditHistoryProvider].
class _AuditTrendStrip extends ConsumerWidget {
  const _AuditTrendStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditHistoryProvider);
    final history = async.value ?? const [];
    if (history.length < 2) return const SizedBox.shrink();
    final tail = history.length > 14
        ? history.sublist(history.length - 14)
        : history;
    final delta = tail.last.score - tail.first.score;
    final deltaColor = delta == 0
        ? _C.muted
        : (delta > 0 ? _C.accent : _C.danger);
    final deltaSymbol = delta == 0 ? '·' : (delta > 0 ? '↑' : '↓');
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Score trend (last 14 audits)',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: _C.muted,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '$deltaSymbol ${delta.abs()}',
                  style: TextStyle(
                    fontFamily: _C.font,
                    color: deltaColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final s in tail)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Container(
                          height: (s.score.clamp(0, 100) / 100.0 * 44.0).clamp(
                            2,
                            44,
                          ),
                          decoration: BoxDecoration(
                            color: s.score >= 90
                                ? _C.accent
                                : (s.score >= 70 ? _C.warn : _C.danger),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${tail.first.score}',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  '${tail.last.score}',
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    color: _C.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Build a plain-text email body for forwarding a feedback entry. Format is
/// stable so it can be parsed back into a JSON shape if you later wire a
/// Vercel function or Formspree endpoint.
String _formatEmailBody(FeedbackEntry e) {
  final lines = <String>[
    'Aziz Academy — Feedback forwarded from admin console',
    '',
    'Kind:     ${e.kind.emoji} ${e.kind.label}',
    'Status:   ${e.status.name}',
    'When:     ${e.at.toIso8601String()}',
    'From:     ${e.from.isEmpty ? "(anon)" : e.from}',
    if (e.contact.isNotEmpty) 'Contact:  ${e.contact}',
    if (e.context.isNotEmpty) 'Context:  ${e.context}',
    'ID:       ${e.id}',
    '',
    '---',
    e.message,
    '---',
  ];
  return lines.join('\n');
}

/// "5m ago", "2h ago", "3d ago", or "—" for null. Shared across every
/// section that renders relative timestamps (Traffic, Engagement, Audit).
String fmtAgo(DateTime? at) {
  if (at == null) return '—';
  final d = DateTime.now().difference(at);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

/// "230ms" / "12.4s" / "1.8m" — duration formatter for the engagement table.
String fmtDuration(int ms) {
  if (ms < 1000) return '${ms}ms';
  final s = ms / 1000;
  if (s < 60) return '${s.toStringAsFixed(1)}s';
  return '${(s / 60).toStringAsFixed(1)}m';
}
