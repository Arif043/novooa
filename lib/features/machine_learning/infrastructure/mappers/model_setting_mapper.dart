import '../../domain/entities/model_catalog_entry.dart';
import 'model_json_fields.dart';

/// Übersetzt die Einstellungen eines Modellvertrags (Schieberegler, Checkbox, Auswahl).
class ModelSettingMapper {
  const ModelSettingMapper();

  ModelManifestSetting fromJson(Object? value) {
    final parameter = jsonObject(value);
    return ModelManifestSetting(
      name: jsonText(parameter, 'name'),
      label: jsonText(parameter, 'label'),
      control: _settingControlFrom(parameter['control']),
    );
  }

  ModelManifestSettingControl _settingControlFrom(Object? value) {
    final control = jsonObject(value);
    return switch (jsonText(control, 'type')) {
      'slider' => ModelManifestSliderControl(
        initial: jsonNumber(control['initial']),
        minimum: jsonNumber(control['minimum']),
        maximum: jsonNumber(control['maximum']),
        step: jsonNumber(control['step']),
      ),
      'checkbox' => ModelManifestCheckboxControl(
        initial: jsonBoolean(control['initial']),
      ),
      'radioGroup' => ModelManifestRadioGroupControl(
        initial: _parameterValue(control['initial']),
        options: jsonItems(
          control['options'],
        ).map(_radioOptionFrom).toList(growable: false),
      ),
      _ => throw const FormatException('Der Modellparameter ist ungültig.'),
    };
  }

  ModelManifestSettingOption _radioOptionFrom(Object? value) {
    final option = jsonObject(value);
    return ModelManifestSettingOption(
      value: _parameterValue(option['value']),
      label: jsonText(option, 'label'),
    );
  }

  Object _parameterValue(Object? value) {
    if (value is String || value is bool || value is num) {
      return value as Object;
    }
    throw const FormatException('Der Modellparameter ist ungültig.');
  }
}
