import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

class WriteFileWidget extends StatefulWidget {
  const WriteFileWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<WriteFileWidget> createState() => _WriteFileWidgetState();
}

class _WriteFileWidgetState extends State<WriteFileWidget> {
  late final TextEditingController _fileNameController;
  late final TextEditingController _contentTypeController;
  late final TextEditingController _fileIdController;

  WriteFileNodeConfig get _config {
    return widget.node.config as WriteFileNodeConfig;
  }

  @override
  void initState() {
    super.initState();
    _fileNameController = TextEditingController(text: _config.fileName);
    _contentTypeController = TextEditingController(text: _config.contentType);
    _fileIdController = TextEditingController(text: _config.fileId ?? '');
  }

  @override
  void didUpdateWidget(WriteFileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(_fileNameController, _config.fileName);
    _sync(_contentTypeController, _config.contentType);
    _sync(_fileIdController, _config.fileId ?? '');
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    _contentTypeController.dispose();
    _fileIdController.dispose();
    super.dispose();
  }

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
          TextField(
            controller: _fileNameController,
            decoration: const InputDecoration(labelText: 'Dateiname'),
            onChanged: _updateFileName,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _contentTypeController,
            decoration: const InputDecoration(labelText: 'Inhaltstyp'),
            onChanged: _updateContentType,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _fileIdController,
            decoration: const InputDecoration(
              labelText: 'Bestehende Datei-ID',
              helperText: 'Leer lassen, um eine neue Datei zu erstellen.',
            ),
            onChanged: _updateFileId,
          ),
        ],
      ),
    );
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _updateFileName(String fileName) {
    context.read<TaskBuilderCubit>().updateWriteFileName(
      widget.node.id,
      fileName,
    );
  }

  void _updateContentType(String contentType) {
    context.read<TaskBuilderCubit>().updateWriteFileContentType(
      widget.node.id,
      contentType,
    );
  }

  void _updateFileId(String fileId) {
    context.read<TaskBuilderCubit>().updateWriteFileId(widget.node.id, fileId);
  }
}
