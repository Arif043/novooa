import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/scanned_document.dart';

/// Vorschau des begradigten Dokuments mit „Wiederholen“ und „Übernehmen“.
class DocumentScanReviewView extends StatelessWidget {
  const DocumentScanReviewView({
    super.key,
    required this.document,
    required this.onRetake,
    required this.onAccept,
  });

  final ScannedDocument document;
  final VoidCallback onRetake;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Image.memory(
              document.bytes,
              fit: BoxFit.contain,
              semanticLabel: 'Gescanntes Dokument',
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Wiederholen'),
                ),
                FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check),
                  label: const Text('Übernehmen'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
