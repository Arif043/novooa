import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_collection_name.dart';

/// Name für eine neue Sammlung oder — mit [current] — einen neuen Namen. Beim Umbenennen warnt
/// der Dialog, dass Bausteine den alten Namen weiter nennen.
Future<DataCollectionName?> showDatabaseNameDialog(
  BuildContext context, {
  DataCollection? current,
}) => showDialog<DataCollectionName>(
  context: context,
  builder: (_) => _NameDialog(current: current),
);

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.current});

  final DataCollection? current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.current?.name);
  bool _touched = false;

  bool get _isRename => widget.current != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        _isRename
            ? LocaleKeys.ui_db_name_rename_title.tr()
            : LocaleKeys.ui_db_name_create_title.tr(),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: DataCollectionName.maximumLength,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_db_name_label.tr(),
              errorText: _touched ? _errorText : null,
            ),
            onChanged: (_) => setState(() => _touched = true),
            onSubmitted: (_) => _submit(),
          ),
          if (_isRename) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.ui_db_name_rename_warning.tr(),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.ui_abbrechen.tr()),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _isRename
                ? LocaleKeys.ui_umbenennen.tr()
                : LocaleKeys.ui_db_create.tr(),
          ),
        ),
      ],
    );
  }

  String? get _errorText =>
      switch (DataCollectionName.issueOf(_controller.text)) {
        DataCollectionNameIssue.empty => LocaleKeys.ui_db_name_empty.tr(),
        DataCollectionNameIssue.tooLong => LocaleKeys.ui_db_name_too_long.tr(
          namedArgs: {'max': '${DataCollectionName.maximumLength}'},
        ),
        null => null,
      };

  void _submit() {
    final name = DataCollectionName.tryParse(_controller.text);
    if (name == null) return setState(() => _touched = true);
    // Unveränderter Name beim Umbenennen: nichts zu tun.
    if (name.value == widget.current?.name) return Navigator.of(context).pop();
    Navigator.of(context).pop(name);
  }
}
