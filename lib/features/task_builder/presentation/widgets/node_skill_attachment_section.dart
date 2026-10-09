import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/skill_attachment.dart';
import '../cubits/node_skill_attachments_cubit.dart';
import '../cubits/node_skill_attachments_state.dart';
import 'skill_attachment_section.dart';

class NodeSkillAttachmentSection extends StatelessWidget {
  const NodeSkillAttachmentSection({
    super.key,
    required this.attachments,
    required this.onAttach,
    required this.onDetach,
  });

  final List<SkillAttachment> attachments;
  final ValueChanged<SkillAttachment> onAttach;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeSkillAttachmentsCubit, NodeSkillAttachmentsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkillAttachmentSection(
              attachments: attachments,
              availableSkills: state.skills,
              canAttach:
                  state.status == NodeSkillAttachmentsStatus.ready &&
                  state.skills.isNotEmpty,
              onAttach: onAttach,
              onDetach: onDetach,
            ),
            _SkillStatusHint(state: state),
          ],
        );
      },
    );
  }
}

class _SkillStatusHint extends StatelessWidget {
  const _SkillStatusHint({required this.state});

  final NodeSkillAttachmentsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      NodeSkillAttachmentsStatus.loading => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      NodeSkillAttachmentsStatus.failure => _RetryHint(
        message: state.message ?? LocaleKeys.ui_skills_load_failed.tr(),
      ),
      NodeSkillAttachmentsStatus.ready when state.skills.isEmpty =>
        const _TextHint('Noch keine Fähigkeiten angelegt.'),
      NodeSkillAttachmentsStatus.ready => const SizedBox.shrink(),
    };
  }
}

class _RetryHint extends StatelessWidget {
  const _RetryHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: _TextHint(message)),
          TextButton(
            onPressed: context.read<NodeSkillAttachmentsCubit>().load,
            child: Text(LocaleKeys.ui_erneut_versuchen.tr()),
          ),
        ],
      ),
    );
  }
}

class _TextHint extends StatelessWidget {
  const _TextHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}
