import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../../data/domain/entities/data_collection.dart';
import '../../../data/domain/usecases/data_records.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

/// Konfigurationsfläche für „Sammlung als Tabelle": eine Collection-Auswahl,
/// sonst nichts — der Baustein gibt die gelesene Sammlung als Tabellen-Wert
/// weiter, ohne selbst eine Datei zu schreiben (das übernimmt „Datei
/// schreiben", wenn es einen solchen Wert als Eingabe erhält).
class TableFromCollectionWidget extends StatelessWidget {
  const TableFromCollectionWidget({super.key, required this.node});

  final WorkflowNode node;

  TableFromCollectionNodeConfig get _config =>
      node.config as TableFromCollectionNodeConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sammlung als Tabelle', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          _CollectionField(
            value: _config.collectionName,
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateTableFromCollectionCollectionName(node.id, value),
          ),
        ],
      ),
    );
  }
}

/// Echtes Dropdown mit vorhandenen Collections, wenn `ListDataCollections`
/// im aktuellen Laufzeitprofil registriert ist (Standalone-Profil) — sonst
/// ein einfaches Textfeld, wie es `documentLookup`/`saveDocument` bereits
/// verwenden (Cloud-Profil hat noch keinen Firestore-`DataRepository`).
class _CollectionField extends StatelessWidget {
  const _CollectionField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!serviceLocator.isRegistered<ListDataCollections>()) {
      return TemplateExpressionTextField(
        value: value,
        suggestions: TemplateExpressionScope.suggestionsOf(context),
        decoration: const InputDecoration(labelText: 'Sammlung'),
        onChanged: onChanged,
      );
    }
    return _CollectionDropdown(value: value, onChanged: onChanged);
  }
}

class _CollectionDropdown extends StatefulWidget {
  const _CollectionDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_CollectionDropdown> createState() => _CollectionDropdownState();
}

class _CollectionDropdownState extends State<_CollectionDropdown> {
  late final Future<List<DataCollection>> _collections =
      serviceLocator<ListDataCollections>()();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DataCollection>>(
      future: _collections,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _CollectionFieldLoading();
        }
        if (snapshot.hasError) {
          return TemplateExpressionTextField(
            value: widget.value,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: const InputDecoration(labelText: 'Sammlung'),
            onChanged: widget.onChanged,
          );
        }
        return _buildDropdown(snapshot.data ?? const []);
      },
    );
  }

  Widget _buildDropdown(List<DataCollection> collections) {
    if (collections.isEmpty) {
      return const InputDecorator(
        decoration: InputDecoration(labelText: 'Sammlung'),
        child: Text('Keine Sammlungen vorhanden'),
      );
    }
    final names = collections.map((collection) => collection.name).toSet();
    return DropdownButtonFormField<String>(
      initialValue: names.contains(widget.value) ? widget.value : null,
      decoration: const InputDecoration(labelText: 'Sammlung'),
      items: [
        for (final name in names)
          DropdownMenuItem(value: name, child: Text(name)),
      ],
      onChanged: (name) {
        if (name != null) widget.onChanged(name);
      },
    );
  }
}

class _CollectionFieldLoading extends StatelessWidget {
  const _CollectionFieldLoading();

  @override
  Widget build(BuildContext context) {
    return const InputDecorator(
      decoration: InputDecoration(labelText: 'Sammlung'),
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
