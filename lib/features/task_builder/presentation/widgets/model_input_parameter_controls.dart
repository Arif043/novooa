part of 'model_input_parameter_configuration.dart';

class _SliderParameter extends StatelessWidget {
  const _SliderParameter({
    required this.label,
    required this.control,
    required this.value,
    required this.onChanged,
    required this.onUseTemplate,
  });
  final String label;
  final ModelManifestSliderControl control;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onUseTemplate;
  @override
  Widget build(BuildContext context) {
    final divisions = ((control.maximum - control.minimum) / control.step)
        .round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('$label: ${value.toStringAsFixed(2)}')),
            _TemplateButton(onPressed: onUseTemplate),
          ],
        ),
        Slider(
          value: value,
          min: control.minimum,
          max: control.maximum,
          divisions: divisions > 0 && divisions <= 100 ? divisions : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CheckboxParameter extends StatelessWidget {
  const _CheckboxParameter({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onUseTemplate,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onUseTemplate;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value,
          onChanged: (next) => onChanged(next ?? false),
        ),
      ),
      _TemplateButton(onPressed: onUseTemplate),
    ],
  );
}

class _RadioParameter extends StatelessWidget {
  const _RadioParameter({
    required this.label,
    required this.control,
    required this.value,
    required this.onChanged,
    required this.onUseTemplate,
  });
  final String label;
  final ModelManifestRadioGroupControl control;
  final String value;
  final ValueChanged<Object> onChanged;
  final VoidCallback onUseTemplate;
  @override
  Widget build(BuildContext context) {
    final selected = control.options
        .map((option) => option.value)
        .where((option) => '$option' == value)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            _TemplateButton(onPressed: onUseTemplate),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        CupertinoSlidingSegmentedControl<Object>(
          groupValue: selected,
          children: {
            for (final option in control.options)
              option.value: Text(option.label),
          },
          onValueChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}

class _TemplateField extends StatelessWidget {
  const _TemplateField({
    required this.parameter,
    required this.value,
    required this.onChanged,
    required this.onReset,
  });
  final ModelManifestSetting parameter;
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TemplateExpressionTextField(
          key: ValueKey(value),
          value: value,
          suggestions: TemplateExpressionScope.suggestionsOf(context),
          decoration: InputDecoration(
            labelText: '${parameter.label} (Template)',
          ),
          onChanged: onChanged,
        ),
      ),
      IconButton(
        tooltip: 'Standardwert verwenden',
        onPressed: onReset,
        icon: const Icon(Icons.restart_alt),
      ),
    ],
  );
}

class _TemplateButton extends StatelessWidget {
  const _TemplateButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Template-Ausdruck verwenden',
    onPressed: onPressed,
    icon: const Icon(Icons.code),
  );
}
