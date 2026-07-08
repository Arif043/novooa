import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/node_attachment.dart';
import '../cubits/node_file_attachments_cubit.dart';
import '../cubits/node_file_attachments_state.dart';
import 'file_attachment_section.dart';

class NodeFileAttachmentSection extends StatelessWidget {
  const NodeFileAttachmentSection({
    super.key,
    required this.attachments,
    required this.onAttach,
    required this.onDetach,
  });

  final List<NodeAttachment> attachments;
  final ValueChanged<NodeAttachment> onAttach;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeFileAttachmentsCubit, NodeFileAttachmentsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileAttachmentSection(
              attachments: attachments,
              availableFiles: state.files,
              canAttach:
                  state.status == NodeFileAttachmentsStatus.ready &&
                  state.files.isNotEmpty,
              onAttach: onAttach,
              onDetach: onDetach,
            ),
            _AttachmentStatusHint(state: state),
          ],
        );
      },
    );
  }
}

class _AttachmentStatusHint extends StatelessWidget {
  const _AttachmentStatusHint({required this.state});

  final NodeFileAttachmentsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      NodeFileAttachmentsStatus.loading => const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      NodeFileAttachmentsStatus.failure => _RetryHint(
        message: state.message ?? 'Dateien konnten nicht geladen werden.',
      ),
      NodeFileAttachmentsStatus.ready when state.files.isEmpty =>
        const _TextHint('Noch keine Dateien hochgeladen.'),
      NodeFileAttachmentsStatus.ready => const SizedBox.shrink(),
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
            onPressed: context.read<NodeFileAttachmentsCubit>().load,
            child: const Text('Erneut versuchen'),
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
