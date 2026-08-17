import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bild aufnehmen', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _config.instruction,
            decoration: const InputDecoration(
              hintText: 'Hinweis für die Aufnahme',
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<MediaInputSource>(
            initialValue: _config.source,
            decoration: const InputDecoration(labelText: 'Quelle'),
            items: [
              for (final source in MediaInputSource.values)
                DropdownMenuItem(value: source, child: Text(source.label)),
            ],
            onChanged: (source) {
              if (source == null) return;
              _update(context, (config) => config.copyWith(source: source));
            },
          ),
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
