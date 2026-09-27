import 'package:equatable/equatable.dart';

class ModelManifestSetting extends Equatable {
  const ModelManifestSetting({
    required this.name,
    required this.label,
    required this.control,
  });
  final String name;
  final String label;
  final ModelManifestSettingControl control;
  @override
  List<Object?> get props => [name, label, control];
}

sealed class ModelManifestSettingControl extends Equatable {
  const ModelManifestSettingControl();
  Object initialValue();
}

class ModelManifestSliderControl extends ModelManifestSettingControl {
  const ModelManifestSliderControl({
    required this.initial,
    required this.minimum,
    required this.maximum,
    required this.step,
  });
  final double initial;
  final double minimum;
  final double maximum;
  final double step;
  @override
  double initialValue() => initial;
  @override
  List<Object?> get props => [initial, minimum, maximum, step];
}

class ModelManifestCheckboxControl extends ModelManifestSettingControl {
  const ModelManifestCheckboxControl({required this.initial});
  final bool initial;
  @override
  bool initialValue() => initial;
  @override
  List<Object?> get props => [initial];
}

class ModelManifestRadioGroupControl extends ModelManifestSettingControl {
  const ModelManifestRadioGroupControl({
    required this.initial,
    required this.options,
  });
  final Object initial;
  final List<ModelManifestSettingOption> options;
  @override
  Object initialValue() => initial;
  @override
  List<Object?> get props => [initial, options];
}

class ModelManifestSettingOption extends Equatable {
  const ModelManifestSettingOption({required this.value, required this.label});
  final Object value;
  final String label;
  @override
  List<Object?> get props => [value, label];
}
