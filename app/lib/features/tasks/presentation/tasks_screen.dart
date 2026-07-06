// Tasks screen (T5.2, FR-1.4.1, NFR-2.4.1). The "Exercises & Tasks" surface:
// create / complete / delete with a due-date picker. Reads [tasksProvider];
// mutations invalidate it so the list refreshes atomically. Each tile is a
// checkbox (complete) + title + due-date subtitle (an Overdue pill marks
// past-due incomplete tasks); tap opens the detail (T9.4), swipe deletes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:rivendell/core/database/app_database.dart';
import 'package:rivendell/features/tasks/application/task_providers.dart';
import 'package:rivendell/features/tasks/presentation/task_edit_dialog.dart';
import 'package:rivendell/l10n/app_strings.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final async = ref.watch(tasksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(strings.tasksTitle), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        // HomeShell mounts this FAB alongside the Library tab's scan FAB in an
        // IndexedStack; both default-tagged FABs would collide on Hero. Unique
        // tag keeps them distinct.
        heroTag: 'tasks-add',
        onPressed: () => createOrEditTask(context, ref, existing: null),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.tasksAdd),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => _StatusView(
          icon: Icons.error_outline_rounded,
          message: strings.errorTitle,
          action: FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(tasksProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.retry),
          ),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _StatusView(
              icon: Icons.task_alt_rounded,
              message: strings.tasksEmptyTitle,
              body: strings.tasksEmptyBody,
            );
          }
          return Scrollbar(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];
                return _TaskTile(task: task);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    final due = task.dueDate;
    final overdue = due != null && !task.completed && due.isBefore(_today());

    String? subtitle;
    if (due != null) {
      subtitle = strings.taskDueOn(dateFormat.format(due));
    }

    return Dismissible(
      key: ValueKey('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        final commands = await ref.read(taskCommandsProvider.future);
        await commands.delete(task.id);
        ref.invalidate(tasksProvider);
        return true;
      },
      child: ListTile(
        onTap: () => context.push('/tasks/${task.id}'),
        leading: Checkbox(
          value: task.completed,
          onChanged: (value) async {
            final commands = await ref.read(taskCommandsProvider.future);
            await commands.setCompleted(task.id, completed: value ?? false);
            ref.invalidate(tasksProvider);
          },
        ),
        title: Text(
          task.title,
          style: task.completed
              ? theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
        subtitle: subtitle == null
            ? null
            : Row(
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
                  Flexible(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: overdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
  const _StatusView({
    required this.icon,
    required this.message,
    this.body,
    this.action,
  });

  final IconData icon;
  final String message;
  final String? body;
  final Widget? action;

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
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
