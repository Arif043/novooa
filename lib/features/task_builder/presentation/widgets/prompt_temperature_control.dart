import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';

/// Temperatur des Modells: ohne Wert gilt der Modellstandard, ein Knopf
/// setzt einen Wert bzw. kehrt zum Standard zurück.
class PromptTemperatureControl extends StatelessWidget {
  const PromptTemperatureControl({
    super.key,
    required this.temperature,
    required this.onChanged,
  });

  static const _initialTemperature = 0.7;
  static const _step = 0.1;

  final double? temperature;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final value = temperature;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(_label(value))),
            _ToggleButton(
              usesDefault: value == null,
              onPressed: () =>
                  onChanged(value == null ? _initialTemperature : null),
            ),
          ],
        ),
        if (value != null)
          Slider(
            value: value,
            min: PromptGenerationOptions.minTemperature,
            max: PromptGenerationOptions.maxTemperature,
            divisions: _divisions,
            label: value.toStringAsFixed(1),
            semanticFormatterCallback: (value) => value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
      ],
    );
  }

  static int get _divisions =>
      ((PromptGenerationOptions.maxTemperature -
                  PromptGenerationOptions.minTemperature) /
              _step)
          .round();

  String _label(double? value) {
    final title = LocaleKeys.task_builder_generation_options_temperature.tr();
    final shown = value == null
        ? LocaleKeys.task_builder_generation_options_temperature_default.tr()
        : value.toStringAsFixed(1);
    return '$title: $shown';
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.usesDefault, required this.onPressed});

  final bool usesDefault;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = usesDefault
        ? LocaleKeys.task_builder_generation_options_set_temperature.tr()
        : LocaleKeys.task_builder_generation_options_use_model_default.tr();
    return IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(
        usesDefault ? Icons.tune_outlined : Icons.restart_alt_outlined,
        semanticLabel: label,
      ),
    );
  }
}
