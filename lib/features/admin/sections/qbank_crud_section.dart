import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/qbank_drafts_provider.dart';
import 'package:aziz_academy/core/services/qbank_remote_service.dart';

// =============================================================================
// Q-Bank CRUD admin section
//
// Companion to lib/features/admin/q_bank_service.dart (read-only pool stats).
// This file is the WRITE side: add, edit, publish, archive, delete questions
// from inside the admin dashboard. Backed by Supabase via QBankRemoteService;
// changes appear live in the app after `ref.invalidate(publishedDraftsProvider)`
// or next app start.
//
// All UI here is gated by [isAdminProvider]. Non-admins see a "not authorised"
// card. The server-side RLS also blocks them — this is just the local
// hide-the-buttons layer.
//
// Drop this widget into the existing admin shell as a new section panel:
//
//   const QBankCrudSection()
//
// Or wire it into [_Section.qBank] in admin_dashboard_screen.dart when
// that file gets the Phase 1 split (see PROJECT_PLAN.md §1.1).
// =============================================================================

/// Top-level section widget. Renders the list + editor.
class QBankCrudSection extends ConsumerStatefulWidget {
  const QBankCrudSection({super.key});

  @override
  ConsumerState<QBankCrudSection> createState() => _QBankCrudSectionState();
}

class _QBankCrudSectionState extends ConsumerState<QBankCrudSection> {
  String? _selectedPoolId;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading: () => const _CenteredLoader(),
      error: (e, _) => _ErrorCard(message: 'Could not check admin status: $e'),
      data: (isAdmin) {
        if (!isAdmin) return const _NotAuthorisedCard();
        return _CrudUi(
          selectedPoolId: _selectedPoolId,
          filter: _filter,
          onSelectPool: (id) => setState(() => _selectedPoolId = id),
          onFilter: (q) => setState(() => _filter = q),
        );
      },
    );
  }
}

class _CrudUi extends ConsumerWidget {
  const _CrudUi({
    required this.selectedPoolId,
    required this.filter,
    required this.onSelectPool,
    required this.onFilter,
  });

