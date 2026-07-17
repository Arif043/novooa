import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task.dart';
import '../cubits/task_homepage_cubit.dart';
import 'delete_task_dialog.dart';
import 'rename_task_dialog.dart';

enum TaskMenuAction { duplicate, rename, delete }

class TaskContextMenu extends StatelessWidget {
  const TaskContextMenu({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<TaskMenuAction>(
      tooltip: 'Aufgabenmenü öffnen',
      icon: const Icon(Icons.more_horiz),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: TaskMenuAction.duplicate,
          child: ListTile(
            leading: Icon(Icons.copy_outlined),
            title: Text('Duplizieren'),
          ),
        ),
        PopupMenuItem(
          value: TaskMenuAction.rename,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Umbenennen'),
          ),
        ),
        PopupMenuItem(
          value: TaskMenuAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Löschen'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    TaskMenuAction action,
  ) async {
    final cubit = context.read<TaskHomepageCubit>();
    switch (action) {
      case TaskMenuAction.duplicate:
        await cubit.duplicateTask(task);
      case TaskMenuAction.rename:
        await _renameTask(context, cubit);
      case TaskMenuAction.delete:
        await _deleteTask(context, cubit);
    }
  }

  Future<void> _renameTask(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => RenameTaskDialog(initialTitle: task.title),
    );
    if (title == null) return;
    await cubit.renameTask(task, title);
  }

  Future<void> _deleteTask(
    BuildContext context,
    TaskHomepageCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteTaskDialog(taskTitle: task.title),
    );
    if (confirmed ?? false) await cubit.deleteTask(task);
  }
}
