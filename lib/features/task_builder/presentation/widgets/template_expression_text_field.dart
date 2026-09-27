import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

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
    _controller = _TemplateExpressionController(widget.value);
  }

  @override
  void didUpdateWidget(TemplateExpressionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.rawValue == widget.value) return;
    _controller.replaceRawValue(widget.value);
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

  void _handleChanged(String displayValue) {
    final selection = _controller.selection;
    if (!_shouldOpenPicker(displayValue, selection)) {
      _controller.normalizePlainExpressions();
      widget.onChanged(_controller.rawValue);
      return;
    }
    final insertionOffset = selection.baseOffset - 1;
    _controller.removeDisplayRange(insertionOffset, selection.baseOffset);
    widget.onChanged(_controller.rawValue);
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
    _controller.insertExpression(expression, offset);
    widget.onChanged(_controller.rawValue);
  }
}

class _TemplateExpressionController extends TextEditingController {
  _TemplateExpressionController(String rawValue) {
    replaceRawValue(rawValue);
  }

  static final _expression = RegExp(r'{{[^{}]+}}');
  static const _firstToken = 0xe000;
  final _expressions = <String, String>{};
  var _nextToken = _firstToken;

  String get rawValue => _rawValueFor(text);

  void replaceRawValue(String rawValue) {
    _expressions.clear();
    _nextToken = _firstToken;
    final displayValue = _displayValueFor(rawValue);
    _setDisplayText(displayValue, selectionOffset: displayValue.length);
  }

  void removeDisplayRange(int start, int end) {
    _setDisplayText(text.replaceRange(start, end, ''), selectionOffset: start);
  }

  void insertExpression(String expression, int offset) {
    final token = _tokenFor(expression);
    _setDisplayText(
      text.replaceRange(offset, offset, token),
      selectionOffset: offset + token.length,
    );
  }

  void normalizePlainExpressions() {
    if (!_expression.hasMatch(text)) return;
    replaceRawValue(rawValue);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <InlineSpan>[];
    var start = 0;
    for (var index = 0; index < text.length; index++) {
      final token = text[index];
      final expression = _expressions[token];
      if (expression == null) continue;
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(_labelSpan(expression));
      start = index + 1;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return TextSpan(style: style, children: spans);
  }

  String _displayValueFor(String rawValue) {
    return rawValue.replaceAllMapped(
      _expression,
      (match) => _tokenFor(match.group(0)!),
    );
  }

  String _rawValueFor(String displayValue) {
    return displayValue.replaceAllMapped(
      RegExp(
        '[${String.fromCharCode(_firstToken)}-${String.fromCharCode(0xf8ff)}]',
      ),
      (match) => _expressions[match.group(0)!] ?? match.group(0)!,
    );
  }

  String _tokenFor(String expression) {
    final token = String.fromCharCode(_nextToken++);
    _expressions[token] = expression;
    return token;
  }

  void _setDisplayText(String value, {required int selectionOffset}) {
    this.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
  }

  InlineSpan _labelSpan(String expression) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _TemplateExpressionLabel(expression: expression),
    );
  }
}

class _TemplateExpressionLabel extends StatelessWidget {
  const _TemplateExpressionLabel({required this.expression});

  final String expression;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = expression.substring(2, expression.length - 2).trim();
    return Semantics(
      label: 'Workflow-Wert $name',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Text(
          name,
          style: theme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
