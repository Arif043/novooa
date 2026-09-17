import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/file_content_kind.dart';
import '../../domain/entities/team_file.dart';
import '../cubits/file_detail_state.dart';
import 'content/image_content_view.dart';
import 'content/text_content_view.dart';
import 'content/unsupported_content_view.dart';

/// Picks the right viewer/editor for [file]'s content type (Strategy
/// pattern) and shows the four standard async states: loading, error,
/// empty (unsupported type) and success.
class FileContentViewer extends StatelessWidget {
  const FileContentViewer({
    super.key,
    required this.file,
    required this.state,
    this.classifier = const FileContentKindClassifier(),
  });

  final TeamFile file;
  final FileDetailState state;
  final FileContentKindClassifier classifier;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ContentTypeLabel(file: file),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _Body(file: file, state: state, classifier: classifier)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.file, required this.state, required this.classifier});

  final TeamFile file;
  final FileDetailState state;
  final FileContentKindClassifier classifier;

  @override
  Widget build(BuildContext context) {
    final bytes = state.bytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (classifier.classify(file.contentType)) {
      FileContentKind.text => TextContentView(state: state),
      FileContentKind.image => ImageContentView(file: file, bytes: bytes),
      FileContentKind.unsupported => UnsupportedContentView(file: file),
    };
  }
}

class _ContentTypeLabel extends StatelessWidget {
  const _ContentTypeLabel({required this.file});

  final TeamFile file;

  @override
  Widget build(BuildContext context) {
    return Text(file.contentType, style: Theme.of(context).textTheme.bodySmall);
  }
}
