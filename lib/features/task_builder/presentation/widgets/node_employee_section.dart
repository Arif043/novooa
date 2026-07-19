import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/employee_attachment.dart';
import '../cubits/node_employee_assignments_cubit.dart';
import '../cubits/node_employee_assignments_state.dart';

/// UI-Slot für einen Mitarbeiter-Assignment am Baustein. 0..1 Auswahl.
class NodeEmployeeSection extends StatelessWidget {
  const NodeEmployeeSection({
    super.key,
    required this.assigned,
    required this.onAssign,
    required this.onUnassign,
  });

  final EmployeeAttachment? assigned;
  final ValueChanged<EmployeeAttachment> onAssign;
  final VoidCallback onUnassign;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NodeEmployeeAssignmentsCubit,
      NodeEmployeeAssignmentsState
    >(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onPressed: state.status == NodeEmployeeAssignmentsStatus.ready &&
                      state.employees.isNotEmpty
                  ? () => _showPicker(context, state.employees)
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (assigned == null)
              const _EmptyState()
            else
              _AssignedTile(employee: assigned!, onUnassign: onUnassign),
            _StatusHint(state: state),
          ],
        );
      },
    );
  }

  void _showPicker(
    BuildContext context,
    List<EmployeeAttachment> employees,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PickerSheet(
        employees: employees,
        selectedId: assigned?.id,
        onSelect: (employee) {
          onAssign(employee);
          Navigator.of(context).pop();
        },
      ),
    );
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
      subtitle: Text(
        skillCount == 0
            ? 'Rolle · keine Standard-Fähigkeiten'
            : skillCount == 1
                ? 'Rolle · 1 Standard-Fähigkeit'
                : 'Rolle · $skillCount Standard-Fähigkeiten',
      ),
      trailing: IconButton(
        tooltip: 'Mitarbeiter entfernen',
        onPressed: onUnassign,
        icon: const Icon(Icons.close),
      ),
    );
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
        itemBuilder: (context, index) {
          final employee = employees[index];
          final selected = employee.id == selectedId;
          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle : Icons.person_outline,
            ),
            title: Text(employee.name),
            subtitle: employee.role.isEmpty
                ? null
                : Text(
                    employee.role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => onSelect(employee),
          );
        },
      ),
    );
  }
}

class _StatusHint extends StatelessWidget {
  const _StatusHint({required this.state});

  final NodeEmployeeAssignmentsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      NodeEmployeeAssignmentsStatus.loading => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      NodeEmployeeAssignmentsStatus.failure => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          state.message ?? 'Mitarbeiter konnten nicht geladen werden.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      NodeEmployeeAssignmentsStatus.ready when state.employees.isEmpty => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          'Noch keine Mitarbeiter angelegt.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      NodeEmployeeAssignmentsStatus.ready => const SizedBox.shrink(),
    };
  }
}
