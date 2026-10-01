import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../../settings/presentation/widgets/settings_section.dart';
import '../cubits/workspace_import_cubit.dart';
import '../cubits/workspace_import_state.dart';
import 'import_preview.dart';
import 'import_summary.dart';
import 'transfer_category_checklist.dart';
import 'transfer_status_message.dart';

class WorkspaceImportSection extends StatelessWidget {
  const WorkspaceImportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      icon: Icons.file_upload_outlined,
      title: 'Import',
      description:
          'Übernimmt Bereiche aus einer novooa-Export-Datei. Einträge mit '
          'gleicher ID werden überschrieben, vorhandene Daten bleiben erhalten.',
      child: BlocBuilder<WorkspaceImportCubit, WorkspaceImportState>(
        builder: (context, state) => switch (state) {
          ImportIdle() => const _PickFileAction(),
          ImportUploading() => const TransferStatusMessage(
            tone: TransferMessageTone.progress,
            message: 'Datei wird hochgeladen und geprüft …',
          ),
          ImportReady() => ImportPreview(
            staged: state.staged,
            selection: state.selection,
            isApplying: false,
          ),
          ImportApplying() => ImportPreview(
            staged: state.staged,
            selection: state.selection,
            isApplying: true,
          ),
          ImportSucceeded(:final imported) => ImportSummary(imported: imported),
          ImportFailed(:final message) => _ImportFailure(message: message),
        },
      ),
    );
  }
}

class _PickFileAction extends StatelessWidget {
  const _PickFileAction({this.label = 'Export-Datei auswählen'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FilledButton.tonalIcon(
        style: transferButtonStyle,
        onPressed: context.read<WorkspaceImportCubit>().pickFile,
        icon: const Icon(Icons.folder_open_outlined),
        label: Text(label),
      ),
    );
  }
}

class _ImportFailure extends StatelessWidget {
  const _ImportFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TransferStatusMessage(
          tone: TransferMessageTone.error,
          message: message,
        ),
        const SizedBox(height: AppSpacing.md),
        const _PickFileAction(label: 'Erneut versuchen'),
      ],
    );
  }
}
