import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/employee_attachment.dart';
import '../cubits/node_employee_assignments_cubit.dart';
import '../cubits/node_employee_assignments_state.dart';
import 'employee_assignment_picker.dart';

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
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeAssignmentPicker(
            assigned: assigned,
            employees: state.employees,
            enabled: state.status == NodeEmployeeAssignmentsStatus.ready,
            onAssign: onAssign,
            onUnassign: onUnassign,
          ),
          _StatusHint(state: state),
        ],
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
      NodeEmployeeAssignmentsStatus.failure => _TextHint(
        state.message ?? 'Mitarbeiter konnten nicht geladen werden.',
      ),
      NodeEmployeeAssignmentsStatus.ready when state.employees.isEmpty =>
        const _TextHint('Noch keine Mitarbeiter angelegt.'),
      NodeEmployeeAssignmentsStatus.ready => const SizedBox.shrink(),
    };
  }
}

class _TextHint extends StatelessWidget {
  const _TextHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
