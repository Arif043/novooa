import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../domain/entities/file_failure.dart';
import '../../../domain/entities/file_name.dart';
import '../../localization/file_failure_message.dart';

/// Neuer Name für eine Datei. Der Dialog bleibt offen, bis [onSubmit]
/// gelingt, damit ein vergebener Name am Feld erscheint.
Future<void> showRenameFileDialog(
  BuildContext context, {
  required String currentName,
  required Future<FileFailureKind?> Function(String name) onSubmit,
}) => showDialog<void>(
  context: context,
  builder: (_) => _RenameDialog(currentName: currentName, onSubmit: onSubmit),
);

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.currentName, required this.onSubmit});

  final String currentName;
  final Future<FileFailureKind?> Function(String name) onSubmit;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.currentName)
    ..selection = TextSelection(
      baseOffset: 0,
      // Nur der Basisname ist markiert; die Endung bleibt beim Tippen stehen.
      extentOffset:
          FileName.tryParse(widget.currentName)?.baseName.length ??
          widget.currentName.length,
    );
  FileFailureKind? _failure;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocaleKeys.files_rename_title.tr()),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: FileName.maximumLength,
        decoration: InputDecoration(
          labelText: LocaleKeys.files_rename_label.tr(),
          errorText: _failure == null ? null : fileFailureMessage(_failure!),
          errorMaxLines: 3,
        ),
        onChanged: (_) => setState(() => _failure = null),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(LocaleKeys.files_action_rename.tr()),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (FileName.tryParse(_controller.text) == null) {
      return setState(() => _failure = FileFailureKind.invalidFileName);
    }
    setState(() => _isSaving = true);
    final failure = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    if (failure == null) return Navigator.of(context).pop();
    setState(() {
      _isSaving = false;
      _failure = failure;
    });
  }
}
