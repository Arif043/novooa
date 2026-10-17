import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Eine Token-Angabe (Antwortlänge, Kontextfenster). Leer heißt
/// Modellstandard; nur ganze Zahlen sind eingebbar.
class PromptTokenLimitField extends StatelessWidget {
  const PromptTokenLimitField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helperText,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: LocaleKeys.task_builder_generation_options_empty_means_default
            .tr(),
        helperText: helperText,
        helperMaxLines: 3,
      ),
      onChanged: (text) => onChanged(int.tryParse(text.trim())),
    );
  }
}
