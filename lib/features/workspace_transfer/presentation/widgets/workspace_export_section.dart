import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../../settings/presentation/widgets/settings_section.dart';
import '../../domain/entities/transfer_category.dart';
import '../cubits/workspace_export_cubit.dart';
import '../cubits/workspace_export_state.dart';
import 'transfer_category_checklist.dart';
import 'transfer_status_message.dart';

class WorkspaceExportSection extends StatelessWidget {
  const WorkspaceExportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.file_download_outlined,
      title: 'Export',
      description:
          'Sichert die ausgewählten Bereiche als ZIP-Datei. Trigger, '
          'Ausführungen und Zugangsdaten sind nicht enthalten.',
      child: BlocBuilder<WorkspaceExportCubit, WorkspaceExportState>(
        builder: (context, state) => _ExportForm(state: state),
      ),
    );
  }
}

class _ExportForm extends StatelessWidget {
  const _ExportForm({required this.state});

  final WorkspaceExportState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkspaceExportCubit>();
    final isRunning = state.status is ExportRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransferCategoryChecklist(
          categories: TransferCategory.values,
          selection: state.selection,
          onChanged: isRunning
              ? null
              : (category, selected) =>
                    cubit.toggle(category, selected: selected),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_statusMessage(state) case final message?) ...[
          message,
          const SizedBox(height: AppSpacing.md),
        ],
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            style: transferButtonStyle,
            onPressed: state.canExport ? cubit.export : null,
            icon: const Icon(Icons.file_download_outlined),
            label: Text(
              state.status is ExportFailed ? 'Erneut versuchen' : 'Exportieren',
            ),
          ),
        ),
      ],
    );
  }

  Widget? _statusMessage(WorkspaceExportState state) => switch (state.status) {
    ExportIdle() when state.selection.isEmpty => const TransferStatusMessage(
      tone: TransferMessageTone.error,
      message: 'Wähle mindestens einen Bereich aus.',
    ),
    ExportIdle() => null,
    ExportRunning() => const TransferStatusMessage(
      tone: TransferMessageTone.progress,
      message: 'Export wird erstellt …',
    ),
    ExportSaved() => const TransferStatusMessage(
      tone: TransferMessageTone.success,
      message: 'Export wurde gespeichert.',
    ),
    ExportFailed(:final message) => TransferStatusMessage(
      tone: TransferMessageTone.error,
      message: message,
    ),
  };
}
