import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_sort.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import 'database_record_actions.dart';
import 'database_sheet.dart';
import 'database_sheet_options.dart';
import 'database_states.dart';

/// Datensätze als Blatt mit Auswahlspalte, sortierbaren Spalten und Löschen je Zeile.
class DatabaseRecordsSheet extends StatelessWidget {
  const DatabaseRecordsSheet({
    super.key,
    required this.state,
    required this.enabled,
  });

  final DatabaseState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (state.records.isEmpty) {
      return DatabaseEmptyState(
        title: LocaleKeys.ui_db_empty_records_title.tr(),
        message: LocaleKeys.ui_db_empty_records_body.tr(),
      );
    }
    final fields =
        state.records.expand((record) => record.fields.keys).toSet().toList()
          ..sort();
    final cubit = context.read<DatabaseCubit>();
    final records = state.records;
    return DatabaseSheet(
      key: ValueKey(state.collection!.name),
      columns: fields.isEmpty ? [LocaleKeys.ui_db_import_fields.tr()] : fields,
      rows: [
        for (final record in records)
          fields.isEmpty
              ? [LocaleKeys.ui_db_cell_empty.tr()]
              : [
                  for (final field in fields)
                    databaseCellText(record.fields[field]),
                ],
      ],
      enabled: enabled,
      onOpen: (index) => editDatabaseRecord(context, records[index]),
      selection: DatabaseSheetSelection(
        isSelected: (row) => state.selectedIds.contains(records[row].id),
        onToggleRow: (row) => cubit.toggleSelection(records[row]),
        allSelected: state.allSelected,
        anySelected: state.selectedIds.isNotEmpty,
        onToggleAll: cubit.toggleAllSelected,
      ),
      sort: DatabaseSheetSort(
        column: _sortedColumn(fields),
        ascending: state.sort?.direction != DataSortDirection.descending,
        isSortable: (column) =>
            fields.isNotEmpty && DataSort.isSortable(fields[column]),
        onSort: (column) => cubit.toggleSort(fields[column]),
      ),
      trailingBuilder: (_, index) => IconButton(
        tooltip: LocaleKeys.ui_db_record_delete.tr(),
        onPressed: enabled
            ? () => deleteDatabaseRecord(context, records[index])
            : null,
        icon: const Icon(CupertinoIcons.trash, size: AppSpacing.gutter),
      ),
    );
  }

  int? _sortedColumn(List<String> fields) {
    final index = fields.indexOf(state.sort?.field ?? '');
    return index < 0 ? null : index;
  }
}
