import 'package:flutter/material.dart';

import '../cubits/files_state.dart';
import 'files_action_bar.dart';
import 'files_breadcrumbs.dart';

/// Titel links, Aktionen rechts — wie die Kopfzeile des Zeitplans.
class FilesHeader extends StatelessWidget {
  const FilesHeader({super.key, required this.state});
  final FilesState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 16,
            children: [
              Text('Dateien', style: theme.textTheme.headlineLarge),
              FilesActionBar(state: state),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Dokumente und Inhalte an einem Ort.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (state.currentFolderId != null) ...[
          const SizedBox(height: 24),
          FilesBreadcrumbs(state: state),
        ],
      ],
    );
  }
}
