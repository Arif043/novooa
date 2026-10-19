import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/presentation/widgets/employee_avatar.dart';
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
            employeeId: assignedId!,
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
      title: LocaleKeys.ui_mitarbeiter_zuweisen.tr(),
      emptyMessage: LocaleKeys.ui_no_employees_yet.tr(),
      selectedIds: {?assignedId},
      items: [
        for (final employee in employees)
          AttachmentPickerItem(
            id: employee.id,
            title: employee.name,
            subtitle: _subtitleFor(employee),
            leading: EmployeeAvatar(employeeId: employee.id),
          ),
      ],
    );
    if (pickedId != null) onAssign(pickedId);
  }

  String _subtitleFor(Employee employee) {
    final count = employee.skillNames.length;
    return switch (count) {
      0 => LocaleKeys.ui_constraint_no_skills.tr(),
      1 => LocaleKeys.ui_constraint_one_skill.tr(),
      _ => LocaleKeys.ui_constraint_skill_count.tr(
        namedArgs: {'count': '$count'},
      ),
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
        Expanded(
          child: Text(
            LocaleKeys.ui_mitarbeiter.tr(),
            style: SyscatTheme.taskBody,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_mitarbeiter_zuweisen.tr(),
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
      LocaleKeys.ui_kein_mitarbeiter_zugewiesen.tr(),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _AssignedTile extends StatelessWidget {
  const _AssignedTile({
    required this.employeeId,
    required this.employee,
    required this.lookupReady,
    required this.onUnassign,
  });

  final String employeeId;
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
      leading: missing
          ? Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            )
          : EmployeeAvatar(employeeId: employeeId),
      title: Text(
        employee?.name ?? (missing ? LocaleKeys.ui_employee_gone.tr() : '…'),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: employee == null
          ? (missing
                ? Text(LocaleKeys.ui_waehle_einen_anderen_mitarbeiter.tr())
                : null)
          : Text(_skillDescription(employee.skillNames.length)),
      trailing: IconButton(
        tooltip: LocaleKeys.ui_mitarbeiter_entfernen.tr(),
        onPressed: onUnassign,
        icon: const Icon(Icons.close),
      ),
    );
  }

  String _skillDescription(int skillCount) {
    return switch (skillCount) {
      0 => LocaleKeys.ui_constraint_no_skills.tr(),
      1 => LocaleKeys.ui_constraint_one_skill.tr(),
      _ => LocaleKeys.ui_constraint_skill_count.tr(
        namedArgs: {'count': '$skillCount'},
      ),
    };
  }
}
