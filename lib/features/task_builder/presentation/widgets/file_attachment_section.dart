import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import '../../domain/entities/node_attachment.dart';

class FileAttachmentSection extends StatelessWidget {
  const FileAttachmentSection({
    super.key,
    required this.attachments,
    required this.availableFiles,
    required this.onAttach,
    required this.onDetach,
    this.canAttach = true,
  });

  final List<NodeAttachment> attachments;
  final List<NodeAttachment> availableFiles;
  final ValueChanged<NodeAttachment> onAttach;
  final ValueChanged<String> onDetach;
  final bool canAttach;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AttachmentHeader(
          onPressed: canAttach ? () => _showFilePicker(context) : null,
        ),
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

  final VoidCallback? onPressed;

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

  final List<NodeAttachment> attachments;
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

  final NodeAttachment attachment;
  final ValueChanged<String> onDetach;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(attachment.displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(_metadataFor(context, attachment)),
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

  final List<NodeAttachment> files;
  final Set<String> selectedIds;
  final ValueChanged<NodeAttachment> onAttach;

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
            subtitle: Text(_metadataFor(context, file)),
            onTap: selected ? null : () => _select(context, file),
          );
        },
      ),
    );
  }

  void _select(BuildContext context, NodeAttachment file) {
    onAttach(file);
    Navigator.of(context).pop();
  }
}

String _metadataFor(BuildContext context, NodeAttachment attachment) {
  final timestamp = attachment.versionCreatedAt;
  final versionTime = timestamp == null
      ? ''
      : ' · ${_formatVersionTime(context, timestamp)}';
  return '${attachment.contentType} · ${_sizeLabel(attachment.sizeBytes)} · Version ${attachment.generation}$versionTime';
}

String _formatVersionTime(BuildContext context, DateTime timestamp) {
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatMediumDate(timestamp);
  final time = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(timestamp));
  return '$date, $time';
}

String _sizeLabel(int sizeBytes) {
  if (sizeBytes >= 1000000) {
    return '${(sizeBytes / 1000000).toStringAsFixed(1)} MB';
  }
  if (sizeBytes >= 1000) return '${(sizeBytes / 1000).toStringAsFixed(0)} KB';
  return '$sizeBytes B';
}
