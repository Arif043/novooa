part of 'model_input_parameter_configuration.dart';

class _ParameterControl extends StatelessWidget {
  const _ParameterControl({
    required this.nodeId,
    required this.parameter,
    required this.value,
  });
  final NodeId nodeId;
  final ModelManifestSetting parameter;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.contains('{{')) {
      return _TemplateField(
        parameter: parameter,
        value: value,
        onChanged: _update(context),
        onReset: () => _update(context)('${parameter.control.initialValue()}'),
      );
    }
    return switch (parameter.control) {
      ModelManifestSliderControl control => _SliderParameter(
        label: parameter.label,
        control: control,
        value: _sliderValue(control),
        onChanged: (next) => _update(context)('$next'),
        onUseTemplate: () => _update(context)('{{}}'),
      ),
      ModelManifestCheckboxControl() => _CheckboxParameter(
        label: parameter.label,
        value: value == 'true',
        onChanged: (next) => _update(context)('$next'),
        onUseTemplate: () => _update(context)('{{}}'),
      ),
      ModelManifestRadioGroupControl control => _RadioParameter(
        label: parameter.label,
        control: control,
        value: value,
        onChanged: (next) => _update(context)('$next'),
        onUseTemplate: () => _update(context)('{{}}'),
      ),
    };
  }

  double _sliderValue(ModelManifestSliderControl control) {
    final parsed = double.tryParse(value);
    return parsed == null ||
            parsed < control.minimum ||
            parsed > control.maximum
        ? control.initial
        : parsed;
  }

  ValueChanged<String> _update(BuildContext context) =>
      (next) => context.read<TaskBuilderCubit>().updateModelInferenceSetting(
        nodeId,
        ModelInferenceSetting(name: parameter.name, valueTemplate: next),
      );
}
