import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_file.dart';
import '../cubits/file_detail_cubit.dart';
import '../cubits/file_detail_state.dart';

class FileContentEditor extends StatefulWidget {
  const FileContentEditor({super.key, required this.file, required this.state});

  final TeamFile file;
  final FileDetailState state;

  @override
  State<FileContentEditor> createState() => _FileContentEditorState();
}

class _FileContentEditorState extends State<FileContentEditor> {
  late final TextEditingController _controller;
  String? _versionId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant FileContentEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final versionId = widget.state.selectedVersion?.id;
    if (versionId != _versionId && widget.state.content != null) {
      _versionId = versionId;
      _controller.text = widget.state.content!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        widget.file.contentType.startsWith('text/') ||
        widget.file.contentType == 'application/json';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EditorHeader(
            file: widget.file,
            canEdit: canEdit,
            isSaving: widget.state.isSaving,
            onSave: _save,
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _EditorBody(
              state: widget.state,
              canEdit: canEdit,
              controller: _controller,
            ),
          ),
        ],
      ),
    );
  }

  void _save() => context.read<FileDetailCubit>().save(_controller.text);
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.file,
    required this.canEdit,
    required this.isSaving,
    required this.onSave,
  });

  final TeamFile file;
  final bool canEdit;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            file.contentType,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (canEdit)
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const _SmallSpinner()
                : const Icon(Icons.save_outlined),
            label: const Text('Neue Version sichern'),
          ),
      ],
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.state,
    required this.canEdit,
    required this.controller,
  });

  final FileDetailState state;
  final bool canEdit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.content == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!canEdit) {
      return SingleChildScrollView(
        child: SelectableText(
          state.content!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return TextField(
      controller: controller,
      expands: true,
      maxLines: null,
      minLines: null,
      textAlignVertical: TextAlignVertical.top,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Dateiinhalt',
      ),
    );
  }
}

class _SmallSpinner extends StatelessWidget {
  const _SmallSpinner();
  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
