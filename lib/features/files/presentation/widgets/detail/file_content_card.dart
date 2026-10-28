import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../cubits/file_actions_cubit.dart';
import '../../cubits/file_actions_state.dart';
import '../../cubits/file_detail_cubit.dart';
import '../../cubits/file_detail_state.dart';
import '../file_content_viewer.dart';
import 'file_detail_commands.dart';
import 'old_version_banner.dart';

/// Der Inhalt der gewählten Version in einer Karte, bei einer alten
/// Version mit Hinweis darüber.
class FileContentCard extends StatelessWidget {
  const FileContentCard({
    super.key,
    required this.state,
    required this.commands,
  });

  final FileDetailReady state;
  final FileDetailCommands commands;

  @override
  Widget build(BuildContext context) {
    final selected = state.selectedVersion;
    final cubit = context.read<FileDetailCubit>();
    return LuminousCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selected != null && state.isViewingOldVersion) ...[
              OldVersionBanner(
                version: selected,
                onRestore: () => commands.restore(selected),
                onShowCurrent: cubit.showCurrentVersion,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: BlocBuilder<FileActionsCubit, FileActionsState>(
                buildWhen: (previous, current) =>
                    previous.isRunning(FileAction.saveText) !=
                    current.isRunning(FileAction.saveText),
                builder: (context, actions) => FileContentViewer(
                  state: state,
                  isSaving: actions.isRunning(FileAction.saveText),
                  onSaveText: (text) => context
                      .read<FileActionsCubit>()
                      .saveText(state.file, text),
                  onDownload: commands.download,
                  onRetry: () {
                    if (selected != null) cubit.selectVersion(selected);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
