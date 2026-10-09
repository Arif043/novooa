import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_file_attachment_section.dart';

class ReadFileWidget extends StatelessWidget {
  const ReadFileWidget({super.key, required this.node});

  final WorkflowNode node;

  ReadFileNodeConfig get _config {
    return node.config as ReadFileNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_datei_lesen.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          NodeFileAttachmentSection(
            attachments: _attachments,
            onAttach: (file) => _selectFile(context, file),
            onDetach: (_) => _clearFile(context),
          ),
        ],
      ),
    );
  }

  List<NodeAttachment> get _attachments {
    final file = _config.file;
    return file == null ? const [] : [file];
  }

  void _selectFile(BuildContext context, NodeAttachment file) {
    context.read<TaskBuilderCubit>().selectReadFile(node.id, file);
  }

  void _clearFile(BuildContext context) {
    context.read<TaskBuilderCubit>().clearReadFile(node.id);
  }
}
