import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/staged_transfer_import.dart';
import '../../domain/entities/transfer_category.dart';
import '../cubits/workspace_import_cubit.dart';
import 'transfer_category_checklist.dart';
import 'transfer_status_message.dart';

/// Zeigt den Inhalt einer geprüften Export-Datei und lässt die zu
/// übernehmenden Bereiche wählen.
class ImportPreview extends StatelessWidget {
  const ImportPreview({
    super.key,
    required this.staged,
    required this.selection,
    required this.isApplying,
  });

  final StagedTransferImport staged;
  final Set<TransferCategory> selection;
  final bool isApplying;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkspaceImportCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Export vom ${_dateTimeLabel(staged.exportedAt)}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TransferCategoryChecklist(
          categories: staged.contents.categories,
          selection: selection,
          counts: staged.contents,
          onChanged: isApplying
              ? null
              : (category, selected) =>
                    cubit.toggle(category, selected: selected),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isApplying)
          const TransferStatusMessage(
            tone: TransferMessageTone.progress,
            message: 'Import läuft …',
          )
        else
          _PreviewActions(canApply: selection.isNotEmpty),
      ],
    );
  }
}

class _PreviewActions extends StatelessWidget {
  const _PreviewActions({required this.canApply});

  final bool canApply;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkspaceImportCubit>();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TextButton(
          style: transferButtonStyle,
          onPressed: cubit.discard,
          child: const Text('Verwerfen'),
        ),
        FilledButton.icon(
          style: transferButtonStyle,
          onPressed: canApply ? cubit.apply : null,
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Importieren'),
        ),
      ],
    );
  }
}

String _dateTimeLabel(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}.${twoDigits(value.month)}.${value.year}, '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)} Uhr';
}
