/// Update page.
///
/// Shows update information and provides download/install controls.
/// For mandatory updates, blocks the main UI.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/infrastructure/backend/dtos/latest_release_dto.dart';

class UpdatePage extends StatelessWidget {
  const UpdatePage({
    required this.release,
    this.isMandatory = false,
    super.key,
  });

  final LatestReleaseDto release;
  final bool isMandatory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('版本更新'),
        automaticallyImplyLeading: !isMandatory,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.system_update, size: 64),
              const SizedBox(height: 24),
              Text(
                '新版本 v${release.version}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (isMandatory) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '强制更新',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(release.releaseNotes),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // TODO: Download and verify update.
                },
                icon: const Icon(Icons.download),
                label: const Text('下载更新'),
              ),
              if (!isMandatory) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('稍后再说'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
