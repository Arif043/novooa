import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import 'branch_condition_operand_type.dart';

/// Feste Auswahl für einen Vergleichswert (gespeicherter Wert → Anzeige);
/// leer, wenn der Wert frei eingegeben wird.
Map<String, String> fixedConditionValuesFor(OperandTypeHint hint) {
  return switch (hint) {
    EnumTypeHint(:final values) => {for (final value in values) value: value},
    BooleanTypeHint() => {
      'true': LocaleKeys.task_builder_condition_value_kinds_true.tr(),
      'false': LocaleKeys.task_builder_condition_value_kinds_false.tr(),
    },
    _ => const <String, String>{},
  };
}
