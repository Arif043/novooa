import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/data_filter.dart';
import '../cubits/database_cubit.dart';
import '../cubits/database_state.dart';

class DatabaseFilterBar extends StatelessWidget {
  const DatabaseFilterBar({required this.state, super.key});

  final DatabaseState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          key: ValueKey(state.collection!.name),
          decoration: const InputDecoration(
            labelText: 'Suchen',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: context.read<DatabaseCubit>().search,
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: context.read<DatabaseCubit>().addFilter,
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filter hinzufügen'),
          ),
        ),
        ...state.filters.indexed.map(
          (entry) => _FilterRow(index: entry.$1, filter: entry.$2),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.index, required this.filter});

  final int index;
  final DataFilter filter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DatabaseCubit>();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('filter-field-$index-${filter.field}'),
              initialValue: filter.field,
              decoration: const InputDecoration(labelText: 'Feld'),
              onFieldSubmitted: (value) => cubit.changeFilter(
                index,
                filter.copyWith(field: value.trim()),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: DropdownButtonFormField<DataFilterOperator>(
              initialValue: filter.operator,
              decoration: const InputDecoration(labelText: 'Vergleich'),
              items: DataFilterOperator.values
                  .map((operator) {
                    return DropdownMenuItem(
                      value: operator,
                      child: Text(operator.label),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  cubit.changeFilter(index, filter.copyWith(operator: value));
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: TextFormField(
              key: ValueKey('filter-value-$index-${filter.value}'),
              initialValue: '${filter.value}',
              decoration: const InputDecoration(labelText: 'Wert'),
              onFieldSubmitted: (value) => cubit.changeFilter(
                index,
                filter.copyWith(value: _valueFrom(value)),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filter entfernen',
            onPressed: () => cubit.removeFilter(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Object _valueFrom(String value) {
    final trimmed = value.trim();
    if (trimmed == 'true') return true;
    if (trimmed == 'false') return false;
    return num.tryParse(trimmed) ?? trimmed;
  }
}
