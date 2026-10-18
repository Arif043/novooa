import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/node_config.dart';
import 'template_expression_suggestion.dart';
import 'template_expression_text_field.dart';

/// Editierbare Liste aus Name und Wert, etwa Query-Parameter oder Header.
class HttpNameValueList extends StatelessWidget {
  const HttpNameValueList({
    super.key,
    required this.title,
    required this.addLabel,
    required this.items,
    required this.suggestions,
    required this.onChanged,
  });

  final String title;
  final String addLabel;
  final List<HttpNameValue> items;
  final List<TemplateExpressionSuggestion> suggestions;
  final ValueChanged<List<HttpNameValue>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TemplateExpressionTextField(
                    value: items[index].name,
                    suggestions: suggestions,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.ui_name.tr(),
                    ),
                    onChanged: (name) =>
                        _replace(index, items[index].copyWith(name: name)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: TemplateExpressionTextField(
                    value: items[index].value,
                    suggestions: suggestions,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.ui_wert.tr(),
                    ),
                    onChanged: (value) =>
                        _replace(index, items[index].copyWith(value: value)),
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.ui_entfernen.tr(),
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged([
                    for (var other = 0; other < items.length; other++)
                      if (other != index) items[other],
                  ]),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(addLabel),
            onPressed: () => onChanged([...items, const HttpNameValue()]),
          ),
        ),
      ],
    );
  }

  void _replace(int index, HttpNameValue item) {
    onChanged([
      for (var other = 0; other < items.length; other++)
        if (other == index) item else items[other],
    ]);
  }
}
