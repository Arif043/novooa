import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/transfer_counts.dart';
import '../cubits/workspace_import_cubit.dart';
import 'transfer_category_checklist.dart';
import 'transfer_status_message.dart';

class ImportSummary extends StatelessWidget {
  const ImportSummary({super.key, required this.imported});

  final TransferCounts imported;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TransferStatusMessage(
          tone: TransferMessageTone.success,
          message: 'Import abgeschlossen.',
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final category in imported.categories)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: Text(category.label),
            trailing: Text(
              '${imported.countOf(category)} ${category.countLabel}',
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            style: transferButtonStyle,
            onPressed: context.read<WorkspaceImportCubit>().reset,
            child: const Text('Weitere Datei importieren'),
          ),
        ),
      ],
    );
  }
}
