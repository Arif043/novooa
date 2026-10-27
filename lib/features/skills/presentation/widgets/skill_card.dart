import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/luminous_card.dart';

import '../../domain/entities/skill.dart';
import '../cubits/skills_cubit.dart';
import 'skill_delete_dialog.dart';

/// Eine Fähigkeit als Karte im Stil des Zeitplans: Symbol, Name und Beschreibung oben,
/// Dateien und Lizenz in der Fußzeile, Löschen rechts.
class SkillCard extends StatelessWidget {
  const SkillCard({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LuminousCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuminousCardHeading(
            icon: Icons.auto_awesome_outlined,
            title: skill.name,
            subtitle: skill.description,
            subtitleMaxLines: 3,
          ),
          for (final warning in skill.warnings) _Warning(text: warning),
          const SizedBox(height: AppSpacing.gutter),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          _Footer(skill: skill, onDelete: () => _delete(context)),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<SkillsCubit>();
    if (await confirmSkillDeletion(context, skill.name)) {
      await cubit.delete(skill.name);
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.skill, required this.onDelete});

  final Skill skill;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Text(_details, style: theme.textTheme.bodySmall),
        IconButton(
          tooltip: LocaleKeys.ui_skill_delete_tooltip.tr(
            namedArgs: {'name': skill.name},
          ),
          onPressed: onDelete,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xxl,
            minHeight: AppSpacing.xxl,
          ),
          icon: Icon(
            CupertinoIcons.trash,
            size: AppSpacing.gutter,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String get _details => [
    skill.fileCount == 1
        ? LocaleKeys.ui_skill_files_one.tr()
        : LocaleKeys.ui_skill_files_other.tr(
            namedArgs: {'count': '${skill.fileCount}'},
          ),
    ?skill.license,
  ].join(' · ');
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: AppSpacing.md,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
