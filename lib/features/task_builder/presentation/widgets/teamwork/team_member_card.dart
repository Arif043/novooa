import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/employees/presentation/widgets/employee_avatar.dart';

import '../../../domain/entities/node_config.dart';
import '../node_language_model_field.dart';

/// Ein Mitarbeiter im Team: wer er ist, wofür er hier zuständig ist und mit
/// welchem Modell er arbeitet. Gibt es ihn nicht mehr, steht das da.
class TeamMemberCard extends StatefulWidget {
  const TeamMemberCard({
    super.key,
    required this.member,
    required this.employee,
    required this.lookupReady,
    required this.onChanged,
    required this.onRemove,
  });

  final TeamMember member;

  /// `null`: noch nicht geladen oder gelöscht (siehe [lookupReady]).
  final Employee? employee;

  /// Die Liste ist geladen; vorher wäre „nicht mehr vorhanden“ voreilig.
  final bool lookupReady;
  final ValueChanged<TeamMember> onChanged;
  final VoidCallback onRemove;

  @override
  State<TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<TeamMemberCard> {
  late final TextEditingController _responsibility = TextEditingController(
    text: widget.member.responsibility,
  );

  @override
  void didUpdateWidget(TeamMemberCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final text = widget.member.responsibility;
    if (_responsibility.text != text) _responsibility.text = text;
  }

  @override
  void dispose() {
    _responsibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberHeader(
              employeeId: widget.member.employeeId,
              employee: widget.employee,
              missing: widget.employee == null && widget.lookupReady,
              onRemove: widget.onRemove,
            ),
            TextField(
              controller: _responsibility,
              minLines: 1,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_teamwork_responsibility.tr(),
                hintText: LocaleKeys.ui_teamwork_responsibility_hint.tr(),
                errorText: widget.member.hasResponsibility
                    ? null
                    : LocaleKeys.ui_teamwork_responsibility_required.tr(),
              ),
              onChanged: (text) => widget.onChanged(
                widget.member.copyWith(responsibility: text),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            NodeLanguageModelField(
              selectedModelId: widget.member.languageModelId,
              onChanged: (modelId) => widget.onChanged(
                widget.member.copyWith(languageModelId: modelId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.employeeId,
    required this.employee,
    required this.missing,
    required this.onRemove,
  });

  final String employeeId;
  final Employee? employee;
  final bool missing;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name =
        employee?.name ?? (missing ? LocaleKeys.ui_employee_gone.tr() : '…');
    return Row(
      children: [
        if (missing)
          Icon(
            Icons.warning_amber_rounded,
            color: colors.error,
            semanticLabel: LocaleKeys.ui_employee_gone.tr(),
          )
        else
          EmployeeAvatar(employeeId: employeeId),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_teamwork_remove_member.tr(),
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
