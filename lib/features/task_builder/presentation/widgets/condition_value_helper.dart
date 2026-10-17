import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/node_config.dart';
import 'branch_condition_operand_type.dart';

/// Hilfetext unter einem festen Vergleichswert, wo das Format nicht
/// selbsterklärend ist (Datum, Dateityp, Zeilenanzahl).
String? conditionValueHelperFor(
  OperandTypeHint hint,
  ComparisonOperator operator,
) {
  return switch (hint) {
    DateTimeTypeHint() =>
      LocaleKeys.task_builder_condition_value_hints_date.tr(),
    FileTypeHint() when operator == ComparisonOperator.contentTypeIs =>
      LocaleKeys.task_builder_condition_value_hints_content_type.tr(),
    TableTypeHint() =>
      LocaleKeys.task_builder_condition_value_hints_row_count.tr(),
    _ => null,
  };
}
