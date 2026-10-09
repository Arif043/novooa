import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_attachment.dart';
import '../cubits/node_knowledge_attachments_cubit.dart';
import '../cubits/node_knowledge_attachments_state.dart';
import 'knowledge_attachment_section.dart';

class NodeKnowledgeAttachmentSection extends StatelessWidget {
  const NodeKnowledgeAttachmentSection({
    super.key,
    required this.attachments,
    required this.onAttach,
    required this.onDetach,
  });

  final List<KnowledgeAttachment> attachments;
  final ValueChanged<KnowledgeAttachment> onAttach;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NodeKnowledgeAttachmentsCubit,
      NodeKnowledgeAttachmentsState
    >(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KnowledgeAttachmentSection(
              attachments: attachments,
              availableNotes: state.notes,
              canAttach:
                  state.status == NodeKnowledgeAttachmentsStatus.ready &&
                  state.notes.isNotEmpty,
              onAttach: onAttach,
              onDetach: onDetach,
            ),
            _KnowledgeStatusHint(state: state),
          ],
        );
      },
    );
  }
}

class _KnowledgeStatusHint extends StatelessWidget {
  const _KnowledgeStatusHint({required this.state});

  final NodeKnowledgeAttachmentsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      NodeKnowledgeAttachmentsStatus.loading => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      NodeKnowledgeAttachmentsStatus.failure => _RetryHint(
        message: state.message ?? LocaleKeys.ui_notes_load_failed.tr(),
      ),
      NodeKnowledgeAttachmentsStatus.ready when state.notes.isEmpty =>
        _TextHint(LocaleKeys.ui_no_knowledge_notes_imported.tr()),
      NodeKnowledgeAttachmentsStatus.ready => const SizedBox.shrink(),
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
            onPressed: context.read<NodeKnowledgeAttachmentsCubit>().load,
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
