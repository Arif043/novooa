import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/skill_attachment_section.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';

/// Dialog zum Erstellen und Bearbeiten eines Mitarbeiters. Der Aufrufer
/// stellt einen [NodeSkillAttachmentsCubit] als BlocProvider bereit, damit
/// wir die verfügbaren Team-Skills für die Default-Skill-Auswahl kennen.
class EmployeeEditorDialog extends StatefulWidget {
  const EmployeeEditorDialog({super.key, this.initial});

  final Employee? initial;

  @override
  State<EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<EmployeeEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _promptTemplateController;
  late List<SkillAttachment> _defaultSkills;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _roleController = TextEditingController(text: initial?.role ?? '');
    _promptTemplateController = TextEditingController(
      text: initial?.promptTemplate ?? '{{instruction}}',
    );
    _defaultSkills = List.of(initial?.defaultSkills ?? const []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _promptTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'Mitarbeiter bearbeiten' : 'Mitarbeiter anlegen'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z. B. Rezeption',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Rolle (System-Prompt)',
                  hintText:
                      'Beschreibe, wer der Mitarbeiter ist und wie er '
                      'antwortet.',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _promptTemplateController,
                decoration: const InputDecoration(
                  labelText: 'Prompt-Vorlage',
                  hintText:
                      'Nutze {{instruction}}, um die Baustein-Anweisung '
                      'einzusetzen.',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: AppSpacing.md),
              _DefaultSkillsSection(
                selectedSkills: _defaultSkills,
                onChanged: _setDefaultSkills,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Speichern' : 'Anlegen'),
        ),
      ],
    );
  }

  void _setDefaultSkills(List<SkillAttachment> skills) {
    setState(() => _defaultSkills = skills);
  }

  void _submit() {
    final draft = EmployeeDraft(
      name: _nameController.text,
      role: _roleController.text,
      promptTemplate: _promptTemplateController.text,
      defaultSkills: _defaultSkills,
    );
    Navigator.of(context).pop(draft);
  }
}

class _DefaultSkillsSection extends StatelessWidget {
  const _DefaultSkillsSection({
    required this.selectedSkills,
    required this.onChanged,
  });

  final List<SkillAttachment> selectedSkills;
  final ValueChanged<List<SkillAttachment>> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeSkillAttachmentsCubit, NodeSkillAttachmentsState>(
      builder: (context, state) {
        return SkillAttachmentSection(
          attachments: selectedSkills,
          availableSkills: state.skills,
          canAttach:
              state.status == NodeSkillAttachmentsStatus.ready &&
              state.skills.isNotEmpty,
          onAttach: (attachment) =>
              onChanged([...selectedSkills, attachment]),
          onDetach: (id) => onChanged(
            selectedSkills.where((skill) => skill.id != id).toList(
              growable: false,
            ),
          ),
        );
      },
    );
  }
}
