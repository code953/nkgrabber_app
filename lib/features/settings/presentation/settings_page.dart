/// Settings page.
///
/// Provides UI for theme switching, the four grabber limits, and
/// diagnostics export.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/app/theme.dart';
import 'package:nkgrabber/core/utils/constants.dart';
import 'package:nkgrabber/core/utils/diagnostics_exporter.dart';
import 'package:nkgrabber/features/accounts/application/accounts_notifier.dart';
import 'package:nkgrabber/features/grabber/application/grabber_controller.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';
import 'package:nkgrabber/infrastructure/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: switch (settings) {
        AsyncError(:final error) => Center(child: Text('无法读取设置：$error')),
        AsyncData(:final value) => _SettingsBody(settings: value),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody({required this.settings});

  final AppSettingsEntry settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(appSettingsProvider.notifier);
    // Rebuilding the engine mid-run would orphan its workers, so the values it
    // reads at construction stay locked while a task is active.
    final isRunning = ref.watch(grabberProvider).isRunning;

    return ListView(
      children: [
        const _SectionHeader(title: '外观'),
        _ThemeSetting(
          selected: AppThemeMode.fromString(settings.theme),
          onChanged: (mode) => notifier.setTheme(mode.name),
        ),
        if (AppThemeMode.fromString(settings.theme) == AppThemeMode.custom)
          _CustomColorSetting(
            color: settings.customThemeColor != null
                ? Color(int.parse(settings.customThemeColor!))
                : null,
            onChanged: (Color? color) => notifier.setCustomThemeColor(
              color?.toARGB32().toString(),
            ),
          ),
        const Divider(),
        const _SectionHeader(title: '抢课'),
        if (isRunning)
          const ListTile(
            leading: Icon(Icons.lock_outline),
            subtitle: Text('抢课进行中，暂时无法修改以下设置'),
          ),
        _SliderSetting(
          icon: Icons.timer_outlined,
          title: '请求间隔',
          value: settings.userIntervalMs,
          min: 500,
          max: 5000,
          divisions: 9,
          format: (v) => '$v ms',
          subtitleHint: settings.userIntervalMs < settings.minRequestIntervalMs
              ? '低于下限，实际按 ${settings.minRequestIntervalMs} ms 执行'
              : null,
          onChanged: isRunning ? null : notifier.setUserIntervalMs,
        ),
        _SliderSetting(
          icon: Icons.speed_outlined,
          title: '间隔下限',
          value: settings.minRequestIntervalMs,
          min: 500,
          max: 3000,
          divisions: 10,
          format: (v) => '$v ms',
          subtitleHint: '过低可能触发学校风控',
          onChanged: isRunning ? null : notifier.setMinRequestIntervalMs,
        ),
        _SliderSetting(
          icon: Icons.people_outline,
          title: '最大账号数',
          value: settings.maxAccounts,
          min: 1,
          max: 20,
          divisions: 19,
          format: (v) => '$v 个',
          subtitleHint: '超出后按添加时间从新到旧停用',
          onChanged: isRunning
              ? null
              : (v) async {
                  await notifier.setMaxAccounts(v);
                  // Applying the new ceiling is the point of the setting;
                  // persisting it without enforcing would be a no-op.
                  await ref
                      .read(accountsProvider.notifier)
                      .enforceAccountLimit(v);
                },
        ),
        _SliderSetting(
          icon: Icons.dynamic_feed_outlined,
          title: '最大并发账号数',
          value: settings.maxConcurrentAccounts,
          min: 1,
          max: 10,
          divisions: 9,
          format: (v) => '$v 个',
          subtitleHint: '同时抢课的账号数量',
          onChanged: isRunning ? null : notifier.setMaxConcurrentAccounts,
        ),
        const Divider(),
        const _SectionHeader(title: '数据'),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('导出诊断包'),
          subtitle: const Text('最近3次任务日志（已脱敏）'),
          onTap: () => _exportDiagnostics(context, ref),
        ),
        const Divider(),
        const _SectionHeader(title: '关于'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('NKgrabber'),
          subtitle: Text('v${AppConstants.appVersion}'),
        ),
        const Divider(),
        // Last section on purpose: it is the one setting that changes what a
        // failure means, and it should not sit above the everyday controls.
        const _SectionHeader(title: '调试'),
        SwitchListTile(
          secondary: const Icon(Icons.science_outlined),
          title: const Text('调试模式'),
          subtitle: const Text('忽略批次状态，对已结束或无法识别的批次也发起提交'),
          value: settings.debugModeEnabled,
          // The engine reads this at construction, so it is locked mid-run
          // like the other grabber settings.
          onChanged: isRunning ? null : notifier.setDebugModeEnabled,
        ),
        if (settings.debugModeEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '提交仍携带服务器返回的原始 xkms，不做伪造。学校服务器几乎肯定会拒绝已结束批次的提交——那个拒绝本身就是调试要看的结果。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _exportDiagnostics(BuildContext context, WidgetRef ref) async {
    final exporter = DiagnosticsExporter(
      grabTaskDao: ref.read(grabTaskDaoProvider),
    );
    final json = (await exporter.export()).toSanitizedJson();

    if (!context.mounted) return;
    // Copied to the clipboard rather than written to a file: the client has no
    // file-picker dependency, and this keeps the data on-device by default.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('诊断包'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              json,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('复制'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting({required this.selected, required this.onChanged});

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('主题'),
      subtitle: Text(selected.label),
      onTap: () async {
        final picked = await showDialog<AppThemeMode>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择主题'),
            children: AppThemeMode.values.map((mode) {
              return ListTile(
                title: Text(mode.label),
                leading: Icon(
                  mode == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => Navigator.of(context).pop(mode),
              );
            }).toList(),
          ),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

extension on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.simple => '简约 (蓝色)',
    AppThemeMode.anime => '二次元 (粉紫)',
    AppThemeMode.custom => '自定义',
    AppThemeMode.system => '跟随系统',
  };
}

class _CustomColorSetting extends StatelessWidget {
  const _CustomColorSetting({required this.color, required this.onChanged});

  final Color? color;
  final ValueChanged<Color?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.color_lens_outlined),
      title: const Text('自定义主题色'),
      trailing: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
      ),
      onTap: () => _showColorPicker(context),
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final currentColor = color ?? Theme.of(context).colorScheme.primary;
    var selectedColor = currentColor;

    final result = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题色'),
        content: SizedBox(
          width: 300,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                _ColorSlider(
                  label: '色相',
                  value: HSVColor.fromColor(selectedColor).hue,
                  max: 360,
                  onChanged: (v) => setState(() {
                    final hsv = HSVColor.fromColor(selectedColor);
                    selectedColor = hsv.withHue(v).toColor();
                  }),
                ),
                _ColorSlider(
                  label: '饱和度',
                  value: HSVColor.fromColor(selectedColor).saturation * 100,
                  max: 100,
                  onChanged: (v) => setState(() {
                    final hsv = HSVColor.fromColor(selectedColor);
                    selectedColor = hsv.withSaturation(v / 100).toColor();
                  }),
                ),
                _ColorSlider(
                  label: '亮度',
                  value: HSVColor.fromColor(selectedColor).value * 100,
                  max: 100,
                  onChanged: (v) => setState(() {
                    final hsv = HSVColor.fromColor(selectedColor);
                    selectedColor = hsv.withValue(v / 100).toColor();
                  }),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(selectedColor),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            value.round().toString(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// A slider-backed numeric setting row.
///
/// All four grabber limits share this shape, so they share the widget.
///
/// Local state tracks the drag so the thumb follows the finger, but only the
/// release is persisted — writing on every frame would issue dozens of
/// database updates per gesture.
class _SliderSetting extends StatefulWidget {
  const _SliderSetting({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
    this.subtitleHint,
  });

  final IconData icon;
  final String title;
  final int value;
  final double min;
  final double max;
  final int divisions;

  /// Renders the current value, e.g. `(v) => '$v ms'`.
  final String Function(int value) format;

  /// Persists the released value. Null disables the slider.
  final void Function(int value)? onChanged;

  /// Optional second line explaining what the value protects against.
  final String? subtitleHint;

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  /// Non-null only while dragging.
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final current = _dragValue ?? widget.value.toDouble();
    final hint = widget.subtitleHint;
    final onChanged = widget.onChanged;

    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Text(
        hint == null
            ? widget.format(current.toInt())
            : '${widget.format(current.toInt())} · $hint',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: current.clamp(widget.min, widget.max),
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.format(current.toInt()),
          onChanged: onChanged == null
              ? null
              : (v) => setState(() => _dragValue = v),
          onChangeEnd: onChanged == null
              ? null
              : (v) {
                  setState(() => _dragValue = null);
                  onChanged(v.toInt());
                },
        ),
      ),
    );
  }
}
