import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/write_file_folders_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/existing_write_file_list.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/new_write_file_form.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_mode_selector.dart';
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
          BlocProvider.value(value: context.read<WriteFileFoldersCubit>()),
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
  String? _folderId;

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
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
      title: Text(LocaleKeys.ui_ausgabedatei_waehlen.tr()),
      content: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WriteFileModeSelector(value: _mode, onChanged: _setMode),
                const SizedBox(height: AppSpacing.lg),
                _modeContent(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        if (_mode == WriteTargetMode.fresh)
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: _canSubmit ? _submitNew : null,
            child: Text(LocaleKeys.ui_uebernehmen.tr()),
          ),
      ],
    );
  }

  Widget _modeContent() {
    if (_mode == WriteTargetMode.existing) {
      return ExistingWriteFileList(node: widget.node);
    }
    return NewWriteFileForm(
      nameController: _nameController,
      selectedFolderId: _folderId,
      onFolderSelected: (folderId) => setState(() => _folderId = folderId),
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
      folderId: _folderId,
    );
    Navigator.of(context).pop();
  }
}
