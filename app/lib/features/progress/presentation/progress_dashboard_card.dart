// coverage:ignore-file — presentation; exercised via widget test driving the
// real snapshot provider over an in-memory ledger (no unit-testable logic here
// beyond layout).
//
// Progress dashboard card (M11 T11.5, AC 1/3/4). Mounted at the top of the
// Today queue. Renders the derived [ProgressSnapshot]: level, an XP progress
// bar (xpIntoLevel / 500), the streak count, and a freeze badge when one is
// banked. XP + streak are informational — nothing gates on these fields.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/progress/application/progress_providers.dart';
import 'package:rivendell/features/progress/domain/progress_snapshot.dart';
import 'package:rivendell/features/progress/domain/xp_level.dart';
import 'package:rivendell/l10n/app_strings.dart';

class ProgressDashboardCard extends ConsumerWidget {
  const ProgressDashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(progressSnapshotProvider);

    final snapshot = async.value ?? ProgressSnapshot.empty;
    final progress = xpPerLevel == 0
        ? 0.0
        : (snapshot.xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  strings.progressCardLevel(snapshot.level),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (snapshot.freezesBanked > 0)
                  _FreezeBadge(label: strings.progressCardFreezeBadge),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              strings.progressCardXpOfTotal(snapshot.xpIntoLevel, xpPerLevel),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _StreakRow(count: snapshot.streakCount),
          ],
        ),
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final active = count > 0;
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 18,
          color: active ? Colors.orange.shade700 : theme.disabledColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            active
                ? strings.progressCardStreakDays(count)
                : strings.progressCardStreakZero,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: active
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _FreezeBadge extends StatelessWidget {
  const _FreezeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ac_unit_rounded,
            size: 14,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
