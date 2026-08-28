/// Grabber control page.
///
/// Shows the current grabber state, a stop control, the live request/response
/// log, and real-time progress of course selection.
library;

import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/grabber_controller.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_entry.dart';
import 'package:nkgrabber/features/grabber/domain/grab_log_export.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';
import 'package:nkgrabber/infrastructure/providers.dart';

/// Accounts that are enabled and have at least one enabled course target.
///
/// Starting without this check would create task records that immediately
/// fail with '没有可用的课程目标'.
final grabbableAccountsProvider = FutureProvider<List<String>>((ref) async {
  final accounts = ref.watch(accountsProvider).accounts;
  final dao = ref.watch(courseTargetDaoProvider);

  final ids = <String>[];
  for (final account in accounts.where((a) => a.enabled)) {
    final targets = await dao.getEnabledByAccount(account.id);
    if (targets.isNotEmpty) ids.add(account.id);
  }
  return ids;
});

class GrabberPage extends ConsumerWidget {
  const GrabberPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(grabberProvider);
    // Debug mode changes what a failure means, so it is surfaced wherever the
    // user reads results — not left buried in the settings page.
    final debugMode =
        ref.watch(appSettingsProvider).valueOrNull?.debugModeEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('抢课'),
        actions: const [_ExportLogButton()],
      ),
      body: Column(
        children: [
          if (debugMode) const _DebugModeBanner(),
          // Only the very first, never-run state gets the big empty view.
          // Everything else — running, stopped, finished — keeps the log on
          // screen and offers a restart, because stopping is not a dead end
          // and a separate reset press costs time during an open batch.
          if (state.status == GrabberStatus.idle)
            const Expanded(child: _IdleView())
          else ...[
            _RunSummary(state: state),
            const Divider(height: 1),
            const Expanded(child: _LiveLogView()),
            _RunControls(state: state),
          ],
        ],
      ),
    );
  }
}

/// Exports the on-screen log to the clipboard or a file.
///
/// Neither destination is sanitized, and neither touches the log file — see
/// `grab_log_export.dart` for why that is the intended boundary.
class _ExportLogButton extends ConsumerWidget {
  const _ExportLogButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(grabLogProvider).valueOrNull ?? const [];

