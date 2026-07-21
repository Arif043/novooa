import 'package:flutter/cupertino.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/employee_attachment.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/skill_attachment.dart';
import 'node_employee_section.dart';
import 'node_skill_attachment_section.dart';

enum _PromptResourceType { skills, employee }

class PromptResourceSelection extends StatefulWidget {
  const PromptResourceSelection({
    super.key,
    required this.config,
    required this.onAttachSkill,
    required this.onDetachSkill,
    required this.onAssignEmployee,
    required this.onUnassignEmployee,
  });

  final PromptNodeConfig config;
  final ValueChanged<SkillAttachment> onAttachSkill;
  final ValueChanged<String> onDetachSkill;
  final ValueChanged<EmployeeAttachment> onAssignEmployee;
  final VoidCallback onUnassignEmployee;

  @override
  State<PromptResourceSelection> createState() =>
      _PromptResourceSelectionState();
}

class _PromptResourceSelectionState extends State<PromptResourceSelection> {
  late _PromptResourceType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = _typeForConfig();
  }

  @override
  void didUpdateWidget(PromptResourceSelection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.employee != null) _selectedType = .employee;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zuweisung', style: SyscatTheme.taskBody),
        const SizedBox(height: AppSpacing.xs),
        CupertinoSlidingSegmentedControl<_PromptResourceType>(
          groupValue: _selectedType,
          backgroundColor: SyscatTheme.surfaceContainer,
          thumbColor: SyscatTheme.glassSurface,
          children: const {
            _PromptResourceType.skills: Text('Fähigkeiten'),
            _PromptResourceType.employee: Text('Mitarbeiter'),
          },
          onValueChanged: _selectType,
        ),
        const SizedBox(height: AppSpacing.md),
        _selection(),
      ],
    );
  }

  _PromptResourceType _typeForConfig() {
    return widget.config.employee == null ? .skills : .employee;
  }

  Widget _selection() {
    return switch (_selectedType) {
      .skills => NodeSkillAttachmentSection(
        attachments: widget.config.skillAttachments,
        onAttach: widget.onAttachSkill,
        onDetach: widget.onDetachSkill,
      ),
      .employee => NodeEmployeeSection(
        assigned: widget.config.employee,
        onAssign: widget.onAssignEmployee,
        onUnassign: widget.onUnassignEmployee,
      ),
    };
  }

  void _selectType(_PromptResourceType? type) {
    if (type == null || type == _selectedType) return;
    setState(() => _selectedType = type);
    if (type == .skills && widget.config.employee != null) {
      widget.onUnassignEmployee();
    }
    if (type == .employee) _detachSkills();
  }

  void _detachSkills() {
    for (final attachment in widget.config.skillAttachments) {
      widget.onDetachSkill(attachment.id);
    }
  }
}
