import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';

/// Inline-Titel + Objective oben im Canvas-Bereich.
///
/// Wird im 2-Spalten-Layout oberhalb der Knotenliste angezeigt.
/// Beide Felder sind editierbar; onChanged feuert bei jeder
/// Tastatureingabe — der Cubit entscheidet, ob tatsächlich persistiert
/// wird (kein Op bei identischem Wert).
class CanvasHeader extends StatelessWidget {
  const CanvasHeader({
    super.key,
    required this.title,
    required this.objective,
    required this.onTitleChanged,
    required this.onObjectiveChanged,
  });

  final String title;
  final String objective;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onObjectiveChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeaderField(
            initialValue: title,
            hint: 'Titel der Aufgabe',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: SyscatTheme.textMain,
            ),
            onChanged: onTitleChanged,
            semanticsLabel: 'Aufgabentitel',
          ),
          const SizedBox(height: AppSpacing.xs),
          _HeaderField(
            initialValue: objective,
            hint: 'Was soll diese Aufgabe erreichen?',
            style: TextStyle(
              fontSize: 14,
              color: SyscatTheme.textSecondary,
            ),
            onChanged: onObjectiveChanged,
            semanticsLabel: 'Aufgabenziel',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _HeaderField extends StatefulWidget {
  const _HeaderField({
    required this.initialValue,
    required this.hint,
    required this.style,
    required this.onChanged,
    required this.semanticsLabel,
    this.maxLines = 1,
  });

  final String initialValue;
  final String hint;
  final TextStyle style;
  final ValueChanged<String> onChanged;
  final String semanticsLabel;
  final int maxLines;

  @override
  State<_HeaderField> createState() => _HeaderFieldState();
}

class _HeaderFieldState extends State<_HeaderField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _HeaderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.semanticsLabel,
      child: TextField(
        controller: _controller,
        maxLines: widget.maxLines,
        style: widget.style,
        decoration: InputDecoration(
          hintText: widget.hint,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}