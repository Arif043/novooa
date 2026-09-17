import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../cubits/file_detail_cubit.dart';
import '../../cubits/file_detail_state.dart';

/// Editable text/JSON viewer. Decodes the raw bytes lazily (only text kinds
/// ever reach this widget), so binary content is never routed through here.
class TextContentView extends StatefulWidget {
  const TextContentView({super.key, required this.state});

  final FileDetailState state;

  @override
  State<TextContentView> createState() => _TextContentViewState();
}

class _TextContentViewState extends State<TextContentView> {
  late final TextEditingController _controller;
  String? _versionId;

  @override
  void initState() {
    super.initState();
    _versionId = widget.state.selectedVersion?.id;
    _controller = TextEditingController(text: _decode(widget.state.bytes));
  }

  @override
  void didUpdateWidget(covariant TextContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final versionId = widget.state.selectedVersion?.id;
    if (versionId != _versionId && widget.state.bytes != null) {
      _versionId = versionId;
      _controller.text = _decode(widget.state.bytes);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _decode(List<int>? bytes) =>
      utf8.decode(bytes ?? const [], allowMalformed: true);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SaveBar(isSaving: widget.state.isSaving, onSave: _save),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Dateiinhalt',
            ),
          ),
        ),
      ],
    );
  }

  void _save() => context.read<FileDetailCubit>().save(_controller.text);
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FilledButton.icon(
        onPressed: isSaving ? null : onSave,
        icon: isSaving
            ? const _SmallSpinner()
            : const Icon(Icons.save_outlined),
        label: const Text('Neue Version sichern'),
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
