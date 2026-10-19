import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/presentation/widgets/employee_avatar.dart';

import '../../../domain/entities/node_config.dart';
import '../../cubits/node_employee_assignments_cubit.dart';
import '../../cubits/node_employee_assignments_state.dart';
import '../attachment_picker_sheet.dart';
import '../field_helper_text.dart';
import 'team_member_card.dart';

/// Die Mitarbeiter des Teams. Der Baustein kennt nur ihre IDs; Name und
/// Fähigkeiten kommen aus der Live-Liste der Mitarbeiter.
class TeamMemberSection extends StatelessWidget {
  const TeamMemberSection({
    super.key,
    required this.config,
    required this.onAdd,
    required this.onChanged,
    required this.onRemove,
  });

  final TeamworkNodeConfig config;
  final ValueChanged<String> onAdd;
  final ValueChanged<TeamMember> onChanged;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NodeEmployeeAssignmentsCubit,
      NodeEmployeeAssignmentsState
    >(
      builder: (context, state) {
        final ready = state.status == NodeEmployeeAssignmentsStatus.ready;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onAdd: ready && config.canAddMember && state.employees.isNotEmpty
                  ? () => _pick(context, state.employees)
                  : null,
            ),
            _StatusHint(state: state),
            if (config.members.isEmpty)
              FieldHelperText(LocaleKeys.ui_teamwork_no_members.tr()),
            for (final member in config.members)
              TeamMemberCard(
                key: ValueKey(member.employeeId),
                member: member,
                employee: _employeeFor(state.employees, member.employeeId),
                lookupReady: ready,
                onChanged: onChanged,
                onRemove: () => onRemove(member.employeeId),
              ),
            if (!config.canAddMember)
              FieldHelperText(
                LocaleKeys.ui_teamwork_team_full.tr(
                  namedArgs: {'max': '${TeamworkNodeConfig.maximumMembers}'},
                ),
              ),
          ],
        );
      },
    );
  }

  Employee? _employeeFor(List<Employee> employees, String id) {
    for (final employee in employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  Future<void> _pick(BuildContext context, List<Employee> employees) async {
    final taken = {for (final member in config.members) member.employeeId};
    final pickedId = await AttachmentPickerSheet.show(
      context,
      title: LocaleKeys.ui_teamwork_add_member.tr(),
      emptyMessage: LocaleKeys.ui_no_employees_yet.tr(),
      selectedIds: taken,
      items: [
        for (final employee in employees)
          if (!taken.contains(employee.id))
            AttachmentPickerItem(
              id: employee.id,
              title: employee.name,
              subtitle: employee.constraint.split('\n').first,
              leading: EmployeeAvatar(employeeId: employee.id),
            ),
      ],
    );
    if (pickedId != null) onAdd(pickedId);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.ui_teamwork_team.tr(),
            style: SyscatTheme.taskBody,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_teamwork_add_member.tr(),
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ],
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
        padding: EdgeInsets.only(bottom: AppSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      NodeEmployeeAssignmentsStatus.failure => FieldHelperText(
        state.message ?? LocaleKeys.ui_employees_load_failed.tr(),
      ),
      NodeEmployeeAssignmentsStatus.ready when state.employees.isEmpty =>
        FieldHelperText(LocaleKeys.ui_no_employees_yet.tr()),
      NodeEmployeeAssignmentsStatus.ready => const SizedBox.shrink(),
    };
  }
}
