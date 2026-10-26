import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_search_tile.dart';

/// Trefferliste mit Lade-, Fehler- und Leerzustand des globalen Katalogs.
class ModelSearchResults extends StatelessWidget {
  const ModelSearchResults({
    super.key,
    required this.state,
    required this.models,
    required this.hasQuery,
    this.onResetFilters,
  });

  final ModelCatalogState state;
  final List<ModelCatalogEntry> models;
  final bool hasQuery;

  /// Gesetzt, wenn Filter-Chips aktiv sind; der Leerzustand bietet dann das Zurücksetzen an.
  final VoidCallback? onResetFilters;

  bool get _catalogLoading =>
      state.globalStatus == ModelCatalogStatus.loading ||
      state.status == ModelCatalogStatus.loading;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty && _catalogLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.globalStatus == ModelCatalogStatus.failure)
          const _CatalogUnavailable(),
        Expanded(
          child: models.isEmpty
              ? _NoResults(hasQuery: hasQuery, onResetFilters: onResetFilters)
              : ListView.separated(
                  itemCount: models.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => ModelSearchTile(
                    model: models[index],
                    vocabulary: state.tagVocabulary,
                    onTap: () => Navigator.of(context).pop(models[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CatalogUnavailable extends StatelessWidget {
  const _CatalogUnavailable();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                LocaleKeys.ui_catalog_unreachable.tr(),
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: context.read<ModelCatalogCubit>().loadGlobal,
              child: Text(LocaleKeys.ui_erneut_versuchen.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.hasQuery, required this.onResetFilters});

  final bool hasQuery;
  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.ui_kein_modell_gefunden.tr(),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              onResetFilters != null
                  ? LocaleKeys.ui_no_match_for_filters.tr()
                  : hasQuery
                  ? LocaleKeys.ui_try_another_search_term.tr()
                  : LocaleKeys.ui_no_model_for_block.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onResetFilters case final reset?) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: reset,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(LocaleKeys.ui_filter_zuruecksetzen.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
