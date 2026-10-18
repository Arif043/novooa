import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operator_labels.dart';

import '../../domain/entities/activity_failure_code.dart';

extension ActivityFailureCodeLabel on ActivityFailureCode {
  /// Die übersetzte Erklärung; [details] liefert die Werte für Codes mit
  /// Platzhaltern (z. B. Operator und erhaltener Wert).
  String localizedExplanation(Map<String, String> details) => switch (this) {
    ActivityFailureCode.outputSchemaViolated =>
      LocaleKeys.activity_failures_codes_outputSchemaViolated.tr(),
    ActivityFailureCode.responseTruncated =>
      LocaleKeys.activity_failures_codes_responseTruncated.tr(),
    ActivityFailureCode.emptyResponse =>
      LocaleKeys.activity_failures_codes_emptyResponse.tr(),
    ActivityFailureCode.providerUnavailable =>
      LocaleKeys.activity_failures_codes_providerUnavailable.tr(),
    ActivityFailureCode.requestRejected =>
      LocaleKeys.activity_failures_codes_requestRejected.tr(),
    ActivityFailureCode.timedOut =>
      LocaleKeys.activity_failures_codes_timedOut.tr(),
    ActivityFailureCode.capabilityMissing =>
      LocaleKeys.activity_failures_codes_capabilityMissing.tr(),
    ActivityFailureCode.conditionOperandMismatch =>
      LocaleKeys.activity_failures_codes_conditionOperandMismatch.tr(
        namedArgs: {
          'operator': _operatorLabel(details['operator']),
          'expected': _operandKindLabel(details['expected']),
          'received': details['received'] ?? '',
        },
      ),
  };
}

/// Unbekannte Operatoren (neuere Runtime) erscheinen mit ihrem Namen.
String _operatorLabel(String? name) {
  final operator = ComparisonOperator.values.asNameMap()[name];
  return operator?.localizedLabel ?? name ?? '';
}

String _operandKindLabel(String? kind) {
  return switch (kind) {
    'number' => LocaleKeys.activity_failures_operand_kinds_number.tr(),
    'date' => LocaleKeys.activity_failures_operand_kinds_date.tr(),
    'boolean' => LocaleKeys.activity_failures_operand_kinds_boolean.tr(),
    'text' => LocaleKeys.activity_failures_operand_kinds_text.tr(),
    'file' => LocaleKeys.activity_failures_operand_kinds_file.tr(),
    _ => kind ?? '',
  };
}
