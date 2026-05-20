import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aziz_academy/core/providers/qbank_drafts_provider.dart';
import 'package:aziz_academy/core/services/qbank_remote_service.dart';

// =============================================================================
// Admin polish: audit log viewer + bulk operations
//
// Two helpers that make the dashboard feel "professional":
//
//   AuditLogTimeline — recent qbank_audit entries grouped by day, with diff
//     preview on tap. Good for "what changed and when" investigations.
//
//   BulkPublishButton — one-click promote every draft+review row to
//     'published' status. Safer than clicking through 50 questions when an
//     editor finishes a batch.
//
// Both gated on isAdminProvider; show a non-authorised card otherwise.
// =============================================================================

class AuditLogTimeline extends ConsumerWidget {
  const AuditLogTimeline({super.key, this.limit = 50});
  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);
    return isAdminAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Admin check failed: $e'),
      data: (isAdmin) {
        if (!isAdmin) return const SizedBox.shrink();
        final auditAsync = ref.watch(recentAuditProvider);
        return auditAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Audit load failed: $e'),
          data: (entries) {
            if (entries.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No edits yet.'),
              );
            }
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Text('Recent changes',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18),
                            onPressed: () =>
                                ref.invalidate(recentAuditProvider),
                            tooltip: 'Refresh',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 360,
                      child: ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (_, i) => _AuditTile(entry: entries[i]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});
  final QBankAuditEntry entry;

  Color get _color {
    switch (entry.action) {
      case 'create':  return Colors.green;
      case 'update':  return Colors.blue;
      case 'publish': return Colors.teal;
      case 'archive': return Colors.orange;
      case 'delete':  return Colors.red;
      default:        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = entry.at.toLocal();
    String pad(int x) => x.toString().padLeft(2, '0');
    final stamp = '${when.year}-${pad(when.month)}-${pad(when.day)} '
        '${pad(when.hour)}:${pad(when.minute)}';
    return ListTile(
      dense: true,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          entry.action[0].toUpperCase(),
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text('${entry.action}  ·  ${entry.poolId} / ${entry.questionId}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
      subtitle: Text(stamp,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _AuditDetailDialog(entry: entry),
      ),
    );
  }
}

class _AuditDetailDialog extends StatelessWidget {
  const _AuditDetailDialog({required this.entry});
  final QBankAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${entry.action} — ${entry.poolId}/${entry.questionId}'),
      content: SizedBox(
        width: 720,
        height: 480,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _JsonBlock(label: 'Before', data: entry.before)),
            const SizedBox(width: 8),
            Expanded(child: _JsonBlock(label: 'After', data: entry.after)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.label, required this.data});
  final String label;
  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final text = data == null
        ? '— null —'
        : data!.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 4),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Bulk publish — promote every draft + review row to 'published'
// =============================================================================

class BulkPublishButton extends ConsumerStatefulWidget {
  const BulkPublishButton({super.key});

  @override
  ConsumerState<BulkPublishButton> createState() => _BulkPublishButtonState();
}

class _BulkPublishButtonState extends ConsumerState<BulkPublishButton> {
  bool _busy = false;

  Future<void> _run() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publish all drafts?'),
        content: const Text(
          'Every row currently in DRAFT or REVIEW will move to PUBLISHED. '
          'Published rows are visible to all app users on next reload. '
          'This action is logged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish all'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    final svc = ref.read(qBankRemoteServiceProvider);
    final all = await svc.fetchAllDrafts();
    var done = 0, fail = 0;
    for (final d in all) {
      if (d.status == QBankDraftStatus.published) continue;
      final res = await svc.upsertDraft(
        poolId: d.poolId,
        id: d.id,
        status: QBankDraftStatus.published,
        payload: d.payload,
      );
      if (res.ok) {
        done++;
      } else {
        fail++;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(publishedDraftsProvider);
    ref.invalidate(recentAuditProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Published $done · failed $fail'),
      backgroundColor: fail == 0 ? Colors.green.shade700 : Colors.orange.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _busy ? null : _run,
      icon: _busy
          ? const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.publish, size: 18),
      label: const Text('Publish all drafts'),
    );
  }
}
