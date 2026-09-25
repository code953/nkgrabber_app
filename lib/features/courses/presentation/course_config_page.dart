/// Course configuration page.
///
/// Allows the user to browse batches and courses from the campus system,
/// and add them as grabbing targets.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/courses/application/course_targets_notifier.dart';
import 'package:nkgrabber/infrastructure/campus/models/campus_models.dart';
import 'package:nkgrabber/infrastructure/campus/xkms_enum.dart';
import 'package:nkgrabber/infrastructure/providers.dart';

class CourseConfigPage extends ConsumerWidget {
  const CourseConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).accounts;
    final selectedId = ref.watch(selectedAccountIdProvider);

    // Fall back to the first account so the page is usable without an extra
    // tap, but only when the stored selection is gone (deleted account).
    final activeId = accounts.any((a) => a.id == selectedId)
        ? selectedId
        : (accounts.isEmpty ? null : accounts.first.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('课程设置'),
        actions: [
          if (accounts.length > 1 && activeId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.switch_account),
              initialValue: activeId,
              onSelected: (id) =>
                  ref.read(selectedAccountIdProvider.notifier).state = id,
              itemBuilder: (context) => [
                for (final a in accounts)
                  PopupMenuItem(value: a.id, child: Text(a.displayName)),
              ],
            ),
        ],
      ),
      body: activeId == null
          ? const _NoAccountState()
          : _TargetList(accountId: activeId),
      floatingActionButton: activeId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openBatchPicker(context, activeId),
              icon: const Icon(Icons.add),
              label: const Text('添加目标'),
            ),
    );
  }

  void _openBatchPicker(BuildContext context, String accountId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _BatchPickerPage(accountId: accountId),
      ),
    );
  }
}

class _NoAccountState extends StatelessWidget {
  const _NoAccountState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text('选择课程目标', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('请先在「账号」页添加校园账号'),
        ],
      ),
    );
  }
}

/// The configured targets for one account, reorderable by priority.
class _TargetList extends ConsumerWidget {
  const _TargetList({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseTargetsProvider(accountId));

    if (state.isLoading && state.targets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.targets.isEmpty) {
      return const Center(child: Text('还没有配置抢课目标，点击右下角添加'));
    }

    final notifier = ref.read(courseTargetsProvider(accountId).notifier);
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: state.targets.length,
      onReorderItem: notifier.reorder,
      itemBuilder: (context, i) {
        final t = state.targets[i];
        return TargetListCard(
          key: ValueKey(t.id),
          courseName: t.courseName,
          batchName: t.batchName,
          xkms: Xkms.labelFor(t.xkms),
          kmh: t.kmh,
          enabled: t.enabled,
          onToggle: (v) => notifier.toggleEnabled(t.id, enabled: v),
          onDelete: () => notifier.removeTarget(t.id),
        );
      },
    );
  }
}

/// Step 1 of adding a target: pick the selection batch.
class _BatchPickerPage extends ConsumerWidget {
  const _BatchPickerPage({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchesProvider(accountId));
    // Debug mode lifts the selectability gate so a closed or unrecognised
    // batch can be targeted deliberately.
    final debugMode =
        ref.watch(appSettingsProvider).valueOrNull?.debugModeEnabled ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('选择批次')),
      body: batches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e is StateError ? e.message : '无法获取批次列表：$e',
          onRetry: () => ref.invalidate(batchesProvider(accountId)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('当前没有可选批次'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final b = list[i];
              final blockedReason = Xkms.blockedReason(b.xkms);
              final selectable = blockedReason == null || debugMode;
              return ListTile(
                title: Text(b.batchName),
                subtitle: Text(
                  blockedReason != null && debugMode
                      ? '${Xkms.labelFor(b.xkms)} · ${b.kssj} ~ ${b.jssj}'
                            '\n调试模式：$blockedReason，仍可选择'
                      : '${Xkms.labelFor(b.xkms)} · ${b.kssj} ~ ${b.jssj}',
                ),
                isThreeLine: blockedReason != null && debugMode,
                trailing: const Icon(Icons.chevron_right),
                // A closed or unrecognised batch cannot be submitted, so it is
                // shown (so the user can see it exists) but not selectable —
                // unless debug mode is on, which exists to try anyway.
                enabled: selectable,
                onTap: !selectable
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              _CoursePickerPage(accountId: accountId, batch: b),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Step 2 of adding a target: pick courses within the batch.
class _CoursePickerPage extends ConsumerStatefulWidget {
  const _CoursePickerPage({required this.accountId, required this.batch});

  final String accountId;
  final SelectionBatch batch;

  @override
  ConsumerState<_CoursePickerPage> createState() => _CoursePickerPageState();
}

class _CoursePickerPageState extends ConsumerState<_CoursePickerPage> {
  final Set<String> _addedKmhs = {};

  @override
  Widget build(BuildContext context) {
    final key = (accountId: widget.accountId, xkid: widget.batch.xkid);
    final courses = ref.watch(coursesProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(widget.batch.batchName)),
      body: courses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e is StateError ? e.message : '无法获取课程列表：$e',
          onRetry: () => ref.invalidate(coursesProvider(key)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('该批次下没有课程'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              final remaining = c.remaining;
              final isAdded = _addedKmhs.contains(c.kmh);
              return ListTile(
                title: Text(c.courseName),
                subtitle: Text(
                  [
                    if (c.teacherName != null) c.teacherName!,
                    if (remaining != null) '余量 $remaining',
                    'kmh: ${c.kmh}',
                  ].join(' · '),
                ),
                trailing: Icon(
                  isAdded ? Icons.check_circle : Icons.add_circle_outline,
                  color: isAdded ? Theme.of(context).colorScheme.primary : null,
                ),
                onTap: isAdded ? null : () => _addTarget(context, c),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addTarget(BuildContext context, Course course) async {
    final notifier = ref.read(courseTargetsProvider(widget.accountId).notifier);
    final ok = await notifier.addTarget(
      xkid: widget.batch.xkid,
      xkms: widget.batch.xkms,
      kmh: course.kmh,
      courseName: course.courseName,
      batchName: widget.batch.batchName,
      // Snapshotted here so the grab path never has to re-read it.
      zdxk: widget.batch.zdxk,
      xbkid: course.xbkid,
    );

    if (!context.mounted) return;
    if (ok) {
      setState(() => _addedKmhs.add(course.kmh));
    }
    final message = ok
        ? '已添加到抢课目标'
        : (ref.read(courseTargetsProvider(widget.accountId)).error ?? '添加失败');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

/// Target list card for a single course target.
class TargetListCard extends StatelessWidget {
  const TargetListCard({
    required this.courseName,
    required this.batchName,
    required this.xkms,
    required this.kmh,
    required this.enabled,
    this.onToggle,
    this.onDelete,
    super.key,
  });

  final String courseName;
  final String batchName;
  final String xkms;
  final String kmh;
  final bool enabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Switch(value: enabled, onChanged: onToggle),
        title: Text(courseName),
        subtitle: Text('$batchName · $xkms · kmh: $kmh'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
