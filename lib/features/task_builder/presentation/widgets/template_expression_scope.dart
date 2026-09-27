import 'package:flutter/widgets.dart';

import 'template_expression_suggestion.dart';

/// Stellt allen editierbaren Feldern eines Bausteins dieselben erreichbaren
/// Template-Ausdrücke bereit.
class TemplateExpressionScope extends InheritedWidget {
  const TemplateExpressionScope({
    super.key,
    required this.suggestions,
    required super.child,
  });

  final List<TemplateExpressionSuggestion> suggestions;

  static List<TemplateExpressionSuggestion> suggestionsOf(
    BuildContext context,
  ) {
    return context
            .dependOnInheritedWidgetOfExactType<TemplateExpressionScope>()
            ?.suggestions ??
        const [];
  }

  @override
  bool updateShouldNotify(TemplateExpressionScope oldWidget) {
    return !identical(suggestions, oldWidget.suggestions);
  }
}
