import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_state.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

enum WriteTargetMode { existing, fresh }

class WriteFileModeSelector extends StatelessWidget {
  const WriteFileModeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final WriteTargetMode value;
  final ValueChanged<Set<WriteTargetMode>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<WriteTargetMode>(
      segments: const [
        ButtonSegment(
          value: WriteTargetMode.existing,
          label: Text('Bestehend'),
        ),
        ButtonSegment(value: WriteTargetMode.fresh, label: Text('Neu')),
      ],
      selected: {value},
      onSelectionChanged: onChanged,
    );
  }
}

class ExistingWriteFileList extends StatelessWidget {
  const ExistingWriteFileList({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeFileAttachmentsCubit, NodeFileAttachmentsState>(
      builder: (context, state) => switch (state.status) {
        NodeFileAttachmentsStatus.loading => const LinearProgressIndicator(),
        NodeFileAttachmentsStatus.failure => const Text(
          'Dateien konnten nicht geladen werden.',
        ),
        NodeFileAttachmentsStatus.ready when state.files.isEmpty => const Text(
          'Noch keine Dateien hochgeladen.',
        ),
        NodeFileAttachmentsStatus.ready => _FileList(
          node: node,
          files: state.files,
        ),
      },
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.node, required this.files});

  final WorkflowNode node;
  final List<NodeAttachment> files;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < files.length; index++) ...[
          if (index > 0) const Divider(height: AppSpacing.sm),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(files[index].displayName),
            subtitle: Text(files[index].contentType),
            onTap: () => _select(context, files[index]),
          ),
        ],
      ],
    );
  }

  void _select(BuildContext context, NodeAttachment file) {
    context.read<TaskBuilderCubit>().selectExistingWriteFile(node.id, file);
    Navigator.of(context).pop();
  }
}

class NewWriteFileForm extends StatelessWidget {
  const NewWriteFileForm({
    super.key,
    required this.nameController,
    required this.contentTypeController,
  });

  final TextEditingController nameController;
  final TextEditingController contentTypeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Dateiname'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: contentTypeController,
          decoration: const InputDecoration(labelText: 'Inhaltstyp (optional)'),
        ),
      ],
    );
  }
}
