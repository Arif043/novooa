import 'dart:async';

import 'package:flutter/material.dart';

import 'template_expression_suggestion.dart';

/// Editiert Template-Ausdrücke als hervorgehobene Inline-Labels.
///
/// Die Textrepräsentation bleibt absichtlich `{{name}}`. Labels sind eine
/// reine Editor-Darstellung und ändern weder die Konfiguration noch die
/// Template-Auflösung in der Laufzeit.
class TemplateExpressionTextField extends StatefulWidget {
  const TemplateExpressionTextField({
    super.key,
    required this.value,
    required this.suggestions,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String value;
  final List<TemplateExpressionSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final int? minLines;
  final int? maxLines;

  @override
  State<TemplateExpressionTextField> createState() =>
      _TemplateExpressionTextFieldState();
}

class _TemplateExpressionTextFieldState
    extends State<TemplateExpressionTextField> {
  late final _TemplateExpressionController _controller;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = _TemplateExpressionController(text: widget.value);
  }

  @override
  void didUpdateWidget(TemplateExpressionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.value) return;
    _controller.value = _controller.value.copyWith(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: widget.decoration,
      onChanged: _handleChanged,
    );
  }

  void _handleChanged(String value) {
    final selection = _controller.selection;
    if (!_shouldOpenPicker(value, selection)) {
      widget.onChanged(value);
      return;
    }
    final insertionOffset = selection.baseOffset - 1;
    final withoutTrigger = value.replaceRange(
      insertionOffset,
      selection.baseOffset,
      '',
    );
    _controller.value = TextEditingValue(
      text: withoutTrigger,
      selection: TextSelection.collapsed(offset: insertionOffset),
    );
    widget.onChanged(withoutTrigger);
    unawaited(_pickExpression(insertionOffset));
  }

  bool _shouldOpenPicker(String value, TextSelection selection) {
    if (_pickerOpen || !selection.isValid || !selection.isCollapsed) {
      return false;
    }
    final offset = selection.baseOffset;
    return offset > 0 && value[offset - 1] == '#';
  }

  Future<void> _pickExpression(int insertionOffset) async {
    _pickerOpen = true;
    final suggestion = await showDialog<TemplateExpressionSuggestion>(
      context: context,
      builder: (_) =>
          _TemplateExpressionPicker(suggestions: widget.suggestions),
    );
    _pickerOpen = false;
    if (!mounted || suggestion == null) {
      return;
    }
    _insert(suggestion.expression, insertionOffset);
  }

  void _insert(String expression, int insertionOffset) {
    final offset = insertionOffset.clamp(0, _controller.text.length);
    final text = _controller.text;
    final updated = text.replaceRange(offset, offset, expression);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset + expression.length),
    );
    widget.onChanged(updated);
  }
}

class _TemplateExpressionController extends TextEditingController {
  _TemplateExpressionController({super.text});

  static final _expression = RegExp(r'{{[^{}]+}}');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    final labelStyle = baseStyle.copyWith(
      color: Theme.of(context).colorScheme.onSecondaryContainer,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      fontWeight: FontWeight.w600,
    );
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _expression.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(text: _labelText(match.group(0)!), style: labelStyle));
      start = match.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(style: baseStyle, children: spans);
  }

  String _labelText(String expression) {
    final name = expression.substring(2, expression.length - 2).trim();
    return '# $name'.padRight(expression.length);
  }
}

class _TemplateExpressionPicker extends StatefulWidget {
  const _TemplateExpressionPicker({required this.suggestions});

  final List<TemplateExpressionSuggestion> suggestions;

  @override
  State<_TemplateExpressionPicker> createState() =>
      _TemplateExpressionPickerState();
}

class _TemplateExpressionPickerState extends State<_TemplateExpressionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final candidates = widget.suggestions.where(_matchesQuery).toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Workflow-Wert oder Variable suchen',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: candidates.isEmpty
                    ? const Center(
                        child: Text('Keine passenden Werte verfügbar.'),
                      )
                    : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final suggestion = candidates[index];
                          return ListTile(
                            leading: Chip(label: Text(suggestion.expression)),
                            title: Text(suggestion.label),
                            onTap: () => Navigator.of(context).pop(suggestion),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesQuery(TemplateExpressionSuggestion suggestion) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        suggestion.expression.toLowerCase().contains(query) ||
        suggestion.label.toLowerCase().contains(query);
  }
}
