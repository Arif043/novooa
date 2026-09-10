import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_target_dialog_controls.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

class WriteFileTargetDialog extends StatefulWidget {
  const WriteFileTargetDialog({super.key, required this.node});

  final WorkflowNode node;

  static Future<void> show(BuildContext context, WorkflowNode node) {
    return showIosDialog<void>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<TaskBuilderCubit>()),
          BlocProvider.value(value: context.read<NodeFileAttachmentsCubit>()),
        ],
        child: WriteFileTargetDialog(node: node),
      ),
    );
  }

  @override
  State<WriteFileTargetDialog> createState() => _WriteFileTargetDialogState();
}

class _WriteFileTargetDialogState extends State<WriteFileTargetDialog> {
  WriteTargetMode _mode = WriteTargetMode.existing;
  final _nameController = TextEditingController();
  final _contentTypeController = TextEditingController(text: 'text/plain');

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _contentTypeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Ausgabedatei wählen'),
      content: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WriteFileModeSelector(value: _mode, onChanged: _setMode),
                const SizedBox(height: AppSpacing.md),
                if (_mode == WriteTargetMode.existing)
                  ExistingWriteFileList(node: widget.node)
                else
                  NewWriteFileForm(
                    nameController: _nameController,
                    contentTypeController: _contentTypeController,
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        if (_mode == WriteTargetMode.fresh)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _canSubmit ? _submitNew : null,
            child: const Text('Übernehmen'),
          ),
      ],
    );
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _onNameChanged() => setState(() {});

  void _setMode(Set<WriteTargetMode> value) {
    setState(() => _mode = value.first);
  }

  void _submitNew() {
    context.read<TaskBuilderCubit>().selectNewWriteFile(
      nodeId: widget.node.id,
      fileName: _nameController.text.trim(),
      contentType: _contentTypeController.text.trim(),
    );
    Navigator.of(context).pop();
  }
}
