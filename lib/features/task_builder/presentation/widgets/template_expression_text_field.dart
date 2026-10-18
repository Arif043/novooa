import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_target.dart';

import 'field_helper_text.dart';
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
    this.cursorTarget,
    this.helperText,
  });

  final String value;
  final List<TemplateExpressionSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final int? minLines;
  final int? maxLines;

  /// Macht das Feld für den KI-Agent-Cursor auffindbar.
  final AgentCursorTarget? cursorTarget;

  /// Steht unter dem Feld statt in [decoration], weil die mitwachsende Höhe
  /// nur den Eingabetext misst und ein Hilfetext darin das Feld staucht.
  final String? helperText;

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
    final target = widget.cursorTarget;
    final field = _layout();
    if (target == null) return field;
    return AgentCursorAnchor(target: target, child: field);
  }

  Widget _layout() {
    assert(
      widget.decoration.helperText == null,
      'helperText statt decoration.helperText verwenden',
    );
    final helper = widget.helperText;
    if (helper == null) return _sizedField();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [_sizedField(), FieldHelperText(helper)],
    );
  }

  Widget _sizedField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return _textField();
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: _heightFor(context, constraints.maxWidth),
          child: _textField(expands: true),
        );
      },
    );
  }

  Widget _textField({bool expands = false}) {
    return TextField(
      controller: _controller,
      expands: expands,
      minLines: expands ? null : widget.minLines,
      maxLines: expands ? null : widget.maxLines,
      textAlignVertical: TextAlignVertical.top,
      decoration: widget.decoration,
      onChanged: _handleChanged,
    );
  }

  double _heightFor(BuildContext context, double availableWidth) {
    final theme = Theme.of(context);
    final decoration = widget.decoration.applyDefaults(
      theme.inputDecorationTheme,
    );
    final padding = (decoration.contentPadding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    final maxWidth = math.max(0.0, availableWidth - padding.horizontal);
    final painter = _textPainter(context, maxWidth);
    final minHeight = painter.preferredLineHeight * (widget.minLines ?? 1);
    return math.max(minHeight, painter.height) + padding.vertical + 2;
  }

  TextPainter _textPainter(BuildContext context, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: _controller.measurementText,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      textDirection: Directionality.of(context),
      maxLines: widget.maxLines,
    );
    painter.layout(maxWidth: maxWidth);
    return painter;
  }

  void _handleChanged(String displayValue) {
    setState(() {});
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

  String get measurementText {
    final measured = text.replaceAllMapped(
      RegExp(
        '[${String.fromCharCode(_firstToken)}-${String.fromCharCode(0xf8ff)}]',
      ),
      (match) => '  ${_labelFor(match.group(0)!)}  ',
    );
    return measured.isEmpty ? 'M' : measured;
  }

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

  String _labelFor(String token) {
    final expression = _expressions[token] ?? token;
    return expression.substring(2, expression.length - 2).trim();
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
      label: LocaleKeys.ui_workflow_value_named.tr(namedArgs: {'name': name}),
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
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: LocaleKeys.ui_workflow_wert_oder_variable_suchen
                      .tr(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: candidates.isEmpty
                    ? Center(
                        child: Text(
                          LocaleKeys.ui_keine_passenden_werte_verfuegbar.tr(),
                        ),
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
