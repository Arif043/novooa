import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

enum ShopwareFieldKind { text, select, number, toggle }

class ShopwareFieldOption {
  const ShopwareFieldOption(this.value, this.labelKey);

  final String value;

  /// Übersetzungsschlüssel; übersetzt wird in `presentation/`.
  final String labelKey;
}

/// Ein Eingabefeld einer Shopware-Aktion. Die Oberfläche rendert die Felder
/// einer Aktion allein aus dieser Beschreibung; Texte sind
/// Übersetzungsschlüssel (`…Key`).
class ShopwareField {
  const ShopwareField.text(
    this.key,
    this.labelKey, {
    this.hintKey,
    this.helperKey,
    this.lines = 1,
  }) : kind = ShopwareFieldKind.text,
       options = const [],
       min = 0,
       max = 0;

  const ShopwareField.select(
    this.key,
    this.labelKey,
    this.options, {
    this.helperKey,
  }) : kind = ShopwareFieldKind.select,
       hintKey = null,
       lines = 1,
       min = 0,
       max = 0;

  const ShopwareField.number(
    this.key,
    this.labelKey, {
    required this.min,
    required this.max,
    this.helperKey,
  }) : kind = ShopwareFieldKind.number,
       hintKey = null,
       lines = 1,
       options = const [];

  /// Ein/Aus; ausgeschaltet entfällt der Eintrag in `params`.
  const ShopwareField.toggle(this.key, this.labelKey, {this.helperKey})
    : kind = ShopwareFieldKind.toggle,
      hintKey = null,
      lines = 1,
      options = const [],
      min = 0,
      max = 0;

  /// Schlüssel in `params`; muss zur gleichnamigen Eingabe der Aktion im Backend passen.
  final String key;
  final String labelKey;
  final ShopwareFieldKind kind;
  final String? hintKey;
  final String? helperKey;

  /// Sichtbare Zeilen eines Textfelds; mehr als eine ergibt ein mehrzeiliges Feld.
  final int lines;
  final List<ShopwareFieldOption> options;
  final int min;
  final int max;
}

/// Eine Aktion des Shopware-Bausteins. Für Nutzer:innen ist jede Aktion ein
/// eigener Baustein; im Backend teilen sie sich das Primitive `shopware`.
class ShopwareActionSpec {
  const ShopwareActionSpec({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.outputBase,
    required this.primaryOutput,
    required this.outputFields,
    required this.fields,
    this.initialParams = const {},
    this.usesConnection = true,
  });

  /// Entspricht `action` im Backend (`integrations/shopware/actions`).
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String outputBase;
  final NodeOutputType primaryOutput;
  final Map<String, NodeOutputType> outputFields;
  final List<ShopwareField> fields;
  final Map<String, Object?> initialParams;

  /// `false`: der Baustein liest nur das Ereignis des Auslösers und braucht
  /// keine Verbindung.
  final bool usesConnection;
}
