/// Course configuration page.
///
/// Allows the user to browse batches and courses from the campus system,
/// and add them as grabbing targets.
library;

import 'package:flutter/material.dart';

class CourseConfigPage extends StatelessWidget {
  const CourseConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Wire to Riverpod providers for batch/course lists.
    return Scaffold(
      appBar: AppBar(title: const Text('课程设置')),
      body: const _CourseConfigBody(),
    );
  }
}

class _CourseConfigBody extends StatelessWidget {
  const _CourseConfigBody();

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
          Text(
            '选择课程目标',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('请先添加账号，然后选择要抢的课程'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Navigate to batch selection flow.
            },
            icon: const Icon(Icons.add),
            label: const Text('配置目标'),
          ),
        ],
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
    required this.enabled,
    this.onToggle,
    this.onDelete,
    super.key,
  });

  final String courseName;
  final String batchName;
  final String xkms;
  final bool enabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Switch(
          value: enabled,
          onChanged: onToggle,
        ),
        title: Text(courseName),
        subtitle: Text('$batchName · $xkms'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
