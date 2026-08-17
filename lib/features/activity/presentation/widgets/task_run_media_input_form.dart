import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_media_input.dart';

class TaskRunMediaInputForm extends StatelessWidget {
  const TaskRunMediaInputForm({
    super.key,
    required this.input,
    required this.submission,
    required this.isPicking,
    required this.onPick,
    required this.onClear,
  });

  final TaskRunMediaInput input;
  final MediaInputSubmission? submission;
  final bool isPicking;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = submission;
    if (selected == null) return _captureButton();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          child: Image.memory(
            selected.bytes,
            fit: BoxFit.cover,
            semanticLabel: 'Ausgewähltes Bild',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(selected.name, overflow: TextOverflow.ellipsis),
            ),
            IconButton(
              tooltip: 'Bild entfernen',
              onPressed: onClear,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ],
    );
  }

  Widget _captureButton() {
    return OutlinedButton.icon(
      onPressed: isPicking ? null : onPick,
      icon: isPicking
          ? const SizedBox.square(
              dimension: AppSpacing.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_iconFor(input.source)),
      label: Text(input.source.actionLabel),
    );
  }

  IconData _iconFor(TaskRunMediaInputSource source) {
    return source == TaskRunMediaInputSource.camera
        ? Icons.photo_camera_outlined
        : Icons.add_photo_alternate_outlined;
  }
}
