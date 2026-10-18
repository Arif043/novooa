import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';

/// Die eingetragenen Pakete als Chips und ein Feld zum Hinzufügen.
class ScriptPackageEditor extends StatefulWidget {
  const ScriptPackageEditor({
    super.key,
    required this.packages,
    required this.onChanged,
  });

  final List<PythonPackage> packages;
  final ValueChanged<List<PythonPackage>> onChanged;

  @override
  State<ScriptPackageEditor> createState() => _ScriptPackageEditorState();
}

class _ScriptPackageEditorState extends State<ScriptPackageEditor> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.packages.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final package in widget.packages)
                InputChip(
                  label: Text(package.spec),
                  deleteButtonTooltipMessage: LocaleKeys
                      .ui_script_package_remove
                      .tr(namedArgs: {'name': package.spec}),
                  onDeleted: () => _remove(package),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _input,
          decoration: InputDecoration(
            labelText: LocaleKeys.ui_script_package_input.tr(),
            hintText: LocaleKeys.ui_script_package_input_hint.tr(),
            errorText: _error,
            errorMaxLines: 3,
            suffixIcon: IconButton(
              tooltip: LocaleKeys.ui_script_package_add.tr(),
              icon: const Icon(Icons.add),
              onPressed: _add,
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
      ],
    );
  }

  void _add() {
    final package = PythonPackage.parse(_input.text);
    if (package == null) {
      setState(() => _error = LocaleKeys.ui_script_package_invalid.tr());
      return;
    }
    setState(() => _error = null);
    _input.clear();
    if (widget.packages.contains(package)) return;
    widget.onChanged([...widget.packages, package]);
  }

  void _remove(PythonPackage package) {
    widget.onChanged([
      for (final other in widget.packages)
        if (other != package) other,
    ]);
  }
}
