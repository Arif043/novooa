import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Aktion „Neuer Ordner": klappt ein Namensfeld auf und meldet den Namen
/// über [onCreate]. Liefert [onCreate] `true`, klappt die Zeile wieder zu.
class WriteFileNewFolderRow extends StatefulWidget {
  const WriteFileNewFolderRow({
    super.key,
    required this.parentLabel,
    required this.isCreating,
    required this.errorMessage,
    required this.onCreate,
  });

  /// Pfad des Verzeichnisses, in dem angelegt wird; `null` = oberste Ebene.
  final String? parentLabel;
  final bool isCreating;
  final String? errorMessage;
  final Future<bool> Function(String name) onCreate;

  @override
  State<WriteFileNewFolderRow> createState() => _WriteFileNewFolderRowState();
}

class _WriteFileNewFolderRowState extends State<WriteFileNewFolderRow> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return TextButton.icon(
        onPressed: () => setState(() => _expanded = true),
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Neuer Ordner'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          autofocus: true,
          enabled: !widget.isCreating,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Name des Ordners',
            helperText:
                'Wird angelegt in: ${widget.parentLabel ?? 'Oberste Ebene'}',
            errorText: widget.errorMessage,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.isCreating ? null : _collapse,
              child: const Text('Abbrechen'),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: widget.isCreating ? null : _submit,
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final created = await widget.onCreate(name);
    if (created && mounted) _collapse();
  }

  void _collapse() {
    _controller.clear();
    setState(() => _expanded = false);
  }
}
