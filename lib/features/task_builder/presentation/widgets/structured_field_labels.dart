import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/node_config.dart';

/// Typen, die der Prompt-Baustein liefern kann; Dateien schreibt nur ein Team.
const promptFieldTypes = [
  StructuredFieldType.string,
  StructuredFieldType.number,
  StructuredFieldType.boolean,
  StructuredFieldType.datetime,
  StructuredFieldType.json,
];

extension StructuredFieldTypeLabel on StructuredFieldType {
  String get label => switch (this) {
    StructuredFieldType.string => LocaleKeys.ui_field_type_string.tr(),
    StructuredFieldType.number => LocaleKeys.ui_field_type_number.tr(),
    StructuredFieldType.boolean => LocaleKeys.ui_field_type_boolean.tr(),
    StructuredFieldType.datetime => LocaleKeys.ui_field_type_datetime.tr(),
    StructuredFieldType.json => LocaleKeys.ui_field_type_json.tr(),
    StructuredFieldType.file => LocaleKeys.ui_field_type_file.tr(),
  };
}

extension OutputFileFormatLabel on OutputFileFormat {
  String get label => switch (this) {
    OutputFileFormat.markdown => LocaleKeys.ui_file_format_markdown.tr(),
    OutputFileFormat.csv => LocaleKeys.ui_file_format_csv.tr(),
    OutputFileFormat.json => LocaleKeys.ui_file_format_json.tr(),
    OutputFileFormat.text => LocaleKeys.ui_file_format_text.tr(),
  };
}
