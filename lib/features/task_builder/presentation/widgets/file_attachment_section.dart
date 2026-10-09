import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import '../../domain/entities/node_attachment.dart';
import 'attachment_picker_sheet.dart';

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

  Future<void> _showFilePicker(BuildContext context) async {
    final pickedId = await AttachmentPickerSheet.show(
      context,
      title: LocaleKeys.ui_datei_anhaengen.tr(),
      emptyMessage: LocaleKeys.ui_no_files_uploaded_yet.tr(),
      selectedIds: attachments.map((file) => file.id).toSet(),
      items: [
        for (final file in availableFiles)
          AttachmentPickerItem(
            id: file.id,
            title: file.displayName,
            subtitle: _metadataFor(context, file),
            icon: Icons.insert_drive_file,
          ),
      ],
    );
    if (pickedId == null) return;
    onAttach(availableFiles.firstWhere((file) => file.id == pickedId));
  }
}

class _AttachmentHeader extends StatelessWidget {
  const _AttachmentHeader({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(LocaleKeys.ui_dateien.tr(), style: SyscatTheme.taskBody),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_datei_anhaengen.tr(),
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
      LocaleKeys.ui_keine_datei_angehaengt.tr(),
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
        tooltip: LocaleKeys.ui_datei_entfernen.tr(),
        onPressed: () => onDetach(attachment.id),
        icon: const Icon(Icons.close),
      ),
    );
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
