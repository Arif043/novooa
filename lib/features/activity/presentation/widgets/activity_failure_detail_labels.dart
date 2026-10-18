import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Übersetzte Detailwerte einer Failure (z. B. `setting: model` → „Modell“).
/// Unbekannte Werte (neuere Runtime) erscheinen roh.
String failureDetailLabel(String group, String? value) {
  if (value == null) return '';
  return _labels[group]?[value]?.tr() ?? value;
}

const _labels = <String, Map<String, String>>{
  'operand_kinds': {
    'number': LocaleKeys.activity_failures_operand_kinds_number,
    'date': LocaleKeys.activity_failures_operand_kinds_date,
    'boolean': LocaleKeys.activity_failures_operand_kinds_boolean,
    'text': LocaleKeys.activity_failures_operand_kinds_text,
    'file': LocaleKeys.activity_failures_operand_kinds_file,
  },
  'settings': {
    'model': LocaleKeys.activity_failures_settings_model,
    'modelInputMapping':
        LocaleKeys.activity_failures_settings_modelInputMapping,
    'inputFile': LocaleKeys.activity_failures_settings_inputFile,
    'outputFile': LocaleKeys.activity_failures_settings_outputFile,
    'audioInput': LocaleKeys.activity_failures_settings_audioInput,
    'recipient': LocaleKeys.activity_failures_settings_recipient,
    'messageBody': LocaleKeys.activity_failures_settings_messageBody,
    'notificationText': LocaleKeys.activity_failures_settings_notificationText,
    'mailbox': LocaleKeys.activity_failures_settings_mailbox,
    'modelInputDuplicate':
        LocaleKeys.activity_failures_settings_modelInputDuplicate,
    'modelParameter': LocaleKeys.activity_failures_settings_modelParameter,
    'documentFilterValue':
        LocaleKeys.activity_failures_settings_documentFilterValue,
    'documentFieldValue':
        LocaleKeys.activity_failures_settings_documentFieldValue,
    'documentFieldDuplicate':
        LocaleKeys.activity_failures_settings_documentFieldDuplicate,
    'jsonPointer': LocaleKeys.activity_failures_settings_jsonPointer,
  },
  'targets': {
    'modelInput': LocaleKeys.activity_failures_targets_modelInput,
    'documentFilter': LocaleKeys.activity_failures_targets_documentFilter,
    'forEachItems': LocaleKeys.activity_failures_targets_forEachItems,
  },
  'expected': {
    'image': LocaleKeys.activity_failures_expected_image,
    'audio': LocaleKeys.activity_failures_expected_audio,
    'file': LocaleKeys.activity_failures_expected_file,
    'number': LocaleKeys.activity_failures_expected_number,
    'boolean': LocaleKeys.activity_failures_expected_boolean,
    'json': LocaleKeys.activity_failures_expected_json,
    'textList': LocaleKeys.activity_failures_expected_textList,
    'numberList': LocaleKeys.activity_failures_expected_numberList,
    'list': LocaleKeys.activity_failures_expected_list,
    'tensor': LocaleKeys.activity_failures_expected_tensor,
  },
  'outputs': {
    'image': LocaleKeys.activity_failures_outputs_image,
    'audio': LocaleKeys.activity_failures_outputs_audio,
  },
  'triggers': {
    'email': LocaleKeys.activity_failures_triggers_email,
    'whatsapp': LocaleKeys.activity_failures_triggers_whatsapp,
    'sms': LocaleKeys.activity_failures_triggers_sms,
    'telegram': LocaleKeys.activity_failures_triggers_telegram,
    'instagram': LocaleKeys.activity_failures_triggers_instagram,
    'webhook': LocaleKeys.activity_failures_triggers_webhook,
  },
  'capabilities': {
    'speechSynthesis':
        LocaleKeys.activity_failures_capabilities_speechSynthesis,
    'speechTranscription':
        LocaleKeys.activity_failures_capabilities_speechTranscription,
    'httpRequests': LocaleKeys.activity_failures_capabilities_httpRequests,
    'float16Tensors': LocaleKeys.activity_failures_capabilities_float16Tensors,
  },
  'for_each_reasons': {
    'nestedForEach':
        LocaleKeys.activity_failures_for_each_reasons_nestedForEach,
    'pausingBlock': LocaleKeys.activity_failures_for_each_reasons_pausingBlock,
  },
  'script_output_reasons': {
    'duplicateName':
        LocaleKeys.activity_failures_script_output_reasons_duplicateName,
    'invalidEntry':
        LocaleKeys.activity_failures_script_output_reasons_invalidEntry,
    'invalidName':
        LocaleKeys.activity_failures_script_output_reasons_invalidName,
    'unknownType':
        LocaleKeys.activity_failures_script_output_reasons_unknownType,
    'wrongValueType':
        LocaleKeys.activity_failures_script_output_reasons_wrongValueType,
  },
};
