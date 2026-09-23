import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform/document_scan_support.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class MediaInputWidget extends StatelessWidget {
  const MediaInputWidget({super.key, required this.node});

  final WorkflowNode node;

  MediaInputNodeConfig get _config => node.config as MediaInputNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bild anfordern', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _config.instruction,
            decoration: const InputDecoration(
              hintText: 'Hinweis für die Bildeingabe',
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          if (documentScanSupportedOnThisPlatform()) ...[
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Als Dokument scannen'),
              subtitle: const Text(
                'Erkennt beim Fotografieren automatisch die Kanten des '
                'Dokuments, entzerrt es perspektivisch und schneidet den '
                'Hintergrund aus.',
              ),
              value: _config.documentScanEnabled,
              onChanged: (value) => _update(
                context,
                (config) => config.copyWith(documentScanEnabled: value),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    MediaInputNodeConfig Function(MediaInputNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updateMediaInput(node.id, update);
  }
}
