import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/employee.dart';
import 'employee_avatar.dart';

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
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(
                employee: employee,
                onDelete: () => _confirmDelete(context),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                employee.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              if (employee.constraint.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  employee.constraint,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(_skillCountLabel, style: textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  String get _skillCountLabel => switch (employee.skillNames.length) {
    0 => 'Keine Fähigkeiten',
    1 => '1 Fähigkeit',
    final count => '$count Fähigkeiten',
  };

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

class _Header extends StatelessWidget {
  const _Header({required this.employee, required this.onDelete});

  final Employee employee;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EmployeeAvatar(employeeId: employee.id, size: 40),
        const Spacer(),
        IconButton(
          tooltip: 'Mitarbeiter „${employee.name}“ löschen',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
