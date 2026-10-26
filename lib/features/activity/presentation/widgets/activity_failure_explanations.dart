import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/plugins/presentation/plugin_catalog.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operator_labels.dart';

import '../../domain/entities/activity_failure_code.dart';
import 'activity_failure_detail_labels.dart';

typedef FailureArguments = Map<String, String> Function(Map<String, String>);

/// Übersetzungsschlüssel einer Failure und wie ihre Details die Platzhalter
/// füllen.
class ActivityFailureExplanation {
  const ActivityFailureExplanation(this.key, [this.argumentsFor = _none]);

  final String key;
  final FailureArguments argumentsFor;
}

Map<String, String> _none(Map<String, String> details) => const {};

/// Eine Erklärung je Code (Strategie); neue Codes kommen hier hinzu.
const activityFailureExplanations =
    <ActivityFailureCode, ActivityFailureExplanation>{
      ActivityFailureCode.outputSchemaViolated: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_outputSchemaViolated,
      ),
      ActivityFailureCode.responseTruncated: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_responseTruncated,
      ),
      ActivityFailureCode.emptyResponse: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_emptyResponse,
      ),
      ActivityFailureCode.providerUnavailable: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_providerUnavailable,
      ),
      ActivityFailureCode.requestRejected: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_requestRejected,
      ),
      ActivityFailureCode.timedOut: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_timedOut,
      ),
      ActivityFailureCode.capabilityMissing: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_capabilityMissing,
      ),
      ActivityFailureCode.conditionOperandMismatch: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_conditionOperandMismatch,
        _operandArguments,
      ),
      ActivityFailureCode.configurationMissing: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_configurationMissing,
        _primitiveArguments,
      ),
      ActivityFailureCode.settingMissing: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_settingMissing,
        _settingArguments,
      ),
      ActivityFailureCode.settingInvalid: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_settingInvalid,
        _settingArguments,
      ),
      ActivityFailureCode.valueTypeMismatch: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_valueTypeMismatch,
        _valueTypeArguments,
      ),
      ActivityFailureCode.tensorShapeMismatch: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_tensorShapeMismatch,
        _rawNameArguments,
      ),
      ActivityFailureCode.modelOutputInvalid: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_modelOutputInvalid,
        _outputArguments,
      ),
      ActivityFailureCode.triggerMismatch: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_triggerMismatch,
        _triggerArguments,
      ),
      ActivityFailureCode.capabilityUnavailable: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_capabilityUnavailable,
        _capabilityArguments,
      ),
      ActivityFailureCode.httpBodyInvalidJson: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_httpBodyInvalidJson,
      ),
      ActivityFailureCode.httpStatusFailed: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_httpStatusFailed,
        _statusArguments,
      ),
      ActivityFailureCode.forEachUnsupported: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_forEachUnsupported,
        _forEachArguments,
      ),
      ActivityFailureCode.scriptFailed: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_scriptFailed,
      ),
      ActivityFailureCode.scriptOutputInvalid: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_scriptOutputInvalid,
        _scriptOutputArguments,
      ),
      ActivityFailureCode.scriptPackagesUnavailable: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_scriptPackagesUnavailable,
        _scriptPackagesArguments,
      ),
      ActivityFailureCode.pluginDisabled: ActivityFailureExplanation(
        LocaleKeys.activity_failures_codes_pluginDisabled,
        _pluginArguments,
      ),
    };

/// Name des Plugins aus dem Katalog der App; unbekannt bleibt die Kennung.
Map<String, String> _pluginArguments(Map<String, String> details) {
  final id = details['plugin'] ?? '';
  final plugin = PluginCatalog.all.where((entry) => entry.id.value == id);
  return {'plugin': plugin.isEmpty ? id : plugin.first.title};
}

Map<String, String> _operandArguments(Map<String, String> details) => {
  'operator': _operatorLabel(details['operator']),
  'expected': failureDetailLabel('operand_kinds', details['expected']),
  'received': details['received'] ?? '',
};

Map<String, String> _primitiveArguments(Map<String, String> details) => {
  'primitive': details['primitive'] ?? '',
};

Map<String, String> _settingArguments(Map<String, String> details) => {
  'setting': failureDetailLabel('settings', details['setting']),
  'name': _nameSuffix(details['name']),
};

Map<String, String> _valueTypeArguments(Map<String, String> details) => {
  'target': failureDetailLabel('targets', details['target']),
  'expected': failureDetailLabel('expected', details['expected']),
  'name': _nameSuffix(details['name']),
};

Map<String, String> _rawNameArguments(Map<String, String> details) => {
  'name': details['name'] ?? '',
};

Map<String, String> _outputArguments(Map<String, String> details) => {
  'output': failureDetailLabel('outputs', details['output']),
};

Map<String, String> _triggerArguments(Map<String, String> details) => {
  'trigger': failureDetailLabel('triggers', details['trigger']),
};

Map<String, String> _capabilityArguments(Map<String, String> details) => {
  'capability': failureDetailLabel('capabilities', details['capability']),
};

Map<String, String> _statusArguments(Map<String, String> details) => {
  'status': details['status'] ?? '',
};

Map<String, String> _forEachArguments(Map<String, String> details) => {
  'reason': failureDetailLabel('for_each_reasons', details['reason']),
};

Map<String, String> _scriptOutputArguments(Map<String, String> details) => {
  'reason': failureDetailLabel('script_output_reasons', details['reason']),
  'name': _nameSuffix(details['name']),
};

Map<String, String> _scriptPackagesArguments(Map<String, String> details) => {
  'reason': failureDetailLabel('script_packages_reasons', details['reason']),
  'packages': details['packages'] ?? '',
};

String _nameSuffix(String? name) {
  if (name == null || name.isEmpty) return '';
  return LocaleKeys.activity_failures_name_suffix.tr(namedArgs: {'name': name});
}

/// Unbekannte Operatoren (neuere Runtime) erscheinen mit ihrem Namen.
String _operatorLabel(String? name) {
  final operator = ComparisonOperator.values.asNameMap()[name];
  return operator?.localizedLabel ?? name ?? '';
}
