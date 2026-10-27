import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_file.dart';
import '../../domain/entities/data_record_query.dart';
import '../cubits/database_actions_cubit.dart';
import '../cubits/database_cubit.dart';
import 'database_confirm_dialog.dart';
import 'database_import_dialog.dart';
import 'database_name_dialog.dart';

enum DatabaseCollectionAction {
  import,
  exportCsv,
  exportJson,
  rename,
  clear,
  delete,
}

/// Führt eine Menüaktion aus: Rückfrage oder Dialog, Aktion, danach gezielt neu laden.
Future<void> runDatabaseCollectionAction(
  BuildContext context,
  DatabaseCollectionAction action,
  DataCollection collection,
) => switch (action) {
  DatabaseCollectionAction.import => _import(context, collection),
  DatabaseCollectionAction.exportCsv => _export(
    context,
    collection,
    DataFileFormat.csv,
  ),
  DatabaseCollectionAction.exportJson => _export(
    context,
    collection,
    DataFileFormat.json,
  ),
  DatabaseCollectionAction.rename => _rename(context, collection),
  DatabaseCollectionAction.clear => _clear(context, collection),
  DatabaseCollectionAction.delete => _delete(context, collection),
};

Future<void> createDatabaseCollection(BuildContext context) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final name = await showDatabaseNameDialog(context);
  if (name == null) return;
  final created = await actions.createCollection(name);
  if (created != null) await database.openCollection(created);
}

Future<void> deleteSelectedDatabaseRecords(BuildContext context) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final collection = database.state.collection;
  final records = database.state.selectedRecords;
  if (collection == null || records.isEmpty) return;
  final confirmed = await confirmDatabaseAction(
    context,
    title: LocaleKeys.ui_db_delete_records_title.tr(
      namedArgs: {'count': '${records.length}'},
    ),
    body: LocaleKeys.ui_db_delete_records_body.tr(),
    confirmLabel: LocaleKeys.ui_loeschen.tr(),
  );
  if (confirmed && await actions.deleteRecords(collection, records)) {
    await database.reload();
  }
}

Future<void> _import(BuildContext context, DataCollection collection) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final imported = await showDatabaseImportDialog(context, collection);
  if (imported != null) {
    actions.reportImported(imported);
    await database.reload(collection: collection);
  }
}

Future<void> _export(
  BuildContext context,
  DataCollection collection,
  DataFileFormat format,
) {
  final database = context.read<DatabaseCubit>();
  // Aus der Übersicht ohne Suche und Filter; im Blatt mit der aktuellen Ansicht.
  final query = database.state.collection?.name == collection.name
      ? database.state.query
      : const DataRecordQuery();
  return context.read<DatabaseActionsCubit>().export(collection, format, query);
}

Future<void> _rename(BuildContext context, DataCollection collection) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final name = await showDatabaseNameDialog(context, current: collection);
  if (name == null) return;
  final renamed = await actions.renameCollection(collection, name);
  if (renamed == null) return;
  final wasOpen = database.state.collection?.name == collection.name;
  await database.reload(collection: wasOpen ? renamed : null);
}

Future<void> _clear(BuildContext context, DataCollection collection) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final args = {
    'name': collection.name,
    'count': '${collection.documentCount}',
  };
  final confirmed = await confirmDatabaseAction(
    context,
    title: LocaleKeys.ui_db_clear_title.tr(namedArgs: args),
    body: LocaleKeys.ui_db_clear_body.tr(namedArgs: args),
    confirmLabel: LocaleKeys.ui_db_clear_confirm.tr(),
  );
  if (confirmed && await actions.clearCollection(collection)) {
    await database.reload();
  }
}

Future<void> _delete(BuildContext context, DataCollection collection) async {
  final actions = context.read<DatabaseActionsCubit>();
  final database = context.read<DatabaseCubit>();
  final args = {
    'name': collection.name,
    'count': '${collection.documentCount}',
  };
  final confirmed = await confirmDatabaseAction(
    context,
    title: LocaleKeys.ui_db_delete_title.tr(namedArgs: args),
    body: LocaleKeys.ui_db_delete_body.tr(namedArgs: args),
    confirmLabel: LocaleKeys.ui_loeschen.tr(),
  );
  if (confirmed && await actions.deleteCollection(collection)) {
    await database.showCollections();
  }
}
