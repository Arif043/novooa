import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/node_config.dart';

/// Sichtbarer Name eines Feldtyps im Formular-Baustein.
String dialogInputFieldTypeLabel(DialogInputFieldType type) {
  return switch (type) {
    DialogInputFieldType.string => LocaleKeys.ui_feldtyp_text,
    DialogInputFieldType.number => LocaleKeys.ui_feldtyp_zahl,
    DialogInputFieldType.integer => LocaleKeys.ui_feldtyp_ganze_zahl,
    DialogInputFieldType.decimal => LocaleKeys.ui_feldtyp_fliesskommazahl,
    DialogInputFieldType.selection => LocaleKeys.ui_feldtyp_auswahl,
    DialogInputFieldType.boolean => LocaleKeys.ui_feldtyp_schalter,
    DialogInputFieldType.radio => LocaleKeys.ui_feldtyp_radio_buttons,
    DialogInputFieldType.image => LocaleKeys.ui_feldtyp_bild,
    DialogInputFieldType.date => LocaleKeys.ui_feldtyp_datum,
    DialogInputFieldType.time => LocaleKeys.ui_feldtyp_uhrzeit,
  }.tr();
}
