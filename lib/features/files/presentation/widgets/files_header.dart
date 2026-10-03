import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_state.dart';
import 'files_action_bar.dart';

class FilesHeader extends StatelessWidget {
  const FilesHeader({super.key, required this.state});
  final FilesState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Dateien', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Dokumente und Inhalte an einem Ort.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      FilesActionBar(state: state),
    ],
  );
}
