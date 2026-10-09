import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_search_filter.dart';
import 'model_filter_chips.dart';
import 'model_search_results.dart';
import 'model_search_selection.dart';

/// Durchsucht globalen Katalog und eigene Modelle; liefert das gewählte Modell zurück.
Future<ModelCatalogEntry?> showModelSearchSheet(
  BuildContext context, {
  SpeechModelDirection? speechDirection,
}) {
  final cubit = context.read<ModelCatalogCubit>();
  return showModalBottomSheet<ModelCatalogEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ModelSearchSheet(speechDirection: speechDirection),
    ),
  );
}

class _ModelSearchSheet extends StatefulWidget {
  const _ModelSearchSheet({required this.speechDirection});

  final SpeechModelDirection? speechDirection;

  @override
  State<_ModelSearchSheet> createState() => _ModelSearchSheetState();
}

class _ModelSearchSheetState extends State<_ModelSearchSheet> {
  String _query = '';
  ModelSearchSelection _selection = const ModelSearchSelection();

  @override
  Widget build(BuildContext context) {
    final filter = ModelSearchFilter(
      languageTag: Localizations.localeOf(context).toLanguageTag(),
      speechDirection: widget.speechDirection,
    );
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              LocaleKeys.ui_modell_auswaehlen.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: LocaleKeys
                    .ui_nach_name_beschreibung_oder_schlagwort_suchen
                    .tr(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            Expanded(
              child: BlocBuilder<ModelCatalogCubit, ModelCatalogState>(
                builder: (context, state) => _FilteredResults(
                  state: state,
                  filter: filter,
                  query: _query,
                  selection: _selection,
                  onSelectionChanged: (value) =>
                      setState(() => _selection = value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilteredResults extends StatelessWidget {
  const _FilteredResults({
    required this.state,
    required this.filter,
    required this.query,
    required this.selection,
    required this.onSelectionChanged,
  });

  final ModelCatalogState state;
  final ModelSearchFilter filter;
  final String query;
  final ModelSearchSelection selection;
  final ValueChanged<ModelSearchSelection> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final models = state.selectableEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModelFilterChips(
          facets: filter.facets(models, query, selection),
          selection: selection,
          showTasks: filter.fixedTask == null,
          onChanged: onSelectionChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ModelSearchResults(
            state: state,
            models: filter.apply(models, query, selection),
            hasQuery: query.trim().isNotEmpty,
            onResetFilters: selection.isActive
                ? () => onSelectionChanged(const ModelSearchSelection())
                : null,
          ),
        ),
      ],
    );
  }
}
