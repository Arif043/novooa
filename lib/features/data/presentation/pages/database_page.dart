import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/data_record.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';
import '../widgets/database_filter_bar.dart';
import '../widgets/database_record_editor_dialog.dart';
import '../widgets/database_sheet.dart';
import '../widgets/database_theme.dart';

class DatabasePage extends StatelessWidget {
  const DatabasePage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => serviceLocator<DatabaseCubit>()..loadCollections(), child: const DatabaseView());
}

class DatabaseView extends StatelessWidget {
  const DatabaseView({super.key});
  @override
  Widget build(BuildContext context) => Theme(
    data: DatabaseTheme.from(Theme.of(context)),
    child: Builder(
      builder: (context) => BlocConsumer<DatabaseCubit, DatabaseState>(
        listenWhen: (before, after) => before.message != after.message,
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 16 : 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = _Workspace(state: state);
                  if (constraints.maxHeight < 540) {
                    return SingleChildScrollView(child: SizedBox(height: 660, child: content));
                  }
                  return content;
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.state});
  final DatabaseState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseCubit>();
    final records = state.status == DatabaseStatus.records;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (state.collection != null && records)
              IconButton(
                tooltip: 'Datensammlungen',
                onPressed: state.isMutating ? null : cubit.showCollections,
                icon: const Icon(CupertinoIcons.chevron_left),
              ),
            if (records) Text(state.collection!.name, style: theme.textTheme.titleLarge),
            if (records)
              FilledButton.icon(
                onPressed: state.isMutating ? null : () => _edit(context),
                icon: const Icon(CupertinoIcons.add, size: 20),
                label: const Text('Datensatz anlegen'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (records) Text(
           '${state.records.length} Datensätze · Zeile zum Bearbeiten öffnen',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        if (records) ...[
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .28),
            child: SingleChildScrollView(child: DatabaseFilterBar(state: state)),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: switch (state.status) {
            DatabaseStatus.loading => const Center(child: CupertinoActivityIndicator()),
            DatabaseStatus.failure => _Failure(message: state.message ?? 'Die Daten konnten nicht geladen werden.'),
            DatabaseStatus.collections =>
              state.collections.isEmpty
                  ? const _Empty(
                      title: 'Deine Daten bekommen hier ihren Platz',
                      message: 'Datensammlungen entstehen durch deine Aufgaben und erscheinen automatisch hier.',
                    )
                  : DatabaseSheet(
                      columns: const ['Datensammlung', 'Datensätze'],
                      rows: state.collections.map((c) => [c.name, '${c.documentCount}']).toList(),
                      onOpen: (index) => cubit.openCollection(state.collections[index]),
                    ),
            DatabaseStatus.records => _Records(state: state),
          },
        ),
        if (records) ...[const SizedBox(height: 12), _CollectionTabs(state: state)],
      ],
    );
  }
}

class _CollectionTabs extends StatelessWidget {
  const _CollectionTabs({required this.state});
  final DatabaseState state;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final collection in state.collections)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: collection.name,
              child: ChoiceChip(
                showCheckmark: false,
                selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(collection.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                avatar: const Icon(CupertinoIcons.table, size: 18),
                selected: collection.name == state.collection?.name,
                onSelected: state.isMutating ? null : (_) => context.read<DatabaseCubit>().openCollection(collection),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Records extends StatelessWidget {
  const _Records({required this.state});
  final DatabaseState state;
  @override
  Widget build(BuildContext context) {
    if (state.records.isEmpty) {
      return const _Empty(
        title: 'Keine Datensätze gefunden',
        message: 'Lege einen Datensatz an oder passe deine Suche und Filter an.',
      );
    }
    final fields = state.records.expand((record) => record.fields.keys).toSet().toList()..sort();
    return DatabaseSheet(
      key: ValueKey(state.collection!.name),
      columns: fields.isEmpty ? ['Felder'] : fields,
      rows: state.records
          .map((record) => fields.isEmpty ? ['Leer'] : fields.map((field) => _display(record.fields[field])).toList())
          .toList(),
      enabled: !state.isMutating,
      onOpen: (index) => _edit(context, state.records[index]),
      onDelete: (index) => _delete(context, state.records[index]),
    );
  }

  String _display(Object? value) {
    if (value == null) return 'Leer';
    if (value is Map || value is List) return 'Strukturierte Daten';
    return '$value';
  }
}

Future<void> _edit(BuildContext context, [DataRecord? record]) async {
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

Future<void> _delete(BuildContext context, DataRecord record) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Datensatz löschen?'),
      content: const Text('Der Datensatz wird dauerhaft gelöscht.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<DatabaseCubit>().deleteRecord(record);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.table, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: context.read<DatabaseCubit>().loadCollections,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    ),
  );
}
