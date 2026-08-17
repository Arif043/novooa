import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/media_input_submission.dart';

class TaskRunMediaInputForm extends StatelessWidget {
  const TaskRunMediaInputForm({
    super.key,
    required this.submission,
    required this.isPicking,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
    required this.onClear,
  });

  final MediaInputSubmission? submission;
  final bool isPicking;
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = submission;
    if (selected == null) return _sourceButtons();
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

  Widget _sourceButtons() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        OutlinedButton.icon(
          onPressed: isPicking ? null : onPickFromCamera,
          icon: _icon(Icons.photo_camera_outlined),
          label: const Text('Kamera öffnen'),
        ),
        OutlinedButton.icon(
          onPressed: isPicking ? null : onPickFromGallery,
          icon: _icon(Icons.add_photo_alternate_outlined),
          label: const Text('Bild auswählen'),
        ),
      ],
    );
  }

  Widget _icon(IconData icon) {
    if (!isPicking) return Icon(icon);
    return const SizedBox.square(
      dimension: AppSpacing.md,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