    return PopupMenuButton<_ExportTarget>(
      icon: const Icon(Icons.ios_share),
      tooltip: '导出日志',
      // Disabled rather than hidden: a user who has been told the button
      // exists should see why it does nothing, not wonder where it went.
      enabled: entries.isNotEmpty,
      onSelected: (target) => _export(context, target, entries),
      itemBuilder: (context) => const [
        PopupMenuItem(value: _ExportTarget.clipboard, child: Text('复制到剪贴板')),
        PopupMenuItem(value: _ExportTarget.file, child: Text('保存为文件')),
      ],
    );
  }

  Future<void> _export(
    BuildContext context,
    _ExportTarget target,
    List<GrabLogEntry> entries,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = formatGrabLog(entries);

    String message;
    try {
      switch (target) {
        case _ExportTarget.clipboard:
          await Clipboard.setData(ClipboardData(text: text));
          message = '已复制 ${entries.length} 条日志';
        case _ExportTarget.file:
          await FileSaver.instance.saveAs(
            name: grabLogFileName(DateTime.now()),
            bytes: Uint8List.fromList(utf8.encode(text)),
            fileExtension: 'txt',
            mimeType: MimeType.text,
          );
          message = '已保存 ${entries.length} 条日志';
      }
    } on Exception catch (e) {
      // Saving can fail for reasons outside our control (cancelled dialog,
      // no write permission). Say so rather than leaving the user unsure
      // whether the export happened.
      message = '导出失败：$e';
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ExportTarget { clipboard, file }

/// Persistent reminder that the `xkms` gate is off.
///
/// Without it a user who forgot the switch reads "已结束批次提交失败" as a client
/// bug, when it is the campus server behaving correctly.
class _DebugModeBanner extends StatelessWidget {
  const _DebugModeBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.science_outlined,
              size: 20,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '调试模式已开启：忽略批次状态强制提交，失败多为学校服务器的正常拒绝',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends ConsumerWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grabbable = ref.watch(grabbableAccountsProvider);
    final ids = grabbable.valueOrNull ?? const <String>[];
    final ready = ids.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_outlined,
              size: 80,
              color: ready
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              ready ? '准备就绪' : '尚未就绪',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              ready ? '将为 ${ids.length} 个账号抢课' : '请先添加账号，并在「课程」页配置至少一个启用的目标',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: ready
                  ? () => ref.read(grabberProvider.notifier).start(ids)
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始抢课'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Status, progress bar and counters, shown above the live log.
class _RunSummary extends StatelessWidget {
  const _RunSummary({required this.state});

  final GrabberState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        children: [
          _StatusHeader(state: state),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: state.totalTargets > 0
                ? (state.successCount + state.failedCount) / state.totalTargets
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            '成功: ${state.successCount} / '
            '失败: ${state.failedCount} / '
            '总计: ${state.totalTargets}',
          ),
          if (state.message != null) ...[
            const SizedBox(height: 8),
            Text(
              state.message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ],
      ),
    );
  }
}

/// Live request/response log.
///
/// The counters above answer "how many"; this answers "what did we send and
/// what did the school say" — which is the only way to tell a course that is
/// genuinely full from a client that is misreading the response.
class _LiveLogView extends ConsumerStatefulWidget {
  const _LiveLogView();

  @override
  ConsumerState<_LiveLogView> createState() => _LiveLogViewState();
}

class _LiveLogViewState extends ConsumerState<_LiveLogView> {
  final _controller = ScrollController();

  /// Follow the tail until the user scrolls up, then leave their position
  /// alone — auto-scrolling out from under someone reading an error is worse
  /// than making them scroll back down.
  bool _follow = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final atBottom =
        _controller.offset >= _controller.position.maxScrollExtent - 40;
    if (atBottom != _follow) setState(() => _follow = atBottom);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(grabLogProvider).valueOrNull ?? const [];

    if (_follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients && _follow) {
          _controller.jumpTo(_controller.position.maxScrollExtent);
        }
      });
    }

    if (entries.isEmpty) {
      return Center(
        child: Text(
          '等待请求…',
          style: TextStyle(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _onScroll();
        return false;
      },
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: entries.length,
        itemBuilder: (context, i) => _LogTile(entry: entries[i]),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final GrabLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (entry.kind) {
      GrabLogKind.request => (Icons.north_east, scheme.primary),
      GrabLogKind.response => (Icons.south_west, scheme.outline),
      GrabLogKind.success => (Icons.check_circle_outline, Colors.green),
      GrabLogKind.failure => (Icons.error_outline, scheme.error),
      GrabLogKind.lifecycle => (Icons.flag_outlined, scheme.tertiary),
    };

    final mono = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.timestamp,
                      style: mono?.copyWith(color: scheme.outline),
                    ),
                    if (entry.accountLabel != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        entry.accountLabel!,
                        style: mono?.copyWith(color: scheme.outline),
                      ),
                    ],
                  ],
                ),
                Text(entry.message, style: mono?.copyWith(color: color)),
                if (entry.detail != null)
                  Text(
                    entry.detail!,
                    style: mono?.copyWith(color: scheme.outline),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The single control shown during and after a run.
///
/// While running there is only 停止 — pause was removed because it cancelled
/// the workers exactly like stop did, but parked the state in `paused`, which
/// is neither running nor terminal, so neither stop nor reset was offered and
/// the run could not be recovered.
class _RunControls extends ConsumerWidget {
  const _RunControls({required this.state});

  final GrabberState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grabbable = ref.watch(grabbableAccountsProvider);
    final ids = grabbable.valueOrNull ?? const <String>[];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: state.isRunning
            ? FilledButton.icon(
                onPressed: ref.read(grabberProvider.notifier).stop,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              )
            : FilledButton.icon(
                // Restart straight from a stopped run — no reset step.
                onPressed: ids.isEmpty
                    ? null
                    : () => ref.read(grabberProvider.notifier).start(ids),
                icon: const Icon(Icons.play_arrow),
                label: const Text('重新开始'),
              ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state});

  final GrabberState state;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (state.status) {
      GrabberStatus.idle => (Icons.rocket_launch_outlined, '空闲', Colors.grey),
      GrabberStatus.preparing => (Icons.hourglass_top, '准备中...', Colors.orange),
      GrabberStatus.running => (Icons.autorenew, '抢课中...', Colors.blue),
      GrabberStatus.success => (Icons.check_circle, '全部成功', Colors.green),
      GrabberStatus.paused => (Icons.pause_circle, '已暂停', Colors.amber),
      GrabberStatus.stopped => (Icons.stop_circle, '已停止', Colors.grey),
      GrabberStatus.interrupted => (Icons.warning, '异常中断', Colors.red),
      GrabberStatus.captchaRequired => (Icons.security, '需要验证码', Colors.amber),
      GrabberStatus.failed => (Icons.error, '失败', Colors.red),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
