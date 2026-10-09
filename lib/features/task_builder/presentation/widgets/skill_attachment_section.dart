import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

import '../../domain/entities/skill_attachment.dart';

/// Reine Darstellung — kein Bloc-Zugriff. Analog zu
/// [KnowledgeAttachmentSection], damit die beiden Attachment-Typen visuell
/// konsistent bleiben.
class SkillAttachmentSection extends StatelessWidget {
  const SkillAttachmentSection({
    super.key,
    required this.attachments,
    required this.availableSkills,
    required this.onAttach,
    required this.onDetach,
    this.canAttach = true,
  });

  final List<SkillAttachment> attachments;
  final List<SkillAttachment> availableSkills;
  final ValueChanged<SkillAttachment> onAttach;
  final ValueChanged<String> onDetach;
  final bool canAttach;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(onPressed: canAttach ? () => _showPicker(context) : null),
        const SizedBox(height: AppSpacing.sm),
        if (attachments.isEmpty)
          const _EmptyState()
        else
          _AttachmentList(attachments: attachments, onDetach: onDetach),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showIosSheet<void>(
      context: context,
      builder: (_) {
        return _PickerSheet(
          skills: availableSkills,
          selectedIds: attachments.map((skill) => skill.id).toSet(),
          onAttach: onAttach,
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.ui_faehigkeiten.tr(),
            style: SyscatTheme.taskBody,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_faehigkeit_anhaengen.tr(),
          onPressed: onPressed,
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      LocaleKeys.ui_keine_faehigkeit_angehaengt.tr(),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({required this.attachments, required this.onDetach});

  final List<SkillAttachment> attachments;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attachments
          .map(
            (attachment) => _AttachmentTile(
              key: ValueKey(attachment.id),
              attachment: attachment,
              onDetach: onDetach,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    super.key,
    required this.attachment,
    required this.onDetach,
  });

  final SkillAttachment attachment;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(attachment.name, overflow: TextOverflow.ellipsis),
      subtitle: attachment.description.isEmpty
          ? null
          : Text(
              attachment.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: IconButton(
        tooltip: LocaleKeys.ui_faehigkeit_entfernen.tr(),
        onPressed: () => onDetach(attachment.id),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.skills,
    required this.selectedIds,
    required this.onAttach,
  });

  final List<SkillAttachment> skills;
  final Set<String> selectedIds;
  final ValueChanged<SkillAttachment> onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: skills.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final skill = skills[index];
          final selected = selectedIds.contains(skill.id);
          return ListTile(
            enabled: !selected,
            leading: Icon(
              selected ? Icons.check_circle : Icons.auto_awesome_outlined,
            ),
            title: Text(skill.name),
            subtitle: skill.description.isEmpty
                ? null
                : Text(
                    skill.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: selected ? null : () => _select(context, skill),
          );
        },
      ),
    );
  }

  void _select(BuildContext context, SkillAttachment skill) {
    onAttach(skill);
    Navigator.of(context).pop();
  }
}
