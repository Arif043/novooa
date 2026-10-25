import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
          Text(
            LocaleKeys.ui_sammlung_als_tabelle.tr(),
            style: SyscatTheme.taskBody,
          ),
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

/// Dropdown mit den vorhandenen Datensammlungen.
class _CollectionField extends StatelessWidget {
  const _CollectionField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
            decoration: InputDecoration(labelText: LocaleKeys.ui_sammlung.tr()),
            onChanged: widget.onChanged,
          );
        }
        return _buildDropdown(snapshot.data ?? const []);
      },
    );
  }

  Widget _buildDropdown(List<DataCollection> collections) {
    if (collections.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(labelText: LocaleKeys.ui_sammlung.tr()),
        child: Text(LocaleKeys.ui_keine_sammlungen_vorhanden.tr()),
      );
    }
    final names = collections.map((collection) => collection.name).toSet();
    return DropdownButtonFormField<String>(
      initialValue: names.contains(widget.value) ? widget.value : null,
      decoration: InputDecoration(labelText: LocaleKeys.ui_sammlung.tr()),
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
    return InputDecorator(
      decoration: InputDecoration(labelText: LocaleKeys.ui_sammlung.tr()),
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
