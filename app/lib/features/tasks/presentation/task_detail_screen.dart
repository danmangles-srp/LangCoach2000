// coverage:ignore-file
//
// Task detail screen (T9.4, M9 AC 4). Reached from the tasks list row tap.
// Read-only display of the task fields; the AppBar Edit action opens the
// shared [TaskEditDialog] (Todoist-style: list → detail → edit), and Delete
// removes the task + pops back to the list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/application/task_providers.dart';
import 'package:rivendell/features/tasks/presentation/task_edit_dialog.dart';
import 'package:rivendell/l10n/app_strings.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final int taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(taskByIdProvider(taskId));
    final task = async.value;

    Future<void> delete() async {
      final commands = await ref.read(taskCommandsProvider.future);
      await commands.delete(taskId);
      ref
        ..invalidate(tasksProvider)
        ..invalidate(taskByIdProvider(taskId));
      // Pop only when there's somewhere to go — a deep-linked detail screen
      // (restore from a stale notification) has nothing above it. maybeOf
      // returns null when no GoRouter is in scope.
      if (!context.mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) router.pop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.taskDetailTitle),
        actions: [
          if (task != null) ...[
            IconButton(
              tooltip: strings.taskEditAction,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => createOrEditTask(context, ref, existing: task),
            ),
            IconButton(
              tooltip: strings.taskDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: delete,
            ),
          ],
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
        ),
        data: (t) => t == null
            ? _StatusView(
                icon: Icons.task_alt_rounded,
                message: strings.taskNotFound,
              )
            : _TaskBody(task: t),
      ),
    );
  }
}

class _TaskBody extends ConsumerWidget {
  const _TaskBody({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    );

    final due = task.dueDate;
    final overdue = due != null && !task.completed && due.isBefore(_today());
    final description = task.description;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.completed
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Checkbox(
              value: task.completed,
              onChanged: (value) async {
                final commands = await ref.read(taskCommandsProvider.future);
                await commands.setCompleted(task.id, completed: value ?? false);
                ref
                  ..invalidate(taskByIdProvider(task.id))
                  ..invalidate(tasksProvider);
              },
            ),
          ],
        ),
        if (due != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (overdue)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _Pill(
                    label: strings.taskOverdue,
                    background: theme.colorScheme.errorContainer,
                    foreground: theme.colorScheme.onErrorContainer,
                  ),
                ),
              Icon(
                Icons.event_rounded,
                size: 16,
                color: overdue
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  strings.taskDueOn(dateFormat.format(due)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: overdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            strings.taskFieldDescription,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: 20),
        Text(
          strings.taskCreatedOn(dateFormat.format(task.createdAt)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
