import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';
import 'employee_skill_picker.dart';

/// Editor eines Mitarbeiters als Sheet (Bottom Sheet mobil, Fenster-Sheet auf
/// dem Desktop). [onSave] liefert `true`, wenn gespeichert wurde; dann schließt
/// das Sheet, sonst bleibt es mit den Eingaben offen.
class EmployeeEditorSheet extends StatefulWidget {
  const EmployeeEditorSheet({
    super.key,
    required this.style,
    required this.onSave,
    this.initial,
  });

  final AdaptiveSheetStyle style;
  final Employee? initial;
  final Future<bool> Function(EmployeeDraft draft) onSave;

  static Future<void> show(
    BuildContext context, {
    Employee? initial,
    required Future<bool> Function(EmployeeDraft draft) onSave,
    required Widget Function(Widget child) provide,
  }) {
    return showAdaptiveSheet<void>(
      context: context,
      builder: (_, style) => provide(
        EmployeeEditorSheet(style: style, initial: initial, onSave: onSave),
      ),
    );
  }

  @override
  State<EmployeeEditorSheet> createState() => _EmployeeEditorSheetState();
}

class _EmployeeEditorSheetState extends State<EmployeeEditorSheet> {
  static const _windowSheetHeight = 600.0;
  static const _maximumNameLength = 80;
  static const _maximumConstraintLength = 8000;

  late final _name = TextEditingController(text: widget.initial?.name);
  late final _constraint = TextEditingController(
    text: widget.initial?.constraint,
  );
  late List<String> _skills = [...?widget.initial?.skillNames];
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _constraint.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await widget.onSave(
      EmployeeDraft(
        name: _name.text.trim(),
        constraint: _constraint.text.trim(),
        skillNames: _skills,
      ),
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWindow = widget.style.isWindow;
    return SizedBox(
      height: isWindow
          ? _windowSheetHeight
          : MediaQuery.sizeOf(context).height * 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              widget.initial == null
                  ? 'Mitarbeiter anlegen'
                  : 'Mitarbeiter bearbeiten',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(child: _form(context)),
          if (isWindow) ...[
            const Divider(height: 1),
            SheetFooter(
              onCancel: () => Navigator.of(context).pop(),
              confirmLabel: 'Speichern',
              onConfirm: _canSave ? _save : null,
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Speichern'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _form(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: [
        TextField(
          controller: _name,
          maxLength: _maximumNameLength,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _constraint,
          minLines: 4,
          maxLines: 10,
          maxLength: _maximumConstraintLength,
          decoration: const InputDecoration(
            labelText: 'Rahmenbedingung',
            helperText: 'Gilt als System-Prompt für jeden Aufruf.',
            helperMaxLines: 2,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Fähigkeiten', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        EmployeeSkillPicker(
          selected: _skills,
          onChanged: (skills) => setState(() => _skills = skills),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
