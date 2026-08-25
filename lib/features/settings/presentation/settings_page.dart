/// Settings page.
///
/// Provides UI for theme switching, request interval, diagnostics export,
/// and license unbind.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/app/theme.dart';

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
          const _SectionHeader(title: '授权'),
          const _LicenseStatusTile(),
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('解绑设备'),
            subtitle: const Text('解绑后需重新激活'),
            onTap: () {
              // TODO: Confirm and deactivate.
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

class _IntervalSetting extends StatefulWidget {
  const _IntervalSetting();

  @override
  State<_IntervalSetting> createState() => _IntervalSettingState();
}

class _IntervalSettingState extends State<_IntervalSetting> {
  double _intervalMs = 1000;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: const Text('请求间隔'),
      subtitle: Text('${_intervalMs.toInt()} ms'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: _intervalMs,
          min: 500,
          max: 5000,
          divisions: 9,
          label: '${_intervalMs.toInt()} ms',
          onChanged: (v) {
            setState(() => _intervalMs = v);
            // TODO: Persist via SettingsDao.
          },
        ),
      ),
    );
  }
}

class _LicenseStatusTile extends StatelessWidget {
  const _LicenseStatusTile();

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to LicenseNotifier.
    return const ListTile(
      leading: Icon(Icons.verified_outlined),
      title: Text('授权状态'),
      subtitle: Text('未激活'),
    );
  }
}
