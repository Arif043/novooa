import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'attachment_picker_sheet.dart';

/// Zuweisung eines Mitarbeiters an einen Baustein (0..1). Der Baustein kennt
/// nur die ID; Name und Fähigkeiten stammen aus der Live-Liste. Gibt es den
/// Mitarbeiter nicht mehr, steht das da — der Lauf bräche sonst ab.
class EmployeeAssignmentPicker extends StatelessWidget {
  const EmployeeAssignmentPicker({
    super.key,
    required this.assignedId,
    required this.employees,
    required this.enabled,
    required this.onAssign,
    required this.onUnassign,
  });

  final String? assignedId;
  final List<Employee> employees;
  final bool enabled;
  final ValueChanged<String> onAssign;
  final VoidCallback onUnassign;

  Employee? get _assigned {
    for (final employee in employees) {
      if (employee.id == assignedId) return employee;
    }
    return null;
  }

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
        if (assignedId == null)
          const _EmptyState()
        else
          _AssignedTile(
            employee: _assigned,
            lookupReady: enabled,
            onUnassign: onUnassign,
          ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final pickedId = await AttachmentPickerSheet.show(
      context,
      title: 'Mitarbeiter zuweisen',
      emptyMessage: 'Noch keine Mitarbeiter angelegt.',
      selectedIds: {?assignedId},
      items: [
        for (final employee in employees)
          AttachmentPickerItem(
            id: employee.id,
            title: employee.name,
            subtitle: _subtitleFor(employee),
            icon: Icons.person_outline,
          ),
      ],
    );
    if (pickedId != null) onAssign(pickedId);
  }

  String _subtitleFor(Employee employee) {
    final count = employee.skillNames.length;
    return switch (count) {
      0 => 'Rahmenbedingung · keine Fähigkeiten',
      1 => 'Rahmenbedingung · 1 Fähigkeit',
      _ => 'Rahmenbedingung · $count Fähigkeiten',
    };
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
  const _AssignedTile({
    required this.employee,
    required this.lookupReady,
    required this.onUnassign,
  });

  final Employee? employee;

  /// Die Liste ist geladen; vorher wäre „nicht mehr vorhanden" voreilig.
  final bool lookupReady;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    final employee = this.employee;
    final missing = employee == null && lookupReady;
    // Das Panel malt eine gefärbte DecoratedBox; ohne eigenes Material
    // meldet ListTile im Debug-Modus einen Fehler beim Bauen.
    return Material(
      type: MaterialType.transparency,
      child: _tile(context, employee, missing),
    );
  }

  Widget _tile(BuildContext context, Employee? employee, bool missing) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        missing ? Icons.warning_amber_rounded : Icons.person_outline,
        color: missing ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(
        employee?.name ?? (missing ? 'Mitarbeiter nicht mehr vorhanden' : '…'),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: employee == null
          ? (missing ? const Text('Wähle einen anderen Mitarbeiter.') : null)
          : Text(_skillDescription(employee.skillNames.length)),
      trailing: IconButton(
        tooltip: 'Mitarbeiter entfernen',
        onPressed: onUnassign,
        icon: const Icon(Icons.close),
      ),
    );
  }

  String _skillDescription(int skillCount) {
    return switch (skillCount) {
      0 => 'Rahmenbedingung · keine Fähigkeiten',
      1 => 'Rahmenbedingung · 1 Fähigkeit',
      _ => 'Rahmenbedingung · $skillCount Fähigkeiten',
    };
  }
}
