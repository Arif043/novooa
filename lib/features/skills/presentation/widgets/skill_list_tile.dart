import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/skill.dart';
import '../cubits/skills_cubit.dart';

class SkillListTile extends StatelessWidget {
  const SkillListTile({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: SyscatTheme.nodePanelDecoration(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs),
            child: Icon(Icons.auto_awesome_outlined),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _Details(skill: skill)),
          IconButton(
            tooltip: 'Fähigkeit „${skill.name}“ löschen',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<SkillsCubit>();
    final confirmed = await showIosDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Fähigkeit löschen?'),
        content: Text(
          'Der Ordner „${skill.name}“ wird samt allen Dateien endgültig entfernt.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete(skill.name);
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(skill.name, style: SyscatTheme.taskBody),
        if (skill.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            skill.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: SyscatTheme.taskBodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        Text(
          skill.fileCount == 1 ? '1 Datei' : '${skill.fileCount} Dateien',
          style: textTheme.bodySmall,
        ),
        for (final warning in skill.warnings) _Warning(text: warning),
      ],
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppSpacing.md,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
