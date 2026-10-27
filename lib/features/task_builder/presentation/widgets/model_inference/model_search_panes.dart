import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_active_filters.dart';
import 'model_filter_sections.dart';
import 'model_search_results.dart';

class ModelSearchField extends StatelessWidget {
  const ModelSearchField({
    super.key,
    required this.controller,
    required this.autofocus,
  });

  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: LocaleKeys.ui_nach_name_beschreibung_oder_schlagwort_suchen
            .tr(),
      ),
    );
  }
}

/// Öffnet auf schmalen Bildschirmen die Filterseite; das Badge zählt die aktiven Filter.
class ModelFilterButton extends StatelessWidget {
  const ModelFilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(AppSpacing.xxl, AppSpacing.xxl),
      ),
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        child: const Icon(Icons.tune),
      ),
      label: Text(LocaleKeys.ui_filter.tr()),
    );
  }
}

/// Trefferliste mit den aktiven Filtern als entfernbare Chips darüber.
class ModelSearchMatches extends StatelessWidget {
  const ModelSearchMatches({
    super.key,
    required this.state,
    required this.models,
    required this.hasQuery,
    required this.activeFilters,
    required this.onResetFilters,
  });

  final ModelCatalogState state;
  final List<ModelCatalogEntry> models;
  final bool hasQuery;
  final List<ModelFilterOption> activeFilters;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    final hasFilters = activeFilters.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasFilters)
          ModelActiveFilters(options: activeFilters, onReset: onResetFilters),
        Expanded(
          child: ModelSearchResults(
            state: state,
            models: models,
            hasQuery: hasQuery,
            onResetFilters: hasFilters ? onResetFilters : null,
          ),
        ),
      ],
    );
  }
}
