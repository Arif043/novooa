import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/employee.dart';

class EmployeeListTile extends StatelessWidget {
  const EmployeeListTile({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final skillCount = employee.skillNames.length;
    return Container(
      decoration: SyscatTheme.nodePanelDecoration(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(Icons.badge_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: SyscatTheme.taskBody),
                if (employee.constraint.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    employee.constraint,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: SyscatTheme.taskBodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(switch (skillCount) {
                  0 => 'Keine Fähigkeiten',
                  1 => '1 Fähigkeit',
                  _ => '$skillCount Fähigkeiten',
                }, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mitarbeiter „${employee.name}“ bearbeiten',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Mitarbeiter „${employee.name}“ löschen',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Mitarbeiter löschen?'),
        content: Text(
          '„${employee.name}“ wird entfernt. Bausteine, die ihn verwenden, '
          'brechen beim nächsten Lauf mit einer Meldung ab, bis du einen '
          'anderen Mitarbeiter wählst.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) onDelete();
  }
}
