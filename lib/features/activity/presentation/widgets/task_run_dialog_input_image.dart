import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/platform/document_scan_support.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import '../../domain/entities/task_run_media_input.dart';
import 'task_run_media_picking.dart';

/// Bildfeld eines Formulars. Die Quelle wählt die Person hier, auch ob sie
/// ein Dokument scannt; der Baustein legt das nicht fest.
class TaskRunDialogInputImage extends StatefulWidget {
  const TaskRunDialogInputImage({
    super.key,
    required this.field,
    required this.value,
    required this.onValueChanged,
  });

  final TaskRunDialogInputField field;
  final MediaInputSubmission? value;
  final void Function(String name, Object? value) onValueChanged;

  @override
  State<TaskRunDialogInputImage> createState() =>
      _TaskRunDialogInputImageState();
}

class _TaskRunDialogInputImageState extends State<TaskRunDialogInputImage> {
  var _isPicking = false;

  Future<void> _pick(
    FormFieldState<MediaInputSubmission> field,
    TaskRunMediaInputSource source,
  ) async {
    setState(() => _isPicking = true);
    try {
      final submission = await pickImageSubmission(context, source);
      if (submission != null) _set(field, submission);
    } on Object {
      if (mounted) _showPickFailed();
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _set(
    FormFieldState<MediaInputSubmission> field,
    MediaInputSubmission? submission,
  ) {
    field.didChange(submission);
    widget.onValueChanged(widget.field.name, submission);
  }

  void _showPickFailed() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(LocaleKeys.image_field_pick_failed.tr())),
  );

  @override
  Widget build(BuildContext context) {
    return FormField<MediaInputSubmission>(
      initialValue: widget.value,
      validator: (value) =>
          value == null ? LocaleKeys.image_field_required.tr() : null,
      builder: (field) => InputDecorator(
        decoration: InputDecoration(
          labelText: widget.field.name,
          errorText: field.errorText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        child: field.value == null
            ? _ImageSourceButtons(
                isPicking: _isPicking,
                onPick: (source) => _pick(field, source),
              )
            : _ImagePreview(
                submission: field.value!,
                onRemove: () => _set(field, null),
              ),
      ),
    );
  }
}

class _ImageSourceButtons extends StatelessWidget {
  const _ImageSourceButtons({required this.isPicking, required this.onPick});

  final bool isPicking;
  final ValueChanged<TaskRunMediaInputSource> onPick;

  @override
  Widget build(BuildContext context) {
    final sources = [
      (
        TaskRunMediaInputSource.camera,
        Icons.photo_camera_outlined,
        LocaleKeys.image_field_camera,
      ),
      (
        TaskRunMediaInputSource.gallery,
        Icons.add_photo_alternate_outlined,
        LocaleKeys.image_field_gallery,
      ),
      if (documentScanSupportedOnThisPlatform())
        (
          TaskRunMediaInputSource.documentScan,
          Icons.document_scanner_outlined,
          LocaleKeys.image_field_scan,
        ),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (source, icon, label) in sources)
          OutlinedButton.icon(
            onPressed: isPicking ? null : () => onPick(source),
            icon: Icon(icon),
            label: Text(label.tr()),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.submission, required this.onRemove});

  final MediaInputSubmission submission;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Image.memory(
            submission.bytes,
            fit: BoxFit.cover,
            semanticLabel: LocaleKeys.image_field_selected.tr(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(submission.name, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              tooltip: LocaleKeys.image_field_remove.tr(),
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
    );
  }
}
