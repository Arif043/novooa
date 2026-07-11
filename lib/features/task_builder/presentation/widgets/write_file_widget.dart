import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_target_dialog.dart';

class WriteFileWidget extends StatelessWidget {
  const WriteFileWidget({super.key, required this.node});

  final WorkflowNode node;

  WriteFileNodeConfig get _config => node.config as WriteFileNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeHover,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datei schreiben', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          _WriteFileTargetTile(
            config: _config,
            onTap: () => WriteFileTargetDialog.show(context, node),
          ),
        ],
      ),
    );
  }
}

class _WriteFileTargetTile extends StatelessWidget {
  const _WriteFileTargetTile({required this.config, required this.onTap});

  final WriteFileNodeConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.md),
      onTap: onTap,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ausgabedatei',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Icon(_icon, semanticLabel: 'Ausgabedatei'),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _TargetText(config: config)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  IconData get _icon {
    if (config.fileName.trim().isEmpty) return Icons.note_add_outlined;
    if (config.fileId != null) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }
}

class _TargetText extends StatelessWidget {
  const _TargetText({required this.config});

  final WriteFileNodeConfig config;

  @override
  Widget build(BuildContext context) {
    if (config.fileName.trim().isEmpty) {
      return Text(
        'Datei auswählen oder neu anlegen',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final prefix = config.fileId == null ? 'Neue Datei' : 'Bestehende Datei';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$prefix: ${config.fileName}', overflow: TextOverflow.ellipsis),
        Text(
          config.contentType.trim().isEmpty ? 'text/plain' : config.contentType,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
