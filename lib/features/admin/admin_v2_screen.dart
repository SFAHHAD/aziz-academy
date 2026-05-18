import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/features/admin/admin_traffic.dart';
import 'package:aziz_academy/features/admin/admin_error_log.dart';
import 'package:aziz_academy/features/admin/admin_feedback.dart';
import 'package:aziz_academy/features/admin/q_bank_service.dart';
import 'package:aziz_academy/features/home/activity_catalog.dart';

void _navTo(BuildContext context, String route) {
  context.go(route);
}

// =============================================================================
// Admin v2 — a deliberately minimal, brutalist ops console.
//
// Why this exists: the user reports the existing /x9k2-admin-portal "looks
// the same as the kid app" even after a re-skin pass. Two possible causes:
//  1. The browser/service worker is caching the old build.
//  2. The redesign isn't visually different *enough*.
//
// This new screen, mounted at /console-v2, is built from scratch with NO
// shared widgets and NO theme inheritance — it's a clean canvas with raw
// Container + Text widgets, monospace, ASCII chrome. If you load this and it
// still "looks the same as kid app", we know it's a deploy/cache issue, not
// a design issue.
// =============================================================================

const _bg = Color(0xFF000000);
const _fg = Color(0xFFD4D4D4);
const _muted = Color(0xFF6E6E72);
const _accent = Color(0xFF3FB950);
const _danger = Color(0xFFF85149);
const _warn = Color(0xFFE8A85F);
const _border = Color(0xFF1F1F22);
const _font = 'JetBrainsMono';

class AdminV2Screen extends ConsumerStatefulWidget {
  const AdminV2Screen({super.key});

  @override
  ConsumerState<AdminV2Screen> createState() => _AdminV2ScreenState();
}

class _AdminV2ScreenState extends ConsumerState<AdminV2Screen> {
  TrafficSnapshot? _traffic;
  QBankSnapshot? _qbank;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final traffic = await AdminTraffic.snapshot();
      final qbank = await ref.read(qBankProvider.future);
      if (!mounted) return;
      setState(() {
        _traffic = traffic;
        _qbank = qbank;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 28),
              if (_loading) _line('loading...', _muted),
              if (_error != null) _line('error: $_error', _danger),
              if (!_loading && _error == null) ..._content(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const _Block(text: '▍', color: _accent),
        const SizedBox(width: 10),
        const Text(
          'aziz-academy / admin-v2',
          style: TextStyle(
            fontFamily: _font,
            color: _fg,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 10),
        const _Block(text: 'BETA', color: _warn),
        const Spacer(),
        TextButton(
          onPressed: () => _navTo(context, AppRoutes.home),
          child: const Text(
            '[ exit ]',
            style: TextStyle(fontFamily: _font, color: _muted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  List<Widget> _content() {
    final t = _traffic!;
    final q = _qbank!;
    final errLog = AdminErrorLog.entries;
    final criticalErrors = errLog
        .where((e) => e.severity == AdminLogSeverity.error)
        .length;
    final feedback = ref.read(feedbackInboxProvider).value ?? const [];
    final openFeedback = feedback
        .where((e) => e.status == FeedbackStatus.open)
        .length;
    final featuredCount = kActivities.where((a) => a.featured).length;

    return [
      _section('# system', [
        _kv('build', _commit()),
        _kv('runtime', 'flutter web'),
        _kv('storage', 'on-device · shared-preferences'),
        _kv('analytics', 'vercel insights · cookieless'),
      ]),
      _section('# traffic (this device)', [
        _kv('total opens', '${t.totalOpens}'),
        _kv('active days /7d', '${t.openDaysLast7}'),
        _kv('active days /30d', '${t.openDaysLast30}'),
        _kv('first open', t.firstOpenAt?.toIso8601String() ?? 'never'),
        _kv('last open', t.lastOpenAt?.toIso8601String() ?? 'never'),
      ]),
      _section('# q-bank', [
        _kv('pools loaded', '${q.pools.length}'),
        _kv(
          'pools w/ errors',
          '${q.poolsWithErrors}',
          color: q.poolsWithErrors > 0 ? _danger : _accent,
        ),
        _kv('total questions', '${q.totalQuestions}'),
        _kv(
          'bilingual ratio',
          '${(q.totalQuestions == 0 ? 0 : q.totalBilingual / q.totalQuestions * 100).toStringAsFixed(1)}%',
        ),
        _kv('missing AR', '${q.totalMissingAr}'),
        _kv('duplicate IDs', '${q.totalDuplicateIds}'),
        _kv(
          'total bytes',
          '${(q.totalBytes / 1024 / 1024).toStringAsFixed(2)} MB',
        ),
      ]),
      _section('# catalog', [
        _kv('activities', '${kActivities.length}'),
        _kv('featured flagged', '$featuredCount'),
      ]),
      _section('# operations', [
        _kv(
          'framework errors (session)',
          '$criticalErrors',
          color: criticalErrors > 0 ? _warn : _accent,
        ),
        _kv('feedback open', '$openFeedback'),
      ]),
      const SizedBox(height: 32),
      _line(
        '> if this view looks correct and /x9k2-admin-portal still looks like the kid app,',
        _muted,
      ),
      _line(
        '> the issue is browser/service-worker cache. ctrl+shift+r on that tab.',
        _muted,
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          _btn('reload data', () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _loadAll();
          }),
          const SizedBox(width: 8),
          _btn('open old admin', () {
            _navTo(context, AppRoutes.admin);
          }),
          const SizedBox(width: 8),
          _btn('back to home', () {
            _navTo(context, AppRoutes.home);
          }),
        ],
      ),
    ];
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: _font,
                  color: _accent,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: _border)),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _kv(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: _font,
                color: _muted,
                fontSize: 12,
              ),
            ),
          ),
          const Text(
            ' = ',
            style: TextStyle(fontFamily: _font, color: _border, fontSize: 12),
          ),
          Flexible(
            child: SelectableText(
              value,
              style: TextStyle(
                fontFamily: _font,
                color: color ?? _fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String text, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: TextStyle(fontFamily: _font, color: c, fontSize: 12),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _accent),
          ),
          child: Text(
            '[ $label ]',
            style: const TextStyle(
              fontFamily: _font,
              color: _accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _commit() =>
      const String.fromEnvironment('GIT_COMMIT', defaultValue: 'dev');
}

class _Block extends StatelessWidget {
  const _Block({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
