import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/widgets/ios_context_menu.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/task.dart';
import '../cubits/task_homepage_cubit.dart';
import 'delete_task_dialog.dart';
import 'edit_task_objective_dialog.dart';
import 'rename_task_dialog.dart';

enum TaskMenuAction { execute, duplicate, rename, editObjective, delete }

class TaskContextMenu extends StatelessWidget {
  const TaskContextMenu({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: LocaleKeys.ui_aufgabenmenue_oeffnen.tr(),
        icon: const Icon(Icons.more_horiz),
        onPressed: () => _showContextMenu(buttonContext),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final action = await showIosContextMenu<TaskMenuAction>(context, [
      IosContextMenuItem(
        value: TaskMenuAction.execute,
        icon: Icons.play_arrow_rounded,
        label: LocaleKeys.ui_ausfuehren.tr(),
      ),
      IosContextMenuItem(
        value: TaskMenuAction.rename,
        icon: Icons.edit_outlined,
        label: LocaleKeys.ui_umbenennen.tr(),
      ),
      IosContextMenuItem(
        value: TaskMenuAction.duplicate,
        icon: Icons.copy_outlined,
        label: LocaleKeys.ui_duplizieren.tr(),
      ),
      IosContextMenuItem(
        value: TaskMenuAction.editObjective,
        icon: Icons.note_alt_outlined,
        label: LocaleKeys.ui_notiz_bearbeiten.tr(),
      ),
      const IosContextMenuDivider(),
      IosContextMenuItem(
        value: TaskMenuAction.delete,
        icon: Icons.delete_outline,
        label: LocaleKeys.ui_loeschen.tr(),
        isDestructive: true,
      ),
    ]);
    if (context.mounted && action != null) await _handleAction(context, action);
  }

  Future<void> _handleAction(
    BuildContext context,
    TaskMenuAction action,
  ) async {
    final cubit = context.read<TaskHomepageCubit>();
    switch (action) {
      case TaskMenuAction.execute:
        await _executeTask(context, cubit);
      case TaskMenuAction.duplicate:
        await cubit.duplicateTask(task);
      case TaskMenuAction.rename:
        await _renameTask(context, cubit);
      case TaskMenuAction.editObjective:
        await _editObjective(context, cubit);
      case TaskMenuAction.delete:
        await _deleteTask(context, cubit);
    }
  }

  Future<void> _executeTask(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final failureMessage = await cubit.executeTask(task);
    if (!context.mounted) return;
    final message = failureMessage ?? 'Aufgabe wurde gestartet.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _renameTask(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final title = await showIosDialog<String>(
      context: context,
      builder: (_) => RenameTaskDialog(initialTitle: task.title),
    );
    if (title == null) return;
    await cubit.renameTask(task, title);
  }

  Future<void> _editObjective(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final objective = await showIosDialog<String>(
      context: context,
      builder: (_) => EditTaskObjectiveDialog(initialObjective: task.objective),
    );
    if (objective == null) return;
    await cubit.updateObjective(task, objective);
  }

  Future<void> _deleteTask(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (_) => DeleteTaskDialog(taskTitle: task.title),
    );
    if (confirmed ?? false) await cubit.deleteTask(task);
  }
}
