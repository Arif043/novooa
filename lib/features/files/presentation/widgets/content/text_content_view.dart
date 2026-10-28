import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';

/// Editable text/JSON viewer. Decodes the raw bytes lazily (only text kinds
/// ever reach this widget), so binary content is never routed through here.
class TextContentView extends StatefulWidget {
  const TextContentView({
    super.key,
    required this.bytes,
    required this.versionId,
    required this.isSaving,
    required this.onSave,
  });

  final List<int> bytes;

  /// Wechselt die Version, übernimmt das Feld deren Inhalt.
  final String? versionId;
  final bool isSaving;
  final ValueChanged<String> onSave;

  @override
  State<TextContentView> createState() => _TextContentViewState();
}

class _TextContentViewState extends State<TextContentView> {
  late final TextEditingController _controller;
  String? _versionId;

  @override
  void initState() {
    super.initState();
    _versionId = widget.versionId;
    _controller = TextEditingController(text: _decode(widget.bytes));
  }

  @override
  void didUpdateWidget(covariant TextContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.versionId != _versionId) {
      _versionId = widget.versionId;
      _controller.text = _decode(widget.bytes);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _decode(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SaveBar(isSaving: widget.isSaving, onSave: _save),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _controller,
            expands: true,
            maxLines: null,
            minLines: null,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: LocaleKeys.files_text_hint.tr(),
            ),
          ),
        ),
      ],
    );
  }

  void _save() => widget.onSave(_controller.text);
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
        label: Text(LocaleKeys.files_text_save_version.tr()),
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
