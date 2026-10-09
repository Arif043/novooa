import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';

class RenameTaskDialog extends StatefulWidget {
  const RenameTaskDialog({super.key, required this.initialTitle});

  final String initialTitle;

  @override
  State<RenameTaskDialog> createState() => _RenameTaskDialogState();
}

class _RenameTaskDialogState extends State<RenameTaskDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(LocaleKeys.ui_aufgabe_umbenennen.tr()),
      content: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: CupertinoTextField(
          controller: _controller,
          autofocus: true,
          placeholder: LocaleKeys.ui_task_name.tr(),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(context),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => _submit(context),
          child: Text(LocaleKeys.ui_umbenennen.tr()),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(title);
  }
}
