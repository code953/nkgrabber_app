/// Grabber control page.
///
/// Shows the current grabber state, provides start/stop/pause controls,
/// and displays real-time progress of course selection.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/features/grabber/domain/grabber_state.dart';

class GrabberPage extends StatelessWidget {
  const GrabberPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to GrabberNotifier via Riverpod.
    return Scaffold(
      appBar: AppBar(title: const Text('抢课')),
      body: const _GrabberBody(),
    );
  }
}

class _GrabberBody extends StatelessWidget {
  const _GrabberBody();

  @override
  Widget build(BuildContext context) {
    // Default idle state display.
    return const _IdleView();
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rocket_launch_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '准备就绪',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('配置好账号和课程目标后，点击开始按钮'),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // TODO: Start grabber via GrabberNotifier.
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('开始抢课'),
          ),
        ],
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
                ? (state.successCount + state.failedCount) /
                    state.totalTargets
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
          const Spacer(),
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
      GrabberStatus.preparing => (
          Icons.hourglass_top,
          '准备中...',
          Colors.orange,
        ),
      GrabberStatus.running => (
          Icons.autorenew,
          '抢课中...',
          Colors.blue,
        ),
      GrabberStatus.success => (Icons.check_circle, '全部成功', Colors.green),
      GrabberStatus.paused => (Icons.pause_circle, '已暂停', Colors.amber),
      GrabberStatus.stopped => (Icons.stop_circle, '已停止', Colors.grey),
      GrabberStatus.interrupted => (Icons.warning, '异常中断', Colors.red),
      GrabberStatus.authExpired => (Icons.lock, '授权失效', Colors.red),
      GrabberStatus.captchaRequired => (
          Icons.security,
          '需要验证码',
          Colors.amber,
        ),
      GrabberStatus.failed => (Icons.error, '失败', Colors.red),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }
}
