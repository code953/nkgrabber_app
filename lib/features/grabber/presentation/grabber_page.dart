/// Grabber control page.
///
/// Shows the current grabber state, provides start/stop/pause controls,
/// and displays real-time progress of course selection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/grabber_controller.dart';
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
        actions: [
          if (state.isTerminal)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重置',
              onPressed: ref.read(grabberProvider.notifier).reset,
            ),
        ],
      ),
      body: Column(
        children: [
          if (debugMode) const _DebugModeBanner(),
          Expanded(
            child: state.status == GrabberStatus.idle
                ? const _IdleView()
                : GrabberProgressView(
                    state: state,
                    onStop: ref.read(grabberProvider.notifier).stop,
                    onPause: ref.read(grabberProvider.notifier).pause,
                  ),
          ),
        ],
      ),
    );
  }
}

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

/// Running state progress view.
class GrabberProgressView extends StatelessWidget {
  const GrabberProgressView({
    required this.state,
    this.onStop,
    this.onPause,
    super.key,
  });

  final GrabberState state;
  final VoidCallback? onStop;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _StatusHeader(state: state),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: state.totalTargets > 0
                ? (state.successCount + state.failedCount) / state.totalTargets
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            '成功: ${state.successCount} / '
            '失败: ${state.failedCount} / '
            '总计: ${state.totalTargets}',
          ),
          if (state.message != null) ...[
            const SizedBox(height: 12),
            Text(
              state.message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
          const Spacer(),
          // Terminal states have nothing left to stop or pause; the app bar
          // offers a reset instead.
          if (!state.isTerminal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.status == GrabberStatus.running) ...[
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                  ),
                  const SizedBox(width: 16),
                ],
                FilledButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('停止'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
        ],
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
