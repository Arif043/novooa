import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class PromptChoiceField extends StatelessWidget {
  const PromptChoiceField({
    super.key,
    required this.value,
    required this.index,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final String value;
  final int index;
  final bool canRemove;
  final void Function(int index, String value) onChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TemplateExpressionTextField(
        value: value,
        suggestions: TemplateExpressionScope.suggestionsOf(context),
        decoration: InputDecoration(
          hintText: 'Antwort ${index + 1}',
          suffixIcon: canRemove
              ? IconButton(
                  icon: const Icon(CupertinoIcons.delete),
                  onPressed: () => onRemove(index),
                )
              : null,
        ),
        onChanged: (value) => onChanged(index, value),
      ),
    );
  }
}
