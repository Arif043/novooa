import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/skill.dart';
import '../cubits/skills_cubit.dart';

class SkillListTile extends StatelessWidget {
  const SkillListTile({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(skill: skill, onDelete: () => _confirmDelete(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              skill.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium,
            ),
            if (skill.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                skill.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(_fileCountLabel, style: textTheme.bodySmall),
            for (final warning in skill.warnings) _Warning(text: warning),
          ],
        ),
      ),
    );
  }

  String get _fileCountLabel =>
      skill.fileCount == 1 ? '1 Datei' : '${skill.fileCount} Dateien';

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

class _Header extends StatelessWidget {
  const _Header({required this.skill, required this.onDelete});

  final Skill skill;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Fähigkeit „${skill.name}“ löschen',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
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
