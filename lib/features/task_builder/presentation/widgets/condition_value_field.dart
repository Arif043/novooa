import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/workflow_graph.dart';
import 'branch_condition_operand_type.dart';
import 'condition_value_sources.dart';

class ConditionValueField extends StatefulWidget {
  const ConditionValueField({
    super.key,
    required this.value,
    required this.graph,
    required this.label,
    required this.onChanged,
    this.preferSource = false,
    this.hint = const UnknownTypeHint(),
    this.helperText,
  });
  final String value;
  final WorkflowGraph graph;
  final String label;
  final ValueChanged<String> onChanged;
  final bool preferSource;
  final OperandTypeHint hint;
  final String? helperText;
  @override
  State<ConditionValueField> createState() => _ConditionValueFieldState();
}

class _ConditionValueFieldState extends State<ConditionValueField> {
  late bool _source =
      widget.value.contains('{{') ||
      (widget.value.isEmpty && widget.preferSource);
  late final _text = TextEditingController(
    text: widget.value.contains('{{') ? '' : widget.value,
  );
  @override
  void didUpdateWidget(ConditionValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value.isNotEmpty) _source = widget.value.contains('{{');
      if (!widget.value.contains('{{') && _text.text != widget.value) {
        _text.text = widget.value;
      }
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = conditionValueSources(widget.graph);
    final hasStored =
        widget.value.isNotEmpty && !sources.containsKey(widget.value);
    final options = switch (widget.hint) {
      EnumTypeHint(:final values) => {for (final value in values) value: value},
      BooleanTypeHint() => {'true': 'Ja', 'false': 'Nein'},
      _ => <String, String>{},
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            PopupMenuButton<bool>(
              // Der lokale Navigator liegt im horizontalen Seitenmenü.
              // Dessen Scrollposition darf ensureVisible nicht mitverschieben.
              useRootNavigator: true,
              tooltip: LocaleKeys.ui_art_des_werts_waehlen.tr(),
              initialValue: _source,
              onSelected: (source) {
                if (source == _source) return;
                setState(() {
                  _source = source;
                  _text.clear();
                });
                widget.onChanged('');
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: true,
                  child: Text(LocaleKeys.ui_wert_aus_einem_baustein.tr()),
                ),
                PopupMenuItem(
                  value: false,
                  child: Text(LocaleKeys.ui_fester_wert.tr()),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _source ? 'Baustein' : 'Fester Wert',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_source)
          DropdownButtonFormField<String>(
            key: ValueKey('source-${widget.value}'),
            isExpanded: true,
            initialValue: widget.value.isEmpty ? null : widget.value,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_baustein_und_wert.tr(),
              helperText: sources.isEmpty
                  ? LocaleKeys.ui_connect_block_with_output_first.tr()
                  : null,
              helperMaxLines: 3,
            ),
            items: [
              for (final entry in sources.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (hasStored)
                DropdownMenuItem(
                  value: widget.value,
                  child: Text(
                    LocaleKeys.ui_gespeicherter_ausdruck_nicht_in_der_auswahl
                        .tr(),
                    maxLines: 2,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) widget.onChanged(value);
            },
          )
        else if (options.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('fixed-${widget.value}-${options.keys.join()}'),
            isExpanded: true,
            initialValue: widget.value.isEmpty ? null : widget.value,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_vergleichswert_auswaehlen.tr(),
            ),
            items: [
              for (final entry in options.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              if (widget.value.isNotEmpty && !options.containsKey(widget.value))
                DropdownMenuItem(
                  value: widget.value,
                  child: Text(
                    LocaleKeys.ui_previous_value.tr(
                      namedArgs: {'value': widget.value},
                    ),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) widget.onChanged(value);
            },
          )
        else
          TextField(
            controller: _text,
            keyboardType: widget.hint is NumberTypeHint
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  )
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: LocaleKeys.ui_fester_wert.tr(),
              hintText: LocaleKeys.ui_wert_eingeben.tr(),
              helperText: widget.helperText,
            ),
            onChanged: widget.onChanged,
          ),
      ],
    );
  }
}