  final String? selectedPoolId;
  final String filter;
  final ValueChanged<String?> onSelectPool;
  final ValueChanged<String> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(allDraftsForPoolProvider(selectedPoolId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — pool picker + new-question CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _PoolPicker(
                  current: selectedPoolId,
                  onChanged: onSelectPool,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openEditor(context, ref,
                    poolId: selectedPoolId, existing: null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New question'),
              ),
            ],
          ),
        ),
        // Filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: onFilter,
            decoration: const InputDecoration(
              hintText: 'Filter by id, question, or option…',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        // Draft list
        Expanded(
          child: draftsAsync.when(
            loading: () => const _CenteredLoader(),
            error: (e, _) =>
                _ErrorCard(message: 'Could not load drafts: $e'),
            data: (drafts) {
              final filtered = _filterDrafts(drafts, filter);
              if (filtered.isEmpty) {
                return const _EmptyState();
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(allDraftsForPoolProvider(selectedPoolId));
                  ref.invalidate(publishedDraftsProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (_, i) => _DraftRow(
                    draft: filtered[i],
                    onEdit: () => _openEditor(
                      context, ref,
                      poolId: filtered[i].poolId,
                      existing: filtered[i],
                    ),
                    onPublish: () => _setStatus(
                      context, ref, filtered[i], QBankDraftStatus.published),
                    onArchive: () => _setStatus(
                      context, ref, filtered[i], QBankDraftStatus.archived),
                    onDelete: () => _confirmDelete(context, ref, filtered[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<QBankDraft> _filterDrafts(List<QBankDraft> all, String q) {
    if (q.trim().isEmpty) return all;
    final needle = q.trim().toLowerCase();
    return all.where((d) {
      final p = d.payload;
      bool matches(Object? v) =>
          v is String && v.toLowerCase().contains(needle);
      if (d.id.toLowerCase().contains(needle)) return true;
      if (matches(p['question_en'])) return true;
      if (matches(p['question_ar'])) return true;
      if (p['options'] is List) {
        for (final o in p['options'] as List) {
          if (matches(o)) return true;
        }
      }
      return false;
    }).toList();
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref,
      QBankDraft d, QBankDraftStatus status) async {
    final svc = ref.read(qBankRemoteServiceProvider);
    final res = await svc.upsertDraft(
      poolId: d.poolId,
      id: d.id,
      status: status,
      payload: d.payload,
    );
    if (!context.mounted) return;
    if (res.ok) {
      ref.invalidate(allDraftsForPoolProvider(selectedPoolId));
      ref.invalidate(publishedDraftsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Set to ${status.wire}'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${res.error}'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, QBankDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this draft?'),
        content: Text('${d.poolId} / ${d.id} — this cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final svc = ref.read(qBankRemoteServiceProvider);
    final res = await svc.deleteDraft(poolId: d.poolId, id: d.id);
    if (!context.mounted) return;
    if (res.ok) {
      ref.invalidate(allDraftsForPoolProvider(selectedPoolId));
      ref.invalidate(publishedDraftsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${res.error}'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String? poolId,
    required QBankDraft? existing,
  }) async {
    if (poolId == null && existing == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a pool first')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _QuestionEditorDialog(
        poolId: existing?.poolId ?? poolId!,
        existing: existing,
      ),
    );
    if (context.mounted) {
      ref.invalidate(allDraftsForPoolProvider(selectedPoolId));
      ref.invalidate(publishedDraftsProvider);
    }
  }
}

// =============================================================================
// Pool picker — loads pool ids from AssetManifest so the admin can target any
// of the 258 bundled pools.
// =============================================================================

class _PoolPicker extends StatefulWidget {
  const _PoolPicker({required this.current, required this.onChanged});
  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  State<_PoolPicker> createState() => _PoolPickerState();
}

class _PoolPickerState extends State<_PoolPicker> {
  List<String> _poolIds = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final ids = manifest.keys
          .where((k) => k.startsWith('assets/data/') && k.endsWith('.json'))
          .map((k) => k
              .replaceFirst('assets/data/', '')
              .replaceFirst(RegExp(r'\.json$'), ''))
          .toList()
        ..sort();
      if (mounted) {
        setState(() {
          _poolIds = ids;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 40, child: Center(child: LinearProgressIndicator()),
      );
    }
    return DropdownButtonFormField<String?>(
      initialValue: widget.current,
      decoration: const InputDecoration(
        labelText: 'Pool',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(
            value: null, child: Text('— All pools —')),
        for (final id in _poolIds)
          DropdownMenuItem<String?>(value: id, child: Text(id)),
      ],
      onChanged: widget.onChanged,
    );
  }
}

// =============================================================================
// One row in the draft list
// =============================================================================

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.draft,
    required this.onEdit,
    required this.onPublish,
    required this.onArchive,
    required this.onDelete,
  });

  final QBankDraft draft;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = draft.payload;
    final qEn = (p['question_en'] ?? p['name_en'] ?? p['question'] ?? '?') as String;
    final qAr = (p['question_ar'] ?? p['name_ar'] ?? '') as String;
    return ListTile(
      leading: _StatusChip(status: draft.status),
      title: Text(qEn, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (qAr.isNotEmpty)
            Text(qAr, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          Text('${draft.poolId} / ${draft.id}',
              style: TextStyle(
                fontSize: 11, color: Colors.grey.shade400, fontFamily: 'monospace')),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          switch (v) {
            case 'edit': onEdit(); break;
            case 'publish': onPublish(); break;
            case 'archive': onArchive(); break;
            case 'delete': onDelete(); break;
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'publish', child: Text('Publish')),
          PopupMenuItem(value: 'archive', child: Text('Archive')),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final QBankDraftStatus status;
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      QBankDraftStatus.draft => ('Draft', Colors.grey),
      QBankDraftStatus.review => ('Review', Colors.amber),
      QBankDraftStatus.published => ('Live', Colors.green),
      QBankDraftStatus.archived => ('Archived', Colors.blueGrey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// Editor dialog — add or modify a question
// =============================================================================

class _QuestionEditorDialog extends ConsumerStatefulWidget {
  const _QuestionEditorDialog({required this.poolId, this.existing});
  final String poolId;
  final QBankDraft? existing;

  @override
  ConsumerState<_QuestionEditorDialog> createState() =>
      _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends ConsumerState<_QuestionEditorDialog> {
  late final TextEditingController _id;
  late final TextEditingController _qEn;
  late final TextEditingController _qAr;
  late final List<TextEditingController> _opts;     // 4 EN
  late final List<TextEditingController> _optsAr;   // 4 AR
  late final TextEditingController _funEn;
  late final TextEditingController _funAr;
  int _difficulty = 1;
  QBankDraftStatus _status = QBankDraftStatus.draft;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing?.payload ?? const {};
    _id = TextEditingController(text: widget.existing?.id ?? '');
    _qEn = TextEditingController(text: (p['question_en'] ?? '') as String);
    _qAr = TextEditingController(text: (p['question_ar'] ?? '') as String);
    final opts = (p['options'] as List?)?.cast<String>() ?? <String>['', '', '', ''];
    _opts = List.generate(4, (i) =>
        TextEditingController(text: i < opts.length ? opts[i] : ''));
    final optsAr =
        (p['options_ar'] as List?)?.cast<String>() ?? <String>['', '', '', ''];
    _optsAr = List.generate(4, (i) =>
        TextEditingController(text: i < optsAr.length ? optsAr[i] : ''));
    _funEn = TextEditingController(text: (p['fun_fact_en'] ?? '') as String);
    _funAr = TextEditingController(text: (p['fun_fact_ar'] ?? '') as String);
    _difficulty = (p['difficulty'] as int?) ?? 1;
    _status = widget.existing?.status ?? QBankDraftStatus.draft;
  }

  @override
  void dispose() {
    _id.dispose();
    _qEn.dispose();
    _qAr.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    for (final c in _optsAr) {
      c.dispose();
    }
    _funEn.dispose();
    _funAr.dispose();
    super.dispose();
  }

  Map<String, dynamic> _build() {
    final payload = <String, dynamic>{
      'id': _id.text.trim(),
      'question_en': _qEn.text.trim(),
      'question_ar': _qAr.text.trim(),
      'options': _opts.map((c) => c.text.trim()).toList(),
      'correct_answer': _opts.first.text.trim(),
      'difficulty': _difficulty,
    };
    final allAr = _optsAr.every((c) => c.text.trim().isNotEmpty);
    if (allAr) {
      payload['options_ar'] = _optsAr.map((c) => c.text.trim()).toList();
      payload['correct_answer_ar'] = _optsAr.first.text.trim();
    }
    if (_funEn.text.trim().isNotEmpty) payload['fun_fact_en'] = _funEn.text.trim();
    if (_funAr.text.trim().isNotEmpty) payload['fun_fact_ar'] = _funAr.text.trim();
    return payload;
  }

  Future<void> _save() async {
    final payload = _build();
    final err = QBankRemoteService.validatePayload(payload);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final svc = ref.read(qBankRemoteServiceProvider);
    final res = await svc.upsertDraft(
      poolId: widget.poolId,
      id: _id.text.trim(),
      status: _status,
      payload: payload,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = res.error ?? 'unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New question' : 'Edit question'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Pool: ${widget.poolId}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _id,
                enabled: widget.existing == null,
                decoration: const InputDecoration(
                  labelText: 'id (unique within pool)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qEn,
                decoration: const InputDecoration(
                    labelText: 'Question (English)', isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _qAr,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                    labelText: 'Question (Arabic)', isDense: true),
              ),
              const SizedBox(height: 12),
              const Text('Options (first row is the correct answer)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              for (var i = 0; i < 4; i++) ...[
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _opts[i],
                      decoration: InputDecoration(
                          labelText: 'EN option ${i + 1}${i == 0 ? "  (correct)" : ""}',
                          isDense: true),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _optsAr[i],
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                          labelText: 'AR option ${i + 1}',
                          isDense: true),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Text('Difficulty'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _difficulty,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 — easy')),
                    DropdownMenuItem(value: 2, child: Text('2 — medium')),
                    DropdownMenuItem(value: 3, child: Text('3 — hard')),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v ?? 1),
                ),
                const SizedBox(width: 16),
                const Text('Status'),
                const SizedBox(width: 8),
                DropdownButton<QBankDraftStatus>(
                  value: _status,
                  items: const [
                    DropdownMenuItem(
                        value: QBankDraftStatus.draft, child: Text('draft')),
                    DropdownMenuItem(
                        value: QBankDraftStatus.review, child: Text('review')),
                    DropdownMenuItem(
                        value: QBankDraftStatus.published,
                        child: Text('published (live)')),
                  ],
                  onChanged: (v) => setState(
                      () => _status = v ?? QBankDraftStatus.draft),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _funEn,
                decoration: const InputDecoration(
                    labelText: 'Fun fact (English) — optional', isDense: true),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _funAr,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                    labelText: 'Fun fact (Arabic) — optional', isDense: true),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _busy ? null : _save,
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 16),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

// =============================================================================
// Small helper widgets
// =============================================================================

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.red.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message),
          ),
        ),
      );
}

class _NotAuthorisedCard extends StatelessWidget {
  const _NotAuthorisedCard();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 36),
                SizedBox(height: 12),
                Text('Not authorised',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  'You are not in the admin_users allowlist for this Supabase project. '
                  'Ask an existing admin to add your account.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No drafts in this scope yet.\nClick "New question" to add one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
}
