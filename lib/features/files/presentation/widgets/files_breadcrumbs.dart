import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';

class FilesBreadcrumbs extends StatelessWidget {
  const FilesBreadcrumbs({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
          ),
          child: const Text('Alle Dateien'),
          onPressed: context.read<FilesCubit>().openRoot,
        ),
        for (final folder in state.breadcrumbs) ...[
          const Icon(Icons.chevron_right, size: AppSpacing.md),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
            ),
            child: Text(folder.name, overflow: TextOverflow.ellipsis),
            onPressed: () => context.read<FilesCubit>().openFolder(folder.id),
          ),
        ],
      ],
    );
  }
}
