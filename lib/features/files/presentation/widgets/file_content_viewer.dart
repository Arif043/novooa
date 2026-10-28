import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/file_content_kind.dart';
import '../cubits/file_detail_state.dart';
import 'content/image_content_view.dart';
import 'content/pdf_content_view.dart';
import 'content/spreadsheet_content_view.dart';
import 'content/text_content_view.dart';
import 'content/unsupported_content_view.dart';

/// Wählt die Ansicht zur Dateiart (Strategy) und zeigt Laden, Fehler,
/// keine Vorschau und Inhalt.
class FileContentViewer extends StatelessWidget {
  const FileContentViewer({
    super.key,
    required this.state,
    required this.isSaving,
    required this.onSaveText,
    required this.onDownload,
    required this.onRetry,
    this.classifier = const FileContentKindClassifier(),
  });

  final FileDetailReady state;
  final bool isSaving;
  final ValueChanged<String> onSaveText;
  final VoidCallback onDownload;
  final VoidCallback onRetry;
  final FileContentKindClassifier classifier;

  @override
  Widget build(BuildContext context) {
    return switch (state.content) {
      FileContentLoading() => const Center(child: CircularProgressIndicator()),
      FileContentFailed() => _ContentError(onRetry: onRetry),
      FileContentLoaded(:final bytes) => _viewFor(bytes),
    };
  }

  Widget _viewFor(Uint8List bytes) {
    final file = state.file;
    return switch (classifier.classify(
      file.contentType,
      fileName: file.displayName,
    )) {
      FileContentKind.text => TextContentView(
        bytes: bytes,
        versionId: state.selectedVersionId,
        isSaving: isSaving,
        onSave: onSaveText,
      ),
      FileContentKind.image => ImageContentView(file: file, bytes: bytes),
      FileContentKind.pdf => PdfContentView(bytes: bytes),
      FileContentKind.spreadsheet => SpreadsheetContentView(bytes: bytes),
      FileContentKind.unsupported => UnsupportedContentView(
        file: file,
        onDownload: onDownload,
      ),
    };
  }
}

class _ContentError extends StatelessWidget {
  const _ContentError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LocaleKeys.files_content_load_failed.tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(LocaleKeys.ui_erneut_versuchen.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
