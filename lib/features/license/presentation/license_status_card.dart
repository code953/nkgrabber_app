/// License status card for settings page.
///
/// Displays license expiry, plan info, and device binding status.
library;

import 'package:flutter/material.dart';
import 'package:nkgrabber/infrastructure/database/app_database.dart';

class LicenseStatusCard extends StatelessWidget {
  const LicenseStatusCard({
    required this.snapshot,
    super.key,
  });

  final LicenseSnapshotEntry snapshot;

  @override
  Widget build(BuildContext context) {
    final expiresAt = DateTime.tryParse(snapshot.expiresAt);
    final isExpired =
        expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning : Icons.verified,
                  color: isExpired ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  snapshot.planName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: '到期时间',
              value: expiresAt?.toLocal().toString().split('.').first ?? '未知',
              valueColor: isExpired ? Colors.red : null,
            ),
            _InfoRow(
              label: '最大账号数',
              value: '${snapshot.maxAccounts}',
            ),
            _InfoRow(
              label: '最大并发账号',
              value: '${snapshot.maxConcurrentAccounts}',
            ),
            _InfoRow(
              label: '最小请求间隔',
              value: '${snapshot.minRequestIntervalMs} ms',
            ),
            _InfoRow(
              label: '解绑冷却',
              value: '${snapshot.unbindCooldownHours} 小时',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
