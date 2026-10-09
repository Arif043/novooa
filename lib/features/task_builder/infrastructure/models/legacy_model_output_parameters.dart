import '../../domain/entities/node_config.dart';

/// Gespeicherte Modell-Bausteine konnten Ausgangsparameter als `outputParameters`
/// tragen. Heute sind das Settings: Jeder Eintrag wird zum Setting
/// `<ausgang>_<name>` mit dem gespeicherten Wert. Die Runtime wandelt alte
/// Parameterbeschreibungen im Manifest nach derselben Namensregel um.
/// Ein vorhandenes Setting gleichen Namens behält Vorrang.
List<ModelInferenceSetting> settingsWithLegacyOutputParameters(
  List<ModelInferenceSetting> settings,
  Object? outputParameters,
) {
  if (outputParameters is! List) return settings;
  final names = {for (final setting in settings) setting.name};
  final converted = [
    for (final entry in outputParameters.whereType<Map>()) ?_settingFor(entry),
  ].where((setting) => names.add(setting.name));
  return [...settings, ...converted];
}

/// Muss der Namensregel `legacyOutputParameterSettingName` der Runtime entsprechen.
String legacyOutputParameterSettingName(String outputName, String name) {
  final settingName = '${outputName}_$name'.replaceAll(RegExp(r'\W'), '_');
  return RegExp(r'^\d').hasMatch(settingName) ? '_$settingName' : settingName;
}

ModelInferenceSetting? _settingFor(Map<dynamic, dynamic> entry) {
  final outputName = entry['outputName'];
  final name = entry['name'];
  final value = entry['value'];
  if (outputName is! String || name is! String || value is! num) return null;
  return ModelInferenceSetting(
    name: legacyOutputParameterSettingName(outputName, name),
    valueTemplate: '$value',
  );
}
