import 'package:equatable/equatable.dart';

/// Wie ein Feld eines Plugins in Konfigurationen und Panels dargestellt wird.
enum PluginFieldKind {
  text,
  multilineText,
  number,
  choice,
  toggle,

  /// Text, der Template-Ausdrücke wie `{{rechnung.summe}}` enthalten darf.
  template;

  static PluginFieldKind parse(String? name) => values.firstWhere(
    (kind) => kind.name == name,
    orElse: () => PluginFieldKind.text,
  );
}

/// Typ einer Ausgabe, die ein Plugin-Baustein bereitstellt.
enum PluginOutputType {
  string,
  number,
  boolean,
  datetime,
  json;

  static PluginOutputType parse(String? name) => values.firstWhere(
    (type) => type.name == name,
    orElse: () => PluginOutputType.string,
  );
}

class PluginFieldOption extends Equatable {
  const PluginFieldOption({required this.value, required this.label});

  final String value;
  final String label;

  @override
  List<Object?> get props => [value, label];
}

/// Ein deklarativ beschriebenes Eingabefeld — das Plugin liefert keinen
/// Flutter-Code, der Client rendert alles aus diesen Angaben.
class PluginField extends Equatable {
  const PluginField({
    required this.key,
    required this.label,
    required this.kind,
    this.description,
    this.required = false,
    this.secret = false,
    this.options = const [],
    this.defaultValue,
  });

  final String key;
  final String label;
  final PluginFieldKind kind;
  final String? description;
  final bool required;

  /// Geheimnisse verlassen das Backend nie; der Client sieht nur, ob eines gesetzt ist.
  final bool secret;
  final List<PluginFieldOption> options;

  /// `String`, `num` oder `bool` — passend zu [kind].
  final Object? defaultValue;

  @override
  List<Object?> get props => [
    key,
    label,
    kind,
    description,
    required,
    secret,
    options,
    defaultValue,
  ];
}

class PluginOutputDefinition extends Equatable {
  const PluginOutputDefinition({
    required this.name,
    required this.label,
    required this.type,
  });

  final String name;
  final String label;
  final PluginOutputType type;

  @override
  List<Object?> get props => [name, label, type];
}

/// Ein Baustein, den ein Plugin zur Palette beisteuert.
class PluginPrimitiveDefinition extends Equatable {
  const PluginPrimitiveDefinition({
    required this.type,
    required this.label,
    required this.description,
    this.group,
    this.icon,
    this.settings = const [],
    this.outputs = const [],
  });

  final String type;
  final String label;
  final String description;

  /// Gruppe in der Palette; ohne Angabe „Plugins“.
  final String? group;

  /// Name eines Material-Symbols, siehe `pluginIconFor`.
  final String? icon;
  final List<PluginField> settings;
  final List<PluginOutputDefinition> outputs;

  @override
  List<Object?> get props => [
    type,
    label,
    description,
    group,
    icon,
    settings,
    outputs,
  ];
}

class PluginTriggerDefinition extends Equatable {
  const PluginTriggerDefinition({
    required this.type,
    required this.label,
    required this.description,
    this.settings = const [],
  });

  final String type;
  final String label;
  final String description;
  final List<PluginField> settings;

  @override
  List<Object?> get props => [type, label, description, settings];
}

/// Ein Einstellungs-Bereich, den ein Plugin unter „Einstellungen → Plugins“ ergänzt.
class PluginSettingsPanel extends Equatable {
  const PluginSettingsPanel({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.fields = const [],
  });

  final String id;
  final String title;
  final String? description;
  final String? icon;
  final List<PluginField> fields;

  @override
  List<Object?> get props => [id, title, description, icon, fields];
}

/// Alles, was ein Plugin bündelt: Bausteine, Trigger und Einstellungs-Panels.
class PluginManifest extends Equatable {
  const PluginManifest({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    this.primitives = const [],
    this.triggers = const [],
    this.settingsPanels = const [],
  });

  final String id;
  final String version;
  final String name;
  final String description;
  final List<PluginPrimitiveDefinition> primitives;
  final List<PluginTriggerDefinition> triggers;
  final List<PluginSettingsPanel> settingsPanels;

  PluginPrimitiveDefinition? primitive(String type) {
    for (final primitive in primitives) {
      if (primitive.type == type) return primitive;
    }
    return null;
  }

  PluginTriggerDefinition? trigger(String type) {
    for (final trigger in triggers) {
      if (trigger.type == type) return trigger;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    version,
    name,
    description,
    primitives,
    triggers,
    settingsPanels,
  ];
}
