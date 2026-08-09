import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/employee_attachment.dart';

class EmployeeAssignmentPicker extends StatelessWidget {
  const EmployeeAssignmentPicker({
    super.key,
    required this.assigned,
    required this.employees,
    required this.enabled,
    required this.onAssign,
    required this.onUnassign,
  });

  final EmployeeAttachment? assigned;
  final List<EmployeeAttachment> employees;
  final bool enabled;
  final ValueChanged<EmployeeAttachment> onAssign;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          onPressed: enabled && employees.isNotEmpty
              ? () => _showPicker(context)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (assigned == null)
          const _EmptyState()
        else
          _AssignedTile(employee: assigned!, onUnassign: onUnassign),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showIosSheet<void>(
      context: context,
      builder: (_) => _PickerSheet(
        employees: employees,
        selectedId: assigned?.id,
        onSelect: (employee) => _select(context, employee),
      ),
    );
  }

  void _select(BuildContext context, EmployeeAttachment employee) {
    onAssign(employee);
    Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Mitarbeiter', style: SyscatTheme.taskBody)),
        IconButton(
          tooltip: 'Mitarbeiter zuweisen',
          onPressed: onPressed,
          icon: const Icon(Icons.person_outline),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Kein Mitarbeiter zugewiesen.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _AssignedTile extends StatelessWidget {
  const _AssignedTile({required this.employee, required this.onUnassign});

  final EmployeeAttachment employee;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    final skillCount = employee.defaultSkills.length;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.person_outline),
      title: Text(employee.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(_skillDescription(skillCount)),
      trailing: IconButton(
        tooltip: 'Mitarbeiter entfernen',
        onPressed: onUnassign,
        icon: const Icon(Icons.close),
      ),
    );
  }

  String _skillDescription(int skillCount) {
    return switch (skillCount) {
      0 => 'Rolle · keine Standard-Fähigkeiten',
      1 => 'Rolle · 1 Standard-Fähigkeit',
      _ => 'Rolle · $skillCount Standard-Fähigkeiten',
    };
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.employees,
    required this.selectedId,
    required this.onSelect,
  });

  final List<EmployeeAttachment> employees;
  final String? selectedId;
  final ValueChanged<EmployeeAttachment> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: employees.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.md),
        itemBuilder: (context, index) => _itemFor(employees[index]),
      ),
    );
  }

  Widget _itemFor(EmployeeAttachment employee) {
    final selected = employee.id == selectedId;
    return ListTile(
      leading: Icon(selected ? Icons.check_circle : Icons.person_outline),
      title: Text(employee.name),
      subtitle: employee.role.isEmpty
          ? null
          : Text(employee.role, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => onSelect(employee),
    );
  }
}
