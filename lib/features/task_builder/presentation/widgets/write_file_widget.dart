import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/write_file_folders_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_folder_tree.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_target_dialog.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

class WriteFileWidget extends StatelessWidget {
  const WriteFileWidget({super.key, required this.node});

  final WorkflowNode node;

  WriteFileNodeConfig get _config => node.config as WriteFileNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Datei schreiben', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.contentTemplate,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Inhalt',
              hintText: '{{baustein.value}}',
            ),
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateWriteFileContent(node.id, value),
          ),
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

  /// Nur für neue Dateien: Eine bestehende Datei bleibt in ihrem Ordner.
  String? _folderLabel(BuildContext context) {
    final folderId = config.folderId;
    if (config.fileId != null || folderId == null) return null;
    final folders = context.watch<WriteFileFoldersCubit>().state.folders;
    return folderPathLabel(folderId, folders);
  }

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
        if (_folderLabel(context) case final String folderLabel)
          Text(
            'Verzeichnis: $folderLabel',
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}
