import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/knowledge_attachment.dart';

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

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return _PickerSheet(
          notes: availableNotes,
          selectedIds: attachments.map((note) => note.id).toSet(),
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
        Expanded(child: Text('Wissensbasis', style: SyscatTheme.taskBody)),
        IconButton(
          tooltip: 'Notiz anhängen',
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
      'Keine Notiz angehängt.',
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
      leading: Icon(_iconFor(attachment.type)),
      title: Text(attachment.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(_metadataFor(attachment)),
      trailing: IconButton(
        tooltip: 'Notiz entfernen',
        onPressed: () => onDetach(attachment.id),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.notes,
    required this.selectedIds,
    required this.onAttach,
  });

  final List<KnowledgeAttachment> notes;
  final Set<String> selectedIds;
  final ValueChanged<KnowledgeAttachment> onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: notes.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final note = notes[index];
          final selected = selectedIds.contains(note.id);
          return ListTile(
            enabled: !selected,
            leading: Icon(selected ? Icons.check_circle : _iconFor(note.type)),
            title: Text(note.title),
            subtitle: Text(_metadataFor(note)),
            onTap: selected ? null : () => _select(context, note),
          );
        },
      ),
    );
  }

  void _select(BuildContext context, KnowledgeAttachment note) {
    onAttach(note);
    Navigator.of(context).pop();
  }
}

IconData _iconFor(KnowledgeAttachmentType type) {
  return switch (type) {
    KnowledgeAttachmentType.moc => Icons.account_tree_outlined,
    KnowledgeAttachmentType.atomic => Icons.notes_outlined,
    KnowledgeAttachmentType.unknown => Icons.article_outlined,
  };
}

String _metadataFor(KnowledgeAttachment attachment) {
  return '${_typeLabelFor(attachment.type)} · ${attachment.path}';
}

String _typeLabelFor(KnowledgeAttachmentType type) {
  return switch (type) {
    KnowledgeAttachmentType.atomic => 'Atomare Notiz',
    KnowledgeAttachmentType.moc => 'MOC',
    KnowledgeAttachmentType.unknown => 'Notiz',
  };
}
