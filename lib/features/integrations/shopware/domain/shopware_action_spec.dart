import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

enum ShopwareFieldKind { text, select, number, toggle }

class ShopwareFieldOption {
  const ShopwareFieldOption(this.value, this.label);

  final String value;
  final String label;
}

/// Ein Eingabefeld einer Shopware-Aktion. Die Oberfläche rendert die Felder
/// einer Aktion allein aus dieser Beschreibung.
class ShopwareField {
  const ShopwareField.text(
    this.key,
    this.label, {
    this.hint,
    this.helper,
    this.lines = 1,
  }) : kind = ShopwareFieldKind.text,
       options = const [],
       min = 0,
       max = 0;

  const ShopwareField.select(this.key, this.label, this.options, {this.helper})
    : kind = ShopwareFieldKind.select,
      hint = null,
      lines = 1,
      min = 0,
      max = 0;

  const ShopwareField.number(
    this.key,
    this.label, {
    required this.min,
    required this.max,
    this.helper,
  }) : kind = ShopwareFieldKind.number,
       hint = null,
       lines = 1,
       options = const [];

  /// Ein/Aus; ausgeschaltet entfällt der Eintrag in `params`.
  const ShopwareField.toggle(this.key, this.label, {this.helper})
    : kind = ShopwareFieldKind.toggle,
      hint = null,
      lines = 1,
      options = const [],
      min = 0,
      max = 0;

  /// Schlüssel in `params`; muss zur gleichnamigen Eingabe der Aktion im Backend passen.
  final String key;
  final String label;
  final ShopwareFieldKind kind;
  final String? hint;
  final String? helper;

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
    required this.title,
    required this.description,
    required this.outputBase,
    required this.primaryOutput,
    required this.secondaryOutputs,
    required this.fields,
    this.initialParams = const {},
    this.usesConnection = true,
  });

  /// Entspricht `action` im Backend (`integrations/shopware/actions`).
  final String id;
  final String title;
  final String description;
  final String outputBase;
  final NodeOutputType primaryOutput;
  final Map<String, NodeOutputType> secondaryOutputs;
  final List<ShopwareField> fields;
  final Map<String, Object?> initialParams;

  /// `false`: der Baustein liest nur das Ereignis des Auslösers und braucht
  /// keine Verbindung.
  final bool usesConnection;
}
