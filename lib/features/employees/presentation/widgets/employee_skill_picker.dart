import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_skill_attachments_state.dart';

/// Auswahl der Fähigkeiten eines Mitarbeiters aus den vorhandenen Skills.
/// Namen, die es nicht mehr gibt (Skill gelöscht), bleiben sichtbar und lassen
/// sich entfernen — ein Lauf würde sonst mit einer Fehlermeldung abbrechen.
class EmployeeSkillPicker extends StatelessWidget {
  const EmployeeSkillPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeSkillAttachmentsCubit, NodeSkillAttachmentsState>(
      builder: (context, state) => switch (state.status) {
        NodeSkillAttachmentsStatus.loading => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: LinearProgressIndicator(minHeight: 2),
        ),
        NodeSkillAttachmentsStatus.failure => _Hint(
          state.message ?? 'Fähigkeiten konnten nicht geladen werden.',
        ),
        NodeSkillAttachmentsStatus.ready => _Options(
          available: state.skills.map((skill) => skill.name).toList(),
          descriptions: {
            for (final skill in state.skills) skill.name: skill.description,
          },
          selected: selected,
          onChanged: onChanged,
        ),
      },
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.available,
    required this.descriptions,
    required this.selected,
    required this.onChanged,
  });

  final List<String> available;
  final Map<String, String> descriptions;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final missing = selected.where((name) => !available.contains(name));
    if (available.isEmpty && missing.isEmpty) {
      return const _Hint(
        'Noch keine Fähigkeiten vorhanden. Importiere welche unter „Fähigkeiten“.',
      );
    }
    return Column(
      children: [
        for (final name in available)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: selected.contains(name),
            title: Text(name),
            subtitle: (descriptions[name] ?? '').isEmpty
                ? null
                : Text(
                    descriptions[name]!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onChanged: (checked) => onChanged(_toggled(name, checked == true)),
          ),
        for (final name in missing)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(name),
            subtitle: const Text('Nicht mehr vorhanden'),
            trailing: IconButton(
              tooltip: 'Fähigkeit „$name“ entfernen',
              icon: const Icon(Icons.close),
              onPressed: () => onChanged(_toggled(name, false)),
            ),
          ),
      ],
    );
  }

  List<String> _toggled(String name, bool add) {
    final next = selected.where((current) => current != name).toList();
    if (add) next.add(name);
    return next;
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
