import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_record.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import '../widgets/database_filter_bar.dart';
import '../widgets/database_record_editor_dialog.dart';

class DatabasePage extends StatelessWidget {
  const DatabasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DatabaseCubit>()..loadCollections(),
      child: const _DatabaseView(),
    );
  }
}

class _DatabaseView extends StatelessWidget {
  const _DatabaseView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DatabaseCubit, DatabaseState>(
      listenWhen: (before, after) => before.message != after.message,
      listener: _message,
      builder: (context, state) => Scaffold(
        floatingActionButton: state.status == DatabaseStatus.records
            ? FloatingActionButton(
                tooltip: 'Datensatz anlegen',
                onPressed: state.isMutating
                    ? null
                    : () => _editRecord(context, state.collection!.name),
                child: const Icon(Icons.add),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: switch (state.status) {
            DatabaseStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            DatabaseStatus.failure => _Failure(
              message:
                  state.message ?? 'Die Daten konnten nicht geladen werden.',
            ),
            DatabaseStatus.collections => _CollectionList(
              collections: state.collections,
            ),
            DatabaseStatus.records => _RecordList(state),
          },
        ),
      ),
    );
  }

  void _message(BuildContext context, DatabaseState state) {
    final message = state.message;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    String collectionName, [
    DataRecord? record,
  ]) async {
    final fields = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => DatabaseRecordEditorDialog(record: record),
    );
    if (fields == null || !context.mounted) return;
    final cubit = context.read<DatabaseCubit>();
    if (record == null) {
      await cubit.createRecord(fields);
    } else {
      await cubit.updateRecord(record, fields);
    }
  }
}

class _CollectionList extends StatelessWidget {
  const _CollectionList({required this.collections});

  final List<DataCollection> collections;

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Datensammlungen vorhanden. Sie entstehen durch Aufgaben.',
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Datenbank', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Datensammlungen aus deinen Aufgaben.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Datensammlung')),
                DataColumn(label: Text('Datensätze'), numeric: true),
              ],
              rows: collections
                  .map(
                    (collection) => DataRow(
                      onSelectChanged: (_) => context
                          .read<DatabaseCubit>()
                          .openCollection(collection),
                      cells: [
                        DataCell(Text(collection.name)),
                        DataCell(Text('${collection.documentCount}')),
                      ],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecordList extends StatelessWidget {
  const _RecordList(this.state);

  final DatabaseState state;

  @override
  Widget build(BuildContext context) {
    final fields =
        state.records.expand((record) => record.fields.keys).toSet().toList()
          ..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Datensammlungen',
              onPressed: () => context.read<DatabaseCubit>().showCollections(),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                state.collection!.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        DatabaseFilterBar(state: state),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: state.records.isEmpty
              ? const Center(
                  child: Text('Keine passenden Datensätze vorhanden.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        ...fields.map(
                          (field) => DataColumn(label: Text(field)),
                        ),
                        const DataColumn(label: Text('')),
                      ],
                      rows: state.records
                          .map(
                            (record) => DataRow(
                              onSelectChanged: (_) => _edit(context, record),
                              cells: [
                                ...fields.map(
                                  (field) => DataCell(
                                    Text(_display(record.fields[field])),
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    tooltip: 'Datensatz löschen',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: state.isMutating
                                        ? null
                                        : () => _delete(context, record),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context, DataRecord record) async {
    final fields = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => DatabaseRecordEditorDialog(record: record),
    );
    if (fields != null && context.mounted) {
      await context.read<DatabaseCubit>().updateRecord(record, fields);
    }
  }

  Future<void> _delete(BuildContext context, DataRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datensatz löschen?'),
        content: const Text('Der Datensatz wird dauerhaft gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<DatabaseCubit>().deleteRecord(record);
    }
  }

  String _display(Object? value) {
    if (value == null) return 'Leer';
    if (value is Map || value is List) return 'Strukturierte Daten';
    return '$value';
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => context.read<DatabaseCubit>().loadCollections(),
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
