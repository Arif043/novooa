import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/node_file_attachments_state.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_kind_filter.dart';

class ExistingWriteFileList extends StatelessWidget {
  const ExistingWriteFileList({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeFileAttachmentsCubit, NodeFileAttachmentsState>(
      builder: (context, state) => switch (state.status) {
        NodeFileAttachmentsStatus.loading => const LinearProgressIndicator(),
        NodeFileAttachmentsStatus.failure => _FileListError(
          message: state.message ?? 'Dateien konnten nicht geladen werden.',
        ),
        NodeFileAttachmentsStatus.ready when state.files.isEmpty => const _Hint(
          'Noch keine Dateien hochgeladen.',
        ),
        NodeFileAttachmentsStatus.ready => _FilterableFileList(
          node: node,
          files: state.files,
        ),
      },
    );
  }
}

class _FilterableFileList extends StatefulWidget {
  const _FilterableFileList({required this.node, required this.files});

  final WorkflowNode node;
  final List<NodeAttachment> files;

  @override
  State<_FilterableFileList> createState() => _FilterableFileListState();
}

class _FilterableFileListState extends State<_FilterableFileList> {
  WriteFileKindFilter _filter = WriteFileKindFilter.all;

  @override
  Widget build(BuildContext context) {
    final filters = WriteFileKindFilter.availableFor(widget.files);
    final selected = filters.contains(_filter) ? _filter : filters.first;
    final visibleFiles = widget.files.where(selected.matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WriteFileKindFilterChips(
          filters: filters,
          selected: selected,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = 0; index < visibleFiles.length; index++) ...[
          if (index > 0) const Divider(height: AppSpacing.sm),
          _FileTile(node: widget.node, file: visibleFiles[index]),
        ],
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.node, required this.file});

  final WorkflowNode node;
  final NodeAttachment file;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_outlined),
      title: Text(file.displayName, overflow: TextOverflow.ellipsis),
      subtitle: Text(file.contentType),
      onTap: () => _select(context),
    );
  }

  void _select(BuildContext context) {
    context.read<TaskBuilderCubit>().selectExistingWriteFile(node.id, file);
    Navigator.of(context).pop();
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _FileListError extends StatelessWidget {
  const _FileListError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Hint(message),
        TextButton.icon(
          onPressed: context.read<NodeFileAttachmentsCubit>().load,
          icon: const Icon(Icons.refresh),
          label: const Text('Erneut versuchen'),
        ),
      ],
    );
  }
}
