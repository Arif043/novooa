import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class SpeechTextMappingField extends StatelessWidget {
  const SpeechTextMappingField({
    super.key,
    required this.nodeId,
    required this.value,
    required this.onChanged,
  });

  final String nodeId;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TemplateExpressionTextField(
        key: ValueKey('$nodeId-speech-text'),
        value: value,
        suggestions: TemplateExpressionScope.suggestionsOf(context),
        decoration: InputDecoration(
          labelText: LocaleKeys.ui_text.tr(),
          hintText: '{{eingabe.value}} oder {{global.eingabe.value}}',
        ),
        onChanged: onChanged,
      ),
    );
  }
}
