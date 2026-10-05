import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

enum ShopwareFieldKind { text, select, number }

class ShopwareFieldOption {
  const ShopwareFieldOption(this.value, this.label);

  final String value;
  final String label;
}

/// Ein Eingabefeld einer Shopware-Aktion. Die Oberfläche rendert die Felder
/// einer Aktion allein aus dieser Beschreibung.
class ShopwareField {
  const ShopwareField.text(this.key, this.label, {this.hint, this.helper})
    : kind = ShopwareFieldKind.text,
      options = const [],
      min = 0,
      max = 0;

  const ShopwareField.select(this.key, this.label, this.options, {this.helper})
    : kind = ShopwareFieldKind.select,
      hint = null,
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
       options = const [];

  /// Schlüssel in `params`; muss zur gleichnamigen Eingabe der Aktion im Backend passen.
  final String key;
  final String label;
  final ShopwareFieldKind kind;
  final String? hint;
  final String? helper;
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
}
