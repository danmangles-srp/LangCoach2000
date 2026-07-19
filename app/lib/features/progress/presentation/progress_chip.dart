// coverage:ignore-file — presentation; exercised via widget test driving the
// real snapshot + settings providers (no unit-testable logic here).
//
// Progress chip (M11 T11.5, AC 4). A compact level + streak glance shown in
// the Today queue AppBar. Hidden entirely when the user toggles
// `showProgressIndicator` off in Settings (the dashboard card on Today stays
// regardless — this only gates the glance indicator). XP is informational.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rivendell/features/progress/application/progress_providers.dart';
import 'package:rivendell/features/progress/domain/progress_snapshot.dart';
import 'package:rivendell/features/settings/application/settings_providers.dart';
import 'package:rivendell/l10n/app_strings.dart';

class ProgressChip extends ConsumerWidget {
  const ProgressChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(
      appSettingsProvider.select((s) => s.showProgressIndicator),
    );
    if (!show) return const SizedBox.shrink();

    final snapshot =
        ref.watch(progressSnapshotProvider).value ?? ProgressSnapshot.empty;
    final strings = AppStrings.of(context);

    return Tooltip(
      message: strings.progressChipTooltip(
        snapshot.level,
        snapshot.streakCount,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              strings.progressCardLevel(snapshot.level),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.local_fire_department,
              size: 16,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              '${snapshot.streakCount}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
