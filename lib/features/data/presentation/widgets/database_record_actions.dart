import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/data_record.dart';
import '../cubits/database_cubit.dart';
import 'database_confirm_dialog.dart';
import 'database_record_editor_dialog.dart';

/// Öffnet den Editor; ohne [record] legt er einen neuen Datensatz an.
Future<void> editDatabaseRecord(
  BuildContext context, [
  DataRecord? record,
]) async {
  final cubit = context.read<DatabaseCubit>();
  final fields = await showDialog<Map<String, Object?>>(
    context: context,
    builder: (_) => DatabaseRecordEditorDialog(record: record),
  );
  if (fields == null) return;
  if (record == null) {
    await cubit.createRecord(fields);
  } else {
    await cubit.updateRecord(record, fields);
  }
}

Future<void> deleteDatabaseRecord(
  BuildContext context,
  DataRecord record,
) async {
  final cubit = context.read<DatabaseCubit>();
  final confirmed = await confirmDatabaseAction(
    context,
    title: LocaleKeys.ui_db_record_delete_title.tr(),
    body: LocaleKeys.ui_db_record_delete_body.tr(),
    confirmLabel: LocaleKeys.ui_loeschen.tr(),
  );
  if (confirmed) await cubit.deleteRecord(record);
}

/// Anzeige eines Feldwerts in einer Zelle; Strukturen zeigt erst der Editor.
String databaseCellText(Object? value) {
  if (value == null) return LocaleKeys.ui_db_cell_empty.tr();
  if (value is Map || value is List) {
    return LocaleKeys.ui_db_cell_structured.tr();
  }
  return '$value';
}
