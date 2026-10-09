import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/knowledge_attachment.dart';
import 'attachment_picker_sheet.dart';

class KnowledgeAttachmentSection extends StatelessWidget {
  const KnowledgeAttachmentSection({
    super.key,
    required this.attachments,
    required this.availableNotes,
    required this.onAttach,
    required this.onDetach,
    this.canAttach = true,
  });

  final List<KnowledgeAttachment> attachments;
  final List<KnowledgeAttachment> availableNotes;
  final ValueChanged<KnowledgeAttachment> onAttach;
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

  Future<void> _showPicker(BuildContext context) async {
    final pickedId = await AttachmentPickerSheet.show(
      context,
      title: LocaleKeys.ui_notiz_anhaengen.tr(),
      emptyMessage: LocaleKeys.ui_no_notes_in_knowledge_base.tr(),
      selectedIds: attachments.map((note) => note.id).toSet(),
      items: [
        for (final note in availableNotes)
          AttachmentPickerItem(
            id: note.id,
            title: note.title,
            subtitle: _metadataFor(note),
            icon: Icons.note_outlined,
          ),
      ],
    );
    if (pickedId == null) return;
    onAttach(availableNotes.firstWhere((note) => note.id == pickedId));
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
            LocaleKeys.ui_wissensbasis.tr(),
            style: SyscatTheme.taskBody,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_notiz_anhaengen.tr(),
          onPressed: onPressed,
          icon: const Icon(Icons.library_books_outlined),
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
      LocaleKeys.ui_keine_notiz_angehaengt.tr(),
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({required this.attachments, required this.onDetach});

  final List<KnowledgeAttachment> attachments;
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

  final KnowledgeAttachment attachment;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.note_outlined),
      title: Text(attachment.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(_metadataFor(attachment)),
      trailing: IconButton(
        tooltip: LocaleKeys.ui_notiz_entfernen.tr(),
        onPressed: () => onDetach(attachment.id),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

String _metadataFor(KnowledgeAttachment attachment) {
  return attachment.path;
}
