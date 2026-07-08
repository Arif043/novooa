import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import '../../domain/entities/prompt_attachment.dart';

class PromptAttachmentSection extends StatelessWidget {
  const PromptAttachmentSection({
    super.key,
    required this.attachments,
    required this.availableFiles,
    required this.onAttach,
    required this.onDetach,
  });

  final List<PromptAttachment> attachments;
  final List<PromptAttachment> availableFiles;
  final ValueChanged<PromptAttachment> onAttach;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AttachmentHeader(onPressed: () => _showFilePicker(context)),
        const SizedBox(height: AppSpacing.sm),
        if (attachments.isEmpty)
          const _AttachmentEmptyState()
        else
          _AttachmentList(attachments: attachments, onDetach: onDetach),
      ],
    );
  }

  void _showFilePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _AttachmentPickerSheet(
          files: availableFiles,
          selectedIds: attachments.map((file) => file.id).toSet(),
          onAttach: onAttach,
        );
      },
    );
  }
}

class _AttachmentHeader extends StatelessWidget {
  const _AttachmentHeader({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text('Dateien', style: SyscatTheme.taskBody)),
        IconButton(
          tooltip: 'Datei anhängen',
          onPressed: onPressed,
          icon: const Icon(Icons.attach_file),
        ),
      ],
    );
  }
}

class _AttachmentEmptyState extends StatelessWidget {
  const _AttachmentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Keine Datei angehängt.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({required this.attachments, required this.onDetach});

  final List<PromptAttachment> attachments;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: attachments
          .map((attachment) {
            return _AttachmentTile(
              key: ValueKey(attachment.id),
              attachment: attachment,
              onDetach: onDetach,
            );
          })
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

  final PromptAttachment attachment;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(attachment.displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(_metadataFor(attachment)),
      trailing: IconButton(
        tooltip: 'Datei entfernen',
        onPressed: () => onDetach(attachment.id),
        icon: const Icon(Icons.close),
      ),
    );
  }
}

class _AttachmentPickerSheet extends StatelessWidget {
  const _AttachmentPickerSheet({
    required this.files,
    required this.selectedIds,
    required this.onAttach,
  });

  final List<PromptAttachment> files;
  final Set<String> selectedIds;
  final ValueChanged<PromptAttachment> onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: files.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final file = files[index];
          final selected = selectedIds.contains(file.id);
          return ListTile(
            enabled: !selected,
            leading: Icon(
              selected ? Icons.check_circle : Icons.insert_drive_file,
            ),
            title: Text(file.displayName),
            subtitle: Text(_metadataFor(file)),
            onTap: selected ? null : () => _select(context, file),
          );
        },
      ),
    );
  }

  void _select(BuildContext context, PromptAttachment file) {
    onAttach(file);
    Navigator.of(context).pop();
  }
}

String _metadataFor(PromptAttachment attachment) {
  return '${attachment.contentType} · ${_sizeLabel(attachment.sizeBytes)} · Version ${attachment.generation}';
}

String _sizeLabel(int sizeBytes) {
  if (sizeBytes >= 1000000) {
    return '${(sizeBytes / 1000000).toStringAsFixed(1)} MB';
  }
  if (sizeBytes >= 1000) return '${(sizeBytes / 1000).toStringAsFixed(0)} KB';
  return '$sizeBytes B';
}
