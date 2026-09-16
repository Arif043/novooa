import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

class DocumentLookupFilterEditor extends StatelessWidget {
  const DocumentLookupFilterEditor({
    super.key,
    required this.nodeId,
    required this.index,
    required this.filter,
    required this.canRemove,
  });

  final NodeId nodeId;
  final int index;
  final DocumentLookupFilter filter;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Suchbedingung ${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: filter.field,
            decoration: const InputDecoration(labelText: 'Feld'),
            onChanged: (value) => _update(context, field: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<DocumentFilterOperator>(
            initialValue: filter.operator,
            decoration: const InputDecoration(labelText: 'Vergleich'),
            items: DocumentFilterOperator.values.map(_operatorItem).toList(),
            onChanged: (value) => _update(context, operator: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: filter.value,
            decoration: const InputDecoration(labelText: 'Wert'),
            onChanged: (value) => _update(context, value: value),
          ),
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Suchbedingung entfernen',
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .removeDocumentLookupFilter(nodeId, index),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ),
        ],
      ),
    );
  }

  DropdownMenuItem<DocumentFilterOperator> _operatorItem(
    DocumentFilterOperator operator,
  ) {
    return DropdownMenuItem(value: operator, child: Text(operator.label));
  }

  void _update(
    BuildContext context, {
    String? field,
    DocumentFilterOperator? operator,
    String? value,
  }) {
    context.read<TaskBuilderCubit>().updateDocumentLookupFilter(
      nodeId,
      index,
      filter.copyWith(field: field, operator: operator, value: value),
    );
  }
}

extension on DocumentFilterOperator {
  String get label {
    return switch (this) {
      .equals => 'ist gleich',
      .notEquals => 'ist nicht gleich',
      .contains => 'enthält',
      .greaterThan => 'ist größer als',
      .greaterThanOrEqual => 'ist mindestens',
      .lessThan => 'ist kleiner als',
      .lessThanOrEqual => 'ist höchstens',
    };
  }
}
