/// Settings page.
///
/// Provides UI for theme switching, the four grabber limits, and
/// diagnostics export.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/app/theme.dart';
import 'package:nkgrabber/core/utils/constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to SettingsDao and providers via Riverpod.
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const _SectionHeader(title: '外观'),
          const _ThemeSetting(),
          const Divider(),
          const _SectionHeader(title: '抢课'),
          const _IntervalSetting(),
          const _MinIntervalSetting(),
          const _MaxAccountsSetting(),
          const _MaxConcurrentSetting(),
          const Divider(),
          const _SectionHeader(title: '数据'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('导出诊断包'),
            subtitle: const Text('最近3次任务日志（已脱敏）'),
            onTap: () {
              // TODO: Export diagnostics.
            },
          ),
          const Divider(),
          const _SectionHeader(title: '关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('NKgrabber'),
            subtitle: Text('v1.0.0'),
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

class _ThemeSetting extends StatefulWidget {
  const _ThemeSetting();

  @override
  State<_ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<_ThemeSetting> {
  AppThemeMode _selected = AppThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('主题'),
      subtitle: Text(_selected.label),
      onTap: () {
        showDialog<AppThemeMode>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('选择主题'),
            children: AppThemeMode.values.map((mode) {
              return ListTile(
                title: Text(mode.label),
                leading: Icon(
                  mode == _selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == _selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => Navigator.of(context).pop(mode),
              );
            }).toList(),
          ),
        ).then((value) {
          if (value != null) {
            setState(() => _selected = value);
            // TODO: Persist via SettingsDao.
          }
        });
      },
    );
  }
}

extension on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.simple => '简约 (蓝色)',
        AppThemeMode.anime => '二次元 (粉紫)',
        AppThemeMode.system => '跟随系统',
      };
}

/// A slider-backed numeric setting row.
///
/// All four grabber limits share this shape, so they share the widget.
class _SliderSetting extends StatefulWidget {
  const _SliderSetting({
    required this.icon,
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    this.subtitleHint,
  });

  final IconData icon;
  final String title;
  final double initial;
  final double min;
  final double max;
  final int divisions;

  /// Renders the current value, e.g. `(v) => '$v ms'`.
  final String Function(int value) format;

  /// Optional second line explaining what the value protects against.
  final String? subtitleHint;

  @override
  State<_SliderSetting> createState() => _SliderSettingState();
}

class _SliderSettingState extends State<_SliderSetting> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final hint = widget.subtitleHint;
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.title),
      subtitle: Text(
        hint == null
            ? widget.format(_value.toInt())
            : '${widget.format(_value.toInt())} · $hint',
      ),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          label: widget.format(_value.toInt()),
          onChanged: (v) {
            setState(() => _value = v);
            // TODO: Persist via SettingsDao.
          },
        ),
      ),
    );
  }
}

class _IntervalSetting extends StatelessWidget {
  const _IntervalSetting();

  @override
  Widget build(BuildContext context) {
    return _SliderSetting(
      icon: Icons.timer_outlined,
      title: '请求间隔',
      initial: AppConstants.defaultUserIntervalMs.toDouble(),
      min: 500,
      max: 5000,
      divisions: 9,
      format: (v) => '$v ms',
    );
  }
}

class _MinIntervalSetting extends StatelessWidget {
  const _MinIntervalSetting();

  @override
  Widget build(BuildContext context) {
    return _SliderSetting(
      icon: Icons.speed_outlined,
      title: '间隔下限',
      initial: AppConstants.defaultMinRequestIntervalMs.toDouble(),
      min: 500,
      max: 3000,
      divisions: 10,
      format: (v) => '$v ms',
      subtitleHint: '过低可能触发学校风控',
    );
  }
}

class _MaxAccountsSetting extends StatelessWidget {
  const _MaxAccountsSetting();

  @override
  Widget build(BuildContext context) {
    return _SliderSetting(
      icon: Icons.people_outline,
      title: '最大账号数',
      initial: AppConstants.defaultMaxAccounts.toDouble(),
      min: 1,
      max: 20,
      divisions: 19,
      format: (v) => '$v 个',
      subtitleHint: '超出后按添加时间从新到旧停用',
    );
  }
}

class _MaxConcurrentSetting extends StatelessWidget {
  const _MaxConcurrentSetting();

  @override
  Widget build(BuildContext context) {
    return _SliderSetting(
      icon: Icons.dynamic_feed_outlined,
      title: '最大并发账号数',
      initial: AppConstants.defaultMaxConcurrentAccounts.toDouble(),
      min: 1,
      max: 10,
      divisions: 9,
      format: (v) => '$v 个',
      subtitleHint: '同时抢课的账号数量',
    );
  }
}
