import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import 'template_expression_suggestion.dart';

/// Öffnet die Suche über die verfügbaren Workflow-Werte; `null`, wenn
/// nichts gewählt wurde.
Future<TemplateExpressionSuggestion?> pickTemplateExpression(
  BuildContext context,
  List<TemplateExpressionSuggestion> suggestions,
) {
  return showDialog<TemplateExpressionSuggestion>(
    context: context,
    builder: (_) => TemplateExpressionPicker(suggestions: suggestions),
  );
}

class TemplateExpressionPicker extends StatefulWidget {
  const TemplateExpressionPicker({super.key, required this.suggestions});

  final List<TemplateExpressionSuggestion> suggestions;

  @override
  State<TemplateExpressionPicker> createState() =>
      _TemplateExpressionPickerState();
}

class _TemplateExpressionPickerState extends State<TemplateExpressionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final candidates = widget.suggestions.where(_matchesQuery).toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: LocaleKeys.ui_workflow_wert_suchen.tr(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _CandidateList(candidates: candidates)),
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

class _CandidateList extends StatelessWidget {
  const _CandidateList({required this.candidates});

  final List<TemplateExpressionSuggestion> candidates;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return Center(
        child: Text(LocaleKeys.ui_keine_passenden_werte_verfuegbar.tr()),
      );
    }
    return ListView.builder(
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final suggestion = candidates[index];
        return ListTile(
          leading: Chip(label: Text(suggestion.expression)),
          title: Text(suggestion.label),
          onTap: () => Navigator.of(context).pop(suggestion),
        );
      },
    );
  }
}
