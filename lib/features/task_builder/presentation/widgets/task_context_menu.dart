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
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: 'Aufgabenmenü öffnen',
        icon: const Icon(Icons.more_horiz),
        onPressed: () => _showContextMenu(buttonContext),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final action = await showMenu<TaskMenuAction>(
      context: context,
      position: _menuPositionFor(context),
      color: _menuColorFor(context),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      items: const [
        PopupMenuItem(
          value: TaskMenuAction.rename,
          height: 36,
          child: _TaskMenuRow(icon: Icons.edit_outlined, label: 'Umbenennen'),
        ),
        PopupMenuItem(
          value: TaskMenuAction.duplicate,
          height: 36,
          child: _TaskMenuRow(icon: Icons.copy_outlined, label: 'Duplizieren'),
        ),
        PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: TaskMenuAction.delete,
          height: 36,
          child: _TaskMenuRow(
            icon: Icons.delete_outline,
            label: 'Löschen',
            isDestructive: true,
          ),
        ),
      ],
    );
    if (context.mounted && action != null) await _handleAction(context, action);
  }

  RelativeRect _menuPositionFor(BuildContext context) {
    final button = context.findRenderObject() as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final offset = button.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + button.size.height,
      overlay.size.width - offset.dx - button.size.width,
      overlay.size.height - offset.dy,
    );
  }

  Color _menuColorFor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (colorScheme.brightness == Brightness.dark) {
      return const Color(0xFF151515);
    }
    return colorScheme.surface;
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

class _TaskMenuRow extends StatelessWidget {
  const _TaskMenuRow({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
