import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/skill_attachment.dart';
import 'node_employee_section.dart';
import 'node_skill_attachment_section.dart';

enum _ResourceType { skills, employee }

/// Zuweisung für Bausteine mit LLM-Aufruf: **entweder** ein Mitarbeiter
/// (Rahmenbedingung + dessen Fähigkeiten) **oder** selbst gewählte
/// Fähigkeiten — nie beides. Der Wechsel räumt die andere Seite auf; die
/// Config selbst hält die Regel ebenfalls ein (`resolveNodeDelegation`).
class PromptResourceSelection extends StatefulWidget {
  const PromptResourceSelection({
    super.key,
    required this.employeeId,
    required this.skillAttachments,
    required this.onAttachSkill,
    required this.onDetachSkill,
    required this.onAssignEmployee,
    required this.onUnassignEmployee,
  });

  final String? employeeId;
  final List<SkillAttachment> skillAttachments;
  final ValueChanged<SkillAttachment> onAttachSkill;
  final ValueChanged<String> onDetachSkill;
  final ValueChanged<String> onAssignEmployee;
  final VoidCallback onUnassignEmployee;

  @override
  State<PromptResourceSelection> createState() =>
      _PromptResourceSelectionState();
}

class _PromptResourceSelectionState extends State<PromptResourceSelection> {
  late _ResourceType _selectedType = _typeForConfig();

  @override
  void didUpdateWidget(PromptResourceSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.employeeId != null) _selectedType = .employee;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.ui_zuweisung.tr(), style: SyscatTheme.taskBody),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<_ResourceType>(
            groupValue: _selectedType,
            backgroundColor: SyscatTheme.surfaceContainer,
            thumbColor: SyscatTheme.glassSurface,
            children: {
              _ResourceType.skills: Text(LocaleKeys.ui_faehigkeiten.tr()),
              _ResourceType.employee: Text(LocaleKeys.ui_mitarbeiter.tr()),
            },
            onValueChanged: _selectType,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          LocaleKeys.ui_entweder_ein_mitarbeiter_oder_eigene_faehigkeite.tr(),
          style: SyscatTheme.taskBodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _selection(),
      ],
    );
  }

  _ResourceType _typeForConfig() =>
      widget.employeeId != null ? .employee : .skills;

  Widget _selection() {
    return switch (_selectedType) {
      .skills => NodeSkillAttachmentSection(
        attachments: widget.skillAttachments,
        onAttach: widget.onAttachSkill,
        onDetach: widget.onDetachSkill,
      ),
      .employee => NodeEmployeeSection(
        assignedId: widget.employeeId,
        onAssign: widget.onAssignEmployee,
        onUnassign: widget.onUnassignEmployee,
      ),
    };
  }

  void _selectType(_ResourceType? type) {
    if (type == null || type == _selectedType) return;
    setState(() => _selectedType = type);
    if (type == .skills && widget.employeeId != null) {
      widget.onUnassignEmployee();
    }
    if (type == .employee) _detachSkills();
  }

  void _detachSkills() {
    for (final attachment in widget.skillAttachments) {
      widget.onDetachSkill(attachment.id);
    }
  }
}
