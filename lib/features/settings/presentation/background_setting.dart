/// Settings rows for the background image.
library;

import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nkgrabber/core/errors/app_exception.dart';
import 'package:nkgrabber/features/settings/application/background_controller.dart';
import 'package:nkgrabber/infrastructure/background/background_image_service.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';

enum _BackgroundAction { local, url, refresh, remove }

class BackgroundSetting extends ConsumerWidget {
  const BackgroundSetting({required this.settings, super.key});

  final AppSettingsEntry settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref.watch(backgroundImageFileProvider).valueOrNull;
    final url = settings.backgroundImageUrl;
    final hasBackground = settings.backgroundImageFile != null;

    final String subtitle;
    if (!hasBackground) {
      subtitle = '未设置 · 支持本地图片和图床链接';
    } else if (file == null &&
        !ref.watch(backgroundImageFileProvider).isLoading) {
      subtitle = '图片文件已丢失，请重新选择';
    } else if (url != null) {
      subtitle = '图床 · ${Uri.tryParse(url)?.host ?? url}';
    } else {
      subtitle = '本地图片';
    }

    return ListTile(
      leading: const Icon(Icons.wallpaper_outlined),
      title: const Text('背景图片'),
      subtitle: Text(subtitle),
      trailing: file == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                file,
                width: 56,
                height: 40,
                fit: BoxFit.cover,
                cacheWidth: 168,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox(width: 56),
              ),
            ),
      onTap: () => _showActions(context, ref, hasBackground, url != null),
    );
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    bool hasBackground,
    bool fromUrl,
  ) async {
    final action = await showModalBottomSheet<_BackgroundAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从本地选择图片'),
              onTap: () => Navigator.of(context).pop(_BackgroundAction.local),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('使用图床链接'),
              subtitle: const Text('图片直链或随机图 API'),
              onTap: () => Navigator.of(context).pop(_BackgroundAction.url),
            ),
            if (fromUrl)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('重新获取'),
                subtitle: const Text('随机图 API 会换一张新图片'),
                onTap: () =>
                    Navigator.of(context).pop(_BackgroundAction.refresh),
              ),
            if (hasBackground)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('移除背景'),
                subtitle: const Text('主题色保持不变'),
                onTap: () =>
                    Navigator.of(context).pop(_BackgroundAction.remove),
              ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final controller = ref.read(backgroundControllerProvider);
    switch (action) {
      case _BackgroundAction.local:
        final picked = await FilePicker.pickFiles(type: FileType.image);
        final path = picked?.files.singleOrNull?.path;
        if (path == null || !context.mounted) return;
        await _runImport(context, () => controller.setFromFile(path));
      case _BackgroundAction.url:
        final input = await showDialog<(String, ImageHostClient?)>(
          context: context,
          builder: (context) => _ImageUrlDialog(
            initialUrl: settings.backgroundImageUrl ?? '',
            initialClient: ImageHostClient.fromString(
              settings.backgroundImageClient,
            ),
          ),
        );
        if (input == null || !context.mounted) return;
        final (url, client) = input;
        await _runImport(
          context,
          () => controller.setFromUrl(url, client: client),
        );
      case _BackgroundAction.refresh:
        await _runImport(context, controller.refresh);
      case _BackgroundAction.remove:
        await controller.clear();
    }
  }

  /// Run an import behind a blocking progress dialog, then report the outcome.
  Future<void> _runImport(
    BuildContext context,
    Future<ImportedBackground> Function() import,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 20),
                Text('正在处理图片…'),
              ],
            ),
          ),
        ),
      ),
    );

    String message;
    try {
      final imported = await import();
      message = imported.seedColors.isEmpty
          ? '背景已更新（图片色彩过少，主题色未改变）'
          : '背景已更新，主题色已根据图片调整';
    } on BackgroundImageException catch (e) {
      message = e.message;
    } on Object catch (e) {
      message = '设置背景失败：$e';
    } finally {
      navigator.pop();
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ImageUrlDialog extends StatefulWidget {
  const _ImageUrlDialog({required this.initialUrl, this.initialClient});

  final String initialUrl;
  final ImageHostClient? initialClient;

  @override
  State<_ImageUrlDialog> createState() => _ImageUrlDialogState();
}

class _ImageUrlDialogState extends State<_ImageUrlDialog> {
  late final _controller = TextEditingController(text: widget.initialUrl);
  late String _client = widget.initialClient?.name ?? _auto;
  String? _error;

  static const _auto = 'auto';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      parseImageUrl(_controller.text);
    } on BackgroundImageException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    Navigator.of(
      context,
    ).pop((_controller.text.trim(), ImageHostClient.fromString(_client)));
  }

  @override
  Widget build(BuildContext context) {
    final autoLabel = ImageHostClient.platformDefault == ImageHostClient.mobile
        ? '当前设备按手机端请求'
        : '当前设备按电脑端请求';
    return AlertDialog(
      title: const Text('图床链接'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: '图片链接',
                hintText: 'https://example.com/random',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text('请求方式', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: _auto, label: Text('自动')),
                ButtonSegment(
                  value: 'desktop',
                  label: Text('电脑端'),
                  icon: Icon(Icons.desktop_windows_outlined),
                ),
                ButtonSegment(
                  value: 'mobile',
                  label: Text('手机端'),
                  icon: Icon(Icons.smartphone_outlined),
                ),
              ],
              selected: {_client},
              onSelectionChanged: (s) => setState(() => _client = s.first),
            ),
            const SizedBox(height: 8),
            Text(
              '部分图床会按设备返回横屏或竖屏图片（双端适配）。'
              '「自动」时$autoLabel；想要另一种比例的图片时可手动切换。'
              '图片会下载保存到本地，之后启动不再联网。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('下载')),
      ],
    );
  }
}
