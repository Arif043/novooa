import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/services/script_workflow_input_parser.dart';
import 'template_expression_suggestion.dart';

/// Pfade aus `workflow_input`, deren Wert vor dem Baustein nicht entsteht.
/// `iteration` (Element einer Schleife) und `global` (äußere Ebene) gibt es
/// erst zur Laufzeit; sie gelten als bekannt.
List<String> unknownScriptInputs(
  String script,
  List<TemplateExpressionSuggestion> suggestions,
) {
  final known = {
    'iteration',
    'global',
    for (final suggestion in suggestions) _rootOf(suggestion.expression),
  };
  return [
    for (final path in const ScriptWorkflowInputParser()(script))
      if (!known.contains(path.split('.').first)) path,
  ];
}

String _rootOf(String expression) {
  final path = expression.replaceAll(RegExp(r'^\{\{\s*|\s*\}\}$'), '');
  return path.split('.').first;
}

/// Warnt unter dem Editor, wenn das Script einen Wert liest, den es an
/// dieser Stelle nicht gibt; der Lauf würde dort mit einer Meldung abbrechen.
class ScriptInputWarning extends StatelessWidget {
  const ScriptInputWarning({super.key, required this.unknownPaths});

  final List<String> unknownPaths;

  @override
  Widget build(BuildContext context) {
    if (unknownPaths.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: colors.error),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              LocaleKeys.ui_script_inputs_unknown.tr(
                namedArgs: {'names': unknownPaths.join(', ')},
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
